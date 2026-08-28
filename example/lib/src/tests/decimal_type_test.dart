import 'package:decimal_type/decimal_type.dart';

import '../operations.dart';
import '../packages.dart';
import 'my_benchmark_base.dart';

final class DecimalTypeTest extends MyBenchmarkBase {
  final List<Decimal> values;

  /// One cycle's worth of strings.
  ///
  /// Late because the runner sets [viewLength] after the benchmark is
  /// built: for a pooled `raw-view` set one cycle is a small part of it.
  late final List<String> _convertToStringResult =
      List<String>.filled(viewLength, '');
  final List<Object> _objectResult;

  DecimalTypeTest(
    List<(BigInt, int)> list,
    Op operation,
    Object? expectedExerciseResult,
  )   : values = list
            .map(
              (e) => Decimal.fromString(_toStr(e.$1, e.$2)),
            )
            .toList(growable: false),
        _objectResult = List<Object>.filled(list.length, ''),
        super(
          Package.decimalType,
          operation,
          expectedExerciseResult,
        );

  static String _toStr(BigInt n, int decimalPrecision) {
    final str = n.toString();
    if (str.length <= decimalPrecision) {
      return '0.${str.padLeft(decimalPrecision, '0')}';
    }

    final i = str.substring(0, str.length - decimalPrecision);
    final f = str.substring(str.length - decimalPrecision);
    return '${i.isEmpty ? '0' : i}.${f.isEmpty ? '0' : f}';
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
      _objectResult[i] = Decimal.fromString(inputs[i]);
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
  Object toDouble() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      _objectResult[i] = values[i].toDouble();
    }

    return _objectResult;
  }
}
