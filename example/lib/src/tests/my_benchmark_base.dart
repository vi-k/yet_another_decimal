import 'dart:math';

import 'package:ansi_escape_codes/ansi_escape_codes.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

import '../operations.dart';
import '../packages.dart';
import '../utils/output.dart';

abstract base class MyBenchmarkBase extends BenchmarkBase {
  final Package package;
  final Op operation;
  final Object? expectedExerciseResult;

  String? resultMessage;
  String? error;
  double? score;

  MyBenchmarkBase(
    this.package,
    this.operation, [
    this.expectedExerciseResult,
  ]) : super(package.id);

  bool get hasError => error != null;

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

    if (!isWarning) {
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
          result = add();
        }

      case Op.multiply:
        for (var i = 0; i < count; i++) {
          result = multiply();
        }

      case Op.divide:
        for (var i = 0; i < count; i++) {
          result = divide();
        }

      case Op.divideAndView:
        for (var i = 0; i < count; i++) {
          result = divideAndView();
        }

      case Op.rawView:
        for (var i = 0; i < count; i++) {
          result = rawView();
        }

      case Op.preparedView:
        prepareValues();
        for (var i = 0; i < count; i++) {
          result = preparedView();
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

  void prepareValues();

  List<String> preparedView();
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

  if (end == actual.length && actual.length < expected.length) {
    return (expectedReturn, isWarning ? warning(actual) : error(actual));
  }

  final rest = actual.substring(end);
  return (
    expectedReturn,
    '${actual.substring(0, end)}${isWarning ? warning(rest) : error(rest)}'
  );
}
