import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../fixed_point.dart';
import '../helpers.dart';

part 'division.dart';
part 'fraction.dart';

/// A decimal number with a fixed point and no limit on magnitude.
///
/// The value is kept as an unscaled [base] and a [scale] — `base × 10^-scale`
/// — and both are exact, so the arithmetic is exact too: `0.1 + 0.2` is `0.3`,
/// and a sum of money stays the sum it was.
///
/// ```dart
/// final price = Decimal.parse('19.99');
/// print(price * Decimal(3)); // 59.97
/// ```
///
/// [base] is a `BigInt`: nothing overflows, and there is no bound on the number
/// of digits. Where the values are known to be small, `ShortDecimal` does the
/// same on `int` and is several times faster.
///
/// Division is the one operation that cannot always answer — one third has no
/// finite decimal form. [divideOrNull] returns null there, [divide] rounds to
/// as many digits as it is told, [isDivisibleBy] asks the question in advance,
/// and [operator /] throws [DecimalDivideException].
///
/// One bound the type does have: the power of ten it will build. Past a
/// million, ten to that power is a number nobody can hold —
/// `round(-1000000000)` asks for ten to the billionth — and the package
/// refuses with `ArgumentError` instead of exhausting the memory. It refuses
/// where the request comes in and again where the power would be built, so a
/// scale driven that far by shifting is caught too. `Decimal.parse` refuses to
/// read such a number in the first place.
final class Decimal implements FixedPoint<Decimal> {
  static final _char0 = '0'.codeUnitAt(0);
  static final _charMinus = '-'.codeUnitAt(0);

  static final _bigInt5 = BigInt.from(5);
  static final _bigInt10 = BigInt.from(10);

  /// Powers of ten, kept between calls.
  ///
  /// `pow` shows up under `+`, `-`, `%`, `remainder`, `~/`, every comparison,
  /// `==`, `compareTo`, `Division` and `divideToFraction` — the hottest code
  /// in the package — and it built the same power again on every call. Adding
  /// two decimals of the same scale costs about a third of adding two of
  /// different scales; the rest went into `pow`.
  static final List<BigInt> _pow10Cache = <BigInt>[BigInt.one];

  /// Powers past this one are not kept: nobody asks for them twice.
  static const _pow10CacheLimit = 128;

  /// Powers of five, kept the same way [_pow10Cache] keeps powers of ten.
  ///
  /// Dividing by `2^n` is multiplying by `5^n` with the scale moved by `n`.
  static final List<BigInt> _pow5Cache = <BigInt>[BigInt.one];

  /// Five to the power of [exponent].
  static BigInt _pow5(int exponent) {
    assert(exponent >= 0, "exponent can't be negative");

    if (exponent >= _pow10CacheLimit) {
      return _bigInt5.pow(exponent);
    }

    for (var i = _pow5Cache.length; i <= exponent; i++) {
      _pow5Cache.add(_pow5Cache[i - 1] * _bigInt5);
    }

    return _pow5Cache[exponent];
  }

  /// Ten to the power of [exponent].
  ///
  /// Every power of ten in this family is built here, so this is the last line
  /// before an absurd one is attempted — and the only place that sees all of
  /// them at once, whether the exponent came from a number of digits, from a
  /// scale or from the gap between two scales. Past [maxDecimalExponent] it
  /// refuses: ten to the billionth is four hundred megabytes, and an
  /// `ArgumentError` is a better answer than the death of the process.
  static BigInt _pow10(int exponent) {
    assert(exponent >= 0, "exponent can't be negative");

    if (exponent >= _pow10CacheLimit) {
      // On the rare road only: the cached powers are the hot ones, and they
      // are all far below the bound.
      if (exponent > maxDecimalExponent) {
        throw ArgumentError.value(
          exponent,
          'exponent',
          'Ten to this power is a number too large to build',
        );
      }

      return _bigInt10.pow(exponent);
    }

    for (var i = _pow10Cache.length; i <= exponent; i++) {
      _pow10Cache.add(_pow10Cache[i - 1] * _bigInt10);
    }

    return _pow10Cache[exponent];
  }

  /// A decimal with the numerical value 0.
  static final Decimal zero = Decimal.fromBigInt(BigInt.zero);

  /// A decimal with the numerical value 1.
  static final Decimal one = Decimal.fromBigInt(BigInt.one);

  /// A decimal with the numerical value 2.
  static final Decimal two = Decimal.fromBigInt(BigInt.two);

  /// A decimal with the numerical value 10.
  static final Decimal ten = Decimal.fromBigInt(_bigInt10);

  /// The unscaled value: the number is `base × 10^-scale`.
  ///
  /// Visible for testing because the tests check the stored form, not because
  /// the pair is a promise: one value has more than one form, and which one is
  /// on hand is an artefact of the last operation. Compare decimals by value,
  /// never by this pair.
  @visibleForTesting
  final BigInt base;

  /// The power of ten the [base] is divided by.
  ///
  /// A negative scale is a working mode and not an error: `1e21` is a base of
  /// one at a scale of minus twenty-one, and nothing is lost that way.
  @visibleForTesting
  final int scale;

  /// It's to maximize performance.
  ///
  /// The Decimal class can never be constant, since BigInt is not constant.
  /// So we use the trick of preserving the intermediate optimal result.
  Decimal? _packed;

  /// The printed form, kept for the next call.
  ///
  /// One and the same decimal is printed again and again — a Flutter widget
  /// rebuilds dozens of times a second — and every call redid `BigInt`
  /// arithmetic, the loop that strips zeros and several substrings. The
  /// competitor keeps its normalized form and beat us on the repeat by up to
  /// two and a half times; the first call we win by two to five, and that is
  /// the call the string stripping was written for.
  String? _text;

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
  factory Decimal(int base, {int shiftRight = 0}) =>
      Decimal.fromBigInt(BigInt.from(base), shiftRight: shiftRight);

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
  factory Decimal.fromBigInt(BigInt base, {int shiftRight = 0}) {
    // Not an assert: the two of them would part ways in release, where the
    // check is gone and a negative shift quietly multiplies instead.
    _checkNonNegativeArgument(shiftRight, 'shiftRight');

    return Decimal._asIs(base, shiftRight);
  }

