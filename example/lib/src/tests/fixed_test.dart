import 'package:fixed/fixed.dart';

import '../operations.dart';
import '../packages.dart';
import 'my_benchmark_base.dart';

final class FixedTest extends MyBenchmarkBase {
  final List<Fixed> values;
  final List<String> _convertToStringResult;

  FixedTest(
    List<(BigInt, int)> list,
    Op operation,
    String? expectedExerciseResult,
  )   : values = list
            .map(
              (e) => Fixed.fromBigInt(e.$1, scale: e.$2),
            )
            .toList(),
        _convertToStringResult = List<String>.filled(list.length, ''),
        super(
          Package.fixed,
          operation,
          expectedExerciseResult,
        );

  @override
  Fixed add() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result += values[i];
    }

    return result;
  }

  @override
  Fixed multiply() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result *= values[i];
    }

    return result;
  }

  @override
  Fixed divide() {
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
