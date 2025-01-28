import 'dart:math';

import 'package:meta/meta.dart';

import 'division.dart';
import 'fraction.dart';
import 'helpers.dart';

final class Decimal implements Comparable<Decimal> {
  static final _char0 = '0'.codeUnitAt(0);
  static final _bigInt5 = BigInt.from(5);
  static final _bigInt10 = BigInt.from(10);

  static final Decimal zero = Decimal.fromBigInt(BigInt.zero);
  static final Decimal one = Decimal.fromBigInt(BigInt.one);
  static final Decimal two = Decimal.fromBigInt(BigInt.two);
  static final Decimal ten = Decimal.fromBigInt(_bigInt10);

  @visibleForTesting
  final BigInt value;

  @visibleForTesting
  final int scale; // = fraction digits

  /// It's to maximize performance.
  ///
  /// The Decimal class can never be constant, since BigInt is not constant.
  /// So we use the trick of preserving the intermediate optimal result.
  Decimal? _minimized;

  Decimal(
    int value, {
    int shiftLeft = 0,
    int shiftRight = 0,
  }) : this.fromBigInt(
          BigInt.from(value),
          shiftLeft: shiftLeft,
          shiftRight: shiftRight,
        );

  Decimal.fromBigInt(
    this.value, {
    int shiftLeft = 0,
    int shiftRight = 0,
  })  : assert(
          shiftLeft == 0 || shiftRight == 0,
          'Use only one value: either `shiftLeft` or `shiftRight`',
        ),
        assert(
          shiftLeft >= 0,
          'Use `shiftRight` instead of the negative `shiftLeft`',
        ),
        assert(
          shiftRight >= 0,
          'Use `shiftLeft` instead of the negative `shiftRight`',
        ),
        scale = shiftRight - shiftLeft;

  factory Decimal.parse(String str) =>
      tryParse(str) ?? (throw FormatException('Could not parse Decimal: $str'));

  Decimal._(this.value, this.scale);

  static Decimal? tryParse(String str) {
    try {
      str = str.trim();

      // Remove point.
      final pointIndex = str.indexOf('.');
      if (pointIndex == -1) {
        return Decimal._(BigInt.parse(str), 0);
      }

      // "123." is invalid.
      if (pointIndex == str.length - 1) {
        return null;
      }

      final packedStr =
          '${str.substring(0, pointIndex)}${str.substring(pointIndex + 1)}';

      return Decimal._(
        BigInt.parse(packedStr),
        str.length - pointIndex - 1,
      );
    } on FormatException {
      return null;
    }
  }

  int get fractionDigits => scale <= 0 ? 0 : max(_minimize().scale, 0);

  int get sign => value.sign;

  bool get isNegative => value.isNegative;

  bool get isInteger => scale <= 0 || _minimize().scale <= 0;

  bool get isZero => value == BigInt.zero;

  Decimal operator -() => Decimal._(-value, scale);

  Decimal operator +(Decimal other) {
    final (a, b, scale) = align(other);

    return Decimal._(a + b, scale);
  }

  Decimal operator -(Decimal other) {
    final (a, b, scale) = align(other);

    return Decimal._(a - b, scale);
  }

  Decimal operator *(Decimal other) => Decimal._(
        value * other.value,
        scale + other.scale,
      );

  Decimal operator /(Decimal other) {
    var value = this.value;
    var scale = this.scale - other.scale;
    var divisor = other.value;

    final gcd = value.fastGcd(divisor);
    if (gcd != BigInt.one) {
      value ~/= gcd;
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

      value *= k;
    }

    return Decimal._(value, scale);
  }

  Decimal operator ~/(Decimal other) {
    final (a, b, _) = align(other);

    return Decimal._(a ~/ b, 0);
  }

  /// Calculates the result of division as double.
  double divideToDouble(Decimal other) {
    final fraction = divideToFraction(other);

    return fraction.numerator / fraction.denominator;
  }

  /// Calculates the result of division as fraction.
  Fraction divideToFraction(Decimal other) {
    final (dividend, divisor, _) = align(other);

    return Fraction(dividend, divisor);
  }

  /// Calculates the result of division as an integer quotient and remainder.
  Division divideWithRemainder(Decimal other) => Division(this, other);

  Decimal operator %(Decimal other) {
    final (a, b, scale) = align(other);

    return Decimal._(a % b, scale);
  }

  Decimal remainder(Decimal other) {
    final (a, b, scale) = align(other);

    return Decimal._(a.remainder(b), scale);
  }

  bool operator <(Decimal other) {
    final (a, b, _) = align(other);

    return a < b;
  }

  bool operator <=(Decimal other) {
    final (a, b, _) = align(other);

    return a <= b;
  }

