import 'package:decimal2/decimal2.dart';

import '../operations.dart';
import '../packages.dart';
import 'my_benchmark_base.dart';

final class Decimal2ShortTest extends MyBenchmarkBase {
  final List<ShortDecimal> values;
  final List<String> _convertToStringResult;

  Decimal2ShortTest(
    List<(int, int)> list,
    Op operation,
    String? expectedExerciseResult,
  )   : values = list
            .map(
              (e) => ShortDecimal(e.$1, scale: e.$2),
            )
            .toList(),
        _convertToStringResult = List<String>.filled(list.length, ''),
        super(
          Package.decimal2Short,
          operation,
          expectedExerciseResult,
        );

  @override
  ShortDecimal add() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result += values[i];
    }

    return result;
  }

  @override
  ShortDecimal multiply() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result *= values[i];
    }

    return result;
  }

  @override
  ShortDecimal divide() {
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
