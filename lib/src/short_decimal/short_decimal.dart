import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../helpers.dart';

part 'short_fraction.dart';
part 'short_division.dart';

@immutable
final class ShortDecimal implements Comparable<ShortDecimal> {
  static final _charCode0 = '0'.codeUnitAt(0);
  static final _charCodePoint = '.'.codeUnitAt(0);
  static final _charCodeMinus = '-'.codeUnitAt(0);
  static final _charCodeSpace = ' '.codeUnitAt(0);

  /// A decimal with the numerical value 0.
  static const ShortDecimal zero = ShortDecimal._asIs(0, 0);

  /// A decimal with the numerical value 1.
  static const ShortDecimal one = ShortDecimal._asIs(1, 0);

  /// A decimal with the numerical value 2.
  static const ShortDecimal two = ShortDecimal._asIs(2, 0);

  /// A decimal with the numerical value 10.
  static const ShortDecimal ten = ShortDecimal._asIs(10, 0);

  @visibleForTesting
  final int base;

  @visibleForTesting
  final int scale;

  /// Returns [ShortDecimal] from integer [base].
  ///
  /// Parameter [shiftRight] shifts [base] to the right relative to the decimal
  /// point:
  ///
  /// ```dart
  /// Decimal(1); // 1
  /// Decimal(1, shiftRight: 1); // 0.1
  /// Decimal(1, shiftRight: 2); // 0.01
  /// ```
  ///
  /// Parameter [shiftLeft] shifts [base] to the left relative to the decimal
  /// point:
  ///
  /// ```dart
  /// Decimal(1); // 1
  /// Decimal(1, shiftLeft: 1); // 10
  /// Decimal(1, shiftLeft: 2); // 100
  /// ```
  factory ShortDecimal(
    int base, {
    int shiftLeft = 0,
    int shiftRight = 0,
  }) {
    assert(
      shiftLeft == 0 || shiftRight == 0,
      'Use either `shiftLeft` or `shiftRight`',
    );
    assert(
      shiftLeft >= 0,
      'Use `shiftRight` instead of the negative `shiftLeft`',
    );
    assert(
      shiftRight >= 0,
      'Use `shiftLeft` instead of the negative `shiftRight`',
    );

    return ShortDecimal._pack(base, shiftRight - shiftLeft);
  }

  /// Parse the [string] to [ShortDecimal].
  ///
  /// Throw [FormatException] on failure.
  factory ShortDecimal.parse(String string) =>
      tryParse(string) ??
      (throw FormatException('Could not parse $ShortDecimal: $string'));

  factory ShortDecimal._pack(int base, int scale) {
    if (base == 0) {
      return ShortDecimal.zero;
    }

    while (base % 10 == 0) {
      base ~/= 10;
      scale--;
    }

    return ShortDecimal._asIs(base, scale);
  }

  const ShortDecimal._asIs(this.base, this.scale);

  /// Try to parse the [string] to [ShortDecimal].
  ///
  /// Returns null on failure.
  static ShortDecimal? tryParse(String string) {
    try {
      string = string.trim();

      // Dot.
      final dot = string.indexOf('.');

      // "123." and "" is invalid.
      if (dot == string.length - 1) {
        return null;
      }

      // Remove trailing zeros after dot.
      var end = string.length;
      if (dot != -1) {
        // `end` always > 0
        while (string.codeUnitAt(end - 1) == _charCode0) {
          end--;
        }

        final lastCharCode = string.codeUnitAt(end - 1);
        if (lastCharCode == _charCodePoint) {
          end--;
        } else {
          if (lastCharCode == _charCodeSpace) {
            throw const FormatException();
          }

          return ShortDecimal._asIs(
            int.parse(
              '${string.substring(0, dot)}'
              '${string.substring(dot + 1, end)}',
            ),
            end - dot - 1,
          );
        }
      }

      // Remove trailing zeros before dot.
      var scale = 0;
      while (end > 0 && string.codeUnitAt(end - 1) == _charCode0) {
        end--;
        scale--;
      }

      if (end == 0) {
        return zero;
      }

      final lastCharCode = string.codeUnitAt(end - 1);
      if (lastCharCode == _charCodeSpace) {
        throw const FormatException();
      }

      return end == 1 && lastCharCode == _charCodeMinus
          ? zero
          : ShortDecimal._asIs(
              int.parse(string.substring(0, end)),
              scale,
            );
    } on FormatException {
      return null;
    }
  }

