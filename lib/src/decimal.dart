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
  final int shift; // = fraction digits

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
        shift = shiftLeft - shiftRight;

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
        dotIndex + 1 - str.length,
      );
    } on FormatException {
      throw FormatException('Could not parse Decimal: $str');
    }
  }

  const Decimal._(this.value, this.shift);

  int get fractionDigits {
    final shift = _normalize().shift;
    return shift > 0 ? 0 : -shift;
  }

  int get sign => value.sign;

  bool get isNegative => value.isNegative;

  bool get isInteger => _normalize().shift == 0;

  bool get isZero => value == BigInt.zero;

  Decimal operator -() => Decimal._(-value, shift);

  Decimal operator +(Decimal other) {
    final (a, b, shift) = _align(this, other);
    return Decimal._(a + b, shift);
  }

  Decimal operator -(Decimal other) {
    final (a, b, shift) = _align(this, other);
    return Decimal._(a - b, shift);
  }

  Decimal operator *(Decimal other) => Decimal._(
        value * other.value,
        shift + other.shift,
      );

  Decimal operator /(Decimal other) {
    final (value, shift, denominator) = _fractionalize(other);

    if (denominator != BigInt.one) {
      throw DecimalDivideException._(
        Decimal._(value, shift),
        denominator,
      );
    }

    return Decimal._(value, shift);
  }

  Decimal operator ~/(Decimal other) {
    final (a, b, _) = _align(this, other);
    return Decimal._(a ~/ b, 0);
  }

  Decimal operator %(Decimal other) {
    final (a, b, shift) = _align(this, other);
    return Decimal._(a % b, shift);
  }

  (Decimal, Decimal) divide(Decimal other) {
    final (a, b, shift) = _align(this, other);
    return (Decimal._(a ~/ b, 0), Decimal._(a % b, shift));
  }

  @visibleForTesting
  Fraction fraction(Decimal other) {
    final (value, shift, denominator) = _fractionalize(other);

    return Fraction._(
      Decimal._(value, shift),
      denominator,
    );
  }

  bool operator <(Decimal other) {
    final (a, b, _) = _align(this, other);
    return a < b;
  }

  bool operator <=(Decimal other) {
    final (a, b, _) = _align(this, other);
    return a <= b;
  }

  bool operator >(Decimal other) {
    final (a, b, _) = _align(this, other);
    return a > b;
  }

  bool operator >=(Decimal other) {
    final (a, b, _) = _align(this, other);
    return a >= b;
  }

  Decimal operator <<(int shiftAmount) => Decimal._(value, shift + shiftAmount);

  Decimal operator >>(int shiftAmount) => Decimal._(value, shift - shiftAmount);

  Decimal abs() => value.isNegative ? Decimal._(-value, shift) : this;

  Decimal _dropFraction(
    int fractionDigits,
    BigInt Function(BigInt result, BigInt divisor) callback,
  ) {
    if (-shift <= fractionDigits) {
      return this;
    }

    final divisor = _mult10N(BigInt.one, -(shift + fractionDigits));
    final result = callback(value ~/ divisor, divisor);

    return Decimal._(result, -fractionDigits);
  }

  Decimal floor({int fractionDigits = 0}) => _dropFraction(
        fractionDigits,
        (result, divisor) => isNegative && value % divisor != BigInt.zero
            ? result - BigInt.one
            : result,
      );

  Decimal round({int fractionDigits = 0}) => _dropFraction(
        fractionDigits,
        (result, divisor) {
          final modulo = value.abs() % divisor;
          return modulo >= divisor - modulo
              ? result + BigInt.from(value.sign)
              : result;
        },
      );

  Decimal ceil({int fractionDigits = 0}) => _dropFraction(
        fractionDigits,
        (result, divisor) => !isNegative && value % divisor != BigInt.zero
            ? result + BigInt.one
            : result,
      );

  Decimal truncate({int fractionDigits = 0}) => _dropFraction(
        fractionDigits,
        (result, divisor) => result,
      );

  Decimal clamp(Decimal lowerLimit, Decimal upperLimit) {
    assert(
      lowerLimit <= upperLimit,
      'The `lowerLimit` must be no greater than `upperLimit`',
    );

    return this < lowerLimit
        ? lowerLimit
        : this > upperLimit
            ? upperLimit
            : this;
  }

  Decimal pow(int exponent) {
    if (exponent < 0) {
      throw ArgumentError.value(
        exponent,
        null,
        'Eexponent must not be negative',
      );
    }

    return Decimal._(value.pow(exponent), shift * exponent);
  }

  BigInt toBigInt() => truncate().value;

  double toDouble() => double.parse(toString());

  @override
  int compareTo(Decimal other) {
    final (a, b, _) = _align(this, other);
    return a.compareTo(b);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    switch (other) {
      case Decimal():
        final (a, b, _) = _align(this, other);
        return a == b;

      case BigInt():
        final corrected = _normalize();
        return corrected.shift == 0 && corrected.value == other;

      case int():
        final corrected = _normalize();
        return corrected.shift == 0 &&
            corrected.value.isValidInt &&
            corrected.value.toInt() == other;

      default:
        return false;
    }
  }

  @override
  int get hashCode => Object.hash(value, shift);

  String debugToString() => '$Decimal(value: $value, shift: $shift)';

  @override
  String toString() {
    var result = value.toString();
    var shift = this.shift;

    if (value == BigInt.zero) {
      return result;
    }

    // Remove trailing zeros.
    if (shift < 0) {
      var last = result.length - 1;
      if (result.codeUnitAt(last) == _char0) {
        do {
          shift++;
          last--;
        } while (shift < 0 && result.codeUnitAt(last) == _char0);
        result = result.substring(0, last + 1);
      }
    }

    if (shift == 0) {
      return result;
    }

    // Going between a sign and a number.
    final (sign, number) = _splitByIndex(result, value.isNegative ? 1 : 0);

    if (shift > 0) {
      return '$sign$number${'0' * shift}';
    }

    if (-shift >= number.length) {
      return '${sign}0.${number.padLeft(-shift, '0')}';
    }

    final (integer, fractional) = _splitByIndex(number, number.length + shift);

    return '$sign$integer.$fractional';
  }

  String toStringAsExponential([int fractionDigits = 0]) =>
      throw UnimplementedError();

  String toStringAsFixed(int fractionDigits) => throw UnimplementedError();

  String toStringAsPrecision(int precision) => throw UnimplementedError();

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

  static (BigInt, BigInt, int) _align(Decimal a, Decimal b) {
    final as = a.shift;
    final bs = b.shift;

    if (as == bs) {
      return (a.value, b.value, as);
    } else if (as < bs) {
      return (a.value, _mult10N(b.value, bs - as), as);
    } else {
      return (_mult10N(a.value, as - bs), b.value, bs);
    }
  }

  Decimal _normalize() {
    var value = this.value;
    var shift = this.shift;

    while (shift < 0 && value % _bigIntTen == BigInt.zero) {
      value ~/= _bigIntTen;
      shift++;
    }

    while (shift > 0) {
      value *= _bigIntTen;
      shift--;
    }

    return Decimal._(value, shift);
  }

  /// Fractionalize.
  ///
  /// Return:
  /// numerator - value and scale
  /// denominator - always > 0
  (BigInt, int, BigInt) _fractionalize(Decimal other) {
    var value = this.value;
    var shift = this.shift;
    var denominator = other.value;

    if (denominator.isNegative) {
      denominator = -denominator;
      value = -value;
    }

    final gcd = _gcd(value, denominator);
    value ~/= gcd;
    denominator ~/= gcd;
    shift -= other.shift;

    if (denominator != BigInt.one) {
      while (denominator % _bigIntFive == BigInt.zero) {
        value *= BigInt.two;
        shift--;
        denominator = denominator ~/ _bigIntFive;
      }

      while (denominator % BigInt.two == BigInt.zero) {
        value *= _bigIntFive;
        shift--;
        denominator = denominator ~/ BigInt.two;
      }
    }

    return (value, shift, denominator);
  }

  (String, String) _splitByIndex(String str, int index) =>
      (str.substring(0, index), str.substring(index));
}

