import 'operations.dart';
import 'packages.dart';
import 'tests.dart';
import 'tests/decimal2_short_test.dart';
import 'tests/decimal2_test.dart';
import 'tests/decimal_test.dart';
import 'tests/decimal_type_test.dart';
import 'tests/fixed_test.dart';
import 'tests/my_benchmark_base.dart';

void _measure(Set<Package> packages, MyBenchmarkBase benchmark) {
  if (packages.contains(benchmark.package)) {
    try {
      final score = benchmark.measure();
      final msg = benchmark.resultMessage;

      print(
        '${benchmark.name}: ${score.toStringAsFixed(1)} us'
        '${msg == null ? '' : ' <- $msg'}',
      );
    } on Object catch (e) {
      print('${benchmark.name} <- FAILED!!! $e');
      // rethrow;
    }
  }
}

void run({
  required Set<Package> packages,
  required Set<Test> tests,
}) {
  if (tests.contains(Test.addBigInt)) {
    print('\n*** add BigInt values ***');

    final values = List<(BigInt, int)>.generate(
      40,
      (index) => (BigInt.parse('10000000000000000000'), index),
      growable: false,
    );
    const result = '11111111111111111111.11111111111111111111';

    _measure(packages, DecimalTest(values, Op.add, result));
    _measure(packages, FixedTest(values, Op.add, result));
    _measure(packages, DecimalTypeTest(values, Op.add, result));
    _measure(packages, Decimal2Test(values, Op.add, result));
  }

  if (tests.contains(Test.addInt)) {
    print('\n*** add int values ***');

    final values = List<(int, int)>.generate(
      16,
      (index) => (10000000, index),
      growable: false,
    );
    final bigValues =
        values.map((e) => (BigInt.from(e.$1), e.$2)).toList(growable: false);
    const result = '11111111.11111111';

    _measure(packages, DecimalTest(bigValues, Op.add, result));
    _measure(packages, FixedTest(bigValues, Op.add, result));
    _measure(packages, DecimalTypeTest(bigValues, Op.add, result));
    _measure(packages, Decimal2Test(bigValues, Op.add, result));
    _measure(packages, Decimal2ShortTest(values, Op.add, result));
  }

  if (tests.contains(Test.multiplyBigInt)) {
    print('\n*** multiply BigInt values ***');

    final values = List<(BigInt, int)>.generate(
      6,
      (index) => (BigInt.from(123456), index),
      growable: false,
    );
    const result = '3540570200530940.541182574329856';

    _measure(packages, DecimalTest(values, Op.multiply, result));
    _measure(packages, FixedTest(values, Op.multiply, result));
    _measure(packages, DecimalTypeTest(values, Op.multiply, result));
    _measure(packages, Decimal2Test(values, Op.multiply, result));
  }

  if (tests.contains(Test.multiplyInt)) {
    print('\n*** multiply int values ***');

    final values = List<(int, int)>.generate(
      6,
      (index) => (123, index),
      growable: false,
    );
    final bigValues =
        values.map((e) => (BigInt.from(e.$1), e.$2)).toList(growable: false);
    const result = '0.003462825991689';

    _measure(packages, DecimalTest(bigValues, Op.multiply, result));
    _measure(packages, FixedTest(bigValues, Op.multiply, result));
    _measure(packages, DecimalTypeTest(bigValues, Op.multiply, result));
    _measure(packages, Decimal2Test(bigValues, Op.multiply, result));
    _measure(packages, Decimal2ShortTest(values, Op.multiply, result));
  }

  if (tests.contains(Test.divideBigInt)) {
    print('\n*** divide BigInt values ***');

    final values = List<(BigInt, int)>.generate(
      6,
      (index) => index == 0
          ? (BigInt.parse('3540570200530940541182574329856'), 15)
          : (BigInt.from(123456), index - 1),
      growable: false,
    );
    const result = '1.23456';

    _measure(packages, DecimalTest(values, Op.divide, result));
    _measure(packages, FixedTest(values, Op.divide, result));
    _measure(packages, DecimalTypeTest(values, Op.divide, result));
    _measure(packages, Decimal2Test(values, Op.divide, result));
  }

  if (tests.contains(Test.divideInt)) {
    print('\n*** divide int values ***');

    final values = List<(int, int)>.generate(
      6,
      (index) => index == 0 ? (3462825991689, 15) : (123, index - 1),
      growable: false,
    );
    final bigValues =
        values.map((e) => (BigInt.from(e.$1), e.$2)).toList(growable: false);
    const result = '0.00123';

    _measure(packages, DecimalTest(bigValues, Op.divide, result));
    _measure(packages, FixedTest(bigValues, Op.divide, result));
    _measure(packages, DecimalTypeTest(bigValues, Op.divide, result));
    _measure(packages, Decimal2Test(bigValues, Op.divide, result));
    _measure(packages, Decimal2ShortTest(values, Op.divide, result));
  }

  if (tests.contains(Test.convertToStringBigInt)) {
    print('\n*** toString BigInt values ***');

    final values = List<(BigInt, int)>.generate(
      40,
      (index) => (BigInt.parse('10000000000000000000'), index),
      growable: false,
    );
    final result = [
      for (var i = 0; i < 20; i++) '1${'0' * (19 - i)}',
      for (var i = 0; i < 20; i++) '0.${'0' * i}1',
    ].toString();

    _measure(packages, DecimalTest(values, Op.convertToString, result));
    _measure(packages, FixedTest(values, Op.convertToString, result));
    _measure(packages, DecimalTypeTest(values, Op.convertToString, result));
    _measure(packages, Decimal2Test(values, Op.convertToString, result));
  }

  if (tests.contains(Test.convertToStringInt)) {
    print('\n*** toString int values ***');

    final values = List<(int, int)>.generate(
      20,
      (index) => (1000000000, index),
      growable: false,
    );
    final bigValues =
        values.map((e) => (BigInt.from(e.$1), e.$2)).toList(growable: false);
    final result = [
      for (var i = 0; i < 10; i++) '1${'0' * (9 - i)}',
      for (var i = 0; i < 10; i++) '0.${'0' * i}1',
    ].toString();

    _measure(packages, DecimalTest(bigValues, Op.convertToString, result));
    _measure(packages, FixedTest(bigValues, Op.convertToString, result));
    _measure(packages, DecimalTypeTest(bigValues, Op.convertToString, result));
    _measure(packages, Decimal2Test(bigValues, Op.convertToString, result));
    _measure(packages, Decimal2ShortTest(values, Op.convertToString, result));
  }
}
