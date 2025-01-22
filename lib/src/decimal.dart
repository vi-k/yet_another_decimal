import 'package:meta/meta.dart';

import 'division.dart';
import 'fraction.dart';
import 'helpers.dart';

@immutable
final class Decimal implements Comparable<Decimal> {
  static final _char0 = '0'.codeUnitAt(0);
  static final _bigIntFive = BigInt.from(5);
  static final _bigIntTen = BigInt.from(10);

  static final Decimal zero = Decimal.fromBigInt(BigInt.zero);
  static final Decimal one = Decimal.fromBigInt(BigInt.one);
  static final Decimal two = Decimal.fromBigInt(BigInt.two);
  static final Decimal ten = Decimal.fromBigInt(_bigIntTen);

  @visibleForTesting
  final BigInt value;

  @visibleForTesting
  final int scale; // = fraction digits

  Decimal(
    int value, {
    int shiftLeft = 0,
    int shiftRight = 0,
  }) : this.fromBigInt(
          BigInt.from(value),
          shiftLeft: shiftLeft,
          shiftRight: shiftRight,
        );

  const Decimal.fromBigInt(
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

  factory Decimal.parse(String str) {
    try {
      str = str.trim();
      final dotIndex = str.indexOf('.');

      if (dotIndex == -1) {
        return Decimal._(BigInt.parse(str), 0);
      }

      // "123." is invalid.
      if (dotIndex == str.length - 1) {
        throw const FormatException();
      }

      final packedStr =
          '${str.substring(0, dotIndex)}${str.substring(dotIndex + 1)}';

      return Decimal._(
        BigInt.parse(packedStr),
        str.length - dotIndex - 1,
      );
    } on FormatException {
      throw FormatException('Could not parse Decimal: $str');
    }
  }

  const Decimal._(this.value, this.scale);

  int get fractionDigits {
    final scale = _normalize().scale;
    return scale >= 0 ? scale : 0;
  }

  int get sign => value.sign;

  bool get isNegative => value.isNegative;

  bool get isInteger => _normalize().scale == 0;

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
    var scale = this.scale;
    var divisor = other.value;

    if (divisor.isNegative) {
      divisor = -divisor;
      value = -value;
    }

    final gcd = value.fastGcd(divisor);
    value ~/= gcd;
    divisor ~/= gcd;
    scale -= other.scale;

    if (divisor != BigInt.one) {
      while (divisor % _bigIntFive == BigInt.zero) {
        value *= BigInt.two;
        scale++;
        divisor = divisor ~/ _bigIntFive;
      }

      while (divisor % BigInt.two == BigInt.zero) {
        value *= _bigIntFive;
        scale++;
        divisor = divisor ~/ BigInt.two;
      }
    }

    if (divisor != BigInt.one) {
      throw DecimalDivideException._(this, other);
    }

    return Decimal._(value, scale); // as quotient
  }

  Decimal operator ~/(Decimal other) {
    final (a, b, _) = align(other);
    return Decimal._(a ~/ b, 0);
  }

  /// Calculates the result of division as an integer quotient and remainder.
  Division divide(Decimal other) => Division(this, other);

