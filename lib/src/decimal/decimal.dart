import 'dart:math';

import 'package:meta/meta.dart';

import '../helpers.dart';

part 'division.dart';
part 'fraction.dart';

final class Decimal implements Comparable<Decimal> {
  static final _char0 = '0'.codeUnitAt(0);
  static final _bigInt5 = BigInt.from(5);
  static final _bigInt10 = BigInt.from(10);

  /// A decimal with the numerical value 0.
  static final Decimal zero = Decimal.fromBigInt(BigInt.zero);

  /// A decimal with the numerical value 1.
  static final Decimal one = Decimal.fromBigInt(BigInt.one);

  /// A decimal with the numerical value 2.
  static final Decimal two = Decimal.fromBigInt(BigInt.two);

  /// A decimal with the numerical value 10.
  static final Decimal ten = Decimal.fromBigInt(_bigInt10);

  @visibleForTesting
  final BigInt base;

  @visibleForTesting
  final int scale;

  /// It's to maximize performance.
  ///
  /// The Decimal class can never be constant, since BigInt is not constant.
  /// So we use the trick of preserving the intermediate optimal result.
  Decimal? _packed;

  /// Returns [Decimal] from integer [base].
  ///
  /// Parameter [shiftRight] shifts [base] to the right relative to the decimal
  /// point:
  ///
  /// ```dart
  /// Decimal(1); // 1
  /// Decimal(1, shiftRight: 1); // 0.1
  /// Decimal(1, shiftRight: 2); // 0.01
  /// ```
  Decimal(
    int base, {
    int shiftRight = 0,
  }) : this.fromBigInt(BigInt.from(base), shiftRight: shiftRight);

  /// Returns [Decimal] from `BigInt` [base].
  ///
  /// Parameter [shiftRight] shifts [base] to the right relative to the decimal
  /// point:
  ///
  /// ```dart
  /// Decimal.fromBigInt(BigInt.one); // 1
  /// Decimal.fromBigInt(BigInt.one, shiftRight: 1); // 0.1
  /// Decimal.fromBigInt(BigInt.one, shiftRight: 2); // 0.01
  /// ```
  Decimal.fromBigInt(
    this.base, {
    int shiftRight = 0,
  })  : assert(shiftRight >= 0, 'shiftRight must be positive'),
        scale = shiftRight;

  /// Parse the [string] to [Decimal].
  ///
  /// Throw [FormatException] on failure.
  factory Decimal.parse(String string) =>
      tryParse(string) ??
      (throw FormatException('Could not parse $Decimal: $string'));

  Decimal._asIs(this.base, this.scale);

  /// Parse the [string] to [Decimal].
  ///
  /// Returns null on failure.
  static Decimal? tryParse(String string) {
    try {
      string = string.trim();

      // Remove dot.
      final dot = string.indexOf('.');
      if (dot == -1) {
        return Decimal._asIs(BigInt.parse(string), 0);
      }

      // "123." is invalid.
      if (dot == string.length - 1) {
        return null;
      }

      final packedStr =
          '${string.substring(0, dot)}${string.substring(dot + 1)}';

      return Decimal._asIs(BigInt.parse(packedStr), string.length - dot - 1);
    } on FormatException {
      return null;
    }
  }

  /// Returns number of digits after the decimal point.
  int get fractionDigits => scale <= 0 ? 0 : max(_requirePacked.scale, 0);

  /// Returns the sign of this decimal.
  ///
  /// Returns 0 for zero, -1 for values less than zero and +1 for values
  /// greater than zero.
  int get sign => base.sign;

  /// Whether this decimal is negative.
  bool get isNegative => base.isNegative;

  /// Whether this decimal is an integer.
  bool get isInteger => scale <= 0 || _requirePacked.scale <= 0;

  /// Whether this decimal is zero.
  bool get isZero => base == BigInt.zero;

  /// Returns the negative value of this decimal.
  Decimal operator -() => Decimal._asIs(-base, scale);

  /// Adds [other] to this decimal.
  Decimal operator +(Decimal other) {
    final (a, b, scale) = _align(other);

    return Decimal._asIs(a + b, scale);
  }

  /// Subtracts [other] from this decimal.
  Decimal operator -(Decimal other) {
    final (a, b, scale) = _align(other);

    return Decimal._asIs(a - b, scale);
  }

  /// Multiplies this decimal by [other].
  Decimal operator *(Decimal other) => Decimal._asIs(
        base * other.base,
        scale + other.scale,
      );

