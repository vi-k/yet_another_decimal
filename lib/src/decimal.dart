import 'package:meta/meta.dart';

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

  Decimal(int value, {int shiftLeft = 0})
      : value = BigInt.from(value),
        scale = shiftLeft {
    if (shiftLeft < 0) {
      throw ArgumentError('shiftLeft must be at least 0');
    }
  }

  Decimal.fromBigInt(this.value, {int shiftLeft = 0}) : scale = shiftLeft {
    if (shiftLeft < 0) {
      throw ArgumentError('shiftLeft must be at least 0');
    }
  }

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

  const Decimal._(this.value, this.scale)
      : assert(scale >= 0, 'The scale must be at least 0');

  int get precision => _rescale().scale;

  int get sign => value.sign;

  bool get isNegative => value.isNegative;

  bool get isInteger => _rescale().scale == 0;

  bool get isZero => value == BigInt.zero;

  Decimal operator -() => Decimal._(-value, scale);

  Decimal operator +(Decimal other) {
    final (a, b, scale) = _toCommonScale(this, other);
    return Decimal._(a + b, scale);
  }

  Decimal operator -(Decimal other) {
    final (a, b, scale) = _toCommonScale(this, other);
    return Decimal._(a - b, scale);
  }

  Decimal operator *(Decimal other) => Decimal._(
        value * other.value,
        scale + other.scale,
      );

  Decimal operator /(Decimal other) {
    final (value, scale, denominator) = _fractionalize(other);

    if (denominator != BigInt.one) {
      throw DecimalDivideException._(
        Decimal._(value, scale),
        denominator,
      );
    }

    return Decimal._(value, scale);
  }

  Decimal operator ~/(Decimal other) {
    final (a, b, _) = _toCommonScale(this, other);
    return Decimal._(a ~/ b, 0);
  }

  Decimal operator %(Decimal other) {
    final (a, b, scale) = _toCommonScale(this, other);
    return Decimal._(a % b, scale);
  }

  (Decimal, Decimal) divide(Decimal other) {
    final (a, b, scale) = _toCommonScale(this, other);
    return (Decimal._(a ~/ b, 0), Decimal._(a % b, scale));
  }

  bool operator <(Decimal other) {
    final (a, b, _) = _toCommonScale(this, other);
    return a < b;
  }

  bool operator <=(Decimal other) {
    final (a, b, _) = _toCommonScale(this, other);
    return a <= b;
  }

  bool operator >(Decimal other) {
    final (a, b, _) = _toCommonScale(this, other);
    return a > b;
  }

  bool operator >=(Decimal other) {
    final (a, b, _) = _toCommonScale(this, other);
    return a >= b;
  }

  Decimal operator <<(int shiftAmount) => Decimal._(value, scale - shiftAmount);

  Decimal operator >>(int shiftAmount) => Decimal._(value, scale + shiftAmount);

  Decimal abs() => value.isNegative ? Decimal._(-value, scale) : this;

  Decimal floor({int precision = 0}) => throw UnimplementedError();

  Decimal round({int precision = 0}) => throw UnimplementedError();

  Decimal truncate({int precision = 0}) => throw UnimplementedError();

  Decimal ceil({int precision = 0}) => throw UnimplementedError();

  Decimal clamp(Decimal lowerLimit, Decimal upperLimit) {
    assert(
      lowerLimit <= upperLimit,
      'The lowerLimit must be no greater than upperLimit',
    );

    return this < lowerLimit
        ? lowerLimit
        : this > upperLimit
            ? upperLimit
            : this;
  }

  Decimal pow(int exponent) => throw UnimplementedError();

  BigInt toBigInt() => throw UnimplementedError();

  double toDouble() => double.parse(toString());

  String toStringAsExponential([int fractionDigits = 0]) =>
      throw UnimplementedError();

  String toStringAsFixed(int fractionDigits) => throw UnimplementedError();

  String toStringAsPrecision(int precision) => throw UnimplementedError();

  @override
  int compareTo(Decimal other) {
    final (a, b, _) = _toCommonScale(this, other);

    return a.compareTo(b);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    switch (other) {
      case Decimal():
        final (a, b, _) = _toCommonScale(this, other);
        return a == b;

      case BigInt():
        final corrected = _rescale();
        return corrected.scale == 0 && corrected.value == other;

      case int():
        final corrected = _rescale();
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
    var result = value.toString();
    var scale = this.scale;

    // When 0 or scale == 0, return immediately.
    if (scale == 0 || value == BigInt.zero) {
      return result;
    }

    // Remove the trailing zeros.
    var last = result.length - 1;
    while (scale > 0 && result.codeUnitAt(last) == _char0) {
      scale--;
      last--;
    }
    result = result.substring(0, last + 1);

    if (scale == 0) {
      return result;
    }

    final (sign, number) = _splitByIndex(result, value.isNegative ? 1 : 0);

    // Going between a sign and a number.
    if (scale >= number.length) {
      result = '${sign}0.${number.padLeft(scale, '0')}';
    } else {
      final (integer, fractional) =
          _splitByIndex(number, number.length - scale);
      result = '$sign$integer.$fractional';
    }

    return result;
  }

  static BigInt _mult10N(BigInt value, int count) {
    var result = value;
    for (var i = count; i > 0; i--) {
      result *= _bigIntTen;
    }

    return result;
  }

  // https://github.com/dart-lang/sdk/issues/46180
  static BigInt _gcd(BigInt a, BigInt b) {
    while (b != BigInt.zero) {
      final tmp = b;
      b = a % b;
      a = tmp;
    }

    return a;
  }

  static (BigInt, BigInt, int) _toCommonScale(Decimal a, Decimal b) {
    final as = a.scale;
    final bs = b.scale;

    if (as == bs) {
      return (a.value, b.value, as);
    } else if (as > bs) {
      return (a.value, _mult10N(b.value, as - bs), as);
    } else {
      return (_mult10N(a.value, bs - as), b.value, bs);
    }
  }

  Decimal _rescale() {
    var value = this.value;
    var scale = this.scale;
    while (scale > 0 && value % _bigIntTen == BigInt.zero) {
      value ~/= _bigIntTen;
      scale--;
    }

    return Decimal._(value, scale);
  }

  /// Fractionalize.
  ///
  /// Return:
  /// numerator - value and scale
  /// denominator - always > 0
  (BigInt, int, BigInt) _fractionalize(Decimal other) {
    var value = this.value;
    var scale = this.scale;
    var denominator = other.value;

    if (denominator.isNegative) {
      denominator = -denominator;
      value = -value;
    }

    final gcd = _gcd(value, denominator);
    value ~/= gcd;
    denominator ~/= gcd;
    scale -= other.scale;

    if (denominator != BigInt.one) {
      while (denominator % _bigIntFive == BigInt.zero) {
        value *= BigInt.two;
        scale++;
        denominator = denominator ~/ _bigIntFive;
      }

      while (denominator % BigInt.two == BigInt.zero) {
        value *= _bigIntFive;
        scale++;
        denominator = denominator ~/ BigInt.two;
      }
    }

    while (scale < 0) {
      value *= _bigIntTen;
      scale++;
    }

    return (value, scale, denominator);
  }

  (String, String) _splitByIndex(String str, int index) =>
      (str.substring(0, index), str.substring(index));
}

