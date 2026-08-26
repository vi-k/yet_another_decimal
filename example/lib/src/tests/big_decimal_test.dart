import 'package:big_decimal/big_decimal.dart';

import '../operations.dart';
import '../packages.dart';
import 'my_benchmark_base.dart';

final class BigDecimalTest extends MyBenchmarkBase {
  final List<BigDecimal> values;
  final List<String> _convertToStringResult;
  final List<Object> _objectResult;

  BigDecimalTest(
    List<(BigInt, int)> list,
    Op operation,
    Object? expectedExerciseResult,
  )   : values = list
            .map(
              (e) => BigDecimal(intVal: e.$1, scale: e.$2),
            )
            .toList(growable: false),
        _convertToStringResult = List<String>.filled(list.length, ''),
        _objectResult = List<Object>.filled(list.length, ''),
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
      // `parse`, `round` and `unrepresentableDivide` answer with a list that
      // holds the package's own type but is typed as `List<Object>`.
      List<Object>() => result
          .map((e) => e is BigDecimal ? e.toPlainString() : e)
          .toList(growable: false),
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
  List<String> repeatView() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      _convertToStringResult[i] = values[i].toPlainString();
    }

    return _convertToStringResult;
  }

  static final _three = BigDecimal.parse('3');

  @override
  Object parse() {
    final length = inputs.length;
    for (var i = 0; i < length; i++) {
      _objectResult[i] = BigDecimal.parse(inputs[i]);
    }

    return _objectResult;
  }

  @override
  Object compare() {
    var result = 0;
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result += values[i - 1].compareTo(values[i]).sign;
    }

    return result;
  }

  @override
  Object round() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      _objectResult[i] = values[i].withScale(
        MyBenchmarkBase.moneyDigits,
        roundingMode: RoundingMode.HALF_UP,
      );
    }

    return _objectResult;
  }

  @override
  Object toDouble() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      _objectResult[i] = values[i].toDouble();
    }

    return _objectResult;
  }

  @override
  Object unrepresentableDivide() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      _objectResult[i] = values[i].divide(
        _three,
        roundingMode: RoundingMode.HALF_UP,
        scale: MyBenchmarkBase.infiniteDigits,
      );
    }

    return _objectResult;
  }
}
