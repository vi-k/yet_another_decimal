import 'dart:math';

import 'package:ansi_escape_codes/ansi_escape_codes.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

import '../operations.dart';
import '../packages.dart';
import '../utils/output.dart';

abstract base class MyBenchmarkBase extends BenchmarkBase {
  /// A sink for the results of the measured cycles.
  ///
  /// Only the last cycle escapes from [exercise]; without a sink the optimizer
  /// is free to drop the rest. A write to a static field it cannot drop.
  static Object? blackhole;

  final Package package;
  final Op operation;
  final Object? expectedExerciseResult;

  /// Scores of every run of the current pass, µs per cycle, in the order
  /// measured.
  final List<double> scores = <double>[];

  /// The median of every pass closed so far, µs per cycle.
  final List<double> passes = <double>[];

  /// The input of [Op.parse], the same strings for every package.
  ///
  /// Filled in by the runner before the benchmark is measured: every adapter
  /// gets the values in its own type, and the strings they were built from
  /// must not depend on how a package prints them.
  List<String> inputs = const <String>[];

  /// How many values one cycle of a view benchmark converts.
  ///
  /// Filled in by the runner before the benchmark is measured, like [inputs].
  /// For most tests it is the whole set. For `raw-view` the set is a pool of
  /// many cycles' worth of values and this is one cycle of it.
  int viewWindow = 0;

  /// Where the next cycle of a view benchmark starts inside the pool.
  int viewCursor = 0;

  /// How many values this cycle converts.
  int get viewLength => viewWindow;

  /// Answers where this cycle reads from, and moves the cursor on.
  ///
  /// `raw-view` is meant to be a first conversion, so no value may be
  /// converted twice while it could still be remembered. The pool is several
  /// times larger than any cache in the comparison and is walked in order, so
  /// by the time the cursor comes back around, the entry has been evicted —
  /// a table keyed by the value misses as surely as one keyed by the object.
  int beginView(int poolLength) {
    if (viewWindow <= 0 || viewWindow >= poolLength) {
      return 0;
    }

    final start = viewCursor;
    final next = start + viewWindow;
    viewCursor = next + viewWindow > poolLength ? 0 : next;

    return start;
  }

  String? resultMessage;
  String? error;

  /// Whether the answer differed from the expected one by more than trailing
  /// zeros.
  ///
  /// Kept apart from [error]: a package excluded from the comparison keeps its
  /// timing even when it answers wrongly, and a wrong answer must not be
  /// decorated as a fast one.
  bool wrongAnswer = false;

  /// How many digits [round] and [toStringAsFixed] keep: money.
  static const int moneyDigits = 2;

  /// How many digits [unrepresentableDivide] keeps.
  ///
  /// Ten and no more: the result has to stay inside int64, otherwise
  /// `ShortDecimal` would be measured overflowing instead of dividing.
  static const int infiniteDigits = 10;

  MyBenchmarkBase(
    this.package,
    this.operation, [
    this.expectedExerciseResult,
  ]) : super(package.id);

  bool get hasError => error != null;

  /// The number the summary shows: the best pass.
  ///
  /// A whole pass can be swallowed by unrelated load on the machine — a burst
  /// that outlasts the eleven seconds of one series leaves its median as
  /// wrong as any single run, and the spread looks respectable throughout.
  /// Load can only ever make a benchmark slower, so the best of several
  /// passes is the honest estimate, and the median is what defends each pass
  /// against a single bad run inside it.
  double? get score => passes.isEmpty ? currentPass : passes.reduce(min);

  /// Closes the current pass: its median joins [passes], its runs are dropped.
  void endPass() {
    final median = currentPass;
    if (median != null) {
      passes.add(median);
      scores.clear();
    }
  }

  /// The median of [scores], `null` until the pass has been measured.
  ///
  /// The median rather than the mean: a single run interrupted by the OS must
  /// not drag the whole series with it.
  double? get currentPass {
    if (scores.isEmpty) {
      return null;
    }

    final sorted = scores.toList()..sort();
    final middle = sorted.length ~/ 2;

    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }

  /// The best and the worst run of the current pass, µs per cycle.
  ///
  /// Printed next to the pass median to make the drift of the machine
  /// visible.
  (double, double)? get spread {
    if (scores.isEmpty) {
      return null;
    }

    return (scores.reduce(min), scores.reduce(max));
  }

  /// Runs one cycle, or every cycle of the pool when the values are pooled,
  /// and answers with all of them at once.
  ///
  /// The whole pool is checked, not just its first cycle: the values a check
  /// never looks at are exactly the ones a package could get wrong unnoticed.
  /// This runs outside the measurement, and it leaves the cursor where it
  /// found it.
  Object? _exerciseEveryWindow() {
    final expected = expectedExerciseResult;
    final windows =
        expected is List && viewWindow > 0 ? expected.length ~/ viewWindow : 1;

    viewCursor = 0;
    if (windows <= 1) {
      final result = exercise(1);
      viewCursor = 0;

      return result;
    }

    final all = <Object>[];
    for (var i = 0; i < windows; i++) {
      all.addAll(exercise(1)! as List<Object>);
    }
    viewCursor = 0;

    return all;
  }

  @override
  void setup() {
    final result = convertResult(_exerciseEveryWindow());

    resultMessage = null;

    final expectedExerciseResult = this.expectedExerciseResult;
    if (expectedExerciseResult == null) {
      return;
    }

    final resultString = result.toString();
    final expectedResultString = expectedExerciseResult.toString();
    if (resultString == expectedResultString) {
      resultMessage = ok('OK');
      return;
    }

    var isWarning = false;
    String description;

    if (result is List<Object> && expectedExerciseResult is List<Object>) {
      final resultWithoutTrailingZeros = result
          .map((e) => e.toString().removeTrailingZeros())
          .toList(growable: false)
          .toString();
      final count = min(result.length, expectedExerciseResult.length);
      final expectedList = <String>[];
      final actualList = <String>[];

      isWarning = resultWithoutTrailingZeros == expectedResultString;

      for (var i = 0; i < count; i++) {
        final (expected, actual) = _diff(
          expectedExerciseResult[i].toString(),
          result[i].toString(),
          isWarning: isWarning,
        );
        expectedList.add(expected);
        actualList.add(actual);
      }

      for (var i = count; i < actualList.length; i++) {
        actualList.add('$error${result[i]}$reset');
      }

      description = '\n ${actualList.join('\n ')}';
    } else {
      if (resultString.removeTrailingZeros() == expectedExerciseResult) {
        isWarning = true;
      }

      final (expected, actual) = _diff(
        expectedResultString,
        resultString,
        isWarning: isWarning,
      );

      description = '\n ${accent('expected:')} $expected'
          '\n ${accent('actual:')}   $actual';
    }

    resultMessage =
        '${isWarning ? accentWarning('WARNING') : accentError('ERROR')}'
        '$reset$description';

    wrongAnswer = !isWarning;

    if (!isWarning && !package.ignoreMatchingErrors) {
      error = "The results don't match";
    }
  }

  /// Runs one unmeasured cycle before the measured ones.
  ///
  /// For `repeat-view` this is also what fills whatever the package caches on
  /// the first conversion, so that the measured cycles see only the second and
  /// later conversion of the same value. It used to be a separate call inside
  /// [exercise], where it added a cycle to every hundred measured — one per
  /// cent, taken off the top of every package alike.
  @override
  void warmup() {
    exercise(1);
  }

  @override
  Object? exercise([int? count]) {
    count ??= operation.numberOfCycles;
    Object? result;

    switch (operation) {
      case Op.add:
        for (var i = 0; i < count; i++) {
          blackhole = result = add();
        }

      case Op.multiply:
        for (var i = 0; i < count; i++) {
          blackhole = result = multiply();
        }

      case Op.divide:
        for (var i = 0; i < count; i++) {
          blackhole = result = divide();
        }

      case Op.divideAndView:
        for (var i = 0; i < count; i++) {
          blackhole = result = divideAndView();
        }

      case Op.rawView:
        for (var i = 0; i < count; i++) {
          blackhole = result = rawView();
        }

      case Op.repeatView:
        for (var i = 0; i < count; i++) {
          blackhole = result = repeatView();
        }

      case Op.parse:
        for (var i = 0; i < count; i++) {
          blackhole = result = parse();
        }

      case Op.compare:
        for (var i = 0; i < count; i++) {
          blackhole = result = compare();
        }

      case Op.round:
        for (var i = 0; i < count; i++) {
          blackhole = result = round();
        }

      case Op.toDouble:
        for (var i = 0; i < count; i++) {
          blackhole = result = toDouble();
        }

      case Op.toStringAsFixed:
        for (var i = 0; i < count; i++) {
          blackhole = result = toStringAsFixed();
        }

      case Op.unrepresentableDivide:
        for (var i = 0; i < count; i++) {
          blackhole = result = unrepresentableDivide();
        }
    }

    return result;
  }

  Object? convertResult(Object? result) => result;

  Object add();

  Object multiply();

  Object divide();

  Object divideAndView();

  List<String> rawView();

  List<String> repeatView();

  /// Everything below is optional: a package that has no such operation says
  /// so by throwing [UnsupportedOperation].
  Object parse() => throw UnsupportedOperation(package, operation);

  Object compare() => throw UnsupportedOperation(package, operation);

  Object round() => throw UnsupportedOperation(package, operation);

  Object toDouble() => throw UnsupportedOperation(package, operation);

  List<String> toStringAsFixed() =>
      throw UnsupportedOperation(package, operation);

  Object unrepresentableDivide() =>
      throw UnsupportedOperation(package, operation);
}