  /// Parse the [string] to [Decimal].
  ///
  /// Throw [FormatException] on failure.
  factory Decimal.parse(String string) =>
      tryParse(string) ??
      (throw FormatException('Could not parse $Decimal: $string'));

  /// Reads a decimal from its [toJson] form.
  ///
  /// Throw [FormatException] on failure.
  factory Decimal.fromJson(String json) => Decimal.parse(json);

  Decimal._asIs(this.base, this.scale);

  /// Parse the [string] to [Decimal].
  ///
  /// Accepts an optional sign, an optional exponent and surrounding
  /// whitespace: `'1'`, `'-0.5'`, `'.5'`, `'+1e21'`. Returns null on anything
  /// else — hexadecimal included, which [BigInt.parse] would have accepted.
  ///
  /// An exponent past a million is refused as well. The scale itself holds
  /// far more, but the number such a string asks for could not be printed
  /// back: a million digits is a megabyte of text, and a billion of them takes
  /// the stack down inside [BigInt.parse] on the way there.
  ///
  /// ```dart
  /// Decimal.tryParse('1e21'); // 1000000000000000000000
  /// Decimal.tryParse('0x10'); // null
  /// ```
  static Decimal? tryParse(String string) {
    final scanned = string.scanDecimal();
    if (scanned == null) {
      return null;
    }

    final (digits, scale) = scanned;

    return Decimal._asIs(BigInt.parse(digits), scale);
  }

  /// Returns number of digits after the decimal point.
  @override
  int get fractionDigits => scale <= 0 ? 0 : math.max(_requirePacked.scale, 0);

  /// The whole number the value is stored as, in canonical form.
  ///
  /// The number is `unscaledValue × 10^exponent`. Both come from the canonical
  /// form rather than from the pair actually stored, so equal decimals answer
  /// equally whatever operation produced them:
  ///
  /// ```dart
  /// final a = Decimal.parse('1.50');
  /// final b = Decimal.parse('1.5');
  /// print(a.unscaledValue); // 15
  /// print(a.exponent); // -1
  /// print(a.unscaledValue == b.unscaledValue); // true
  /// ```
  BigInt get unscaledValue => _requirePacked.base;

  /// The power of ten [unscaledValue] is multiplied by.
  @override
  int get exponent => -_requirePacked.scale;

  /// Returns the sign of this decimal.
  ///
  /// Returns 0 for zero, -1 for values less than zero and +1 for values
  /// greater than zero.
  @override
  int get sign => base.sign;

  /// Whether this decimal is negative.
  @override
  bool get isNegative => base.isNegative;

  /// Whether this decimal is an integer.
  @override
  bool get isInteger => scale <= 0 || _requirePacked.scale <= 0;

  /// Whether this decimal is zero.
  @override
  bool get isZero => base == BigInt.zero;

  /// Returns the negative value of this decimal.
  @override
  Decimal operator -() => Decimal._asIs(-base, scale);

  /// Adds [other] to this decimal.
  @override
  //
  // The alignment is written out here rather than taken from `_align`: the
  // record that method returns is an allocation, and on the shortest operation
  // in the package it showed — two nanoseconds of the twenty-six an addition
  // costs. The same reason keeps the overflow check inside `ShortDecimal`'s
  // multiplication.
  Decimal operator +(Decimal other) {
    final as = scale;
    final bs = other.scale;

    if (as == bs) {
      return Decimal._asIs(base + other.base, as);
    }

    return as > bs
        ? Decimal._asIs(base + other.base * _pow10(as - bs), as)
        : Decimal._asIs(base * _pow10(bs - as) + other.base, bs);
  }

  /// Subtracts [other] from this decimal.
  @override
  Decimal operator -(Decimal other) {
    final as = scale;
    final bs = other.scale;

    if (as == bs) {
      return Decimal._asIs(base - other.base, as);
    }

    return as > bs
        ? Decimal._asIs(base - other.base * _pow10(as - bs), as)
        : Decimal._asIs(base * _pow10(bs - as) - other.base, bs);
  }

  /// Multiplies this decimal by [other].
  @override
  Decimal operator *(Decimal other) =>
      Decimal._asIs(base * other.base, scale + other.scale);

  /// Divides this decimal by [other].
  ///
  /// Throws [UnsupportedError] if [other] is zero and
  /// [DecimalDivideException] if the result cannot be written down as a
  /// decimal with a finite number of digits. [divideOrNull] and [divide]
  /// answer the same question without an exception.
  @override
  Decimal operator /(Decimal other) =>
      divideOrNull(other) ?? (throw DecimalDivideException._(this, other));

