import 'package:denary/denary.dart';

import '../operations.dart';
import '../packages.dart';
import 'my_benchmark_base.dart';

final class YetAnotherDecimalShortTest extends MyBenchmarkBase {
  final List<ShortDecimal> values;

  /// One cycle's worth of strings.
  ///
  /// Late because the runner sets [viewLength] after the benchmark is
  /// built: for a pooled `raw-view` set one cycle is a small part of it.
  late final List<String> _convertToStringResult =
      List<String>.filled(viewLength, '');
  final List<Object> _objectResult;

  YetAnotherDecimalShortTest(
    List<(int, int)> list,
    Op operation,
    Object? expectedExerciseResult,
  )   : values = list.map(
          (e) {
            final scale = e.$2;

            return scale < 0
                ? ShortDecimal(e.$1, shiftLeft: -scale)
                : ShortDecimal(e.$1, shiftRight: scale);
          },
        ).toList(growable: false),
        _objectResult = List<Object>.filled(list.length, ''),
        super(
          Package.yetAnotherDecimalShort,
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

  static final _three = ShortDecimal(3);

  static final _wideDivisor = ShortDecimal.parse(MyBenchmarkBase.wideDivisor);

  @override
  Object parse() {
    final length = inputs.length;
    for (var i = 0; i < length; i++) {
      _objectResult[i] = ShortDecimal.parse(inputs[i]);
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

  @override
  Object unrepresentableDivideWide() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      _objectResult[i] = values[i].divide(
        _wideDivisor,
        scaleOnInfinitePrecision: MyBenchmarkBase.infiniteDigits,
      );
    }

    return _objectResult;
  }
}
