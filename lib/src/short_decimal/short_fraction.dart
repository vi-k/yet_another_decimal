part of 'short_decimal.dart';

@immutable

/// An exact ratio of two integers: what division answers when a decimal cannot.
///
/// One divided by three is `1/3` here: the ratio itself loses nothing, unlike
/// a decimal that has to stop somewhere. It is always kept in lowest terms
/// with a positive [denominator], so equal ratios are equal objects.
///
/// The arithmetic, on the other hand, is int64 arithmetic and **overflows
/// silently**, the same way [ShortDecimal] does. A sum of two fractions whose
/// cross products leave int64 comes back wrong rather than refused. Where the
/// magnitudes are not known in advance, `Fraction` from the BigInt family has
/// no such limit.
///
/// ```dart
/// final third = ShortDecimal(1).divideToFraction(ShortDecimal(3));
/// print(third);            // 1/3
/// print(third.round(4));   // 0.3333
/// print(third.toDouble()); // 0.3333333333333333
/// ```
///
/// [round] and its three neighbours take a number of digits, and past a
/// million they refuse it with `ArgumentError`: the power of ten such a
/// request needs is built in `BigInt` here, and it is a number nobody can
/// hold.
final class ShortFraction implements Comparable<ShortFraction> {
  /// Numerator.
  final int numerator;

  /// Denominator.
  final int denominator;

  /// A ratio of [dividend] over [divisor], reduced to lowest terms.
  ///
  /// The sign is carried by the numerator: the denominator is always positive.
  /// Throws `UnsupportedError` when [divisor] is zero, and `ArgumentError`
  /// when the ratio has no fraction in int64 — see [_orNull].
  factory ShortFraction(int dividend, int divisor) =>
      _orNull(dividend, divisor) ??
      (throw ArgumentError(
        'The fraction $dividend/$divisor cannot be normalized:'
        ' its denominator does not fit into int64 with a positive sign',
      ));

  /// The same ratio, or null where int64 has no room for its sign.
  ///
  /// Only a denominator of 2^63 lands here: its magnitude is one past the
  /// largest int64, so the ratio cannot be written with the positive
  /// denominator a fraction promises. The division it came from is often
  /// answerable all the same — [ShortDecimal.divide] rounds the pair without
  /// the fraction — and that is what this factory is for.
  static ShortFraction? _orNull(int dividend, int divisor) {
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

    // `x == -x` holds for zero and for the minimum integer only. Zero over a
    // negative number is an ordinary ratio — it is zero — and only the
    // minimum integer really has nowhere to put the sign.
    if (numerator == 0) {
      return const ShortFraction._(0, 1);
    }

    if (denominator == -denominator || numerator == -numerator) {
      return null;
    }

    return ShortFraction._(-numerator, -denominator);
  }

  /// Reads a ratio written as `numerator/denominator`, or a bare integer.
  ///
  /// Each side is a whole number with an optional sign, and whitespace around
  /// it is allowed — the same as [ShortDecimal.parse] allows. Hexadecimal is
  /// not a number here any more than it is there.
  ///
  /// Throws [FormatException] on failure, and `UnsupportedError` when the
  /// denominator is zero.
  ///
  /// ```dart
  /// print(ShortFraction.parse('3/4')); // 3/4
  /// print(ShortFraction.parse('5'));   // 5
  /// ```
  factory ShortFraction.parse(String str) {
    final fractionBar = str.indexOf('/');

    if (fractionBar == -1) {
      return ShortFraction._(_parseSide(str, str), 1);
    }

    return ShortFraction(
      _parseSide(str.substring(0, fractionBar), str),
      _parseSide(str.substring(fractionBar + 1), str),
    );
  }

  /// One side of a written ratio, [source] being the whole of it for the
  /// error message.
  static int _parseSide(String side, String source) {
    final digits = side.scanInteger();
    if (digits == null) {
      throw FormatException('Could not parse $ShortFraction: $source');
    }

    return int.parse(digits);
  }

  const ShortFraction._(this.numerator, this.denominator)
      : assert(denominator > 0, 'The denominator must be > 0');

  /// Whether this ratio is less than zero.
  bool get isNegative => numerator.isNegative;