final class _Rational {
  final Decimal numerator;

  /// Always > 0.
  final BigInt denominator;

  _Rational(this.numerator, this.denominator)
      : assert(
          !denominator.isNegative,
          'The denominator must be greater than 0',
        );

  Decimal floor(int addPrecision) {
    final scaledValue = Decimal._mult10N(numerator.value, addPrecision);
    var result = scaledValue ~/ denominator;
    if (numerator.isNegative && scaledValue % denominator != BigInt.zero) {
      result -= BigInt.one;
    }

    return Decimal._(result, numerator.scale + addPrecision);
  }

  Decimal round(int addPrecision) {
    final scaledValue = Decimal._mult10N(numerator.value, addPrecision);
    var result = scaledValue ~/ denominator;
    final modulo = scaledValue.abs() % denominator;
    if (modulo >= denominator - modulo) {
      result += BigInt.from(numerator.sign);
    }

    return Decimal._(result, numerator.scale + addPrecision);
  }

  Decimal ceil(int addPrecision) {
    final scaledValue = Decimal._mult10N(numerator.value, addPrecision);
    var result = scaledValue ~/ denominator;
    if (!numerator.isNegative && scaledValue % denominator != BigInt.zero) {
      result += BigInt.one;
    }

    return Decimal._(result, numerator.scale + addPrecision);
  }

  Decimal truncate(int addPrecision) {
    final scaledValue = Decimal._mult10N(numerator.value, addPrecision);
    final result = scaledValue ~/ denominator;

    return Decimal._(result, numerator.scale + addPrecision);
  }

  @override
  String toString() => '$numerator/$denominator';
}

final class DecimalDivideException extends _Rational implements Exception {
  DecimalDivideException._(super.numerator, super.denominator);

  @visibleForTesting
  DecimalDivideException.forTest(super.numerator, super.denominator);

  @override
  String toString() => '$DecimalDivideException:'
      ' The result of division cannot be represented as $Decimal'
      ' (numerator: $numerator, denominator: $denominator)';
}

extension BigIntExtension on BigInt {
  Decimal toDecimal() => Decimal.fromBigInt(this);
}

extension IntExtension on int {
  Decimal toDecimal() => Decimal(this);
}
