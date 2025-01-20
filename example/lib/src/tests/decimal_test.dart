import 'package:decimal/decimal.dart';

import '../operations.dart';
import '../packages.dart';
import 'my_benchmark_base.dart';

final class DecimalTest extends MyBenchmarkBase {
  final List<Decimal> values;
  final List<String> _convertToStringResult;

  DecimalTest(
    List<(BigInt, int)> list,
    Op operation,
    String? expectedExerciseResult,
  )   : values = list
            .map(
              (e) => Decimal.fromBigInt(e.$1).shift(-e.$2),
            )
            .toList(),
        _convertToStringResult = List<String>.filled(list.length, ''),
        super(
          Package.decimal,
          operation,
          expectedExerciseResult,
        );

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
      result = (result / values[i]).toDecimal();
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
