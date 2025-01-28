import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'helpers.dart';

@immutable
final class ShortDecimal implements Comparable<ShortDecimal> {
  static final _char0 = '0'.codeUnitAt(0);

  static const ShortDecimal zero = ShortDecimal._asIs(0, 0);
  static const ShortDecimal one = ShortDecimal._asIs(1, 0);
  static const ShortDecimal two = ShortDecimal._asIs(2, 0);
  static const ShortDecimal ten = ShortDecimal._asIs(10, 0);

  @visibleForTesting
  final int value;

  @visibleForTesting
  final int scale; // = fraction digits

  factory ShortDecimal(
    int value, {
    int shiftLeft = 0,
    int shiftRight = 0,
  }) {
    assert(
      shiftLeft == 0 || shiftRight == 0,
      'Use only one value: either `shiftLeft` or `shiftRight`',
    );
    assert(
      shiftLeft >= 0,
      'Use `shiftRight` instead of the negative `shiftLeft`',
    );
    assert(
      shiftRight >= 0,
      'Use `shiftLeft` instead of the negative `shiftRight`',
    );

    return ShortDecimal._pack(value, shiftRight - shiftLeft);
  }

  factory ShortDecimal._pack(int value, int scale) {
    while (value != 0 && value % 10 == 0) {
      value ~/= 10;
      scale--;
    }

    return ShortDecimal._asIs(value, scale);
  }

  const ShortDecimal._asIs(this.value, this.scale);

  static ShortDecimal? tryParse(String str) {
    try {
      str = str.trim();

      // Remove trailing zeros.
      var scale = 0;
      var end = str.length;
      while (end > 0 && str.codeUnitAt(end - 1) == _char0) {
        end--;
        scale--;
      }

      if (end != str.length) {
        if (end == 0 || str[end - 1] == '-') {
          end++;
        } else if (str[end - 1] == '.') {
          end--;
          if (end == 0) {
            return zero;
          }
        }

        str = str.substring(0, end);
      }

      // Remove point.
      final pointIndex = str.indexOf('.');
      if (pointIndex == -1) {
        return ShortDecimal._asIs(int.parse(str), scale);
      }

      // "123." is invalid.
      if (pointIndex == str.length - 1) {
        return null;
      }

      final packedStr =
          '${str.substring(0, pointIndex)}${str.substring(pointIndex + 1)}';

      return ShortDecimal._asIs(
        int.parse(packedStr),
        scale + str.length - pointIndex - 1,
      );
    } on FormatException {
      return null;
    }
  }

  int get fractionDigits {
    final scale = this.scale;
    return scale >= 0 ? scale : 0;
  }

  int get sign => value.sign;

  bool get isNegative => value.isNegative;

  bool get isInteger => scale == 0;

  bool get isZero => value == 0;

  ShortDecimal operator -() => ShortDecimal._asIs(-value, scale);

  ShortDecimal operator +(ShortDecimal other) {
    final (a, b, scale) = align(other);

    return ShortDecimal._pack(a + b, scale);
  }

  ShortDecimal operator -(ShortDecimal other) {
    final (a, b, scale) = align(other);

    return ShortDecimal._pack(a - b, scale);
  }

  ShortDecimal operator *(ShortDecimal other) => ShortDecimal._pack(
        value * other.value,
        scale + other.scale,
      );

  ShortDecimal operator /(ShortDecimal other) {
    var value = this.value;
    var scale = this.scale - other.scale;
    var divisor = other.value;

    final gcd = value.fastGcd(divisor);
    if (gcd != 1) {
      value ~/= gcd;
      divisor ~/= gcd;
    }

    if (divisor != 1) {
      while (divisor % 5 == 0) {
        value *= 2;
        scale++;
        divisor = divisor ~/ 5;
      }

      // ignore: use_is_even_rather_than_modulo
      while (divisor % 2 == 0) {
        value *= 5;
        scale++;
        divisor = divisor ~/ 2;
      }

      if (divisor != 1) {
        throw ShortDecimalDivideException._(this, other);
      }
    }

    return ShortDecimal._pack(value, scale);
  }

  // TODO(vi.k): do ShortDivision.
  // ShortDivision divide(ShortDecimal other) => ShortDivision(this, other);

  // TODO(vi.k): do ShortFraction.
  // ShortFraction fraction(ShortDecimal other) {
  //   final (dividend, divisor, _) = align(other);
  //
  //   return Fraction(dividend, divisor);
  // }

  ShortDecimal operator %(ShortDecimal other) {
    final (a, b, scale) = align(other);

    return ShortDecimal._pack(a % b, scale);
  }

  ShortDecimal remainder(ShortDecimal other) {
    final (a, b, scale) = align(other);

    return ShortDecimal._pack(a.remainder(b), scale);
  }

  bool operator <(ShortDecimal other) {
    final (a, b, _) = align(other);

    return a < b;
  }

  bool operator <=(ShortDecimal other) {
    final (a, b, _) = align(other);

    return a <= b;
  }

  bool operator >(ShortDecimal other) {
    final (a, b, _) = align(other);

    return a > b;
  }

  bool operator >=(ShortDecimal other) {
    final (a, b, _) = align(other);

    return a >= b;
  }

  ShortDecimal operator <<(int shiftAmount) =>
      ShortDecimal._asIs(value, scale - shiftAmount);

  ShortDecimal operator >>(int shiftAmount) =>
      ShortDecimal._asIs(value, scale + shiftAmount);

  ShortDecimal abs() =>
      value.isNegative ? ShortDecimal._asIs(-value, scale) : this;

  ShortDecimal floor([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) =>
            isNegative && value % divisor != 0 ? result - 1 : result,
      );

