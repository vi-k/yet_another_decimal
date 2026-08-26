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

    // The sign is normalized after the reduction, not before it: the minimum
    // integer is its own negation, so `2 / int.min` only becomes normalizable
    // once the two is cancelled.
    final gcd = dividend.fastGcd(divisor);
    final numerator = dividend ~/ gcd;
    final denominator = divisor ~/ gcd;

    if (!denominator.isNegative) {
      return ShortFraction._(numerator, denominator);
    }

    // `x == -x` holds for zero and for the minimum integer only, and neither
    // of these is zero here.
    if (denominator == -denominator || numerator == -numerator) {
      throw ArgumentError(
        'The fraction $dividend/$divisor cannot be normalized:'
        ' its denominator does not fit into int64 with a positive sign',
      );
    }

    return ShortFraction._(-numerator, -denominator);
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

  /// Multiplies this fraction by [other].
  ///
  /// The cross factors are cancelled before the multiplication, not after it.
  /// Fraction on BigInt has no need for that; here it is the difference
  /// between an exact answer and an invented one, because the product of two
  /// int64 numbers is not an int64 number.
  ShortFraction operator *(ShortFraction other) {
    final left = numerator.fastGcd(other.denominator);
    final right = other.numerator.fastGcd(denominator);

    return ShortFraction(
      (numerator ~/ left) * (other.numerator ~/ right),
      (denominator ~/ right) * (other.denominator ~/ left),
    );
  }

  /// Divides this fraction by [other].
  ShortFraction operator /(ShortFraction other) {
    final left = numerator.fastGcd(other.numerator);
    final right = other.denominator.fastGcd(denominator);

    return ShortFraction(
      (numerator ~/ left) * (other.denominator ~/ right),
      (denominator ~/ right) * (other.numerator ~/ left),
    );
  }

  /// Adds [other] to this fraction.
  ShortFraction operator +(ShortFraction other) =>
      _addTo(other.numerator, other.denominator);

  /// Subtracts [other] from this fraction.
  ShortFraction operator -(ShortFraction other) {
    final numerator = ShortDecimal._negateOrNull(other.numerator);

    return numerator == null
        // The numerator cannot be negated, so the whole sum is left to BigInt.
        ? _addExactly(-BigInt.from(other.numerator), other.denominator)
        : _addTo(numerator, other.denominator);
  }

  /// Adds `numerator / denominator` to this fraction.
  ///
  /// The common denominator is the least one, not the product: the product
  /// overflows on denominators that have anything in common. That alone is not
  /// enough, though — the sum of the numerators overflows on its own — so an
  /// overflow anywhere sends the whole sum to [_addExactly].
  ShortFraction _addTo(int numerator, int denominator) {
    final gcd = this.denominator.fastGcd(denominator);
    final left = denominator ~/ gcd;
    final right = this.denominator ~/ gcd;

    final a = ShortDecimal._productOrNull(this.numerator, left);
    final b = ShortDecimal._productOrNull(numerator, right);
    final sum = a == null || b == null ? null : ShortDecimal._sumOrNull(a, b);
    final common = ShortDecimal._productOrNull(this.denominator, left);

    return sum != null && common != null
        ? ShortFraction(sum, common)
        : _addExactly(BigInt.from(numerator), denominator);
  }

  /// The same sum for the case where int64 is not wide enough for it.
  ///
  /// The exact result often fits even when the intermediate does not — that is
  /// the whole reason this path exists. When it does not fit either, the
  /// overflow stays silent, as everywhere else in this family.
  ShortFraction _addExactly(BigInt numerator, int denominator) {
    final gcd = BigInt.from(this.denominator).fastGcd(BigInt.from(denominator));
    final left = BigInt.from(denominator) ~/ gcd;
    final right = BigInt.from(this.denominator) ~/ gcd;

    final exact = _fromBigOrNull(
      BigInt.from(this.numerator) * left + numerator * right,
      BigInt.from(this.denominator) * left,
    );

    return exact ??
        ShortFraction(
          this.numerator * left.toInt() + numerator.toInt() * right.toInt(),
          this.denominator * left.toInt(),
        );
  }

  /// The reduced fraction, or null when it does not fit int64.
  static ShortFraction? _fromBigOrNull(BigInt numerator, BigInt denominator) {
    final gcd = numerator.fastGcd(denominator);
    var reducedNumerator = numerator ~/ gcd;
    var reducedDenominator = denominator ~/ gcd;

    if (reducedDenominator.isNegative) {
      reducedNumerator = -reducedNumerator;
      reducedDenominator = -reducedDenominator;
    }

    return reducedNumerator.isValidInt && reducedDenominator.isValidInt
        ? ShortFraction._(reducedNumerator.toInt(), reducedDenominator.toInt())
        : null;
  }

  /// Rounds the fraction towards negative infinity to [fractionDigits].
  ShortDecimal floor([int fractionDigits = 0]) =>
      _dropFraction(fractionDigits, _Rounding.floor);

  /// Rounds the fraction to the closest decimal with [fractionDigits].
  ShortDecimal round([int fractionDigits = 0]) =>
      _dropFraction(fractionDigits, _Rounding.round);

  /// Rounds the fraction towards infinity to [fractionDigits].
  ShortDecimal ceil([int fractionDigits = 0]) =>
      _dropFraction(fractionDigits, _Rounding.ceil);

  /// Rounds the fraction towards zero to [fractionDigits].
  ShortDecimal truncate([int fractionDigits = 0]) =>
      _dropFraction(fractionDigits, _Rounding.truncate);

  /// Brings the fraction to [fractionDigits] digits by [rounding].
  ///
  /// A negative [fractionDigits] rounds to tens, hundreds and so on, the same
  /// as [ShortDecimal.floor] and its neighbours do; it scales the denominator
  /// instead of the numerator.
  ShortDecimal _dropFraction(int fractionDigits, _Rounding rounding) {
    final numerator = fractionDigits >= 0
        ? ShortDecimal._scaledOrNull(this.numerator, fractionDigits)
        : this.numerator;
    final denominator = fractionDigits >= 0
        ? this.denominator
        : ShortDecimal._scaledOrNull(this.denominator, -fractionDigits);

    if (numerator == null || denominator == null) {
      return _dropFractionExactly(fractionDigits, rounding);
    }

    final remainder = numerator.remainder(denominator).abs();

    return ShortDecimal._pack(
      numerator ~/ denominator +
          rounding.correction(
            sign: numerator.sign,
            hasRemainder: remainder != 0,
            atLeastHalf: remainder >= denominator - remainder,
          ),
      fractionDigits,
    );
  }

  /// The same rounding for the case where int64 is not wide enough for it.
  ///
  /// This is the one place in the family that reaches for BigInt, and it is
  /// reached only when the int path would answer with a wrapped-around number.
  /// The alternative was the defect this replaces: a positive fraction coming
  /// back negative.
  ///
  /// When even the result does not fit — asking a fraction for more digits
  /// than int64 holds — the closest representable value is returned instead:
  /// the scale is reduced with rounding until the value fits. Losing the last
  /// digits keeps the sign and the magnitude; wrapping around keeps neither.
  ShortDecimal _dropFractionExactly(int fractionDigits, _Rounding rounding) {
    final ten = BigInt.from(10);
    final power = ten.pow(fractionDigits.abs());
    final numerator = fractionDigits >= 0
        ? BigInt.from(this.numerator) * power
        : BigInt.from(this.numerator);
    final denominator = fractionDigits >= 0
        ? BigInt.from(this.denominator)
        : BigInt.from(this.denominator) * power;

    final remainder = numerator.remainder(denominator).abs();
    var value =
        numerator ~/ denominator +
        BigInt.from(
          rounding.correction(
            sign: numerator.sign,
            hasRemainder: remainder != BigInt.zero,
            atLeastHalf: remainder >= denominator - remainder,
          ),
        );

    var scale = fractionDigits;
    while (!value.isValidInt) {
      final rest = value.remainder(ten).abs();
      value = value ~/ ten;
      if (rest * BigInt.two >= ten) {
        value += BigInt.from(value.sign);
      }
      scale--;
    }

    return ShortDecimal._pack(value.toInt(), scale);
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

/// The rule a rounding method applies to the quotient it got.
///
/// Written once and shared by the int and the BigInt paths of
/// [ShortFraction._dropFraction]: the rule is the same, only the width of the
/// numbers differs.
enum _Rounding {
  floor,
  round,
  ceil,
  truncate;

  /// What to add to the quotient: -1, 0 or 1.
  int correction({
    required int sign,
    required bool hasRemainder,
    required bool atLeastHalf,
  }) => switch (this) {
    _Rounding.truncate => 0,
    _Rounding.floor => sign < 0 && hasRemainder ? -1 : 0,
    _Rounding.ceil => sign > 0 && hasRemainder ? 1 : 0,
    _Rounding.round => atLeastHalf ? sign : 0,
  };
}