  bool operator >(Decimal other) {
    final (a, b, _) = align(other);

    return a > b;
  }

  bool operator >=(Decimal other) {
    final (a, b, _) = align(other);

    return a >= b;
  }

  Decimal operator <<(int shiftAmount) => Decimal._(value, scale - shiftAmount);

  Decimal operator >>(int shiftAmount) => Decimal._(value, scale + shiftAmount);

  /// Optimize value to improve performance.
  void optimize() {
    _minimize();
  }

  Decimal abs() => value.isNegative ? Decimal._(-value, scale) : this;

  Decimal floor([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) => isNegative && value % divisor != BigInt.zero
            ? result - BigInt.one
            : result,
      );

  Decimal round([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) {
          final remainder = value.remainder(divisor).abs();
          return remainder >= divisor - remainder
              ? result + BigInt.from(value.sign)
              : result;
        },
      );

  Decimal ceil([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) => !isNegative && value % divisor != BigInt.zero
            ? result + BigInt.one
            : result,
      );

  Decimal truncate([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) => result,
      );

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

  Decimal pow(int exponent) {
    _checkNonNegativeArgument(exponent, 'exponent');

    return Decimal._(value.pow(exponent), scale * exponent);
  }

  BigInt toBigInt() => truncate().value;

  double toDouble() => double.parse(toString());

  @override
  int compareTo(Decimal other) {
    final (a, b, _) = align(other);

    return a.compareTo(b).sign;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    switch (other) {
      case Decimal():
        final (a, b, _) = align(other);
        return a == b;

      case BigInt():
        final normalized = _normalize();

        return normalized.scale == 0 && normalized.value == other;

      case int():
        final normalized = _normalize();

        return normalized.scale == 0 &&
            normalized.value.isValidInt &&
            normalized.value.toInt() == other;

      default:
        return false;
    }
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hash(value, scale);

  String debugToString() => '$Decimal(value: $value, scale: $scale)';

  @override
  String toString() {
    final minimized = _minimized;
    final it = minimized ?? this;

    final value = it.value;
    var scale = it.scale;
    if (scale == 0 || value == BigInt.zero) {
      return value.toString();
    }

    final sign = value.isNegative ? '-' : '';
    var number = value.abs().toString();

    // Remove trailing zeros.
    if (minimized == null && scale > 0) {
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
      if (value != BigInt.zero) {
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
  //
  // 1234567 (6) -> 1.23457e+6 ?
  String toStringAsPrecision(int precision) => throw UnimplementedError();

  static void _checkNonNegativeArgument(int value, String name) {
    if (value < 0) {
      throw ArgumentError.value(value, name, 'The value must be >= 0');
    }
  }

  Decimal _minimize() => _minimized ??= () {
        var value = this.value;
        var scale = this.scale;

        if (value == BigInt.zero) {
          return Decimal._(value, 0);
        }

        while (value % _bigInt10 == BigInt.zero) {
          value ~/= _bigInt10;
          scale--;
        }

        return Decimal._(value, scale);
      }();

  Decimal _normalize() {
    final minimized = _minimize();
    if (minimized.scale >= 0) {
      return minimized;
    }

    return Decimal._(
      minimized.value * _bigInt10.pow(-scale),
      0,
    );
  }

  Decimal _dropFraction(
    int fractionDigits,
    BigInt Function(BigInt result, BigInt divisor) callback,
  ) {
    if (scale <= fractionDigits) {
      return this;
    }

    final divisor = _bigInt10.pow(scale - fractionDigits);
    final result = callback(value ~/ divisor, divisor);

    return Decimal._(result, fractionDigits);
  }
}

final class DecimalDivideException implements Exception {
  final Decimal dividend;
  final Decimal divisor;

  const DecimalDivideException._(this.dividend, this.divisor);

  @visibleForTesting
  DecimalDivideException.forTest(this.dividend, this.divisor);

  Fraction get fraction => dividend.divideToFraction(divisor);

  Division get division => dividend.divideWithRemainder(divisor);

  Decimal floor([int fractionDigits = 0]) => fraction.floor(fractionDigits);

  Decimal round([int fractionDigits = 0]) => fraction.round(fractionDigits);

  Decimal ceil([int fractionDigits = 0]) => fraction.ceil(fractionDigits);

  Decimal truncate([int fractionDigits = 0]) =>
      fraction.truncate(fractionDigits);

  @override
  String toString() => '$DecimalDivideException:'
      ' The result of division cannot be represented as $Decimal:'
      '\n$dividend / $divisor = $division'
      '\n$dividend / $divisor = $fraction';
}

extension DecimalBigIntExtension on BigInt {
  Decimal toDecimal() => Decimal.fromBigInt(this);
}

extension DecimalIntExtension on int {
  Decimal toDecimal() => Decimal(this);
}
