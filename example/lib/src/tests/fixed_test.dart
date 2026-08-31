import 'package:fixed/fixed.dart';

import '../operations.dart';
import '../packages.dart';
import 'my_benchmark_base.dart';

final class FixedTest extends MyBenchmarkBase {
  final List<Fixed> values;

  /// One cycle's worth of strings.
  ///
  /// Late because the runner sets [viewLength] after the benchmark is
  /// built: for a pooled `raw-view` set one cycle is a small part of it.
  late final List<String> _convertToStringResult =
      List<String>.filled(viewLength, '');
  final List<Object> _objectResult;

  FixedTest(
    List<(BigInt, int)> list,
    Op operation,
    Object? expectedExerciseResult,
  )   : values = list
            .map(
              (e) => Fixed.fromBigInt(e.$1, decimalDigits: e.$2),
            )
            .toList(growable: false),
        _objectResult = List<Object>.filled(list.length, ''),
        super(
          Package.fixed,
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

  @override
  Object parse() {
    final length = inputs.length;
    for (var i = 0; i < length; i++) {
      _objectResult[i] = Fixed.parse(inputs[i]);
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
      _objectResult[i] =
          values[i].copyWith(decimalDigits: MyBenchmarkBase.moneyDigits);
    }

    return _objectResult;
  }

  /// Three, carrying the digits the answer is asked for.
  ///
  /// `Fixed` takes no argument for how far to divide. `operator /` gives the
  /// quotient as many digits as the wider of its two operands had, and it
  /// widens both operands itself, so a divisor already that wide is how this
  /// package is told what is wanted. The divisor is a constant and is built
  /// once, the way every other adapter builds its own; the widening of each
  /// dividend still happens inside the division, where it belongs.
  static final _three =
      Fixed.parse('3', decimalDigits: MyBenchmarkBase.infiniteDigits);

  /// [MyBenchmarkBase.wideDivisor], carrying the same digits as [_three].
  static final _wideDivisor = Fixed.parse(
    MyBenchmarkBase.wideDivisor,
    decimalDigits: MyBenchmarkBase.infiniteDigits,
  );

  @override
  Object unrepresentableDivide() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      _objectResult[i] = values[i] / _three;
    }

    return _objectResult;
  }

  @override
  Object unrepresentableDivideWide() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      _objectResult[i] = values[i] / _wideDivisor;
    }

    return _objectResult;
  }
}