  /// Divides this decimal by [other], or returns null.
  ///
  /// Null means the result has no finite decimal form — one divided by three.
  /// Dividing by zero still throws [UnsupportedError]: that is not a result
  /// nobody can write down, that is a question nobody can answer.
  ///
  /// Reading a null is about five times cheaper than catching the exception:
  /// the throw costs the better part of a microsecond by itself, several times
  /// the division it reports on. This is the form to reach for when the divisor
  /// is not known in advance.
  ///
  /// ```dart
  /// print(Decimal(1).divideOrNull(Decimal(4))); // 0.25
  /// print(Decimal(1).divideOrNull(Decimal(3))); // null
  /// ```
  @override
  Decimal? divideOrNull(Decimal other) {
    var divisor = other.base;

    if (divisor == BigInt.zero) {
      throw UnsupportedError('division by zero');
    }

    var base = this.base;
    // Checked like the shifts are: an unchecked difference wraps into the
    // opposite sign, and what comes out of it is not the quotient by any
    // reading. Written out rather than called: the check is two operations,
    // and a call around them is not inlined — the same reason the overflow
    // check sits inside `operator *`.
    final otherScale = other.scale;
    var scale = this.scale - otherScale;
    if ((this.scale ^ otherScale) < 0 && (scale ^ this.scale) < 0) {
      // The stored scales overflowed, which says nothing about the values:
      // this family normalises lazily, so the same number can be held as
      // `100 × 10^-n` or as `1 × 10^-(n-2)`, and only the second one divides.
      // Equal values must answer equally, so the canonical forms decide.
      final dividend = normalized();
      final divisor = other.normalized();
      if (dividend.scale == this.scale && divisor.scale == otherScale) {
        throw ArgumentError.value(otherScale, 'other', _scaleOutOfRange);
      }

      return dividend.divideOrNull(divisor);
    }

    // The sign is taken out of the divisor before the factorization below.
    // A remainder is never negative in Dart, so a negative divisor never comes
    // down to one, and a result that is perfectly representable would be
    // rejected.
    //
    // The result is negated at the end rather than the dividend here: for
    // ShortDecimal that is the difference between the canonical value and a
    // silent overflow on the minimum integer, and the two families keep the
    // same shape.
    final negate = divisor.isNegative;
    if (negate) {
      divisor = -divisor;
    }

    // Dividing by one, and dividing without a remainder, are the two common
    // cases and neither needs a factorization.
    if (divisor == BigInt.one) {
      return Decimal._asIs(negate ? -base : base, scale);
    }

    if (base.remainder(divisor) == BigInt.zero) {
      final quotient = base ~/ divisor;

      return Decimal._asIs(negate ? -quotient : quotient, scale);
    }

    // A divisor holding neither a two nor a five is the whole question, and
    // the remainder above has just answered it: what such a divisor does not
    // divide has no finite decimal form, and no common factor can change
    // that. Every third division of money lands here, and the factorization
    // below would spend a gcd to arrive at the same nothing.
    if (_coprimeWithTen(divisor)) {
      return null;
    }

    final gcd = base.fastGcd(divisor);
    if (gcd != BigInt.one) {
      base ~/= gcd;
      divisor ~/= gcd;
    }

    if (divisor != BigInt.one) {
      // Every ten in the divisor is a shift of the scale and nothing more, and
      // they come off together rather than one digit at a time: a divisor of
      // 10^6 took twenty-four BigInt operations here.
      // Each of the three steps below raises the scale, and at the ceiling of
      // int64 that rise wraps — the quotient came back with the opposite order
      // of magnitude and no word said. Where it would wrap there is no answer
      // in this form, and null is what this method has for that.
      if (divisor.isEven) {
        final (rest, zeros) = _splitTrailingZeros(divisor);
        if (scale > _maxScale - zeros) {
          return null;
        }

        divisor = rest;
        scale += zeros;
      }

      // What is left is either odd or free of fives, so only one of the two
      // steps below does anything. Both take the whole power at once.
      if (divisor.isEven) {
        // The lowest set bit is the power of two the divisor holds.
        final twos = (divisor & -divisor).bitLength - 1;
        if (scale > _maxScale - twos) {
          return null;
        }

        base *= _pow5(twos);
        scale += twos;
        divisor = divisor >> twos;
      } else if (divisor % _bigInt5 == BigInt.zero) {
        var fives = 0;
        do {
          divisor = divisor ~/ _bigInt5;
          fives++;
        } while (divisor % _bigInt5 == BigInt.zero);

        if (scale > _maxScale - fives) {
          return null;
        }

        base <<= fives;
        scale += fives;
      }

      if (divisor != BigInt.one) {
        return null;
      }
    }

    return Decimal._asIs(negate ? -base : base, scale);
  }

  /// Divides this decimal by [other], rounding what cannot be written down.
  ///
  /// A result with no finite decimal form is rounded to
  /// [scaleOnInfinitePrecision] digits; without that argument it throws
  /// [DecimalDivideException], the same as [operator /].
  ///
  /// ```dart
  /// print(Decimal(1).divide(Decimal(3), scaleOnInfinitePrecision: 4)); // 0.3333
  /// ```
  @override
  Decimal divide(Decimal other, {int? scaleOnInfinitePrecision}) {
    // Where the divisor is coprime with ten, the rounding below answers both
    // questions with one division. No power of ten can carry a numerator into
    // such a divisor, so a remainder here is proof that there is no finite
    // decimal form to return instead — and asking [divideOrNull] first would
    // spend a second division to hear the same thing. On money divided by
    // three that question was half the cost of the answer.
    //
    // An even division falls through: the exact result is [divideOrNull]'s to
    // give, and it keeps the scale this one would have padded out.
    //
    // Out of bounds the fast path steps aside rather than throwing, so that
    // the error still comes from where it came before, naming the argument.
    //
    // Both scales are held to the same bound, and not out of caution about
    // the answer: the exponent below is a sum of three integers, and at the
    // edge of int64 that sum wraps. A wrapped exponent can land inside the
    // window and take the division to a quietly wrong answer. Three numbers
    // under a million cannot wrap; past it this path steps aside anyway.
    if (scaleOnInfinitePrecision != null &&
        scaleOnInfinitePrecision >= -maxDecimalExponent &&
        scaleOnInfinitePrecision <= maxDecimalExponent &&
        scale >= -maxDecimalExponent &&
        scale <= maxDecimalExponent &&
        other.scale >= -maxDecimalExponent &&
        other.scale <= maxDecimalExponent &&
        _coprimeWithTen(other.base)) {
      final exponent = scaleOnInfinitePrecision - scale + other.scale;
      if (exponent > 0 && exponent <= maxDecimalExponent) {
        final (rounded, isExact) =
            _roundedQuotientAndExactness(other, scaleOnInfinitePrecision);
        if (!isExact) {
          return rounded;
        }
      }
    }

    final result = divideOrNull(other);
    if (result != null) {
      return result;
    }

    if (scaleOnInfinitePrecision == null) {
      throw DecimalDivideException._(this, other);
    }

    return _roundedQuotient(other, scaleOnInfinitePrecision);
  }

