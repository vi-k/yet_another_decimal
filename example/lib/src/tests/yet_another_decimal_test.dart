import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../operations.dart';
import '../packages.dart';
import 'my_benchmark_base.dart';

final class YetAnotherDecimalTest extends MyBenchmarkBase {
  final List<Decimal> values;

  /// One cycle's worth of strings.
  ///
  /// Late because the runner sets [viewLength] after the benchmark is
  /// built: for a pooled `raw-view` set one cycle is a small part of it.
  late final List<String> _convertToStringResult =
      List<String>.filled(viewLength, '');
  final List<Object> _objectResult;

  YetAnotherDecimalTest(
    List<(BigInt, int)> list,
    Op operation,
    Object? expectedExerciseResult,
  )   : values = list
            .map(
              (e) => Decimal.fromBigInt(e.$1, shiftRight: e.$2),
            )
            .toList(growable: false),
        _objectResult = List<Object>.filled(list.length, ''),
        super(
          Package.yetAnotherDecimal,
          operation,
          expectedExerciseResult,
        );

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
      result /= values[i];
    }

    return result;
  }

  @override
  Object divideAndView() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result /= values[i];
    }

    return result.toString();
  }

  @override
  List<String> rawView() {
    final start = beginView(values.length);
    final length = viewLength;
    for (var i = 0; i < length; i++) {
      // ignore: unnecessary_parenthesis
      final value = -(-values[start + i]);
      _convertToStringResult[i] = value.toString();
    }

    return _convertToStringResult;
  }

  @override
  List<String> repeatView() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      _convertToStringResult[i] = values[i].toString();
    }

    return _convertToStringResult;
  }

  static final _three = Decimal(3);

  @override
  Object parse() {
    final length = inputs.length;
    for (var i = 0; i < length; i++) {
      _objectResult[i] = Decimal.parse(inputs[i]);
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
      _objectResult[i] = values[i].round(MyBenchmarkBase.moneyDigits);
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
  List<String> toStringAsFixed() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      _convertToStringResult[i] =
          values[i].toStringAsFixed(MyBenchmarkBase.moneyDigits);
    }

    return _convertToStringResult;
  }

  @override
  Object unrepresentableDivide() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      _objectResult[i] = values[i].divide(
        _three,
        scaleOnInfinitePrecision: MyBenchmarkBase.infiniteDigits,
      );
    }

    return _objectResult;
  }
}
