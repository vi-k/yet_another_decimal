part of 'short_decimal.dart';

@immutable
final class ShortFraction {
  /// Numerator.
  final int numerator;

  /// Denominator.
  final int denominator;

  factory ShortFraction(int dividend, int divisor) {
    if (divisor == 0) {
      throw UnsupportedError('division by zero');
    }

    if (divisor.isNegative) {
      dividend = -dividend;
      divisor = -divisor;
    }

    final gcd = dividend.fastGcd(divisor);

    return ShortFraction._(dividend ~/ gcd, divisor ~/ gcd);
  }

  factory ShortFraction.parse(String str) {
    final fractionBar = str.indexOf('/');

    if (fractionBar == -1) {
      final numerator = int.parse(str);
      return ShortFraction._(numerator, 1);
    }

    final dividend = int.parse(str.substring(0, fractionBar));
    final divisor = int.parse(str.substring(fractionBar + 1));

    return ShortFraction(dividend, divisor);
  }

  const ShortFraction._(this.numerator, this.denominator)
    : assert(denominator > 0, 'The denominator must be > 0');

  bool get isNegative => numerator.isNegative;

  int get sign => numerator.sign;

  ShortFraction operator *(ShortFraction other) => ShortFraction(
    numerator * other.numerator,
    denominator * other.denominator,
  );

  ShortFraction operator /(ShortFraction other) => ShortFraction(
    numerator * other.denominator,
    denominator * other.numerator,
  );

  ShortFraction operator +(ShortFraction other) => ShortFraction(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  );

  ShortFraction operator -(ShortFraction other) => ShortFraction(
    numerator * other.denominator - other.numerator * denominator,
    denominator * other.denominator,
  );

  ShortDecimal floor([int fractionDigits = 0]) {
    final scaledNumerator = numerator * ShortDecimal._pow10(fractionDigits);
    var quotient = scaledNumerator ~/ denominator;

    if (scaledNumerator.isNegative && scaledNumerator % denominator != 0) {
      quotient -= 1;
    }

    return ShortDecimal(quotient, shiftRight: fractionDigits);
  }

  ShortDecimal round([int fractionDigits = 0]) {
    final scaledNumerator = numerator * ShortDecimal._pow10(fractionDigits);
    var quotient = scaledNumerator ~/ denominator;

    final remainder = scaledNumerator.remainder(denominator).abs();
    if (remainder >= denominator.abs() - remainder) {
      quotient += scaledNumerator.sign;
    }

    return ShortDecimal(quotient, shiftRight: fractionDigits);
  }

  ShortDecimal ceil([int fractionDigits = 0]) {
    final scaledNumerator = numerator * ShortDecimal._pow10(fractionDigits);
    var quotient = scaledNumerator ~/ denominator;

    if (!scaledNumerator.isNegative && scaledNumerator % denominator != 0) {
      quotient += 1;
    }

    return ShortDecimal(quotient, shiftRight: fractionDigits);
  }

  ShortDecimal truncate([int fractionDigits = 0]) {
    final scaledNumerator = numerator * ShortDecimal._pow10(fractionDigits);
    final quotient = scaledNumerator ~/ denominator;

    return ShortDecimal(quotient, shiftRight: fractionDigits);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShortFraction &&
          numerator == other.numerator &&
          denominator == other.denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() =>
      denominator == 1 ? '$numerator' : '$numerator/$denominator';
}