  /// Whether [divisor] holds neither a two nor a five.
  ///
  /// Such a divisor is coprime with ten, and that is what makes a remainder
  /// decisive: no power of ten can carry a numerator into it, so what the
  /// divisor does not divide now it will not divide after any shift.
  ///
  /// The test goes through `int` where the divisor fits in one, which is the
  /// usual case and forty times cheaper than the same question asked of a
  /// `BigInt`.
  static bool _coprimeWithTen(BigInt divisor) {
    if (divisor.isValidInt) {
      final small = divisor.toInt();

      return small.isOdd && small % 5 != 0;
    }

    return !divisor.isEven && divisor % _bigInt5 != BigInt.zero;
  }

  /// The quotient rounded to [fractionDigits], halves away from zero.
  ///
  /// The answer [divideToFraction] and [Fraction.round] give together, without
  /// building the fraction. Reducing a ratio by its greatest common divisor
  /// changes neither the quotient nor the decision to round up: if
  /// `a·10^n = q·b + r`, then dividing both sides by `g` gives
  /// `(a/g)·10^n = q·(b/g) + r/g`, where `r/g` is a whole number below `b/g` —
  /// the quotient is the same `q`, and `2r ≥ b` holds exactly when
  /// `2(r/g) ≥ b/g` does. So the reduction is work the answer does not need,
  /// and it is not cheap: a `gcd` of two sixty-digit numbers costs more than
  /// the division it makes shorter. Measured at 1.7 times faster on money and
  /// 3.8 on long operands sharing a large factor.
  ///
  /// `ShortDecimal` keeps the fraction here on purpose: there the reduction is
  /// what holds the numbers inside int64, and dropping it would send the
  /// rounding to the exact BigInt path far more often.
  Decimal _roundedQuotient(Decimal other, int fractionDigits) {
    _checkDigits(fractionDigits, 'scaleOnInfinitePrecision');
    final (result, _) = _roundedQuotientAndExactness(other, fractionDigits);

    return result;
  }

  /// The rounded quotient, and whether the division came out even.
  ///
  /// The remainder is wanted twice over: it decides the rounding, and where
  /// the divisor is coprime with ten it also decides whether there was
  /// anything to round at all.
  (Decimal, bool) _roundedQuotientAndExactness(
    Decimal other,
    int fractionDigits,
  ) {
    var numerator = base;
    var denominator = other.base;

    // Bringing the two scales together and shifting to the target one are a
    // single power of ten, taken on whichever side keeps it a multiplication.
    final exponent = fractionDigits - scale + other.scale;
    if (exponent > 0) {
      numerator *= _pow10(exponent);
    } else if (exponent < 0) {
      denominator *= _pow10(-exponent);
    }

    // The sign lives in the numerator, as it does in a fraction: the
    // comparison below reads the divisor as a magnitude.
    if (denominator.isNegative) {
      numerator = -numerator;
      denominator = -denominator;
    }

    final quotient = numerator ~/ denominator;
    final remainder = numerator.remainder(denominator).abs();

    return (
      Decimal._asIs(
        remainder >= denominator - remainder
            ? quotient + BigInt.from(numerator.sign)
            : quotient,
        fractionDigits,
      ),
      remainder == BigInt.zero,
    );
  }

  /// Whether dividing by [other] has a finite decimal form.
  ///
  /// In other words, whether [operator /] returns instead of throwing. This is
  /// not a question about a whole quotient: three divided by two is divisible
  /// in this sense, because 1.5 can be written down.
  ///
  /// Throws [UnsupportedError] if [other] is zero.
  @override
  bool isDivisibleBy(Decimal other) => divideOrNull(other) != null;

  /// Performs truncating division of this decimal by [other].
  ///
  /// Truncating division is division where a fractional result is converted to
  /// an integer by rounding towards zero.
  ///
  /// Throws [UnsupportedError] if [other] is zero, the same as every other
  /// division here does.
  BigInt operator ~/(Decimal other) {
    if (other.isZero) {
      throw UnsupportedError('division by zero');
    }

    final (a, b, _) = _align(other);

    return a ~/ b;
  }

  /// Calculates the result of division as double.
  @override
  double divideToDouble(Decimal other) {
    final fraction = divideToFraction(other);
    final result = _ratioToDouble(fraction.numerator, fraction.denominator);

    // Zero keeps the sign the division gave it, as it does in plain Dart and
    // as the int64 family already did: the fraction cannot carry it, because a
    // reduced `0/-5` is `0/1` and the minus is gone by then.
    return result == 0 && isZero && other.isNegative ? -result : result;
  }

  /// The value of `numerator / denominator` as a [double].
  ///
  /// `BigInt.operator /` is `toDouble() / other.toDouble()`, so once both ends
  /// pass `double.maxFinite` it computes `Infinity / Infinity` and answers NaN
  /// for a ratio that is perfectly ordinary. Numbers of high precision reach
  /// that point easily: aligning the scales grows both ends at once.
  static double _ratioToDouble(BigInt numerator, BigInt denominator) =>
      numerator.ratioToDouble(denominator);

  /// Calculates the result of division as fraction.
  Fraction divideToFraction(Decimal other) {
    final (dividend, divisor, _) = _align(other);

    return Fraction(dividend, divisor);
  }

  /// Calculates the result of division as an integer quotient and remainder.
  Division divideWithRemainder(Decimal other) => Division(this, other);

  /// Euclidean modulo of this number by [other].
  ///
  /// The returned value is never negative — zero, being neither, included.
  ///
  /// Throws [UnsupportedError] if [other] is zero.
  @override
  Decimal operator %(Decimal other) {
    if (other.isZero) {
      throw UnsupportedError('division by zero');
    }

    final (a, b, scale) = _align(other);

    return Decimal._asIs(a % b, scale);
  }

