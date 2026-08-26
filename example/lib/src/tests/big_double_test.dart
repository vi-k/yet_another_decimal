import 'package:big_double/big_double.dart';

import '../operations.dart';
import '../packages.dart';
import 'my_benchmark_base.dart';

final class BigDoubleTest extends MyBenchmarkBase {
  final List<BigDouble> values;
  final List<String> _convertToStringResult;
  final List<Object> _objectResult;

  BigDoubleTest(
    List<(BigInt, int)> list,
    Op operation,
    Object? expectedExerciseResult,
  )   : values = list
            .map(
              (e) => BigDouble.parse(_toStr(e.$1, e.$2)),
            )
            .toList(growable: false),
        _convertToStringResult = List<String>.filled(list.length, ''),
        _objectResult = List<Object>.filled(list.length, ''),
        super(
          Package.bigDouble,
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
      result = result / values[i];
    }

    return result;
  }

  @override
  Object divideAndView() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result = result / values[i];
    }

    return result.toString();
  }

  @override
  List<String> rawView() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      // ignore: unnecessary_parenthesis
      final value = -(-values[i]);
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
      _objectResult[i] = BigDouble.parse(inputs[i]);
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
