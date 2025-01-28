import 'package:big_decimal/big_decimal.dart';

import '../operations.dart';
import '../packages.dart';
import 'my_benchmark_base.dart';

final class BigDecimalTest extends MyBenchmarkBase {
  final List<BigDecimal> values;
  final List<String> _convertToStringResult;

  BigDecimalTest(
    List<(BigInt, int)> list,
    Op operation,
    Object? expectedExerciseResult,
  )   : values = list
            .map(
              (e) => BigDecimal.createAndStripZerosForScale(e.$1, e.$2, e.$2),
            )
            .toList(growable: false),
        _convertToStringResult = List<String>.filled(list.length, ''),
        super(
          Package.bigDecimal,
          operation,
          expectedExerciseResult,
        );

  @override
  Object? convertResult(Object? result) {
    final r = switch (result) {
      BigDecimal() => result.toPlainString(),
      List<BigDecimal>() =>
        result.map((e) => e.toPlainString()).toList(growable: false),
      _ => result,
    };

    return r;
  }

  @override
  Object add() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result += values[i];
    }

    return result;
  }

  @override
  Object multiply() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result *= values[i];
    }

    return result;
  }

  @override
  Object divide() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result = result.divide(values[i]);
    }

    return result;
  }

  @override
  Object divideAndView() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result = result.divide(values[i]);
    }

    return result.toString();
  }

  @override
  List<String> rawView() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      // ignore: unnecessary_parenthesis
      final value = -(-values[i]);
      _convertToStringResult[i] = value.toPlainString();
    }

    return _convertToStringResult;
  }

  @override
  void prepareValues() {}

  @override
  List<String> preparedView() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      _convertToStringResult[i] = values[i].toPlainString();
    }

    return _convertToStringResult;
  }
}