  /// The remainder of the truncating division of this by [other].
  ///
  /// The result r of this operation satisfies:
  /// this == (this ~/ other) * other + r. As a consequence, the remainder r
  /// has the same sign as the dividend this.
  ///
  /// Throws [UnsupportedError] if [other] is zero.
  @override
  Decimal remainder(Decimal other) {
    if (other.isZero) {
      throw UnsupportedError('division by zero');
    }

    final (a, b, scale) = _align(other);

    return Decimal._asIs(a.remainder(b), scale);
  }

  /// Whether this decimal is smaller than [other].
  @override
  bool operator <(Decimal other) {
    final (a, b, _) = _align(other);

    return a < b;
  }

  /// Whether this decimal is smaller than or equal to [other].
  @override
  bool operator <=(Decimal other) {
    final (a, b, _) = _align(other);

    return a <= b;
  }

  /// Whether this decimal is greater than [other].
  @override
  bool operator >(Decimal other) {
    final (a, b, _) = _align(other);

    return a > b;
  }

  /// Whether this decimal is greater than or equal to [other].
  @override
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
  @override
  Decimal operator <<(int shiftAmount) =>
      Decimal._asIs(base, _scaleMinus(scale, shiftAmount, 'shiftAmount'));

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
  @override
  Decimal operator >>(int shiftAmount) =>
      Decimal._asIs(base, _scalePlus(scale, shiftAmount, 'shiftAmount'));

  /// This decimal in its canonical form.
  ///
  /// The value does not change; the stored form loses the trailing zeros it
  /// may have picked up. This family normalises lazily, so here is where that
  /// work happens — and the result is kept for the next caller.
  ///
  /// ```dart
  /// print((Decimal(150) >> 2).normalized() == Decimal.parse('1.5')); // true
  /// ```
  @override
  Decimal normalized() => _requirePacked;

  /// This decimal divided by `10^places`: the point moves left.
  ///
  /// The readable name of [operator >>].
  ///
  /// ```dart
  /// print(Decimal(100).movePointLeft(2)); // 1
  /// ```
  @override
  Decimal movePointLeft(int places) => this >> places;

  /// This decimal multiplied by `10^places`: the point moves right.
  ///
  /// The readable name of [operator <<].
  ///
  /// ```dart
  /// print(Decimal(1).movePointRight(2)); // 100
  /// ```
  @override
  Decimal movePointRight(int places) => this << places;

  /// Returns the absolute value of this decimal.
  @override
  Decimal abs() => base.isNegative ? Decimal._asIs(-base, scale) : this;

  /// Rounds the decimal towards negative infinity to [fractionDigits].
  @override
  Decimal floor([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) => isNegative && base % divisor != BigInt.zero
            ? result - BigInt.one
            : result,
      );

  /// Rounds to the closest decimal with [fractionDigits].
  @override
  Decimal round([int fractionDigits = 0]) =>
      _dropFraction(fractionDigits, (result, divisor) {
        final remainder = base.remainder(divisor).abs();
        return remainder >= divisor - remainder
            ? result + BigInt.from(base.sign)
            : result;
      });

  /// Rounds to the closest decimal with [fractionDigits], halves to even.
  ///
  /// Where [round] sends a half away from zero — 2.5 to 3, 3.5 to 4 — this one
  /// sends it to the even neighbour: 2.5 to 2, 3.5 to 4. Halves then stop
  /// pulling a long column of numbers the same way every time, which is why
  /// accounting asks for this rule and why it is the default one in General
  /// Decimal Arithmetic.
  ///
  /// ```dart
  /// print(Decimal.parse('2.5').roundToEven()); // 2
  /// print(Decimal.parse('3.5').roundToEven()); // 4
  /// print(Decimal.parse('2.675').roundToEven(2)); // 2.68
  /// ```
  @override
  Decimal roundToEven([int fractionDigits = 0]) =>
      _dropFraction(fractionDigits, (result, divisor) {
        final remainder = base.remainder(divisor).abs();
        final rest = divisor - remainder;

        // Below a half it stays, above a half it moves, and exactly a half
        // moves only when staying would leave an odd number behind.
        if (remainder < rest || (remainder == rest && result.isEven)) {
          return result;
        }

        return result + BigInt.from(base.sign);
      });

  /// Rounds the decimal towards infinity to [fractionDigits].
  @override
  Decimal ceil([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) => !isNegative && base % divisor != BigInt.zero
            ? result + BigInt.one
            : result,
      );

  /// Rounds the decimal towards zero to [fractionDigits].
  @override
  Decimal truncate([int fractionDigits = 0]) =>
      _dropFraction(fractionDigits, (result, divisor) => result);

  /// Returns this decimal clamped to be in the range [lowerLimit]-[upperLimit].
  ///
  /// The arguments [lowerLimit] and [upperLimit] must form a valid range where
  /// lowerLimit <= upperLimit.
  @override
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
  ///
  /// A negative [exponent] is one over the positive power, so it throws what
  /// division throws: [DecimalDivideException] when the result has no finite
  /// decimal form, [UnsupportedError] on zero.
  ///
  /// ```dart
  /// print(Decimal(2).pow(-2)); // 0.25
  /// ```
  @override
  Decimal pow(int exponent) {
    if (exponent >= 0) {
      // From the canonical form, so that equal values answer equally: ten held
      // as `10 × 10^0` needs a power of ten the bound refuses, while the same
      // ten held as `1 × 10^1` needs none. The packing is free where the form
      // is canonical already.
      final it = _requirePacked;

      return Decimal._asIs(
        it.base.pow(exponent),
        _scaleTimes(it.scale, exponent, 'exponent'),
      );
    }

    // The minimum integer has no positive counterpart to raise to.
    if (exponent == -exponent) {
      throw ArgumentError.value(exponent, 'exponent', 'The value is too small');
    }

    return one / pow(-exponent);
  }