  /// Divides this decimal by [other].
  Decimal operator /(Decimal other) {
    var base = this.base;
    var scale = this.scale - other.scale;
    var divisor = other.base;

    final gcd = base.fastGcd(divisor);
    if (gcd != BigInt.one) {
      base ~/= gcd;
      divisor ~/= gcd;
    }

    if (divisor != BigInt.one) {
      var k = BigInt.one;
      while (divisor % _bigInt5 == BigInt.zero) {
        k *= BigInt.two;
        scale++;
        divisor = divisor ~/ _bigInt5;
      }

      while (divisor % BigInt.two == BigInt.zero) {
        k *= _bigInt5;
        scale++;
        divisor = divisor ~/ BigInt.two;
      }

      if (divisor != BigInt.one) {
        throw DecimalDivideException._(this, other);
      }

      base *= k;
    }

    return Decimal._asIs(base, scale);
  }

  /// Performs truncating division of this decimal by [other].
  ///
  /// Truncating division is division where a fractional result is converted to
  /// an integer by rounding towards zero.
  BigInt operator ~/(Decimal other) {
    final (a, b, _) = _align(other);

    return a ~/ b;
  }

  /// Calculates the result of division as double.
  double divideToDouble(Decimal other) {
    final fraction = divideToFraction(other);

    return fraction.numerator / fraction.denominator;
  }

  /// Calculates the result of division as fraction.
  Fraction divideToFraction(Decimal other) {
    final (dividend, divisor, _) = _align(other);

    return Fraction(dividend, divisor);
  }

  /// Calculates the result of division as an integer quotient and remainder.
  Division divideWithRemainder(Decimal other) => Division(this, other);

  /// Euclidean modulo of this number by [other].
  ///
  /// The sign of the returned value is always positive.
  Decimal operator %(Decimal other) {
    final (a, b, scale) = _align(other);

    return Decimal._asIs(a % b, scale);
  }

  /// The remainder of the truncating division of this by [other].
  ///
  /// The result r of this operation satisfies:
  /// this == (this ~/ other) * other + r. As a consequence, the remainder r
  /// has the same sign as the dividend this.
  Decimal remainder(Decimal other) {
    final (a, b, scale) = _align(other);

    return Decimal._asIs(a.remainder(b), scale);
  }

  /// Whether this decimal is smaller than [other].
  bool operator <(Decimal other) {
    final (a, b, _) = _align(other);

    return a < b;
  }

  /// Whether this decimal is smaller than or equal to [other].
  bool operator <=(Decimal other) {
    final (a, b, _) = _align(other);

    return a <= b;
  }

  /// Whether this decimal is greater than [other].
  bool operator >(Decimal other) {
    final (a, b, _) = _align(other);

    return a > b;
  }

  /// Whether this decimal is greater than or equal to [other].
  bool operator >=(Decimal other) {
    final (a, b, _) = _align(other);

    return a >= b;
  }

  /// Shifts a decimal relative to the decimal point to the left.
  ///
  /// ```dart
  /// Decimal(1) << 2; // 100
  /// Decimal.parse('0.01') << 1; // 0.1
  /// ```
  Decimal operator <<(int shiftAmount) =>
      Decimal._asIs(base, scale - shiftAmount);

  /// Shifts a decimal relative to the decimal point to the right.
  ///
  /// ```dart
  /// print(Decimal(1) >> 2); // 0.01
  /// print(Decimal(100) >> 1); // 10
  /// ```
  ///
  /// This is equivalent to using the `shiftRight` parameter when creating
  /// a `Decimal`:
  ///
  /// ```dart
  /// print(Decimal(1) >> 2 == Decimal(1, shiftRight: 2)); // true
  /// ```
  Decimal operator >>(int shiftAmount) =>
      Decimal._asIs(base, scale + shiftAmount);

  /// Optimize number to improve performance.
  void optimize() {
    _requirePacked;
  }

  /// Returns the absolute value of this decimal.
  Decimal abs() => base.isNegative ? Decimal._asIs(-base, scale) : this;

  /// Rounds the decimal towards negative infinity to [fractionDigits].
  Decimal floor([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) => isNegative && base % divisor != BigInt.zero
            ? result - BigInt.one
            : result,
      );

  /// Rounds to the closest decimal with [fractionDigits].
  Decimal round([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) {
          final remainder = base.remainder(divisor).abs();
          return remainder >= divisor - remainder
              ? result + BigInt.from(base.sign)
              : result;
        },
      );

  /// Rounds the decimal towards infinity to [fractionDigits].
  Decimal ceil([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) => !isNegative && base % divisor != BigInt.zero
            ? result + BigInt.one
            : result,
      );

  /// Rounds the decimal towards zero to [fractionDigits].
  Decimal truncate([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) => result,
      );

  /// Returns this decimal clamped to be in the range [lowerLimit]-[upperLimit].
  ///
  /// The arguments [lowerLimit] and [upperLimit] must form a valid range where
  /// lowerLimit <= upperLimit.
  Decimal clamp(Decimal lowerLimit, Decimal upperLimit) {
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
  Decimal pow(int exponent) {
    _checkNonNegativeArgument(exponent, 'exponent');

    return Decimal._asIs(base.pow(exponent), scale * exponent);
  }

  /// Returns [BigInt], discarding all fractional digits from this decimal.
  BigInt toBigInt() => truncate().base;

  /// Converts this decimal to [double].
  double toDouble() => double.parse(toString());

  /// Compares this to [other].
  ///
  /// Returns a negative number if this is less than other, zero if they are
  /// equal, and a positive number if this is greater than other.
  @override
  int compareTo(Decimal other) {
    final (a, b, _) = _align(other);

    return a.compareTo(b).sign;
  }

  /// Whether this decimal is equal to [other].
  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is Decimal) {
      final (a, b, _) = _align(other);

      return a == b;
    }

