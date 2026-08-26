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

  /// Scores of every run of the series, µs per cycle, in the order measured.
  final List<double> scores = <double>[];

  String? resultMessage;
  String? error;

  MyBenchmarkBase(
    this.package,
    this.operation, [
    this.expectedExerciseResult,
  ]) : super(package.id);

  bool get hasError => error != null;

  /// The median of [scores], `null` until the benchmark has been measured.
  ///
  /// The median rather than the mean: a single run interrupted by the OS must
  /// not drag the whole series with it.
  double? get score {
    if (scores.isEmpty) {
      return null;
    }

    final sorted = scores.toList()..sort();
    final middle = sorted.length ~/ 2;

    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }

  /// The best and the worst run of the series, µs per cycle.
  ///
  /// Printed next to [score] to make the drift of the machine visible.
  (double, double)? get spread {
    if (scores.isEmpty) {
      return null;
    }

    return (scores.reduce(min), scores.reduce(max));
  }

  @override
  void setup() {
    final result = convertResult(exercise(1));

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

    if (!isWarning && !package.ignoreMatchingErrors) {
      error = "The results don't match";
    }
  }

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
        prepareValues();
        for (var i = 0; i < count; i++) {
          blackhole = result = repeatView();
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

  /// Warms up whatever the package caches on the first conversion.
  ///
  /// Runs the very code [repeatView] measures, so that the measured cycles see
  /// only the second and later conversion of the same value.
  void prepareValues() {
    repeatView();
  }

  List<String> repeatView();
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