  /// The number of digits this decimal is written with, sign and point aside.
  ///
  /// Not the digit count of [unscaledValue], which is a different number: a
  /// thousand is written with four digits and its unscaled value is one. Zero
  /// has a precision of one, the same as `decimal` reports.
  ///
  /// ```dart
  /// print(Decimal.parse('0').precision); // 1
  /// print(Decimal.parse('1.5').precision); // 2
  /// print(Decimal.parse('0.05').precision); // 3
  /// ```
  @override
  int get precision {
    final integer = toBigInt().toString();

    return fractionDigits +
        (integer.codeUnitAt(0) == _charMinus
            ? integer.length - 1
            : integer.length);
  }

  /// Whether this decimal is greater than zero.
  ///
  /// Zero is neither positive nor [isNegative].
  @override
  bool get isPositive => base.sign > 0;

  /// One divided by this decimal, as an exact [Fraction].
  ///
  /// A fraction rather than a decimal because the inverse of three has no
  /// finite decimal form.
  ///
  /// Throws [UnsupportedError] if this decimal is zero.
  Fraction get inverse => scale >= 0
      ? Fraction(_pow10(scale), base)
      : Fraction(BigInt.one, base * _pow10(-scale));

  /// A JSON representation of this decimal: the string [toString] returns.
  @override
  String toJson() => toString();

  /// Returns [int], discarding all fractional digits from this decimal.
  ///
  /// A value that does not fit is truncated to 64 bits, exactly as
  /// [BigInt.toInt] does; [toBigInt] keeps it whole.
  @override
  int toInt() => toBigInt().toInt();

  /// Returns [BigInt], discarding all fractional digits from this decimal.
  @override
  BigInt toBigInt() {
    final truncated = truncate();
    final scale = truncated.scale;

    // The scale is never positive after truncate. A negative one is a shift to
    // the left and has to be materialized, exactly as ShortDecimal.toInt does:
    // the base alone is not the value.
    return scale < 0 ? truncated.base * _pow10(-scale) : truncated.base;
  }

  /// Converts this decimal to [double].
  @override
  double toDouble() {
    final base = this.base;
    final scale = this.scale;

    // Both ends of the division are exact in a double when the base fits into
    // 53 bits and the power of ten into 10^22, so the single rounding of the
    // division is the correctly rounded answer. Outside that the string is the
    // only honest path: it rounds once too, where an inexact division would
    // round twice.
    if (scale >= -_maxExactPow10 &&
        scale <= _maxExactPow10 &&
        base.abs().bitLength <= _exactBits) {
      final value = base.toDouble();
      final power = _doublePow10[scale.abs()];

      return scale >= 0 ? value / power : value * power;
    }

    return double.parse(toString());
  }

  /// How many bits of an integer a double keeps exactly.
  static const _exactBits = 53;

  /// The largest power of ten a double holds exactly.
  static const _maxExactPow10 = 22;

  /// Powers of ten that a double holds exactly.
  static final List<double> _doublePow10 = () {
    final table = List<double>.filled(_maxExactPow10 + 1, 1);
    for (var i = 1; i < table.length; i++) {
      table[i] = table[i - 1] * 10;
    }

    return table;
  }();

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

  /// The stored form, for a failing test to print.
  ///
  /// Not for production: one value has more than one stored form, and this is
  /// the only place in the package that shows which one is on hand.
  @visibleForTesting
  String debugToString() => '$Decimal(base: $base, scale: $scale)';

  /// Returns a string representation of this decimal.
  @override
  String toString() => _text ??= _print();

  String _print() {
    final packed = _packed;
    final it = packed ?? this;

    final base = it.base;
    var scale = it.scale;
    if (scale == 0 || base == BigInt.zero) {
      return base.toString();
    }

    final sign = base.isNegative ? '-' : '';
    var abs = base.abs().toString();

    // Remove trailing zeros.
    if (packed == null && scale > 0) {
      var last = abs.length - 1;
      if (abs.codeUnitAt(last) == _char0) {
        do {
          scale--;
          last--;
        } while (scale > 0 && abs.codeUnitAt(last) == _char0);
        abs = abs.substring(0, last + 1);
      }

      if (scale == 0) {
        return '$sign$abs';
      }
    }

    if (scale < 0) {
      return '$sign$abs${'0' * -scale}';
    }

    if (abs.length <= scale) {
      return '${sign}0.${abs.padLeft(scale, '0')}';
    }

    return '$sign${abs.substring(0, abs.length - scale)}'
        '.${abs.substring(abs.length - scale)}';
  }

  /// Returns a string representation of this decimal with exactly
  /// [fractionDigits] digits after the point.
  ///
  /// Asking for more digits than the value carries pads it with zeros; asking
  /// for fewer rounds it, halves away from zero, the same as [round] does.
  @override
  String toStringAsFixed(int fractionDigits) {
    _checkNonNegativeArgument(fractionDigits, 'fractionDigits');
    _checkDigits(fractionDigits, 'fractionDigits');

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
      return '${sign}0.'
          '${number.padLeft(scale, '0').padRight(fractionDigits, '0')}';
    }

    final (integer, fractional) = number.splitByIndex(number.length - scale);