  /// The sign: -1, 0 or 1.
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
  ///
  /// The sign of the divisor moves up to the numerator before the products are
  /// built, not after them: `2 / (-1/2^62)` is `int.min` exactly, and the
  /// unmoved sign made it `int.min` over minus one — a pair that has nowhere
  /// to put its sign, so an answer that fits was refused.
  ShortFraction operator /(ShortFraction other) {
    final left = numerator.fastGcd(other.numerator);
    final right = other.denominator.fastGcd(denominator);

    var upper = other.denominator ~/ right;
    var lower = other.numerator ~/ left;

    if (lower.isNegative) {
      final positive = ShortDecimal._negateOrNull(lower);
      // A divisor numerator of `int.min` does not come off the bottom, and
      // there the refusal is honest: the denominator would be 2^63 at least.
      if (positive != null) {
        lower = positive;
        // A denominator is positive, so this one always negates.
        upper = -upper;
      }
    }

    return ShortFraction(
      (numerator ~/ left) * upper,
      (denominator ~/ right) * lower,
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
  ///
  /// The denominator is positive on the way in — both fractions carry a
  /// positive one and the common denominator is their product — so there is no
  /// sign to normalize here.
  static ShortFraction? _fromBigOrNull(BigInt numerator, BigInt denominator) {
    assert(!denominator.isNegative, 'The denominator must be > 0');

    final gcd = numerator.fastGcd(denominator);
    final reducedNumerator = numerator ~/ gcd;
    final reducedDenominator = denominator ~/ gcd;

    return reducedNumerator.isValidInt && reducedDenominator.isValidInt
        ? ShortFraction._(reducedNumerator.toInt(), reducedDenominator.toInt())
        : null;
  }

  /// The absolute value of this fraction.
  ///
  /// Throws [ArgumentError] when the numerator is the minimum integer: its
  /// positive counterpart does not fit into int64.
  ShortFraction abs() {
    if (!numerator.isNegative) {
      return this;
    }

    final positive = ShortDecimal._negateOrNull(numerator);
    if (positive == null) {
      throw ArgumentError(
        'The absolute value of $this does not fit into int64',
      );
    }

    return ShortFraction._(positive, denominator);
  }

  /// One divided by this fraction.
  ///
  /// Throws [UnsupportedError] if this fraction is zero.
  ShortFraction get inverse => ShortFraction(denominator, numerator);

  /// Compares this to [other].
  ///
  /// Returns a negative number if this is less than other, zero if they are
  /// equal, and a positive number if this is greater than other.
  @override
  int compareTo(ShortFraction other) {
    final own = ShortDecimal._productOrNull(numerator, other.denominator);
    final theirs = ShortDecimal._productOrNull(other.numerator, denominator);

    if (own != null && theirs != null) {
      return own.compareTo(theirs).sign;
    }

    // The cross products do not fit; the comparison is exact anyway.
    return (BigInt.from(numerator) * BigInt.from(other.denominator))
        .compareTo(BigInt.from(other.numerator) * BigInt.from(denominator))
        .sign;
  }

  /// Converts this fraction to [double].
  ///
  /// Dividing one `int` by another rounds twice once either side is past
  /// 2^53: the operands lose their last bits on the way into `double`, and
  /// the division rounds again what is already wrong. Past that bound the
  /// exact path is taken — the same one `Fraction` uses.
  double toDouble() {
    const exact = ShortDecimal._maxExactInDouble;
    if (numerator >= -exact && numerator <= exact && denominator <= exact) {
      return numerator / denominator;
    }

    return BigInt.from(numerator).ratioToDouble(BigInt.from(denominator));
  }

  /// Converts this fraction to [ShortDecimal].
  ///
  /// Throws [ShortDecimalDivideException] if the value has no finite decimal
  /// form.
  ShortDecimal toShortDecimal() =>
      ShortDecimal(numerator) / ShortDecimal(denominator);

  /// Rounds the fraction towards negative infinity to [fractionDigits].
  ShortDecimal floor([int fractionDigits = 0]) =>
      _dropFraction(fractionDigits, _Rounding.floor);

  /// Rounds the fraction to the closest decimal with [fractionDigits].
  ShortDecimal round([int fractionDigits = 0]) =>
      _dropFraction(fractionDigits, _Rounding.round);

  /// Rounds the fraction to the closest decimal with [fractionDigits], halves
  /// to even.
  ShortDecimal roundToEven([int fractionDigits = 0]) =>
      _dropFraction(fractionDigits, _Rounding.roundToEven);

  /// Rounds the fraction towards infinity to [fractionDigits].
  ShortDecimal ceil([int fractionDigits = 0]) =>
      _dropFraction(fractionDigits, _Rounding.ceil);

  /// Rounds the fraction towards zero to [fractionDigits].
  ShortDecimal truncate([int fractionDigits = 0]) =>
      _dropFraction(fractionDigits, _Rounding.truncate);

  /// Rounds the fraction away from zero to [fractionDigits].
  ///
  /// The mirror of [truncate]: any remainder at all moves the last digit one
  /// step further from zero.
  ShortDecimal roundAwayFromZero([int fractionDigits = 0]) =>
      _dropFraction(fractionDigits, _Rounding.awayFromZero);

  /// Brings the fraction to [fractionDigits] digits by [rounding].
  ///
  /// A negative [fractionDigits] rounds to tens, hundreds and so on, the same
  /// as [ShortDecimal.floor] and its neighbours do; it scales the denominator
  /// instead of the numerator.
  ShortDecimal _dropFraction(int fractionDigits, _Rounding rounding) {
    ShortDecimal._checkDigits(fractionDigits, 'fractionDigits');

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
    final rest = denominator - remainder;
    final quotient = numerator ~/ denominator;

    return ShortDecimal._pack(
      quotient +
          rounding.correction(
            sign: numerator.sign,
            hasRemainder: remainder != 0,
            atLeastHalf: remainder >= rest,
            exactlyHalf: remainder == rest,
            quotientIsEven: quotient.isEven,
          ),
      fractionDigits,
    );
  }

  /// The same rounding for the case where int64 is not wide enough for it.
  ShortDecimal _dropFractionExactly(int fractionDigits, _Rounding rounding) =>
      _roundExactly(
        BigInt.from(numerator),
        BigInt.from(denominator),
        fractionDigits,
        rounding,
      );

  /// The rounding of [dividend] over [divisor] done in `BigInt`.
  ///
  /// This is the one place in the family that reaches for BigInt, and it is
  /// reached only when the int path would answer with a wrapped-around number.
  /// The alternative was the defect this replaces: a positive fraction coming
  /// back negative.
  ///
  /// When even the result does not fit — asking for more digits than int64
  /// holds — the closest representable value **in the direction asked for** is
  /// returned instead: the scale is reduced until the value fits, and every
  /// digit dropped on the way goes the way the caller wanted. Losing the last
  /// digits keeps the sign, the magnitude and the direction; wrapping around
  /// keeps none of the three.
  ///
  /// The pair need not be a fraction: [ShortDecimal.divide] rounds through
  /// here when the ratio has none in int64, and its divisor arrives with
  /// whatever sign it had. Bringing the denominator back to positive is
  /// exactly what int64 could not do and `BigInt` always can.
  static ShortDecimal _roundExactly(
    BigInt dividend,
    BigInt divisor,
    int fractionDigits,
    _Rounding rounding,
  ) {
    final power = ShortDecimal._bigInt10.pow(fractionDigits.abs());

    return _roundScaled(
      fractionDigits >= 0 ? dividend * power : dividend,
      fractionDigits >= 0 ? divisor : divisor * power,
      fractionDigits,
      rounding,
    );
  }

  /// The rounding of a pair already brought to a scale, done in `BigInt`.
  ///
  /// Split out of [_roundExactly] so that a caller holding the scales apart —
  /// [ShortDecimal.divide] does — can fold them into one power of ten instead
  /// of two. Aligning first and scaling after multiplies both sides by the
  /// scale of the operands, and the division then runs on numbers orders
  /// larger than the answer needs.
  /// The quotient of `numerator` over a positive `denominator`, rounded once.
  static BigInt _roundPair(
    BigInt numerator,
    BigInt denominator,
    _Rounding rounding,
  ) {
    final quotient = numerator ~/ denominator;
    final remainder = numerator.remainder(denominator).abs();
    final rest = denominator - remainder;

    return quotient +
        BigInt.from(
          rounding.correction(
            sign: numerator.sign,
            hasRemainder: remainder != BigInt.zero,
            atLeastHalf: remainder >= rest,
            exactlyHalf: remainder == rest,
            quotientIsEven: quotient.isEven,
          ),
        );
  }

  static ShortDecimal _roundScaled(
    BigInt numerator,
    BigInt denominator,
    int scale,
    _Rounding rounding,
  ) {
    final ten = ShortDecimal._bigInt10;

    if (denominator.isNegative) {
      numerator = -numerator;
      denominator = -denominator;
    }

    // Rounded from the pair every time, never from an already rounded number.
    // Dropping a digit off a rounded value rounds twice: .85365 becomes .85
    // and then .8, where .9 is the answer — the tail is gone by the second
    // step, and with it the only thing that could have decided. So a scale
    // that does not fit is taken off the divisor, and the division is done
    // again against the whole of the original remainder.
    var value = _roundPair(numerator, denominator, rounding);
    while (!value.isValidInt) {
      denominator *= ten;
      scale--;
      value = _roundPair(numerator, denominator, rounding);
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
  roundToEven,
  ceil,
  truncate,
  awayFromZero;

  /// What to add to the quotient: -1, 0 or 1.
  ///
  /// [exactlyHalf] and [quotientIsEven] matter to [roundToEven] alone: a half
  /// moves only when standing still would leave an odd number behind. The
  /// other four never ask, so they are given a default that costs the caller
  /// nothing to leave out.
  int correction({
    required int sign,
    required bool hasRemainder,
    required bool atLeastHalf,
    bool exactlyHalf = false,
    bool quotientIsEven = true,
  }) =>
      switch (this) {
        _Rounding.truncate => 0,
        _Rounding.floor => sign < 0 && hasRemainder ? -1 : 0,
        _Rounding.ceil => sign > 0 && hasRemainder ? 1 : 0,
        _Rounding.round => atLeastHalf ? sign : 0,
        _Rounding.roundToEven =>
          atLeastHalf && !(exactlyHalf && quotientIsEven) ? sign : 0,
        _Rounding.awayFromZero => hasRemainder ? sign : 0,
      };
}