  /// Calculates the result of division as fraction.
  Fraction fraction(Decimal other) {
    final (dividend, divisor, _) = align(other);

    return Fraction(dividend, divisor);
  }

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
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    switch (other) {
      case Decimal():
        final (a, b, _) = align(other);
        return a == b;

      case BigInt():
        final corrected = _normalize();
        return corrected.scale == 0 && corrected.value == other;

      case int():
        final corrected = _normalize();
        return corrected.scale == 0 &&
            corrected.value.isValidInt &&
            corrected.value.toInt() == other;

      default:
        return false;
    }
  }

  @override
  int get hashCode => Object.hash(value, scale);

  String debugToString() => '$Decimal(value: $value, scale: $scale)';

  @override
  String toString() {
    final value = this.value;
    var result = value.toString();
    var scale = this.scale;

    if (value == BigInt.zero) {
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

  Decimal _normalize() {
    var value = this.value;
    var scale = this.scale;

    while (scale > 0 && value % _bigIntTen == BigInt.zero) {
      value ~/= _bigIntTen;
      scale--;
    }

    while (scale < 0) {
      value *= _bigIntTen;
      scale++;
    }

    return Decimal._(value, scale);
  }

  Decimal _dropFraction(
    int fractionDigits,
    BigInt Function(BigInt result, BigInt divisor) callback,
  ) {
    if (scale <= fractionDigits) {
      return this;
    }

    final divisor = BigInt.one.mult10N(scale - fractionDigits);
    final result = callback(value ~/ divisor, divisor);

    return Decimal._(result, fractionDigits);
  }
}

// final class _Fraction {
//   final Decimal numerator;

//   /// Always > 0.
//   final BigInt denominator;

//   _Fraction._(this.numerator, this.denominator)
//       : assert(
//           !denominator.isNegative,
//           'The `denominator` must be greater than 0',
//         );

//   (BigInt, BigInt, int) _prepare(int fractionDigits) {
//     BigInt scaledValue;
//     int scale;
//     if (fractionDigits <= numerator.scale) {
//       scaledValue = numerator.value;
//       scale = numerator.scale;
//     } else {
//       scaledValue = numerator.value.mult10N(
//         fractionDigits - numerator.scale,
//       );
//       scale = fractionDigits;
//     }

//     final result = scaledValue ~/ denominator;

//     return (result, scaledValue, scale);
//   }

//   Decimal floor({int fractionDigits = 0}) {
//     var (result, scaledValue, scale) = _prepare(fractionDigits);
//     if (numerator.isNegative && scaledValue % denominator != BigInt.zero) {
//       result -= BigInt.one;
//     }

//     return Decimal._(result, scale).floor(fractionDigits: fractionDigits);
//   }

//   Decimal round({int fractionDigits = 0}) {
//     var (result, scaledValue, scale) = _prepare(fractionDigits);
//     final remainder = scaledValue.remainder(denominator).abs();
//     if (remainder >= denominator - remainder) {
//       result += BigInt.from(numerator.sign);
//     }

//     return Decimal._(result, scale).round(fractionDigits: fractionDigits);
//   }

//   Decimal ceil({int fractionDigits = 0}) {
//     var (result, scaledValue, scale) = _prepare(fractionDigits);
//     if (!numerator.isNegative && scaledValue % denominator != BigInt.zero) {
//       result += BigInt.one;
//     }

//     return Decimal._(result, scale).ceil(fractionDigits: fractionDigits);
//   }

//   Decimal truncate({int fractionDigits = 0}) {
//     final (result, _, scale) = _prepare(fractionDigits);

//     return Decimal._(result, scale).truncate(fractionDigits: fractionDigits);
//   }

//   @override
//   String toString() => '$numerator/$denominator';
// }

final class DecimalDivideException implements Exception {
  final Decimal dividend;
  final Decimal divisor;

  const DecimalDivideException._(this.dividend, this.divisor);

  @visibleForTesting
  DecimalDivideException.forTest(this.dividend, this.divisor);

  Fraction get fraction => dividend.fraction(divisor);

  Division get division => dividend.divide(divisor);

  Decimal floor([int fractionDigits = 0]) => fraction.floor(fractionDigits);

  Decimal round([int fractionDigits = 0]) => fraction.round(fractionDigits);

  Decimal ceil([int fractionDigits = 0]) => fraction.ceil(fractionDigits);

  Decimal truncate([int fractionDigits = 0]) =>
      fraction.truncate(fractionDigits);

  @override
  String toString() => '$DecimalDivideException:'
      ' The result of division cannot be represented as $Decimal:'
      ' $dividend / $divisor = $division';
}

extension BigIntExtension on BigInt {
  Decimal toDecimal() => Decimal.fromBigInt(this);
}

extension IntExtension on int {
  Decimal toDecimal() => Decimal(this);
}