    return '$sign$integer.${fractional.padRight(fractionDigits, '0')}';
  }

  /// An exponential representation of this decimal with [fractionDigits]
  /// digits after the decimal point.
  ///
  /// ```dart
  /// print(Decimal.parse('1234.5').toStringAsExponential(2)); // 1.23e+3
  /// print(Decimal.parse('0.00123').toStringAsExponential(1)); // 1.2e-3
  /// ```
  @override
  String toStringAsExponential([int fractionDigits = 0]) {
    _checkNonNegativeArgument(fractionDigits, 'fractionDigits');
    _checkDigits(fractionDigits, 'fractionDigits');

    if (isZero) {
      return '${zero.toStringAsFixed(fractionDigits)}e+0';
    }

    // The leading digit sits at this power of ten.
    var exponent = _digits.length - 1 - scale;
    var value = round(fractionDigits - exponent);

    // Rounding can carry into a new power of ten: 9.99 with one digit after
    // the point is 10.0, which is 1.0e+1 and not 10.0e+0.
    if (value._digits.length - 1 - value.scale > exponent) {
      exponent++;
      value = round(fractionDigits - exponent);
    }

    final digits = value._digits;
    final mantissa = fractionDigits == 0
        ? digits.substring(0, 1)
        : '${digits.substring(0, 1)}.'
            '${digits.substring(1).padRight(fractionDigits, '0')}';

    return '${isNegative ? '-' : ''}$mantissa'
        'e${exponent.isNegative ? '' : '+'}$exponent';
  }

  /// A representation of this decimal with [precision] significant digits.
  ///
  /// ```dart
  /// print(Decimal.parse('1234.5678').toStringAsPrecision(6)); // 1234.57
  /// print(Decimal.parse('0.05').toStringAsPrecision(3)); // 0.0500
  /// ```
  @override
  String toStringAsPrecision(int precision) {
    if (precision <= 0) {
      throw ArgumentError.value(
        precision,
        'precision',
        'The value must be > 0',
      );
    }
    _checkDigits(precision, 'precision');

    if (isZero) {
      return precision == 1 ? '0' : '0.${'0' * (precision - 1)}';
    }

    var exponent = _digits.length - 1 - scale;
    var fractionDigits = precision - 1 - exponent;
    var value = round(fractionDigits);

    // The same carry as in toStringAsExponential: 9.99 at two digits is 10,
    // which needs one integer digit more and one fractional digit less.
    if (value._digits.length - 1 - value.scale > exponent) {
      exponent++;
      fractionDigits = precision - 1 - exponent;
      value = round(fractionDigits);
    }

    return fractionDigits <= 0
        ? value.toString()
        : value.toStringAsFixed(fractionDigits);
  }

  /// The digits of the base, without a sign.
  ///
  /// Taken from the text rather than from `abs()`: the minimum integer has no
  /// positive counterpart.
  String get _digits {
    final text = base.toString();

    return text.codeUnitAt(0) == _charMinus ? text.substring(1) : text;
  }

  static void _checkNonNegativeArgument(int value, String name) {
    if (value < 0) {
      throw ArgumentError.value(value, name, 'The value must be >= 0');
    }
  }

  /// Refuses a number of digits the package would not be able to answer with.
  ///
  /// Beyond [maxDecimalExponent] the power of ten this would need is a number
  /// nobody can hold: `round(-1000000000)` went looking for ten to the
  /// billionth and took the memory of the process with it. The same bound
  /// stops a string of that size from being read in, so nothing this package
  /// produced can need one.
  static void _checkDigits(int value, String name) {
    if (value < -maxDecimalExponent || value > maxDecimalExponent) {
      throw ArgumentError.value(
        value,
        name,
        'The number of digits must be within a million of zero',
      );
    }
  }

  /// The scale moved by [by], refusing to wrap around.
  ///
  /// The scale is the one number in this class that cannot grow to fit: it is
  /// a plain int while everything else is a `BigInt`. A shift that would take
  /// it out of int64 is an error rather than a value that came back with the
  /// wrong sign — `Decimal.parse('0.01').pow(int.max)` used to print `100`.
  static int _scalePlus(int scale, int by, String name) {
    final result = scale + by;
    if ((scale ^ by) >= 0 && (result ^ scale) < 0) {
      throw ArgumentError.value(by, name, _scaleOutOfRange);
    }

    return result;
  }

  /// The scale moved the other way, with the same refusal.
  static int _scaleMinus(int scale, int by, String name) {
    final result = scale - by;
    if ((scale ^ by) < 0 && (result ^ scale) < 0) {
      throw ArgumentError.value(by, name, _scaleOutOfRange);
    }

    return result;
  }

  /// The scale repeated [by] times, with the same refusal.
  static int _scaleTimes(int scale, int by, String name) {
    if (scale == 0 || by == 0) {
      return 0;
    }

    final result = scale * by;
    if (result ~/ by != scale) {
      throw ArgumentError.value(by, name, _scaleOutOfRange);
    }

    return result;
  }

  static const _maxScale = 9223372036854775807;

  static const _scaleOutOfRange = 'The scale would leave int64';

  Decimal get _requirePacked {
    var packed = _packed;
    if (packed == null) {
      packed = Decimal._pack(base, scale);
      // The canonical form is its own: without this line `normalized()` on the
      // result would pack and allocate all over again, and the promise that
      // the second call is free would not be one.
      packed._packed = packed;
      _packed = packed;
    }

    return packed;
  }

  /// [base] without its trailing zeros, with [scale] moved to match.
  ///
  /// Dividing by ten until the remainder shows up costs two BigInt operations
  /// per zero — a hundred and eleven of them on a hundred-digit number with
  /// fifty-five zeros. Three steps replace that: an odd base has no trailing
  /// zero at all, few zeros come off cheaper one at a time than any search
  /// would set itself up, and many zeros are found by halving the range.
  ///
  /// The middle step is not decoration: without it the search loses to the
  /// loop it replaces on every even number that ends in a nonzero digit.
  factory Decimal._pack(BigInt base, int scale) {
    // A trailing zero needs both a two and a five, so an odd base has none.
    if (base.isOdd) {
      return Decimal._asIs(base, scale);
    }

    if (base == BigInt.zero) {
      return Decimal._asIs(base, 0);
    }

    final (packed, zeros) = _splitTrailingZeros(base);

    // Stripping zeros lowers the scale, and at the floor of int64 it wraps —
    // a huge number would come back as a vanishing one, and canonicalising is
    // the one thing that must never change a value. Unlike the short family
    // the count has no bound here, so the check is on the subtraction itself.
    final result = scale - zeros;
    if (zeros > 0 && result > scale) {
      throw ArgumentError.value(scale, 'scale', _scaleOutOfRange);
    }

    return Decimal._asIs(packed, result);
  }

  /// [base] with its trailing zeros taken off, and how many there were.
  ///
  /// [base] must be even and not zero. An odd one has no trailing zero by
  /// definition, and zero is nothing but trailing zeros — it would come back
  /// with however many the search happened to stop at. Both callers check
  /// first, where it costs nothing.
  static (BigInt, int) _splitTrailingZeros(BigInt base) {
    if (base % _bigInt10 != BigInt.zero) {
      return (base, 0);
    }

    // Up to four zeros the plain loop wins: setting a search up costs more
    // than it saves. Past that the search wins by an order of magnitude.
    var rest = base ~/ _bigInt10;
    var zeros = 1;
    while (zeros < _linearZeros) {
      if (rest % _bigInt10 != BigInt.zero) {
        return (rest, zeros);
      }

      rest = rest ~/ _bigInt10;
      zeros++;
    }

    // A number of `bitLength` bits has at most `bitLength * log10(2)` decimal
    // digits, and the zeros cannot outnumber the digits.
    var low = _linearZeros;
    var high = (base.bitLength * 30103) ~/ 100000 + 1;

    while (low < high) {
      final middle = low + (high - low + 1) ~/ 2;
      if (base % _pow10(middle) == BigInt.zero) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }

    return (base ~/ _pow10(low), low);
  }

  /// How many zeros are taken off one at a time before the search starts.
  static const _linearZeros = 4;

  /// Aligning decimals by decimal point.
  (BigInt, BigInt, int) _align(Decimal other) {
    final as = scale;
    final bs = other.scale;

    if (as == bs) {
      return (base, other.base, as);
    }

    if (as > bs) {
      return (base, other.base * _pow10(as - bs), as);
    }

    return (base * _pow10(bs - as), other.base, bs);
  }

  Decimal _dropFraction(
    int fractionDigits,
    BigInt Function(BigInt result, BigInt divisor) callback,
  ) {
    _checkDigits(fractionDigits, 'fractionDigits');

    if (scale <= fractionDigits) {
      return this;
    }

    final divisor = _pow10(scale - fractionDigits);
    final result = callback(base ~/ divisor, divisor);

    return Decimal._asIs(result, fractionDigits);
  }
}

