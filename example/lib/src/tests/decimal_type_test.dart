import 'package:decimal_type/decimal_type.dart';

import '../operations.dart';
import '../packages.dart';
import 'my_benchmark_base.dart';

final class DecimalTypeTest extends MyBenchmarkBase {
  final List<Decimal> values;
  final List<String> _convertToStringResult;

  DecimalTypeTest(
    List<(BigInt, int)> list,
    Op operation,
    String? expectedExerciseResult,
  )   : values = list
            .map(
              (e) => Decimal.fromString(_toStr(e.$1, e.$2)),
            )
            .toList(),
        _convertToStringResult = List<String>.filled(list.length, ''),
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
  Decimal add() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result += values[i];
    }

    return result;
  }

  @override
  Decimal multiply() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result *= values[i];
    }

    return result;
  }

  @override
  Decimal divide() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result /= values[i];
    }

    return result;
  }

  @override
  List<String> convertToString() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      _convertToStringResult[i] = values[i].toString();
    }

    return _convertToStringResult;
  }
}