/// Raised by a benchmark for an operation the package does not have.
///
/// Not an error: an absent method is not a wrong answer, and a package must
/// not be shown as failing for the lack of one.
final class UnsupportedOperation implements Exception {
  const UnsupportedOperation(this.package, this.operation);

  final Package package;
  final Op operation;

  @override
  String toString() => '${package.id} has no ${operation.id}';
}

extension on String {
  String removeTrailingZeros() {
    final dotIndex = indexOf('.');
    if (dotIndex == -1) {
      return this;
    }

    var r = this;
    if (r[r.length - 1] != '0') {
      return this;
    }

    do {
      r = r.substring(0, r.length - 1);
    } while (r[r.length - 1] == '0');

    if (r[r.length - 1] == '.') {
      r = r.substring(0, r.length - 1);
    }

    return r;
  }
}

(String, String) _diff(
  String expected,
  String actual, {
  bool isWarning = false,
}) {
  final minLength = min(expected.length, actual.length);
  final maxLength = max(expected.length, actual.length);
  final expectedReturn = expected.padRight(maxLength);

  var end = 0;
  while (end < minLength && expected[end] == actual[end]) {
    end++;
  }

  final absent = actual.length >= expected.length
      ? ''
      : '•' * (expected.length - actual.length);

  final rest = actual.substring(end);
  return (
    expectedReturn,
    '${actual.substring(0, end)}'
        '${isWarning ? warning(rest) : error(rest)}'
        '${isWarning ? warning(absent) : error(absent)}'
  );
}