final class Fraction {
  final Decimal numerator;

  /// Always > 0.
  final BigInt denominator;

  Fraction._(this.numerator, this.denominator)
      : assert(
          !denominator.isNegative,
          'The `denominator` must be greater than 0',
        );

  (BigInt, BigInt, int) _prepare(int fractionDigits) {
    final (scaledValue, shift) = fractionDigits > -numerator.shift
        ? (
            Decimal._mult10N(numerator.value, numerator.shift + fractionDigits),
            -fractionDigits
          )
        : (numerator.value, numerator.shift);
    final result = scaledValue ~/ denominator;

    return (result, scaledValue, shift);
  }

  Decimal floor({int fractionDigits = 0}) {
    var (result, scaledValue, shift) = _prepare(fractionDigits);
    if (numerator.isNegative && scaledValue % denominator != BigInt.zero) {
      result -= BigInt.one;
    }

    return Decimal._(result, shift).floor(fractionDigits: fractionDigits);
  }

  Decimal round({int fractionDigits = 0}) {
    var (result, scaledValue, shift) = _prepare(fractionDigits);
    final modulo = scaledValue.abs() % denominator;
    if (modulo >= denominator - modulo) {
      result += BigInt.from(numerator.sign);
    }

    return Decimal._(result, shift).round(fractionDigits: fractionDigits);
  }

  Decimal ceil({int fractionDigits = 0}) {
    var (result, scaledValue, shift) = _prepare(fractionDigits);
    if (!numerator.isNegative && scaledValue % denominator != BigInt.zero) {
      result += BigInt.one;
    }

    return Decimal._(result, shift).ceil(fractionDigits: fractionDigits);
  }

  Decimal truncate({int fractionDigits = 0}) {
    final (result, _, shift) = _prepare(fractionDigits);

    return Decimal._(result, shift).truncate(fractionDigits: fractionDigits);
  }

  @override
  String toString() => '$numerator/$denominator';
}

final class DecimalDivideException extends Fraction implements Exception {
  DecimalDivideException._(super.numerator, super.denominator) : super._();

  @visibleForTesting
  DecimalDivideException.forTest(super.numerator, super.denominator)
      : super._();

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
