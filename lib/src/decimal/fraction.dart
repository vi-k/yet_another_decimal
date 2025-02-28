part of 'decimal.dart';

@immutable
final class Fraction {
  /// Numerator.
  final BigInt numerator;

  /// Denominator.
  final BigInt denominator;

  factory Fraction(BigInt dividend, BigInt divisor) {
    if (divisor == BigInt.zero) {
      throw UnsupportedError('division by zero');
    }

    if (divisor.isNegative) {
      dividend = -dividend;
      divisor = -divisor;
    }

    final gcd = dividend.fastGcd(divisor);

    return Fraction._asIs(dividend ~/ gcd, divisor ~/ gcd);
  }

  factory Fraction.parse(String str) {
    final fractionBar = str.indexOf('/');

    if (fractionBar == -1) {
      final numerator = BigInt.parse(str);
      return Fraction._asIs(numerator, BigInt.one);
    }

    final dividend = BigInt.parse(str.substring(0, fractionBar));
    final divisor = BigInt.parse(str.substring(fractionBar + 1));

    return Fraction(dividend, divisor);
  }

  Fraction._asIs(this.numerator, this.denominator)
      : assert(denominator > BigInt.zero, 'The denominator must be > 0');

  bool get isNegative => numerator.isNegative;

  int get sign => numerator.sign;

  Fraction operator *(Fraction other) => Fraction(
        numerator * other.numerator,
        denominator * other.denominator,
      );

  Fraction operator /(Fraction other) => Fraction(
        numerator * other.denominator,
        denominator * other.numerator,
      );

  Fraction operator +(Fraction other) => Fraction(
        numerator * other.denominator + other.numerator * denominator,
        denominator * other.denominator,
      );

  Fraction operator -(Fraction other) => Fraction(
        numerator * other.denominator - other.numerator * denominator,
        denominator * other.denominator,
      );

  Decimal toDecimal() =>
      Decimal.fromBigInt(numerator) / Decimal.fromBigInt(denominator);

  Decimal floor([int fractionDigits = 0]) {
    final scaledNumerator = numerator * Decimal._bigInt10.pow(fractionDigits);
    var quotient = scaledNumerator ~/ denominator;

    if (scaledNumerator.isNegative &&
        scaledNumerator % denominator != BigInt.zero) {
      quotient -= BigInt.one;
    }

    return Decimal.fromBigInt(quotient, shiftRight: fractionDigits);
  }

  Decimal round([int fractionDigits = 0]) {
    final scaledNumerator = numerator * Decimal._bigInt10.pow(fractionDigits);
    var quotient = scaledNumerator ~/ denominator;

    final remainder = scaledNumerator.remainder(denominator).abs();
    if (remainder >= denominator.abs() - remainder) {
      quotient += BigInt.from(scaledNumerator.sign);
    }

    return Decimal.fromBigInt(quotient, shiftRight: fractionDigits);
  }

  Decimal ceil([int fractionDigits = 0]) {
    final scaledNumerator = numerator * Decimal._bigInt10.pow(fractionDigits);
    var quotient = scaledNumerator ~/ denominator;

    if (!scaledNumerator.isNegative &&
        scaledNumerator % denominator != BigInt.zero) {
      quotient += BigInt.one;
    }

    return Decimal.fromBigInt(quotient, shiftRight: fractionDigits);
  }

  Decimal truncate([int fractionDigits = 0]) {
    final scaledNumerator = numerator * Decimal._bigInt10.pow(fractionDigits);
    final quotient = scaledNumerator ~/ denominator;

    return Decimal.fromBigInt(quotient, shiftRight: fractionDigits);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fraction &&
          numerator == other.numerator &&
          denominator == other.denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() =>
      denominator == BigInt.one ? '$numerator' : '$numerator/$denominator';
}
