import 'package:benchmark_harness/benchmark_harness.dart';

import '../operations.dart';
import '../packages.dart';

abstract base class MyBenchmarkBase extends BenchmarkBase {
  final Package package;
  final Op operation;
  final String? expectedExerciseResult;

  String? resultMessage;

  MyBenchmarkBase(
    this.package,
    this.operation, [
    this.expectedExerciseResult,
  ]) : super('${package.group ?? package.id} (${package.type})');

  @override
  void setup() {
    final result = exercise(1);

    if (expectedExerciseResult == null) {
      resultMessage = null;
    } else {
      if (result == expectedExerciseResult) {
        resultMessage = 'ok';
      } else {
        resultMessage = 'FAILED!!!'
            ' expected: $expectedExerciseResult'
            ' actual: $result';
      }
    }
  }

  @override
  void warmup() {
    exercise(1);
  }

  @override
  String exercise([int? count]) {
    count ??= operation.numberOfCycles;
    Object? result;

    for (var i = 0; i < count; i++) {
      switch (operation) {
        case Op.add:
          result = add();

        case Op.multiply:
          result = multiply();

        case Op.divide:
          result = divide();

        case Op.convertToString:
          result = convertToString();
      }
    }

    return result.toString();
  }

  Object? add();

  Object? multiply();

  Object? divide();

  Object? convertToString();
}
