part of 'decimal.dart';

@immutable

/// An exact ratio of two integers: what division answers when a decimal cannot.
///
/// One divided by three is `1/3` here, and nothing is lost on the way. The
/// ratio is always kept in lowest terms with a positive [denominator], so equal
/// ratios are equal objects.
///
/// ```dart
/// final third = Decimal(1).divideToFraction(Decimal(3));
/// print(third);            // 1/3
/// print(third.round(4));   // 0.3333
/// print(third.toDouble()); // 0.3333333333333333
/// ```
final class Fraction implements Comparable<Fraction> {
  /// Numerator.
  final BigInt numerator;

  /// Denominator.
  final BigInt denominator;

  /// A ratio of [dividend] over [divisor], reduced to lowest terms.
  ///
  /// The sign is carried by the numerator: the denominator is always positive.
  /// Throws `UnsupportedError` when [divisor] is zero.
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

  /// Reads a ratio written as `numerator/denominator`, or a bare integer.
  ///
  /// ```dart
  /// print(Fraction.parse('3/4')); // 3/4
  /// print(Fraction.parse('5'));   // 5
  /// ```
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

  /// Whether this ratio is less than zero.
  bool get isNegative => numerator.isNegative;

  /// The sign: -1, 0 or 1.
  int get sign => numerator.sign;

  Fraction operator *(Fraction other) =>
      Fraction(numerator * other.numerator, denominator * other.denominator);

  Fraction operator /(Fraction other) =>
      Fraction(numerator * other.denominator, denominator * other.numerator);

  Fraction operator +(Fraction other) => Fraction(
        numerator * other.denominator + other.numerator * denominator,
        denominator * other.denominator,
      );

  Fraction operator -(Fraction other) => Fraction(
        numerator * other.denominator - other.numerator * denominator,
        denominator * other.denominator,
      );

  /// The absolute value of this fraction.
  Fraction abs() =>
      numerator.isNegative ? Fraction._asIs(-numerator, denominator) : this;

  /// One divided by this fraction.
  ///
  /// Throws [UnsupportedError] if this fraction is zero.
  Fraction get inverse => Fraction(denominator, numerator);

  /// Compares this to [other].
  ///
  /// Returns a negative number if this is less than other, zero if they are
  /// equal, and a positive number if this is greater than other.
  @override
  int compareTo(Fraction other) => (numerator * other.denominator)
      .compareTo(other.numerator * denominator)
      .sign;

  /// Converts this fraction to [double].
  double toDouble() => Decimal._ratioToDouble(numerator, denominator);

  /// This ratio as a [Decimal].
  ///
  /// Throws [DecimalDivideException] when the ratio has no finite decimal form.
  /// [round], [floor], [ceil] and [truncate] say how many digits to keep and
  /// always answer.
  Decimal toDecimal() =>
      Decimal.fromBigInt(numerator) / Decimal.fromBigInt(denominator);

  /// Rounds the fraction towards negative infinity to [fractionDigits].
  Decimal floor([int fractionDigits = 0]) {
    final (numerator, denominator) = _align(fractionDigits);
    final quotient = numerator ~/ denominator;

    return Decimal._asIs(
      numerator.isNegative && numerator.remainder(denominator) != BigInt.zero
          ? quotient - BigInt.one
          : quotient,
      fractionDigits,
    );
  }

  /// Rounds the fraction to the closest decimal with [fractionDigits].
  Decimal round([int fractionDigits = 0]) {
    final (numerator, denominator) = _align(fractionDigits);
    final quotient = numerator ~/ denominator;
    final remainder = numerator.remainder(denominator).abs();

    return Decimal._asIs(
      remainder >= denominator - remainder
          ? quotient + BigInt.from(numerator.sign)
          : quotient,
      fractionDigits,
    );
  }

  /// Rounds the fraction towards infinity to [fractionDigits].
  Decimal ceil([int fractionDigits = 0]) {
    final (numerator, denominator) = _align(fractionDigits);
    final quotient = numerator ~/ denominator;

    return Decimal._asIs(
      !numerator.isNegative && numerator.remainder(denominator) != BigInt.zero
          ? quotient + BigInt.one
          : quotient,
      fractionDigits,
    );
  }

  /// Rounds the fraction towards zero to [fractionDigits].
  Decimal truncate([int fractionDigits = 0]) {
    final (numerator, denominator) = _align(fractionDigits);

    return Decimal._asIs(numerator ~/ denominator, fractionDigits);
  }

  /// The fraction brought to [fractionDigits] digits after the decimal point.
  ///
  /// A negative [fractionDigits] rounds to tens, hundreds and so on — the same
  /// scenario [Decimal.floor] and its neighbours support. It cannot scale the
  /// numerator then, so it scales the denominator instead: `BigInt.pow` does
  /// not take a negative exponent, and the two directions are the same
  /// division anyway.
  (BigInt, BigInt) _align(int fractionDigits) => fractionDigits >= 0
      ? (numerator * Decimal._pow10(fractionDigits), denominator)
      : (numerator, denominator * Decimal._pow10(-fractionDigits));

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