  /// Returns number of digits after the decimal point.
  int get fractionDigits {
    final scale = this.scale;
    return scale >= 0 ? scale : 0;
  }

  /// Returns the sign of this decimal.
  ///
  /// Returns 0 for zero, -1 for values less than zero and +1 for values
  /// greater than zero.
  int get sign => base.sign;

  /// Whether this decimal is negative.
  bool get isNegative => base.isNegative;

  /// Whether this decimal is an integer.
  bool get isInteger => scale <= 0;

  /// Whether this decimal is zero.
  bool get isZero => base == 0;

  /// Returns the negative value of this decimal.
  ShortDecimal operator -() => ShortDecimal._asIs(-base, scale);

  /// Adds [other] to this decimal.
  ShortDecimal operator +(ShortDecimal other) {
    final (a, b, scale) = _align(other);

    return ShortDecimal._pack(a + b, scale);
  }

  /// Subtracts [other] from this decimal.
  ShortDecimal operator -(ShortDecimal other) {
    final (a, b, scale) = _align(other);

    return ShortDecimal._pack(a - b, scale);
  }

  /// Multiplies this decimal by [other].
  ShortDecimal operator *(ShortDecimal other) => ShortDecimal._pack(
        base * other.base,
        scale + other.scale,
      );

  /// Divides this decimal by [other].
  ShortDecimal operator /(ShortDecimal other) {
    var base = this.base;
    var scale = this.scale - other.scale;
    var divisor = other.base;

    final gcd = base.fastGcd(divisor);
    if (gcd != 1) {
      base ~/= gcd;
      divisor ~/= gcd;
    }

    if (divisor != 1) {
      while (divisor % 5 == 0) {
        base *= 2;
        scale++;
        divisor = divisor ~/ 5;
      }

      // ignore: use_is_even_rather_than_modulo
      while (divisor % 2 == 0) {
        base *= 5;
        scale++;
        divisor = divisor ~/ 2;
      }

      if (divisor != 1) {
        throw ShortDecimalDivideException._(this, other);
      }
    }

    return ShortDecimal._pack(base, scale);
  }

  /// Performs truncating division of this decimal by [other].
  ///
  /// Truncating division is division where a fractional result is converted to
  /// an integer by rounding towards zero.
  int operator ~/(ShortDecimal other) {
    final (a, b, _) = _align(other);

    return a ~/ b;
  }

  /// Calculates the result of division as double.
  double divideToDouble(ShortDecimal other) {
    final fraction = divideToFraction(other);

    return fraction.numerator / fraction.denominator;
  }

  /// Calculates the result of division as fraction.
  ShortFraction divideToFraction(ShortDecimal other) {
    final (dividend, divisor, _) = _align(other);

    return ShortFraction(dividend, divisor);
  }

  /// Calculates the result of division as an integer quotient and remainder.
  ShortDivision divideWithRemainder(ShortDecimal other) =>
      ShortDivision(this, other);

  /// Euclidean modulo of this number by [other].
  ///
  /// The sign of the returned value is always positive.
  ShortDecimal operator %(ShortDecimal other) {
    final (a, b, scale) = _align(other);

    return ShortDecimal._pack(a % b, scale);
  }

  /// The remainder of the truncating division of this by [other].
  ///
  /// The result r of this operation satisfies:
  /// this == (this ~/ other) * other + r. As a consequence, the remainder r
  /// has the same sign as the dividend this.
  ShortDecimal remainder(ShortDecimal other) {
    final (a, b, scale) = _align(other);

    return ShortDecimal._pack(a.remainder(b), scale);
  }

  /// Whether this decimal is smaller than [other].
  bool operator <(ShortDecimal other) {
    final (a, b, _) = _align(other);

    return a < b;
  }

  /// Whether this decimal is smaller than or equal to [other].
  bool operator <=(ShortDecimal other) {
    final (a, b, _) = _align(other);

    return a <= b;
  }