  ShortDecimal round([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) {
          final remainder = value.remainder(divisor).abs();
          return remainder >= divisor - remainder
              ? result + value.sign
              : result;
        },
      );

  ShortDecimal ceil([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) =>
            !isNegative && value % divisor != 0 ? result + 1 : result,
      );

  ShortDecimal truncate([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) => result,
      );

  ShortDecimal clamp(ShortDecimal lowerLimit, ShortDecimal upperLimit) {
    if (lowerLimit > upperLimit) {
      throw ArgumentError('The lowerLimit must be no greater than upperLimit');
    }

    return this < lowerLimit
        ? lowerLimit
        : this > upperLimit
            ? upperLimit
            : this;
  }

  ShortDecimal pow2(int exponent) {
    _checkNonNegativeArgument(exponent, 'exponent');

    return ShortDecimal._pack(
      math.pow(value, exponent) as int,
      scale * exponent,
    );
  }

  int toInt() => truncate().value;

  double toDouble() => double.parse(toString());

  @override
  int compareTo(ShortDecimal other) {
    final (a, b, _) = align(other);

    return a.compareTo(b).sign;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    switch (other) {
      case ShortDecimal():
        final (a, b, _) = align(other);
        return a == b;

      case int():
        return scale == 0 && value == other;

      default:
        return false;
    }
  }

  @override
  int get hashCode => Object.hash(value, scale);

  String debugToString() => '$ShortDecimal(value: $value, scale: $scale)';

  @override
  String toString() {
    final value = this.value;
    var result = value.toString();
    var scale = this.scale;

    if (value == 0) {
      return result;
    }

    // Remove trailing zeros.
    if (scale > 0) {
      var last = result.length - 1;
      if (result.codeUnitAt(last) == _char0) {
        do {
          scale--;
          last--;
        } while (scale > 0 && result.codeUnitAt(last) == _char0);
        result = result.substring(0, last + 1);
      }
    }

    if (scale == 0) {
      return result;
    }

    if (scale < 0) {
      return '$result${'0' * -scale}';
    }

    // Going between a sign and a number.
    final (sign, number) = result.splitByIndex(value.isNegative ? 1 : 0);
    if (scale >= number.length) {
      return '${sign}0.${number.padLeft(scale, '0')}';
    }

    final (integer, fractional) = number.splitByIndex(number.length - scale);

    return '$sign$integer.$fractional';
  }

  String toStringAsFixed(int fractionDigits) {
    _checkNonNegativeArgument(fractionDigits, 'fractionDigits');

    var value = this.value;
    var scale = this.scale;

    if (fractionDigits < scale) {
      final rounded = round(fractionDigits);
      value = rounded.value;
      scale = rounded.scale;
    }

    var result = value.toString();

    if (scale < 0) {
      if (value != 0) {
        result = '$result${'0' * -scale}';
      }
      scale = 0;
    }

    if (fractionDigits == 0) {
      return result;
    }

    // Going between a sign and a number.
    final (sign, number) = result.splitByIndex(value.isNegative ? 1 : 0);

    if (scale >= number.length) {
      return '${sign}0.${number.padLeft(scale, '0')}';
    }

    final (integer, fractional) = number.splitByIndex(number.length - scale);

    return '$sign$integer.${fractional.padRight(fractionDigits, '0')}';
  }

  // TODO(vi.k): do it.
  String toStringAsExponential([int fractionDigits = 0]) =>
      throw UnimplementedError();

  // TODO(vi.k): do it.
  String toStringAsPrecision(int precision) => throw UnimplementedError();

  static void _checkNonNegativeArgument(int value, String name) {
    if (value < 0) {
      throw ArgumentError.value(value, name, 'The value must be >= 0');
    }
  }

  ShortDecimal _dropFraction(
    int fractionDigits,
    int Function(int result, int divisor) callback,
  ) {
    if (scale <= fractionDigits) {
      return this;
    }

    final divisor = ShortDecimalInternals.pow10(scale - fractionDigits);
    final result = callback(value ~/ divisor, divisor);

    return ShortDecimal._pack(result, fractionDigits);
  }
}

final class ShortDecimalDivideException implements Exception {
  final ShortDecimal dividend;
  final ShortDecimal divisor;

  const ShortDecimalDivideException._(this.dividend, this.divisor);

  @visibleForTesting
  ShortDecimalDivideException.forTest(this.dividend, this.divisor);

  // TODO(vi.k): do it.
  // ShortFraction get fraction => dividend.fraction(divisor);

  // TODO(vi.k): do it.
  // ShortDivision get division => dividend.divide(divisor);

  // TODO(vi.k): do it.
  // ShortDecimal floor([int fractionDigits = 0]) =>
  //     fraction.floor(fractionDigits);

  // TODO(vi.k): do it.
  // ShortDecimal round([int fractionDigits = 0]) =>
  //     fraction.round(fractionDigits);

  // TODO(vi.k): do it.
  // ShortDecimal ceil([int fractionDigits = 0]) => fraction.ceil(fractionDigits);

  // TODO(vi.k): do it.
  // ShortDecimal truncate([int fractionDigits = 0]) =>
  //     fraction.truncate(fractionDigits);

  @override
  String toString() => '$ShortDecimalDivideException:'
      ' The result of division cannot be represented as $ShortDecimal:'
      '\n$dividend / $divisor';

  // TODO(vi.k): do it.
  // @override
  // String toString() => '$ShortDecimalDivideException:'
  //     ' The result of division cannot be represented as $ShortDecimal:'
  //     '\n$dividend / $divisor = $division'
  //     '\n$dividend / $divisor = $fraction';
}

extension ShortDecimalIntExtension on int {
  ShortDecimal toShortDecimal() => ShortDecimal._pack(this, 0);
}