/// Thrown by [Decimal.operator /] when the result has no finite decimal form.
///
/// One divided by three cannot be written down in full, and the package does
/// not round behind the caller's back. The exception carries everything that
/// could have been wanted instead of the exact answer, so that catching it is a
/// way of asking again rather than a dead end:
///
/// ```dart
/// try {
///   print(Decimal(1) / Decimal(3));
/// } on DecimalDivideException catch (e) {
///   print(e.fraction); // 1/3
///   print(e.round(4)); // 0.3333
/// }
/// ```
///
/// Catching is the slow way round, though: [Decimal.divideOrNull] asks the same
/// question about five times faster, and [Decimal.divide] rounds in one call.
final class DecimalDivideException implements Exception {
  /// The number that was divided.
  final Decimal dividend;

  /// The number it was divided by.
  final Decimal divisor;

  const DecimalDivideException._(this.dividend, this.divisor);

  /// Builds an instance directly; the package raises the real ones itself.
  ///
  /// Refuses a zero divisor. The package never raises this exception for one —
  /// division by zero throws [UnsupportedError] long before — and an instance
  /// holding one would answer every one of its own questions, [toString]
  /// included, by throwing. An exception whose message cannot be read is the
  /// worst thing to meet inside a `catch`.
  @visibleForTesting
  DecimalDivideException.forTest(this.dividend, this.divisor) {
    if (divisor.isZero) {
      throw ArgumentError.value(
        divisor,
        'divisor',
        'The value must not be zero',
      );
    }
  }

  /// The exact result, as a fraction.
  Fraction get fraction => dividend.divideToFraction(divisor);

  /// The whole quotient and what is left of the dividend.
  Division get quotientWithRemainder => dividend.divideWithRemainder(divisor);

  /// The exact result rounded towards minus infinity, [fractionDigits] digits.
  Decimal floor([int fractionDigits = 0]) => fraction.floor(fractionDigits);

  /// The exact result rounded to [fractionDigits] digits, halves away from
  /// zero.
  Decimal round([int fractionDigits = 0]) => fraction.round(fractionDigits);

  /// The exact result rounded to [fractionDigits] digits, halves to even.
  Decimal roundToEven([int fractionDigits = 0]) =>
      fraction.roundToEven(fractionDigits);

  /// The exact result rounded towards plus infinity, [fractionDigits] digits.
  Decimal ceil([int fractionDigits = 0]) => fraction.ceil(fractionDigits);

  /// The exact result with everything past [fractionDigits] digits cut off.
  Decimal truncate([int fractionDigits = 0]) =>
      fraction.truncate(fractionDigits);

  @override
  String toString() {
    // Never throws: an exception that cannot be printed hides the very
    // failure it reports, and its own dartdoc promises a way of asking again
    // rather than a dead end. Every line that needs building is built
    // defensively — the pair is always there, the rest may not be.
    final buffer = StringBuffer('$DecimalDivideException:'
        ' The result of division cannot be represented as $Decimal:');

    for (final (label, build) in <(String, Object Function())>[
      ('quotient and remainder', () => quotientWithRemainder),
      ('fraction', () => fraction),
    ]) {
      buffer.write('\n$dividend / $divisor = ');
      try {
        buffer.write(build());
        // Deliberately everything: whatever the line failed on, the message
        // has to come out. This is the one place where swallowing is right.
        // ignore: avoid_catches_without_on_clauses
      } catch (_) {
        buffer.write('($label has none in this family)');
      }
    }

    return buffer.toString();
  }
}