  /// Whether this decimal is greater than [other].
  bool operator >(ShortDecimal other) {
    final (a, b, _) = _align(other);

    return a > b;
  }

  /// Whether this decimal is greater than or equal to [other].
  bool operator >=(ShortDecimal other) {
    final (a, b, _) = _align(other);

    return a >= b;
  }

  /// Shifts a decimal relative to the decimal point to the left.
  ///
  /// ```dart
  /// ShortDecimal(1) << 2; // 100
  /// ShortDecimal.parse('0.01') << 1; // 0.1
  /// ```
  ///
  /// This is equivalent to using the `shiftLeft` parameter when creating
  /// a `ShortDecimal`:
  ///
  /// ```dart
  /// print(ShortDecimal(1) << 2 == ShortDecimal(1, shiftLeft: 2)); // true
  /// ```
  ShortDecimal operator <<(int shiftAmount) =>
      base == 0 ? this : ShortDecimal._asIs(base, scale - shiftAmount);

  /// Shifts a decimal relative to the decimal point to the right.
  ///
  /// ```dart
  /// print(ShortDecimal(1) >> 2); // 0.01
  /// print(ShortDecimal(100) >> 1); // 10
  /// ```
  ///
  /// This is equivalent to using the `shiftRight` parameter when creating
  /// a `ShortDecimal`:
  ///
  /// ```dart
  /// print(ShortDecimal(1) >> 2 == ShortDecimal(1, shiftRight: 2)); // true
  /// ```
  ShortDecimal operator >>(int shiftAmount) =>
      base == 0 ? this : ShortDecimal._pack(base, scale + shiftAmount);

  /// Returns the absolute value of this decimal.
  ///
  /// Integer overflow may cause the result of -value to stay negative:
  ///
  /// ```dart
  /// print(ShortDecimal(-9223372036854775808).abs() ==
  ///     ShortDecimal(-9223372036854775808)); // true
  /// ```
  ShortDecimal abs() =>
      base.isNegative ? ShortDecimal._asIs(-base, scale) : this;

  /// Rounds the decimal towards negative infinity to [fractionDigits].
  ShortDecimal floor([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) =>
            isNegative && base % divisor != 0 ? result - 1 : result,
      );

  /// Rounds to the closest decimal with [fractionDigits].
  ShortDecimal round([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) {
          final remainder = base.remainder(divisor).abs();
          return remainder >= divisor - remainder ? result + base.sign : result;
        },
      );

  /// Rounds the decimal towards infinity to [fractionDigits].
  ShortDecimal ceil([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) =>
            !isNegative && base % divisor != 0 ? result + 1 : result,
      );

  /// Rounds the decimal towards zero to [fractionDigits].
  ShortDecimal truncate([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) => result,
      );

  /// Returns this decimal clamped to be in the range [lowerLimit]-[upperLimit].
  ///
  /// The arguments [lowerLimit] and [upperLimit] must form a valid range where
  /// lowerLimit <= upperLimit.
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

  /// Returns this decimal to the power of [exponent].
  ShortDecimal pow(int exponent) {
    _checkNonNegativeArgument(exponent, 'exponent');

    return ShortDecimal._pack(
      math.pow(base, exponent) as int,
      scale * exponent,
    );
  }

  /// Returns [int], discarding all fractional digits from this decimal.
  int toInt() {
    final t = truncate();

    return t.base * _pow10(-t.scale);
  }

  /// Converts this decimal to [double].
  double toDouble() => double.parse(toString());

  /// Compares this to [other].
  ///
  /// Returns a negative number if this is less than other, zero if they are
  /// equal, and a positive number if this is greater than other.
  @override
  int compareTo(ShortDecimal other) {
    final (a, b, _) = _align(other);

    return a.compareTo(b).sign;
  }