    return false;
  }

  /// Returns a hash code for this decimal.
  ///
  /// This is compatible with [operator ==]. It returns the same hashCode for
  /// decimal with the same value.
  ///
  /// The class is not immutable, but its main characteristics ([base] and
  /// [scale]) do not change.
  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode {
    final packed = _requirePacked;

    return Object.hash(packed.base, packed.scale);
  }

  @visibleForTesting
  String debugToString() => '$Decimal(base: $base, scale: $scale)';

  /// Returns a string representation of this decimal.
  @override
  String toString() {
    final packed = _packed;
    final it = packed ?? this;

    final base = it.base;
    var scale = it.scale;
    if (scale == 0 || base == BigInt.zero) {
      return base.toString();
    }

    final sign = base.isNegative ? '-' : '';
    var number = base.abs().toString();

    // Remove trailing zeros.
    if (packed == null && scale > 0) {
      var last = number.length - 1;
      if (number.codeUnitAt(last) == _char0) {
        do {
          scale--;
          last--;
        } while (scale > 0 && number.codeUnitAt(last) == _char0);
        number = number.substring(0, last + 1);
      }

      if (scale == 0) {
        return '$sign$number';
      }
    }

    if (scale < 0) {
      return '$sign$number${'0' * -scale}';
    }

    if (number.length <= scale) {
      return '${sign}0.${number.padLeft(scale, '0')}';
    }

    return '$sign${number.substring(0, number.length - scale)}'
        '.${number.substring(number.length - scale)}';
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
      if (base != BigInt.zero) {
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

  // TODO(vi.k): do it.
  String toStringAsExponential([int fractionDigits = 0]) =>
      throw UnimplementedError();

  // TODO(vi.k): do it.
  //
  // 1234567 (6) -> 1.23457e+6 ?
  String toStringAsPrecision(int precision) => throw UnimplementedError();

  static void _checkNonNegativeArgument(int value, String name) {
    if (value < 0) {
      throw ArgumentError.value(value, name, 'The value must be >= 0');
    }
  }

  Decimal get _requirePacked => _packed ??= () {
        var base = this.base;
        if (base == BigInt.zero) {
          return Decimal._asIs(base, 0);
        }

        var scale = this.scale;
        while (base % _bigInt10 == BigInt.zero) {
          base ~/= _bigInt10;
          scale--;
        }

        return Decimal._asIs(base, scale);
      }();

  /// Aligning decimals by decimal point.
  (BigInt, BigInt, int) _align(Decimal other) {
    final as = scale;
    final bs = other.scale;

    if (as == bs) {
      return (base, other.base, as);
    }

    if (as > bs) {
      return (base, other.base * _bigInt10.pow(as - bs), as);
    }

    return (base * _bigInt10.pow(bs - as), other.base, bs);
  }

  Decimal _dropFraction(
    int fractionDigits,
    BigInt Function(BigInt result, BigInt divisor) callback,
  ) {
    if (scale <= fractionDigits) {
      return this;
    }

    final divisor = _bigInt10.pow(scale - fractionDigits);
    final result = callback(base ~/ divisor, divisor);

    return Decimal._asIs(result, fractionDigits);
  }
}

final class DecimalDivideException implements Exception {
  final Decimal dividend;
  final Decimal divisor;

  const DecimalDivideException._(this.dividend, this.divisor);

  @visibleForTesting
  DecimalDivideException.forTest(this.dividend, this.divisor);

  Fraction get fraction => dividend.divideToFraction(divisor);

  Division get quotientWithRemainder => dividend.divideWithRemainder(divisor);

  Decimal floor([int fractionDigits = 0]) => fraction.floor(fractionDigits);

  Decimal round([int fractionDigits = 0]) => fraction.round(fractionDigits);

  Decimal ceil([int fractionDigits = 0]) => fraction.ceil(fractionDigits);

  Decimal truncate([int fractionDigits = 0]) =>
      fraction.truncate(fractionDigits);

  @override
  String toString() => '$DecimalDivideException:'
      ' The result of division cannot be represented as $Decimal:'
      '\n$dividend / $divisor = $quotientWithRemainder'
      '\n$dividend / $divisor = $fraction';
}

extension DecimalBigIntExtension on BigInt {
  Decimal toDecimal() => Decimal.fromBigInt(this);
}

extension DecimalIntExtension on int {
  Decimal toDecimal() => Decimal(this);
}
