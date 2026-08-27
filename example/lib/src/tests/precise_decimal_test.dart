import 'package:precise_decimal/precise_decimal.dart';

import '../operations.dart';
import '../packages.dart';
import 'my_benchmark_base.dart';

final class PreciseDecimalTest extends MyBenchmarkBase {
  final List<BigDecimal> values;
  final List<String> _convertToStringResult;
  final List<Object> _objectResult;

  PreciseDecimalTest(
    List<(BigInt, int)> list,
    Op operation,
    Object? expectedExerciseResult,
  )   : values = list
            .map(
              (e) => BigDecimal.fromComponents(e.$1, scale: e.$2),
            )
            .toList(growable: false),
        _convertToStringResult = List<String>.filled(list.length, ''),
        _objectResult = List<Object>.filled(list.length, ''),
        super(
          Package.preciseDecimal,
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

  // The package has no `operator /`. `divideExact` is its total form: it
  // answers where the expansion terminates and throws where it does not,
  // which is what the divide sets ask for.
  @override
  Object divide() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result = result.divideExact(values[i]);
    }

    return result;
  }

  @override
  Object divideAndView() {
    var result = values[0];
    final length = values.length;
    for (var i = 1; i < length; i++) {
      result = result.divideExact(values[i]);
    }

    return result.toPlainString();
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
      _objectResult[i] = values[i].round(
        MyBenchmarkBase.moneyDigits,
        RoundingMode.halfUp,
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
  List<String> toStringAsFixed() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      _convertToStringResult[i] = values[i].toStringAsFixed(
        MyBenchmarkBase.moneyDigits,
      );
    }

    return _convertToStringResult;
  }

  @override
  Object unrepresentableDivide() {
    final length = values.length;
    for (var i = 0; i < length; i++) {
      _objectResult[i] = values[i].divideToScale(
        _three,
        scale: MyBenchmarkBase.infiniteDigits,
        roundingMode: RoundingMode.halfUp,
      );
    }

    return _objectResult;
  }
}