  /// Whether this decimal is equal to [other].
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is ShortDecimal) {
      final (a, b, _) = _align(other);

      return a == b;
    }

    return false;
  }

  /// Returns a hash code for this decimal.
  ///
  /// This is compatible with [operator ==]. It returns the same hashCode for
  /// decimal with the same value.
  @override
  int get hashCode => Object.hash(base, scale);

  @visibleForTesting
  String debugToString() => '$ShortDecimal(base: $base, scale: $scale)';

  /// Returns a string representation of this decimal.
  @override
  String toString() {
    final base = this.base;
    final scale = this.scale;
    final string = base.toString();
    if (scale == 0 || base == 0) {
      return string;
    }

    // Calculate the sign and string representation of the absolute value.
    //
    // We don't use `abs()` because of the problem:
    // -(-9223372036854775808) == -9223372036854775808
    final (sign, abs) = string.codeUnitAt(0) == _charCodeMinus
        ? ('-', string.substring(1))
        : ('', string);

    if (scale < 0) {
      return '$sign$abs${'0' * -scale}';
    }

    if (abs.length <= scale) {
      return '${sign}0.${abs.padLeft(scale, '0')}';
    }

    return '$sign${abs.substring(0, abs.length - scale)}'
        '.${abs.substring(abs.length - scale)}';
  }

  /// Returns a string representation of this decimal using new
  /// [fractionDigits].
  ///
  /// If [fractionDigits] is less than `this.fractionDigits`, the [round]
  /// method is used.
  String toStringAsFixed(int fractionDigits) {
    _checkNonNegativeArgument(fractionDigits, 'fractionDigits');

    var base = this.base;
    var scale = this.scale;

    if (fractionDigits < scale) {
      final rounded = round(fractionDigits);
      base = rounded.base;
      scale = rounded.scale;
    }

    var result = base.toString();

    if (scale < 0) {
      if (base != 0) {
        result = '$result${'0' * -scale}';
      }
      scale = 0;
    }

    if (fractionDigits == 0) {
      return result;
    }

    // Going between a sign and a number.
    final (sign, number) = result.splitByIndex(base.isNegative ? 1 : 0);

    if (scale >= number.length) {
      return '${sign}0.${number.padLeft(scale, '0')}';
    }

    final (integer, fractional) = number.splitByIndex(number.length - scale);

    return '$sign$integer.${fractional.padRight(fractionDigits, '0')}';
  }

  static void _checkNonNegativeArgument(int value, String name) {
    if (value < 0) {
      throw ArgumentError.value(value, name, 'The value must be >= 0');
    }
  }

  static int _pow10(int exponent) {
    assert(exponent >= 0, "exponent can't be negative");
    return math.pow(10, exponent) as int;
  }

  (int, int, int) _align(ShortDecimal other) {
    final as = scale;
    final bs = other.scale;

    if (as == bs) {
      return (base, other.base, as);
    }

    if (as > bs) {
      return (base, other.base * _pow10(as - bs), as);
    }

    return (base * _pow10(bs - as), other.base, bs);
  }

  ShortDecimal _dropFraction(
    int fractionDigits,
    int Function(int result, int divisor) callback,
  ) {
    if (scale <= fractionDigits) {
      return this;
    }

    final divisor = _pow10(scale - fractionDigits);
    final result = callback(base ~/ divisor, divisor);

    return ShortDecimal._pack(result, fractionDigits);
  }
}

final class ShortDecimalDivideException implements Exception {
  final ShortDecimal dividend;
  final ShortDecimal divisor;

  const ShortDecimalDivideException._(this.dividend, this.divisor);

  @visibleForTesting
  ShortDecimalDivideException.forTest(this.dividend, this.divisor);

  ShortFraction get fraction => dividend.divideToFraction(divisor);

  ShortDivision get quotientWithRemainder =>
      dividend.divideWithRemainder(divisor);

  ShortDecimal floor([int fractionDigits = 0]) =>
      fraction.floor(fractionDigits);

  ShortDecimal round([int fractionDigits = 0]) =>
      fraction.round(fractionDigits);

  ShortDecimal ceil([int fractionDigits = 0]) => fraction.ceil(fractionDigits);

  ShortDecimal truncate([int fractionDigits = 0]) =>
      fraction.truncate(fractionDigits);

  @override
  String toString() => '$ShortDecimalDivideException:'
      ' The result of division cannot be represented as $ShortDecimal:'
      // '\n$dividend / $divisor = $quotientWithRemainder'
      '\n$dividend / $divisor = $fraction';
}

extension ShortDecimalIntExtension on int {
  ShortDecimal toShortDecimal() => ShortDecimal._pack(this, 0);
}
