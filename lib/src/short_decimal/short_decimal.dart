import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../errors.dart';
import '../fixed_point.dart';
import '../helpers.dart';

part 'short_fraction.dart';
part 'short_division.dart';

/// A decimal number with a fixed point, kept in an `int`.
///
/// The value is `base × 10^-scale`, the same as in `Decimal`, but the unscaled
/// [base] is an `int` rather than a `BigInt`. Arithmetic is exact as long as
/// the numbers stay inside int64 — `0.1 + 0.2` is `0.3` — and several times
/// faster than the BigInt family.
///
/// ```dart
/// final price = ShortDecimal.parse('19.99');
/// print(price * ShortDecimal(3)); // 59.97
/// ```
///
/// **Overflow is silent**, exactly as it is for `int` itself: a result that
/// does not fit in int64 wraps round instead of throwing. Nothing here reports
/// it — not `+`, not `*`, not the fraction types — so where the magnitudes are
/// not known in advance, use `Decimal`, which has no such limit.
///
/// Crossing over is `toDecimal()`, and it lives in the bridge: import
/// `package:denary/denary.dart` to have it. The narrow entry point
/// `package:denary/short_decimal.dart` deliberately carries this family alone,
/// bridge included out.
///
/// Division is the one operation that cannot always answer — one third has no
/// finite decimal form. [divideOrNull] returns null there, [divide] rounds to
/// as many digits as it is told, [isDivisibleBy] asks the question in advance,
/// and [operator /] throws [ShortDecimalDivideException].
///
/// One bound beside the width of int64: the number of digits a member may be
/// asked for. Past a million the power of ten behind it is a number nobody can
/// hold — `round(-1000000000)` asks for ten to the billionth — and the request
/// is refused with [DecimalDigitsOutOfRangeError] rather than attempted.
/// `ShortDecimal.parse` refuses to read such a number in the first place.
// Both fields are `int`, so the class qualifies: the VM may share its
// instances between isolates. `Decimal` never will — a field of type `BigInt`
// is rejected outright, and that is the whole difference.
@pragma('vm:deeply-immutable')
@immutable
final class ShortDecimal implements FixedPoint<ShortDecimal> {
  static final _bigInt10 = BigInt.from(10);
  static final _charCode0 = '0'.codeUnitAt(0);
  static final _charCode9 = '9'.codeUnitAt(0);
  static final _charCodeMinus = '-'.codeUnitAt(0);
  static final _charCodeDot = '.'.codeUnitAt(0);

  /// A decimal with the numerical value 0.
  static const ShortDecimal zero = ShortDecimal._asIs(0, 0);

  /// A decimal with the numerical value 1.
  static const ShortDecimal one = ShortDecimal._asIs(1, 0);

  /// A decimal with the numerical value 2.
  static const ShortDecimal two = ShortDecimal._asIs(2, 0);

  /// A decimal with the numerical value 10.
  ///
  /// The base is one and the scale is minus one: that is what `_pack` makes of
  /// ten, and hashCode is taken from the packed pair as is.
  static const ShortDecimal ten = ShortDecimal._asIs(1, -1);

  /// The unscaled value: the number is `base × 10^-scale`.
  ///
  /// Visible for testing because the tests check the stored form, not because
  /// the pair is a promise. Unlike the BigInt family this one normalises on
  /// construction, so the form is canonical — but comparing decimals by this
  /// pair is still the wrong way round: compare them by value.
  @visibleForTesting
  final int base;

  /// The power of ten the [base] is divided by.
  ///
  /// A negative scale is a working mode and not an error: ten is a base of one
  /// at a scale of minus one, which is what makes [ten] canonical.
  @visibleForTesting
  final int scale;

  /// Returns [ShortDecimal] from integer [base].
  ///
  /// Parameter [shiftRight] shifts [base] to the right relative to the decimal
  /// point:
  ///
  /// ```dart
  /// ShortDecimal(1); // 1
  /// ShortDecimal(1, shiftRight: 1); // 0.1
  /// ShortDecimal(1, shiftRight: 2); // 0.01
  /// ```
  ///
  /// Parameter [shiftLeft] shifts [base] to the left relative to the decimal
  /// point. `Decimal` has no such parameter — there the shift left is the
  /// `<<` operator and nothing else:
  ///
  /// ```dart
  /// ShortDecimal(1); // 1
  /// ShortDecimal(1, shiftLeft: 1); // 10
  /// ShortDecimal(1, shiftLeft: 2); // 100
  /// ```
  factory ShortDecimal(int base, {int shiftLeft = 0, int shiftRight = 0}) {
    // Not asserts: the three of them would be gone in release, where the two
    // shifts would then cancel each other and a negative one would quietly
    // turn into its opposite.
    if (shiftLeft != 0 && shiftRight != 0) {
      throw ArgumentError('Use either `shiftLeft` or `shiftRight`, not both');
    }

    if (shiftLeft < 0) {
      throw ArgumentError.value(
        shiftLeft,
        'shiftLeft',
        'Use `shiftRight` instead of a negative `shiftLeft`',
      );
    }

    if (shiftRight < 0) {
      throw ArgumentError.value(
        shiftRight,
        'shiftRight',
        'Use `shiftLeft` instead of a negative `shiftRight`',
      );
    }

    return ShortDecimal._pack(base, shiftRight - shiftLeft);
  }

  /// Parse the [string] to [ShortDecimal].
  ///
  /// Throw [FormatException] on failure.
  factory ShortDecimal.parse(String string) =>
      tryParse(string) ??
      (throw FormatException('Could not parse $ShortDecimal: $string'));

  /// Reads a decimal from its [toJson] form.
  ///
  /// Throw [FormatException] on failure.
  factory ShortDecimal.fromJson(String json) => ShortDecimal.parse(json);

  // The three-step zero removal that Decimal uses is not mirrored here: it was
  // tried and measured, and every case came out slower — the loop below runs
  // on machine words and there is nothing to save.
  factory ShortDecimal._pack(int base, int scale) {
    if (base == 0) {
      return ShortDecimal.zero;
    }

    // Stripping zeros lowers the scale, and at the floor of int64 it wraps:
    // a huge number came back as a vanishing one, and canonicalising is the
    // one thing that must never change a value. A base of int64 carries at
    // most nineteen zeros, so anything above the floor by that much cannot
    // reach it — one comparison on the hot path, and the careful road is
    // taken by nobody.
    if (scale < _scaleFloorForPacking) {
      return ShortDecimal._packNearFloor(base, scale);
    }

    while (base % 10 == 0) {
      base ~/= 10;
      scale--;
    }

    return ShortDecimal._asIs(base, scale);
  }

  /// The same packing where the scale has no room left to fall.
  factory ShortDecimal._packNearFloor(int base, int scale) {
    while (base % 10 == 0) {
      if (scale == _minScale) {
        throw ScaleOutOfRangeError(scale, 'scale');
      }

      base ~/= 10;
      scale--;
    }

    return ShortDecimal._asIs(base, scale);
  }

  const ShortDecimal._asIs(this.base, this.scale);

  /// Try to parse the [string] to [ShortDecimal].
  ///
  /// Accepts an optional sign, an optional exponent and surrounding
  /// whitespace, and refuses an exponent past a million — the same grammar the
  /// BigInt family reads. Returns null on failure.
  static ShortDecimal? tryParse(String string) {
    final plain = _tryParsePlain(string);
    if (plain != null) {
      return plain;
    }

    final scanned = string.scanDecimal();
    if (scanned == null) {
      return null;
    }

    final (digits, scale) = scanned;

    // Trailing zeros are dropped from the text, before the digits become a
    // number: that is what keeps '9223372036854775807000' in range — as a base
    // with a scale of minus three.
    var end = digits.length;
    var packedScale = scale;
    while (end > 0 && digits.codeUnitAt(end - 1) == _charCode0) {
      end--;
      packedScale--;
    }

    // Nothing but a sign is left of a zero.
    if (end == 0 || (end == 1 && !_isDigit(digits.codeUnitAt(0)))) {
      return zero;
    }

    final base = int.tryParse(digits.substring(0, end));

    return base == null ? null : ShortDecimal._asIs(base, packedScale);
  }

  /// The common shape read without building anything, or null for the rest.
  ///
  /// `-?digits('.'digits)?` and nothing else — no exponent, no spaces, no
  /// leading plus, and few enough digits that the value cannot leave int64 on
  /// the way in. Everything this does not take goes the road below, which
  /// reads the whole grammar; null here means «not my shape», never «not a
  /// number».
  ///
  /// Worth it because that road hands the digits back as a string: two
  /// substrings and an interpolation to build it, a record to carry it and a
  /// third substring to trim its zeros. Money is read in a loop, and a loop
  /// reads this shape.
  ///
  /// Written out again in `Decimal` rather than shared: a shared form would
  /// hand its two numbers back in a record, and a record is an object — the
  /// very thing this road exists to not build.
  static ShortDecimal? _tryParsePlain(String string) {
    final length = string.length;
    var index = 0;
    var negative = false;

    if (length != 0 && string.codeUnitAt(0) == _charCodeMinus) {
      negative = true;
      index = 1;
    }

    var base = 0;
    var digits = 0;
    var scale = 0;
    var afterDot = false;

    while (index < length) {
      final code = string.codeUnitAt(index);

      if (code == _charCodeDot) {
        if (afterDot) {
          return null;
        }

        afterDot = true;
        index++;
        continue;
      }

      final digit = code - _charCode0;
      if (digit < 0 || digit > 9) {
        return null;
      }

      // Eighteen digits cannot take the value out of int64; the nineteenth
      // might, and that is what the other road is for.
      if (digits == 18) {
        return null;
      }

      base = base * 10 + digit;
      digits++;
      if (afterDot) {
        scale++;
      }
      index++;
    }

    // Nothing to read, and a point with nothing behind it, are not numbers —
    // but saying so is the other road's job, not this one's.
    if (digits == 0 || (afterDot && scale == 0)) {
      return null;
    }

    if (base == 0) {
      return zero;
    }

    // The same trailing zeros the other road drops from the text, dropped from
    // the number: they belong in the scale, and it goes below zero for them.
    while (base % 10 == 0) {
      base ~/= 10;
      scale--;
    }

    return ShortDecimal._asIs(negative ? -base : base, scale);
  }

  static bool _isDigit(int code) => code >= _charCode0 && code <= _charCode9;

  /// The whole number the value is stored as.
  ///
  /// The number is `unscaledValue × 10^exponent`. This family stores the
  /// canonical form always, so the pair is a function of the value:
  ///
  /// ```dart
  /// final a = ShortDecimal.parse('1.50');
  /// print(a.unscaledValue); // 15
  /// print(a.exponent); // -1
  /// ```
  int get unscaledValue => base;

  /// The power of ten [unscaledValue] is multiplied by.
  ///
  /// Throws [ScaleOutOfRangeError] at the floor of int64: the minimum integer
  /// has no
  /// negation, so a scale of `-2^63` has no exponent to name — the value can
  /// be held, but not taken apart.
  @override
  int get exponent {
    if (scale == _minScale) {
      throw ScaleOutOfRangeError(scale, 'scale');
    }

    return -scale;
  }

  /// Returns number of digits after the decimal point.
  @override
  int get fractionDigits {
    final scale = this.scale;
    return scale >= 0 ? scale : 0;
  }

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
  bool get isInteger => scale <= 0;

  /// Whether this decimal is zero.
  @override
  bool get isZero => base == 0;

  /// Returns the negative value of this decimal.
  ///
  /// The one value without a negative is the minimum integer: negating it
  /// gives back itself, silently, as `-int.min` does in Dart.
  @override
  ShortDecimal operator -() => ShortDecimal._asIs(-base, scale);

  /// An aligned pair added up, canonical where the canonical form fits.
  ///
  /// `a + b` can leave int64 while the answer itself does not: the exact sum
  /// may end in zeros, and those belong in the scale. The same argument that
  /// fixed multiplication (Д13) — a result whose canonical form fits is a
  /// result this family owes. Past that the overflow stays silent, as the
  /// family promises.
  factory ShortDecimal._sumThatOverflowed(int a, int b, int scale) {
    var value = BigInt.from(a) + BigInt.from(b);
    var result = scale;

    // A sum of two int64 values is at most one digit wider than one of them,
    // so a single zero is all that can ever be moved into the scale — the
    // bound is there to keep the loop honest, not because it is reached.
    for (var i = 0; i < 19 && !value.isValidInt; i++) {
      if (value.remainder(_bigInt10) != BigInt.zero) {
        break;
      }

      value = value ~/ _bigInt10;
      result--;
    }

    return value.isValidInt
        ? ShortDecimal._pack(value.toInt(), result)
        : ShortDecimal._pack(a + b, scale);
  }

  /// Adds [other] to this decimal.
  ///
  /// Overflows silently past int64, as everything in this family does.
  @override
  ShortDecimal operator +(ShortDecimal other) {
    // Zero cannot change a value, and going through the alignment to find
    // that out can: a scale gap wider than eighteen overflows the shift, and
    // the operand being added is exactly the one that would have shifted the
    // other. Answering here costs one comparison and keeps `x + 0 == x`.
    if (other.isZero) {
      return this;
    }

    if (isZero) {
      return other;
    }

    final (a, b, scale) = _align(other);
    final second = b;
    final sum = a + second;

    // Signed overflow, written out rather than called: the addition is the
    // hottest thing in this family, and a call around the check is not
    // inlined. The rare road out of it is a method, as it should be.
    if ((a ^ second) >= 0 && (sum ^ a) < 0) {
      return ShortDecimal._sumThatOverflowed(a, second, scale);
    }

    return ShortDecimal._pack(sum, scale);
  }

  /// Subtracts [other] from this decimal.
  @override
  ShortDecimal operator -(ShortDecimal other) {
    // See [operator +]: subtracting zero must not go near the alignment.
    if (other.isZero) {
      return this;
    }

    if (isZero) {
      return -other;
    }

    final (a, b, scale) = _align(other);
    final second = -b;
    final sum = a + second;

    // Signed overflow, written out rather than called: the addition is the
    // hottest thing in this family, and a call around the check is not
    // inlined. The rare road out of it is a method, as it should be.
    if ((a ^ second) >= 0 && (sum ^ a) < 0) {
      return ShortDecimal._sumThatOverflowed(a, second, scale);
    }

    return ShortDecimal._pack(sum, scale);
  }

  /// Multiplies this decimal by [other].
  ///
  /// The likeliest place in this family to leave int64, and it leaves it
  /// silently: multiplication grows the digits of both operands at once, so a
  /// chain of them — compound interest is the everyday case — walks out of
  /// range while every single step still looks ordinary.
  @override
  ShortDecimal operator *(ShortDecimal other) {
    final a = base;
    final b = other.base;

    // Both sides under 2^31 make a product under 2^62, and nothing below needs
    // asking about them. Four comparisons that do not depend on one another,
    // against a chain of two conversions, a multiplication and a comparison in
    // double — and it is the chain that costs, because multiplications run one
    // after another and each waits for the one before it. A fifth of the
    // operation, measured; what the test does not clear goes on as it did.
    if (a > -2147483648 &&
        a < 2147483648 &&
        b > -2147483648 &&
        b < 2147483648) {
      return ShortDecimal._pack(a * b, scale + other.scale);
    }

    // The approximate product decides the rest: a double is off by a part in
    // 2^52 at worst, which against the gap between the threshold and int.max —
    // more than 2·10^17 — is nothing. Everything close to the boundary goes the
    // careful way, where the check costs a division.
    final approximate = a.toDouble() * b.toDouble();

    return approximate > -_productThreshold && approximate < _productThreshold
        ? ShortDecimal._pack(a * b, scale + other.scale)
        : _multiplyCarefully(other);
  }

  /// Multiplies this decimal by [other] when the product may not fit int64.
  ///
  /// A two on one side and a five on the other make a ten, and a ten belongs
  /// in the scale rather than in the product. Cancelling them keeps results
  /// that are perfectly representable — 2^62 * 5 among them — out of the
  /// overflow. Nothing is cancelled while the product fits.
  ShortDecimal _multiplyCarefully(ShortDecimal other) {
    var a = base;
    var b = other.base;
    var scale = this.scale + other.scale;

    while (!_productFits(a, b)) {
      if (a.isEven && b % 5 == 0) {
        a ~/= 2;
        b ~/= 5;
      } else if (a % 5 == 0 && b.isEven) {
        a ~/= 5;
        b ~/= 2;
      } else {
        break;
      }

      scale--;
    }

    return ShortDecimal._pack(a * b, scale);
  }

  /// The scale moved by [by], refusing to wrap around.
  ///
  /// The base of this family wraps around by contract, and the scale does not
  /// get to: an overflow there is not a number too large to hold but a number
  /// turned into a different one — `ShortDecimal.parse('0.01').pow(int.max)`
  /// used to print `100`. So a shift that takes the scale out of int64 is
  /// refused.
  static int _scalePlus(int scale, int by, String name) {
    final result = scale + by;
    if ((scale ^ by) >= 0 && (result ^ scale) < 0) {
      throw ScaleOutOfRangeError(by, name);
    }

    return result;
  }

  /// The scale moved the other way, with the same refusal.
  static int _scaleMinus(int scale, int by, String name) {
    final result = scale - by;
    if ((scale ^ by) < 0 && (result ^ scale) < 0) {
      throw ScaleOutOfRangeError(by, name);
    }

    return result;
  }

  /// The scale repeated [by] times, with the same refusal.
  static int _scaleTimes(int scale, int by, String name) =>
      _scaleTimesOrNull(scale, by) ?? (throw ScaleOutOfRangeError(by, name));

  /// The same, null where it leaves int64.
  ///
  /// For the caller that has a second road to try. `pow` with a negative
  /// exponent has one: where the scale of the positive power leaves int64,
  /// the reciprocal of the base carries the scale the other way and its power
  /// may still fit — `5e-2^62` to the minus second is four at a scale int64
  /// holds, while five squared at that scale is not.
  static int? _scaleTimesOrNull(int scale, int by) {
    if (scale == 0 || by == 0) {
      return 0;
    }

    final result = scale * by;

    return result ~/ by == scale ? result : null;
  }

  static const _minScale = -9223372036854775808;

  /// Below this a scale can be driven past int64 by stripping zeros alone.
  static const _scaleFloorForPacking = _minScale + 19;

  /// Whether `a * b` stays within int64.
  static bool _productFits(int a, int b) {
    // The approximate product decides the common case. A double multiplication
    // is off by a part in 2^52 at worst, which against the gap between the
    // threshold and int.max — more than 2·10^17 — is nothing; and it costs a
    // few cycles where the reliable check below costs a division.
    final approximate = a.toDouble() * b.toDouble();
    if (approximate > -_productThreshold && approximate < _productThreshold) {
      return true;
    }

    if (a == 0 || b == 0) {
      return true;
    }

    final product = a * b;

    return product ~/ b == a;
  }

  /// `a * b`, or null when it does not stay within int64.
  static int? _productOrNull(int a, int b) => _productFits(a, b) ? a * b : null;

  /// `a + b`, or null when it does not stay within int64.
  ///
  /// A sum overflows only when the addends share a sign and the sum does not
  /// share it with them.
  static int? _sumOrNull(int a, int b) {
    final sum = a + b;

    return (a ^ b) < 0 || (sum ^ a) >= 0 ? sum : null;
  }

  /// `-value`, or null when it does not stay within int64.
  ///
  /// `x == -x` holds for zero and for the minimum integer only.
  static int? _negateOrNull(int value) =>
      value != 0 && value == -value ? null : -value;

  /// Divides this decimal by [other].
  ///
  /// Throws [UnsupportedError] if [other] is zero and
  /// [ShortDecimalDivideException] if the result cannot be written down as a
  /// decimal with a finite number of digits. [divideOrNull] and [divide]
  /// answer the same question without an exception.
  @override
  ShortDecimal operator /(ShortDecimal other) =>
      divideOrNull(other) ?? (throw ShortDecimalDivideException._(this, other));

  /// Divides this decimal by [other], or returns null.
  ///
  /// Null means the result has no finite decimal form — one divided by three.
  /// Dividing by zero still throws [UnsupportedError]: that is not a result
  /// nobody can write down, that is a question nobody can answer.
  ///
  /// Reading a null is more than a hundred times cheaper than catching the
  /// exception: the division itself costs a few nanoseconds on int64, and the
  /// throw costs the better part of a microsecond whatever it reports on. This
  /// is the form to reach for when the divisor is not known in advance.
  ///
  /// ```dart
  /// print(ShortDecimal(1).divideOrNull(ShortDecimal(4))); // 0.25
  /// print(ShortDecimal(1).divideOrNull(ShortDecimal(3))); // null
  /// ```
  @override
  ShortDecimal? divideOrNull(ShortDecimal other) {
    var divisor = other.base;

    if (divisor == 0) {
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
      throw ScaleOutOfRangeError(otherScale, 'other');
    }

    // The sign is taken out of the divisor before the factorization below.
    // A remainder is never negative in Dart, so a negative divisor never comes
    // down to one, and a result that is perfectly representable would be
    // rejected.
    //
    // The result is negated at the end rather than the dividend here: negating
    // the dividend up front turns the minimum integer into itself and loses
    // the sign, while the value after the factorization is the canonical one.
    final negate = divisor.isNegative;
    if (negate) {
      divisor = -divisor;
    }

    // `-int.min` is `int.min`: the sign does not come off, and the negation at
    // the end would then apply it a second time. Halving both ends keeps the
    // ratio and brings the divisor into range — but only for an even dividend.
    // An odd one leaves 2^63 in the denominator, and writing that down as a
    // decimal needs 5^63, which int64 does not hold.
    if (divisor.isNegative) {
      if (base.isOdd) {
        return null;
      }

      base ~/= 2;
      divisor = -(divisor ~/ 2);
    }

    // Dividing by one, and dividing without a remainder, are the two common
    // cases and neither needs a factorization.
    if (divisor == 1) {
      return ShortDecimal._pack(negate ? -base : base, scale);
    }

    if (base.remainder(divisor) == 0) {
      final quotient = base ~/ divisor;

      return ShortDecimal._pack(negate ? -quotient : quotient, scale);
    }

    final gcd = base.fastGcd(divisor);
    if (gcd != 1) {
      base ~/= gcd;
      divisor ~/= gcd;
    }

    if (divisor != 1) {
      // Decimal takes the tens out of the divisor here; this family has none
      // to take. Its bases are packed at every entrance — `_pack`, `tryParse`,
      // the shifts — so a divisor divisible by ten does not exist, and what is
      // left is either odd or free of fives. Only one of the two steps below
      // does anything.
      if (divisor.isEven) {
        var twos = 0;
        do {
          divisor = divisor ~/ 2;
          twos++;
        } while (divisor.isEven);

        // Silence is for a result that wrapped, not for one invented. The
        // exact quotient here is positive and finite; wrapping it hands back a
        // negative number of a wholly different magnitude, and this method
        // promises null where there is no answer to give. Decided 2026-08-29.
        if (twos > _maxPow5Exponent ||
            base > _pow5Ceiling[twos] ||
            base < -_pow5Ceiling[twos]) {
          return null;
        }

        // The scale moves with the factors, and at the ceiling of int64 that
        // move wraps: the quotient came back with the opposite order of
        // magnitude. There is no answer to give past it.
        if (scale > 9223372036854775807 - twos) {
          return null;
        }

        base *= _pow5Table[twos];
        scale += twos;
      } else if (divisor % 5 == 0) {
        var fives = 0;
        do {
          divisor = divisor ~/ 5;
          fives++;
        } while (divisor % 5 == 0);

        // The same on the other side: doubling past int64 would answer with a
        // number nobody asked for.
        if (fives > _maxPow5Exponent ||
            base > _pow2Ceiling[fives] ||
            base < -_pow2Ceiling[fives]) {
          return null;
        }

        if (scale > 9223372036854775807 - fives) {
          return null;
        }

        base <<= fives;
        scale += fives;
      }

      if (divisor != 1) {
        return null;
      }
    }

    return ShortDecimal._pack(negate ? -base : base, scale);
  }

  /// Divides this decimal by [other], rounding what cannot be written down.
  ///
  /// A result with no finite decimal form is rounded to
  /// [scaleOnInfinitePrecision] digits; without that argument it throws
  /// [ShortDecimalDivideException], the same as [operator /].
  ///
  /// ```dart
  /// print(ShortDecimal(1).divide(ShortDecimal(3),
  ///     scaleOnInfinitePrecision: 4)); // 0.3333
  /// ```
  @override
  ShortDecimal divide(ShortDecimal other, {int? scaleOnInfinitePrecision}) {
    final result = divideOrNull(other);
    if (result != null) {
      return result;
    }

    if (scaleOnInfinitePrecision == null) {
      throw ShortDecimalDivideException._(this, other);
    }

    _checkDigits(scaleOnInfinitePrecision, 'scaleOnInfinitePrecision');

    return _roundedQuotient(other, scaleOnInfinitePrecision);
  }

  /// The quotient rounded to [fractionDigits], halves away from zero.
  ///
  /// The two scales and the one asked for fold into a single power of ten.
  /// Aligning the pair first and scaling it after takes two, and both sides
  /// grow by the scale of the operands: money at scale three divided by three
  /// then divides 10^10 by three thousand where 10^7 over three is the same
  /// answer. That is the whole of the gap this method closes.
  ShortDecimal _roundedQuotient(ShortDecimal other, int fractionDigits) {
    // The exponent is a sum of three integers, and at the edge of int64 that
    // sum wraps — a wrapped one would pass the window check below and take
    // the rounding somewhere else entirely. Under a million it cannot wrap.
    final wide = scale < -maxDecimalExponent ||
        scale > maxDecimalExponent ||
        other.scale < -maxDecimalExponent ||
        other.scale > maxDecimalExponent;
    final exponent = wide ? 0 : fractionDigits - scale + other.scale;

    if (!wide &&
        exponent >= -maxDecimalExponent &&
        exponent <= maxDecimalExponent) {
      // A positive divisor keeps the sign work away from `-int.min`, which
      // does not come off; a negative one goes down the BigInt road, where it
      // does no harm.
      final divisor = other.base;
      if (divisor > 0) {
        final numerator = exponent >= 0 ? _scaledOrNull(base, exponent) : base;
        final denominator =
            exponent >= 0 ? divisor : _scaledOrNull(divisor, -exponent);

        if (numerator != null && denominator != null) {
          final remainder = numerator.remainder(denominator).abs();

          // The mode here is always the same one, and the rule fits in the
          // line: a half or more goes away from zero. Calling for it would
          // cost the hottest division path a call that cannot be inlined.
          return ShortDecimal._pack(
            numerator ~/ denominator +
                (remainder >= denominator - remainder ? numerator.sign : 0),
            fractionDigits,
          );
        }
      }

      var numerator = BigInt.from(base);
      var denominator = BigInt.from(other.base);
      if (exponent > 0) {
        numerator *= _bigInt10.pow(exponent);
      } else if (exponent < 0) {
        denominator *= _bigInt10.pow(-exponent);
      }

      return ShortFraction._roundScaled(
        numerator,
        denominator,
        fractionDigits,
        _Rounding.round,
      );
    }

    // Past a gap of eighteen the dividend is smaller in magnitude than the
    // divisor; twenty past the digits asked for it is smaller than half of the
    // last of them, and the rounded answer is nothing. Said here rather than
    // found out by building the power: a scale of a million and a half asked
    // for a number of that many digits to answer zero.
    final gap = _scaleGap(other);
    if (gap > _maxPow10Exponent && gap - 20 >= fractionDigits) {
      return ShortDecimal._pack(0, fractionDigits);
    }

    // Past the power of ten anyone can hold, the aligned pair is the old road
    // and it reaches the same answer. The pair is rounded as it is, without
    // being made into a fraction first: getting here means the scales are a
    // million apart, and a pair that far apart has no fraction in int64 —
    // nor has a divisor of 2^63, whose denominator has nowhere to be
    // positive. The rounded quotient is an ordinary number either way.
    final (dividend, divisor) = _fractionPair(other);

    return ShortFraction._roundExactly(
      dividend,
      divisor,
      fractionDigits,
      _Rounding.round,
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
  bool isDivisibleBy(ShortDecimal other) => divideOrNull(other) != null;

  /// Performs truncating division of this decimal by [other].
  ///
  /// Truncating division is division where a fractional result is converted to
  /// an integer by rounding towards zero.
  ///
  /// Throws [UnsupportedError] if [other] is zero, the same as every other
  /// division here does.
  int operator ~/(ShortDecimal other) {
    if (other.isZero) {
      throw UnsupportedError('division by zero');
    }

    final aligned = _alignOrNull(other);
    if (aligned != null) {
      final (a, b, _) = aligned;

      return a ~/ b;
    }

    // A gap wider than eighteen settles this without a power of ten: the side
    // being scaled up is never zero here — [_scaledOrNull] answers a zero
    // without looking at the exponent at all — so ten to the nineteenth makes
    // it larger in magnitude than any int64 the other side holds. Truncating
    // the smaller by the larger gives nothing.
    if (_scaleGap(other) > _maxPow10Exponent) {
      return 0;
    }

    final (a, b, _) = _alignExactly(other);

    return (a ~/ b).toInt();
  }

  /// Calculates the result of division as double.
  ///
  /// Decimal needs a scaled division here to keep the ratio out of NaN; this
  /// family does not: both ends of the fraction are int64 and always convert.
  @override
  double divideToDouble(ShortDecimal other) {
    if (other.isZero) {
      throw UnsupportedError('division by zero');
    }

    // Where both ends convert to a double exactly, IEEE division rounds once
    // and is already right — and costs no BigInt.
    final aligned = _alignOrNull(other);
    if (aligned != null) {
      final (a, b, _) = aligned;
      if (a >= -_maxExactInDouble &&
          a <= _maxExactInDouble &&
          b >= -_maxExactInDouble &&
          b <= _maxExactInDouble) {
        return a / b;
      }
    }

    // Otherwise from the exact pair rather than through [ShortFraction]: the
    // double is representable even where the fraction is not, and dividing one
    // int by another rounds twice on operands past 2^53.
    final (a, b, _) = _alignExactly(other);

    return a.ratioToDouble(b);
  }

  /// Calculates the result of division as fraction.
  ///
  /// Throws `ArgumentError` where the ratio has no fraction in int64 — a
  /// divisor of 2^63 leaves the denominator nowhere to be positive. [divide]
  /// answers such a division anyway: it needs the rounded quotient, and that
  /// one is an ordinary number.
  ShortFraction divideToFraction(ShortDecimal other) {
    final (dividend, divisor) = _fractionPair(other);
    if (!dividend.isValidInt || !divisor.isValidInt) {
      throw ArgumentError.value(
        other,
        'other',
        'The ratio of this division has no fraction in int64',
      );
    }

    return ShortFraction(dividend.toInt(), divisor.toInt());
  }

  /// The pair a fraction of this division is built from.
  ///
  /// Kept in `BigInt` on purpose: the reduced pair does not always fit int64,
  /// and `BigInt.toInt()` truncates without a word — a truncated pair looks
  /// like an ordinary fraction, which is the wrong answer nobody can spot.
  /// Whoever needs it in int64 checks first, and each caller has its own
  /// answer to a pair that does not fit.
  (BigInt, BigInt) _fractionPair(ShortDecimal other) {
    if (other.isZero) {
      throw UnsupportedError('division by zero');
    }

    final aligned = _alignOrNull(other);
    if (aligned != null) {
      final (dividend, divisor, _) = aligned;

      return (BigInt.from(dividend), BigInt.from(divisor));
    }

    // Reduced first: the aligned pair can leave int64 while the same ratio in
    // lowest terms fits it comfortably.
    final (a, b, _) = _alignExactly(other);
    final gcd = a.fastGcd(b);

    return (a ~/ gcd, b ~/ gcd);
  }

  /// Calculates the result of division as an integer quotient and remainder.
  ShortDivision divideWithRemainder(ShortDecimal other) =>
      ShortDivision(this, other);

  /// Euclidean modulo of this number by [other].
  ///
  /// The returned value is never negative — zero, being neither, included.
  ///
  /// Throws [UnsupportedError] if [other] is zero.
  @override
  ShortDecimal operator %(ShortDecimal other) {
    if (other.isZero) {
      throw UnsupportedError('division by zero');
    }

    final aligned = _alignOrNull(other);
    if (aligned != null) {
      final (a, b, scale) = aligned;

      return ShortDecimal._pack(a % b, scale);
    }

    // See [operator ~/]: past that gap this is smaller in magnitude than the
    // divisor, so the whole of it is the remainder. Only where it is not
    // negative, though — there the euclidean answer is this plus the divisor,
    // and the divisor is the number that would not fit.
    if (!isNegative && _scaleGap(other) > _maxPow10Exponent) {
      return this;
    }

    final (a, b, scale) = _alignExactly(other);

    return ShortDecimal._pack((a % b).toInt(), scale);
  }

  /// The remainder of the truncating division of this by [other].
  ///
  /// The result r of this operation satisfies:
  /// this == (this ~/ other) * other + r. As a consequence, the remainder r
  /// has the same sign as the dividend this.
  ///
  /// Throws [UnsupportedError] if [other] is zero.
  @override
  ShortDecimal remainder(ShortDecimal other) {
    if (other.isZero) {
      throw UnsupportedError('division by zero');
    }

    final aligned = _alignOrNull(other);
    if (aligned != null) {
      final (a, b, scale) = aligned;

      return ShortDecimal._pack(a.remainder(b), scale);
    }

    // See [operator ~/]. This remainder carries the sign of the dividend, so
    // the whole of the dividend is the answer whichever side of zero it is on.
    if (_scaleGap(other) > _maxPow10Exponent) {
      return this;
    }

    final (a, b, scale) = _alignExactly(other);

    return ShortDecimal._pack(a.remainder(b).toInt(), scale);
  }

  /// Whether this decimal is smaller than [other].
  @override
  bool operator <(ShortDecimal other) => _compare(other) < 0;

  /// Whether this decimal is smaller than or equal to [other].
  @override
  bool operator <=(ShortDecimal other) => _compare(other) <= 0;

  /// Whether this decimal is greater than [other].
  @override
  bool operator >(ShortDecimal other) => _compare(other) > 0;

  /// Whether this decimal is greater than or equal to [other].
  @override
  bool operator >=(ShortDecimal other) => _compare(other) >= 0;

  /// Shifts a decimal relative to the decimal point to the left.
  ///
  /// ```dart
  /// ShortDecimal(1) << 2; // 100
  /// ShortDecimal.parse('0.01') << 1; // 0.1
  /// ```
  ///
  /// This is equivalent to using the `shiftLeft` parameter when creating
  /// a `ShortDecimal`:
  ///
  /// ```dart
  /// print(ShortDecimal(1) << 2 == ShortDecimal(1, shiftLeft: 2)); // true
  /// ```
  @override
  ShortDecimal operator <<(int shiftAmount) => base == 0
      ? this
      : ShortDecimal._asIs(
          base,
          _scaleMinus(scale, shiftAmount, 'shiftAmount'),
        );

  /// Shifts a decimal relative to the decimal point to the right.
  ///
  /// ```dart
  /// print(ShortDecimal(1) >> 2); // 0.01
  /// print(ShortDecimal(100) >> 1); // 10
  /// ```
  ///
  /// This is equivalent to using the `shiftRight` parameter when creating
  /// a `ShortDecimal`:
  ///
  /// ```dart
  /// print(ShortDecimal(1) >> 2 == ShortDecimal(1, shiftRight: 2)); // true
  /// ```
  @override
  ShortDecimal operator >>(int shiftAmount) => base == 0
      ? this
      : ShortDecimal._pack(base, _scalePlus(scale, shiftAmount, 'shiftAmount'));

  /// This decimal divided by `10^places`: the point moves left.
  ///
  /// The readable name of [operator >>].
  ///
  /// ```dart
  /// print(ShortDecimal(100).movePointLeft(2)); // 1
  /// ```
  @override
  ShortDecimal movePointLeft(int places) => this >> places;

  /// This decimal multiplied by `10^places`: the point moves right.
  ///
  /// The readable name of [operator <<].
  ///
  /// ```dart
  /// print(ShortDecimal(1).movePointRight(2)); // 100
  /// ```
  @override
  ShortDecimal movePointRight(int places) => this << places;

  /// This decimal in its canonical form — that is, itself.
  ///
  /// Unlike the BigInt family, this one normalises on construction: there is
  /// no other form to be in. The member exists so that code written against
  /// the shared contract can call it.
  @override
  ShortDecimal normalized() => this;

  /// Returns the absolute value of this decimal.
  ///
  /// Integer overflow may cause the result of -value to stay negative:
  ///
  /// ```dart
  /// print(ShortDecimal(-9223372036854775808).abs() ==
  ///     ShortDecimal(-9223372036854775808)); // true
  /// ```
  @override
  ShortDecimal abs() =>
      base.isNegative ? ShortDecimal._asIs(-base, scale) : this;

  /// Rounds the decimal towards negative infinity to [fractionDigits].
  @override
  ShortDecimal floor([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        _floorStep,
        onDivisorOverflow: _floorWide,
      );

  /// Rounds to the closest decimal with [fractionDigits].
  @override
  ShortDecimal round([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        _roundStep,
        onDivisorOverflow: _roundWide,
      );

  /// Rounds to the closest decimal with [fractionDigits], halves to even.
  ///
  /// Where [round] sends a half away from zero — 2.5 to 3, 3.5 to 4 — this one
  /// sends it to the even neighbour: 2.5 to 2, 3.5 to 4. Halves then stop
  /// pulling a long column of numbers the same way every time, which is why
  /// accounting asks for this rule.
  ///
  /// ```dart
  /// print(ShortDecimal.parse('2.5').roundToEven()); // 2
  /// print(ShortDecimal.parse('3.5').roundToEven()); // 4
  /// ```
  @override
  ShortDecimal roundToEven([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        _roundToEvenStep,
        onDivisorOverflow: _roundToEvenWide,
      );

  /// Rounds the decimal towards infinity to [fractionDigits].
  @override
  ShortDecimal ceil([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        _ceilStep,
        onDivisorOverflow: _ceilWide,
      );

  /// Rounds the decimal towards zero to [fractionDigits].
  @override
  ShortDecimal truncate([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        _truncateStep,
        onDivisorOverflow: _truncateWide,
      );

  /// Rounds the decimal away from zero to [fractionDigits].
  ///
  /// The mirror of [truncate]: where that one drops whatever is past the digit
  /// asked for, this one lets any remainder move the last digit one step
  /// further from zero — 2.01 becomes 2.1 and -2.01 becomes -2.1. This is
  /// `ROUND_UP` in General Decimal Arithmetic, a name that reads as [ceil]
  /// here and means something else.
  ///
  /// ```dart
  /// print(ShortDecimal.parse('2.01').roundAwayFromZero(1)); // 2.1
  /// print(ShortDecimal.parse('-2.01').roundAwayFromZero(1)); // -2.1
  /// ```
  @override
  ShortDecimal roundAwayFromZero([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        _awayFromZeroStep,
        // Every digit of the value is past the position asked for, so anything
        // but zero moves the last one a step out.
        onDivisorOverflow: _awayFromZeroWide,
      );

  /// Returns this decimal clamped to be in the range [lowerLimit]-[upperLimit].
  ///
  /// The arguments [lowerLimit] and [upperLimit] must form a valid range where
  /// lowerLimit <= upperLimit.
  @override
  ShortDecimal clamp(ShortDecimal lowerLimit, ShortDecimal upperLimit) {
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
  /// division throws: [ShortDecimalDivideException] when the result has no
  /// finite decimal form, [UnsupportedError] on zero. Where the power itself
  /// leaves int64 the refusal is [UnsupportedError] too — the one [inverse]
  /// makes, and for the same reason. What it will not do is divide by a power
  /// that wrapped: `ShortDecimal(int.min).pow(-3)` reported a division by zero
  /// because the cube had wrapped to zero, not because the base was.
  ///
  /// ```dart
  /// print(ShortDecimal(2).pow(-2)); // 0.25
  /// print(ShortDecimal(5).pow(-30)); // 0.000000000000000000001073741824
  /// ```
  ///
  /// A positive power multiplies, so it overflows the way [operator *] does,
  /// and sooner: the digits multiply with every step.
  @override
  ShortDecimal pow(int exponent) {
    if (exponent >= 0) {
      return ShortDecimal._pack(
        math.pow(base, exponent) as int,
        _scaleTimes(scale, exponent, 'exponent'),
      );
    }

    // Three bases reach an answer without a positive counterpart to raise to,
    // and that is what takes them past the refusal below: one and minus one
    // are their own reciprocals, and zero has none at all. `_powOrNull` skips
    // the loop for the same three; here they skip the minimum integer, whose
    // power they do not depend on.
    switch (base) {
      case 0:
        throw UnsupportedError('division by zero');
      case 1:
      case -1:
        return ShortDecimal._pack(
          base == 1 || exponent.isEven ? 1 : -1,
          _scaleTimes(scale, exponent, 'exponent'),
        );
    }

    // The minimum integer has no positive counterpart to raise to.
    if (exponent == -exponent) {
      throw ArgumentError.value(exponent, 'exponent', 'The value is too small');
    }

    // One over the positive power, and the power is built with the overflow
    // checked: `math.pow` reports it silently, and dividing by what came back
    // answered `int.min ^ -3` with «division by zero» — the cube had wrapped
    // to zero, the base was never zero.
    final power = _powOrNull(-exponent);
    if (power != null) {
      return one / power;
    }

    // The power has no int64 form. The answer may have one all the same: a
    // packed base is a power of two or a power of five, and the reciprocal of
    // a power of five outlives it — `5 ^ -30` is `0.2 ^ 30`, where 5^30 is
    // long gone and 2^30 has room to spare. Where the base has no finite
    // reciprocal, no power of it has one either.
    //
    // Both dead ends refuse the same way, and neither of them raises a divide
    // exception: that exception carries the pair it was raised on, and the
    // divisor here — the power itself — is the number that would not fit. A
    // pair of one and the base is a different division, and answering `3 ^ -40`
    // from it gave 0.33 where the truth rounds to nothing.
    final reciprocal = one.divideOrNull(this);

    return reciprocal?._powOrNull(-exponent) ??
        (throw UnsupportedError(
          'The result of $_named to the power of $exponent has no'
          ' $ShortDecimal form',
        ));
  }

  /// This decimal named for a refusal, without writing it out in full.
  ///
  /// A refusal must not cost more than the operation it refuses. Interpolating
  /// the decimal itself spells out the positional form, and nothing bounds the
  /// scale but int64: `ShortDecimal(3, shiftRight: 224944935700986765)` asked
  /// for 2.2e17 bytes and came back `OutOfMemoryError` where the doc promises
  /// `UnsupportedError` — to a caller who caught the refusal and never printed
  /// it. The two ints name the same number and cost nothing.
  ///
  /// Printing the number is still the caller's to ask for, and
  /// [ShortDecimalDivideException] does write its pair out: there the string
  /// is built when the exception is printed, not when it is raised.
  String get _named => '$base at scale $scale';

  /// This decimal to a non-negative [exponent], or null past int64.
  ///
  /// Squaring is not worth it: a base of two or more in magnitude is gone by
  /// the sixty-fourth step — `(-2) ^ 63` is the last one that fits, and it
  /// fits exactly — so the loop never runs longer than that. The three bases
  /// it would run to the end for do not arrive: [pow] answers them itself,
  /// before either of its two calls here.
  ShortDecimal? _powOrNull(int exponent) {
    assert(exponent > 0, 'A zeroth power does not come from `pow`');

    // Null rather than a refusal, for the same reason the base gives one: the
    // caller has the reciprocal to try, and its scale runs the other way.
    final scale = _scaleTimesOrNull(this.scale, exponent);
    if (scale == null) {
      return null;
    }

    // Zero, one and minus one answer in [pow]: the first call here comes after
    // that answer, and the second comes on a reciprocal, whose base is one of
    // the three only when this one was.
    assert(
      base != 0 && base != 1 && base != -1,
      'A base whose power does not depend on the exponent is answered in `pow`',
    );

    if (exponent >= 64) {
      return null;
    }

    var result = 1;
    for (var i = 0; i < exponent; i++) {
      final next = _productOrNull(result, base);
      if (next == null) {
        return null;
      }

      result = next;
    }

    return ShortDecimal._pack(result, scale);
  }

  /// The number of digits this decimal is written with, sign and point aside.
  ///
  /// Not the digit count of [unscaledValue], which is a different number: a
  /// thousand is written with four digits and its unscaled value is one. Zero
  /// has a precision of one, the same as `decimal` reports.
  ///
  /// ```dart
  /// print(ShortDecimal.parse('0').precision); // 1
  /// print(ShortDecimal.parse('1.5').precision); // 2
  /// print(ShortDecimal.parse('0.05').precision); // 3
  /// ```
  @override
  int get precision {
    final integer = toBigInt().toString();

    return fractionDigits +
        (integer.codeUnitAt(0) == _charCodeMinus
            ? integer.length - 1
            : integer.length);
  }

  /// Whether this decimal is greater than zero.
  ///
  /// Zero is neither positive nor [isNegative].
  @override
  bool get isPositive => base.sign > 0;

  /// One divided by this decimal, as an exact [ShortFraction].
  ///
  /// A fraction rather than a decimal because the inverse of three has no
  /// finite decimal form.
  ///
  /// Throws [UnsupportedError] if this decimal is zero, and where the fraction
  /// itself leaves int64: the inverse of `1e-19` is ten to the nineteenth, and
  /// no numerator here holds it. Overflowing quietly would have answered a
  /// positive number with a negative one, and this family has refused that
  /// twice already.
  ShortFraction get inverse {
    final exponent = scale.abs();
    if (exponent >= 0 && exponent <= _maxPow10Exponent) {
      final power = _pow10(exponent);
      // Either way the pair can be one no fraction is built from — a base of
      // `int.min` leaves the denominator nowhere to be positive. That is the
      // case the doc promises `UnsupportedError` for, so the throw below
      // answers it rather than the factory with its own kind of complaint.
      if (scale >= 0) {
        final fraction = ShortFraction._orNull(power, base);
        if (fraction != null) {
          return fraction;
        }
      } else {
        final denominator = _productOrNull(base, power);
        if (denominator != null) {
          final fraction = ShortFraction._orNull(1, denominator);
          if (fraction != null) {
            return fraction;
          }
        }
      }
    }

    throw UnsupportedError(
      'The inverse of $_named has no fraction in int64',
    );
  }

  /// A JSON representation of this decimal: the string [toString] returns.
  @override
  String toJson() => toString();

  /// Returns [BigInt], discarding all fractional digits from this decimal.
  ///
  /// Unlike [toInt] this one never overflows: a decimal shifted far to the
  /// left holds a value no int64 can.
  @override
  BigInt toBigInt() {
    final truncated = truncate();
    final base = BigInt.from(truncated.base);

    return truncated.scale < 0 ? base * _bigInt10.pow(-truncated.scale) : base;
  }

  /// Returns [int], discarding all fractional digits from this decimal.
  ///
  /// A value too large for int64 comes back as the nearest end of the range,
  /// the way `BigInt.toInt` and `double.toInt` answer it, and the way `~/`
  /// already did in this family. The silent overflow of arithmetic is not
  /// carried over here: a conversion that wraps turns `-1e19` into a positive
  /// number, which is not an answer under any reading.
  @override
  int toInt() {
    final t = truncate();
    final base = t.base;
    if (base == 0) {
      return 0;
    }

    final exponent = -t.scale;
    if (exponent <= _maxPow10Exponent) {
      final power = _pow10(exponent);
      if (_productFits(base, power)) {
        return base * power;
      }
    }

    return base.isNegative ? -9223372036854775808 : 9223372036854775807;
  }

  /// Converts this decimal to [double].
  @override
  double toDouble() {
    final base = this.base;
    final scale = this.scale;

    // The same reasoning as in Decimal: a base of 53 bits and a power of ten
    // up to 10^22 are both exact in a double, so the division rounds once and
    // the answer is correctly rounded. Everything else goes through the string.
    if (scale >= -_maxExactPow10 &&
        scale <= _maxExactPow10 &&
        base >= -_maxExactInt &&
        base <= _maxExactInt) {
      final value = base.toDouble();
      final power = _doublePow10[scale.abs()];

      return scale >= 0 ? value / power : value * power;
    }

    return double.parse(toString());
  }

  /// The largest integer a double holds exactly: 2^53.
  static const _maxExactInt = 9007199254740992;

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
  int compareTo(ShortDecimal other) => _compare(other);

  /// Whether this decimal is equal to [other].
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is ShortDecimal) {
      return _compare(other) == 0;
    }

    return false;
  }

  /// Returns a hash code for this decimal.
  ///
  /// This is compatible with [operator ==]. It returns the same hashCode for
  /// decimal with the same value.
  @override
  int get hashCode => Object.hash(base, scale);

  /// The stored form, for a failing test to print.
  ///
  /// Not for production: this is the only place in the package that shows the
  /// pair a value is kept in.
  @visibleForTesting
  String debugToString() => '$ShortDecimal(base: $base, scale: $scale)';

  /// Returns a string representation of this decimal.
  ///
  /// `Decimal` keeps the printed form for the next call; this family does not.
  /// A field is out of the question — the class is `vm:deeply-immutable`, which
  /// admits only final non-late fields — and a table beside the objects was
  /// measured and rejected: it pays for a write on every first print, which is
  /// the print that happens most. The work here is on machine words anyway,
  /// not on BigInt.
  @override
  String toString() {
    final base = this.base;
    final scale = this.scale;
    final string = base.toString();
    if (scale == 0 || base == 0) {
      return string;
    }

    // Calculate the sign and string representation of the absolute value.
    //
    // We don't use `abs()` because of the problem:
    // -(-9223372036854775808) == -9223372036854775808
    final (sign, abs) = string.codeUnitAt(0) == _charCodeMinus
        ? ('-', string.substring(1))
        : ('', string);

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
      if (base != 0) {
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
  /// print(ShortDecimal.parse('1234.5').toStringAsExponential(2)); // 1.23e+3
  /// print(ShortDecimal.parse('0.00123').toStringAsExponential(1)); // 1.2e-3
  /// ```
  ///
  /// The leading digits are rounded as digits, so this notation costs the same
  /// whatever the scale is: `1e-1000000` prints as `1.00e-1000000` and nothing
  /// builds a power of ten to do it. Only the two ends of int64 refuse, and
  /// with them the [exponent] refuses too: past them the power of ten the
  /// leading digit sits at has no int64 to be named in.
  @override
  String toStringAsExponential([int fractionDigits = 0]) {
    _checkNonNegativeArgument(fractionDigits, 'fractionDigits');
    _checkDigits(fractionDigits, 'fractionDigits');

    if (isZero) {
      return '${zero.toStringAsFixed(fractionDigits)}e+0';
    }

    // The leading digit sits at this power of ten. The subtraction is checked
    // the way [exponent] checks its own: at the floor of the scale the power
    // is one no int64 names.
    final digits = _digits;
    var exponent = _scaleMinus(digits.length - 1, scale, 'scale');

    // The digits are rounded as digits, not by dividing the value: this
    // notation shows the leading ones and nothing else, and the power of ten a
    // division would need is the whole number over again. See [roundDigits].
    final (mantissaDigits, carried) = digits.roundDigits(fractionDigits + 1);

    // Rounding can carry into a new power of ten: 9.99 with one digit after
    // the point is 10.0, which is 1.0e+1 and not 10.0e+0.
    if (carried) {
      if (exponent == 9223372036854775807) {
        throw ScaleOutOfRangeError(scale, 'scale');
      }

      exponent++;
    }

    final mantissa = fractionDigits == 0
        ? mantissaDigits.substring(0, 1)
        : '${mantissaDigits.substring(0, 1)}.'
            '${mantissaDigits.substring(1).padRight(fractionDigits, '0')}';

    return '${isNegative ? '-' : ''}$mantissa'
        'e${exponent.isNegative ? '' : '+'}$exponent';
  }

  /// An engineering representation of this decimal with [fractionDigits]
  /// digits after the decimal point.
  ///
  /// The exponent is a multiple of three, so the mantissa carries one, two or
  /// three digits before the point — the form an SI prefix is read in.
  ///
  /// ```dart
  /// print(ShortDecimal.parse('12345').toStringAsEngineering(2)); // 12.35e+3
  /// print(ShortDecimal.parse('0.00001234').toStringAsEngineering(1)); // 12.3e-6
  /// ```
  ///
  /// Like [toStringAsExponential] it rounds the leading digits as digits and
  /// builds no power of ten, so what it costs does not grow with the scale. It
  /// refuses only where the exponent it would write is itself past int64 —
  /// which is later than [toStringAsExponential] refuses, the multiple of
  /// three below being the smaller number of the two.
  @override
  String toStringAsEngineering([int fractionDigits = 0]) {
    _checkNonNegativeArgument(fractionDigits, 'fractionDigits');
    _checkDigits(fractionDigits, 'fractionDigits');

    if (isZero) {
      return '${zero.toStringAsFixed(fractionDigits)}e+0';
    }

    final digits = _digits;

    // How far the leading digit stands above the multiple of three below it —
    // one, two or three integer digits for the mantissa. The power the leading
    // digit sits at can itself be past int64 while the exponent this notation
    // writes is not, so the remainder is taken apart rather than from it.
    final offset = ((digits.length - 1) % 3 - scale % 3 + 3) % 3;
    var exponent = _scaleMinus(digits.length - 1 - offset, scale, 'scale');
    var integerDigits = offset + 1;

    var mantissaDigits = digits.roundDigits(integerDigits + fractionDigits);

    // A carry takes the mantissa out of its group of three only when it had
    // three integer digits already: 99.9 rounds to 100 at the same exponent,
    // 999.9 rounds to 1000 and needs the next one.
    if (mantissaDigits.$2) {
      if (offset == 2) {
        if (exponent > 9223372036854775807 - 3) {
          throw ScaleOutOfRangeError(scale, 'scale');
        }

        exponent += 3;
        integerDigits = 1;
      } else {
        integerDigits++;
      }

      mantissaDigits = ('1', false);
    }

    final padded =
        mantissaDigits.$1.padRight(integerDigits + fractionDigits, '0');
    final mantissa = fractionDigits == 0
        ? padded
        : '${padded.substring(0, integerDigits)}'
            '.${padded.substring(integerDigits)}';

    return '${isNegative ? '-' : ''}$mantissa'
        'e${exponent.isNegative ? '' : '+'}$exponent';
  }

  /// A representation of this decimal with [precision] significant digits.
  ///
  /// ```dart
  /// print(ShortDecimal.parse('1234.5678').toStringAsPrecision(6)); // 1234.57
  /// print(ShortDecimal.parse('0.05').toStringAsPrecision(3)); // 0.0500
  /// ```
  ///
  /// Unlike [toStringAsExponential] this one writes the number out in full, so
  /// what it asks for is a position to round at — and a position is a number
  /// of digits like any other here: past a million of them, on either side of
  /// the point, it refuses. The digits the number already carries are not
  /// counted: [toString] writes them all, however many there are.
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

    final digits = _digits;
    var exponent = _scaleMinus(digits.length - 1, scale, 'scale');

    // The same carry as in toStringAsExponential: 9.99 at two digits is 10,
    // which needs one integer digit more and one fractional digit less. It is
    // read off the digits, so the value below is rounded once and not twice.
    if (digits.roundDigits(precision).$2) {
      if (exponent == 9223372036854775807) {
        throw ScaleOutOfRangeError(scale, 'scale');
      }

      exponent++;
    }

    // Unlike the exponential form this one writes the number out in full, so
    // the position it rounds at is a count of digits like any other the caller
    // asks for: past the million there is nothing to give back. The bound is
    // checked before the count is worked out, because the count itself wraps
    // at the far ends of the scale — and the wrapped number used to come back
    // named as the argument the caller passed.
    //
    // Both sides are bounded and each says which side it is: the position runs
    // away from the point in either direction, and a power of ten that far off
    // is the same number to build whichever way it went.
    if (exponent < precision - 1 - maxDecimalExponent) {
      throw DecimalDigitsOutOfRangeError(
        precision,
        'precision',
        'The number would need more than a million digits after the point',
      );
    }

    if (exponent > precision - 1 + maxDecimalExponent) {
      throw DecimalDigitsOutOfRangeError(
        precision,
        'precision',
        'The number would be rounded more than a million digits before the'
            ' point',
      );
    }

    final fractionDigits = precision - 1 - exponent;
    final value = round(fractionDigits);

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

    return text.codeUnitAt(0) == _charCodeMinus ? text.substring(1) : text;
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
      throw DecimalDigitsOutOfRangeError(value, name);
    }
  }

  /// Ten to the power of [exponent].
  ///
  /// Only the powers that fit into int64 are tabulated: 10^19 already wraps
  /// around into a negative number, and `math.pow` reports that silently.
  /// Callers that can be given a bigger exponent have to handle it themselves
  /// — see [_compareScaled] and [_dropFraction].
  ///
  /// Two callers still do not, and both mean it: [_align], where the wrap is
  /// this family's declared silent overflow and the operations that cannot
  /// afford it take [_alignOrNull] instead, and [toInt], where a value needing
  /// 10^19 has no int to be converted into anyway.
  static int _pow10(int exponent) {
    assert(exponent >= 0, "exponent can't be negative");

    return exponent <= _maxPow10Exponent
        ? _pow10Table[exponent]
        : math.pow(10, exponent) as int;
  }

  /// The largest integer a double holds exactly, `2^53`.
  static const _maxExactInDouble = 9007199254740992;

  /// The largest power of ten that fits into int64.
  static const _maxPow10Exponent = 18;

  /// Below this an approximate product is known to fit into int64.
  ///
  /// int.max is about 9.223·10^18, so the margin left for the rounding of a
  /// double is over 2·10^17.
  static const _productThreshold = 9.0e18;

  /// Powers of five, built the same way and for the same reason.
  ///
  /// Dividing by `2^n` is multiplying by `5^n` with the scale moved by `n`.
  static final List<int> _pow5Table = () {
    final table = List<int>.filled(_maxPow5Exponent + 1, 1);
    for (var i = 1; i < table.length; i++) {
      table[i] = table[i - 1] * 5;
    }

    return table;
  }();

  /// The largest base each power of five may be applied to.
  ///
  /// Asking `_productFits` instead cost the division path a fifth of its time:
  /// it multiplies doubles and sometimes divides, where a table turns the
  /// whole question into one comparison against a number already computed.
  static final List<int> _pow5Ceiling = List<int>.generate(
    _maxPow5Exponent + 1,
    (i) => 9223372036854775807 ~/ _pow5Table[i],
  );

  /// The same for the powers of two a divisor of fives is multiplied by.
  static final List<int> _pow2Ceiling = List<int>.generate(
    _maxPow5Exponent + 1,
    (i) => 9223372036854775807 >> i,
  );

  /// The largest power of five that fits into int64.
  static const _maxPow5Exponent = 27;

  /// Powers of ten from `10^0` to `10^_maxPow10Exponent`.
  ///
  /// Built rather than written out: the last three do not survive a round trip
  /// through a JavaScript number, and a literal would say they do.
  static final List<int> _pow10Table = () {
    final table = List<int>.filled(_maxPow10Exponent + 1, 1);
    for (var i = 1; i < table.length; i++) {
      table[i] = table[i - 1] * 10;
    }

    return table;
  }();

  /// [value] multiplied by `10^exponent`, or null when it does not fit int64.
  ///
  /// The test is deliberately conservative: `|value| < 10^(18 - exponent)`
  /// keeps the product below 10^18, well inside the range, and costs one table
  /// lookup and one comparison instead of a division.
  static int? _scaledOrNull(int value, int exponent) {
    if (value == 0) {
      return 0;
    }

    if (exponent > _maxPow10Exponent) {
      return null;
    }

    final limit = _pow10Table[_maxPow10Exponent - exponent];

    return value > -limit && value < limit
        ? value * _pow10Table[exponent]
        : null;
  }

  /// Compares [value] with `scaled * 10^exponent` without overflowing.
  ///
  /// The alignment of two decimals multiplies one of the bases by a power of
  /// ten, and that product is exactly what overflows int64 — silently, and
  /// with a change of sign at 10^19. Here the multiplication is done only when
  /// it is known to fit; otherwise the comparison is answered by dividing,
  /// which cannot overflow.
  static int _compareScaled(int value, int scaled, int exponent) {
    final product = _scaledOrNull(scaled, exponent);
    if (product != null) {
      return value.compareTo(product).sign;
    }

    // value == quotient * 10^exponent + remainder, and the two parts have the
    // same sign, so the answer is decided by the quotient and, when the
    // quotients match, by the remainder. Above 10^18 there is nothing to
    // divide by: any base is smaller than the divisor.
    final (quotient, remainder) = exponent > _maxPow10Exponent
        ? (0, value)
        : (
            value ~/ _pow10Table[exponent],
            value.remainder(_pow10Table[exponent]),
          );

    return quotient != scaled
        ? quotient.compareTo(scaled).sign
        : remainder.sign;
  }

  /// Compares this to [other] the way [compareTo] does, without aligning.
  ///
  /// Decimal has no such method: BigInt does not overflow, so there the plain
  /// alignment is both correct and shorter.
  int _compare(ShortDecimal other) {
    final as = scale;
    final bs = other.scale;

    if (as == bs) {
      return base.compareTo(other.base).sign;
    }

    // The saturation of [_scaleGap] written out rather than called: comparison
    // is on the hot path, and a call around two operations is not inlined —
    // the same reason the overflow check sits inside `operator *`. A gap taken
    // in the direction it grows comes back negative only when it left int64,
    // and a gap that wide is past every threshold [_compareScaled] has.
    if (as > bs) {
      final gap = as - bs;

      return _compareScaled(
        base,
        other.base,
        gap < 0 ? 9223372036854775807 : gap,
      );
    }

    final gap = bs - as;

    return -_compareScaled(
      other.base,
      base,
      gap < 0 ? 9223372036854775807 : gap,
    );
  }

  /// The distance from this scale to [other]'s, saturated where the
  /// subtraction leaves int64.
  ///
  /// `int.max - (-1)` wraps to the minimum integer, and the wrapped number
  /// went on to index the table of powers: every operation that aligns fell
  /// over with a `RangeError`, `operator ==` among them. A gap that wide is
  /// past every threshold this family has, so the saturated one answers the
  /// same question the exact one would. It saturates to plus or minus
  /// `int.max` rather than to `int.min`, so that negating it is safe.
  int _scaleGap(ShortDecimal other) {
    final as = scale;
    final bs = other.scale;
    final gap = as - bs;

    if ((as ^ bs) < 0 && (gap ^ as) < 0) {
      return as.isNegative ? -9223372036854775807 : 9223372036854775807;
    }

    // The floor of int64 is a gap the subtraction reaches without overflowing
    // — a scale of minus one against one at the ceiling — and every reader
    // here negates the gap to look at it the other way round. Negating the
    // floor gives the floor back, and the negative that came out of it indexed
    // the table of powers. One short of the floor is past every threshold in
    // this file just the same.
    return gap == -9223372036854775808 ? -9223372036854775807 : gap;
  }

  /// The two bases brought to a common scale, or null when the shift itself
  /// does not fit into int64.
  ///
  /// [_align] shifts with [_pow10], which wraps silently past an exponent of
  /// eighteen — and wraps the base of whichever operand had the smaller scale,
  /// which is the one that was not going to move the answer. Where the answer
  /// is still representable, callers fall back to [_alignExactly].
  (int, int, int)? _alignOrNull(ShortDecimal other) {
    final gap = _scaleGap(other);

    if (gap == 0) {
      return (base, other.base, scale);
    }

    if (gap > 0) {
      final scaled = _scaledOrNull(other.base, gap);

      return scaled == null ? null : (base, scaled, scale);
    }

    final scaled = _scaledOrNull(base, -gap);

    return scaled == null ? null : (scaled, other.base, other.scale);
  }

  /// The same pair in `BigInt`, where the shift cannot overflow.
  ///
  /// The road [_alignOrNull] falls back to. A scale gap wider than eighteen
  /// leaves int64 behind, but the answer to the operation that needed the
  /// alignment often does not: `2e19 ~/ 4` is `5e18`, and int64 holds it with
  /// room to spare.
  (BigInt, BigInt, int) _alignExactly(ShortDecimal other) {
    final gap = _scaleGap(other);
    final a = BigInt.from(base);
    final b = BigInt.from(other.base);

    if (gap == 0) {
      return (a, b, scale);
    }

    return gap > 0
        ? (a, b * _bigInt10Power(gap), scale)
        : (a * _bigInt10Power(-gap), b, other.scale);
  }

  /// Ten to [exponent] in `BigInt`, held to the bound the package holds
  /// everywhere else.
  ///
  /// The second place in the package that builds a power of ten, and the only
  /// one that had no bound: a scale gap of ten million asked for a number of
  /// ten million digits and the operation never came back. The BigInt family
  /// refuses the same gap on the same operations, and refuses it at this same
  /// million — `Decimal(1, shiftRight: 1000001) % Decimal(3)` always has. Now
  /// the two families agree; below the bound nothing changes.
  ///
  /// The gaps that carry an answer do not come here at all: past eighteen the
  /// side being scaled up is larger than any int64 the other side holds, and
  /// the operations that only need to know which side is larger say so
  /// themselves.
  static BigInt _bigInt10Power(int exponent) {
    if (exponent > maxDecimalExponent) {
      throw DecimalDigitsOutOfRangeError(
        exponent,
        'exponent',
        'Ten to this power is a number too large to build',
      );
    }

    return _bigInt10.pow(exponent);
  }

  (int, int, int) _align(ShortDecimal other) {
    final as = scale;
    final bs = other.scale;

    if (as == bs) {
      return (base, other.base, as);
    }

    // Written out rather than called, like the check in `operator *`: this is
    // the alignment addition and subtraction take, and they are the hottest
    // thing in the family. Two gaps get no power of ten built for them — the
    // one that wrapped, which comes back negative, and the one past the
    // sixty-fourth power. Both multiply by nothing: ten to the n carries two
    // to the n, and past the sixty-fourth that leaves nothing in int64. The
    // wrapping did the same before, only slower and by accident.
    if (as > bs) {
      final gap = as - bs;

      return (base, other.base * (gap < 0 || gap > 63 ? 0 : _pow10(gap)), as);
    }

    final gap = bs - as;

    return (base * (gap < 0 || gap > 63 ? 0 : _pow10(gap)), other.base, bs);
  }

  /// The rules the six rounding methods hand to [_dropFraction].
  ///
  /// Static rather than closures over `this`: a closure is an object, and two
  /// of them were allocated on every rounding — one for the step, one for the
  /// road past the divisor. A static tear-off is a constant, so the same call
  /// now allocates nothing. It cost `round` a sixth of its time, measured;
  /// the base is passed in because that is all either rule ever needed.
  static int _floorStep(int base, int result, int divisor) =>
      base.isNegative && base % divisor != 0 ? result - 1 : result;

  static int _floorWide(int base, int exponent) => base.isNegative ? -1 : 0;

  static int _roundStep(int base, int result, int divisor) {
    final remainder = base.remainder(divisor).abs();

    return remainder >= divisor - remainder ? result + base.sign : result;
  }

  /// Half of the divisor still fits into int64 at the exponent of 19 only:
  /// 10^19 / 2 is 5·10^18 while int64 holds about 9.22·10^18. Above that every
  /// base is closer to zero than to the divisor.
  static int _roundWide(int base, int exponent) {
    if (exponent > _maxPow10Exponent + 1) {
      return 0;
    }

    // The same as |base| >= 5·10^18, written without a number that a
    // JavaScript one cannot hold.
    final halves = base ~/ _pow10Table[_maxPow10Exponent];

    return halves >= 5 || halves <= -5 ? base.sign : 0;
  }

  static int _roundToEvenStep(int base, int result, int divisor) {
    final remainder = base.remainder(divisor).abs();
    final rest = divisor - remainder;

    // Below a half it stays, above a half it moves, and exactly a half moves
    // only when staying would leave an odd number behind.
    if (remainder < rest || (remainder == rest && result.isEven)) {
      return result;
    }

    return result + base.sign;
  }

  /// The quotient here is zero, which is even, so an exact half would stay
  /// where it is. It cannot arise: a half at this exponent needs a base ending
  /// in zeros, and the stored form has none — so anything reaching five halves
  /// is already past a half.
  static int _roundToEvenWide(int base, int exponent) =>
      _roundWide(base, exponent);

  static int _ceilStep(int base, int result, int divisor) =>
      !base.isNegative && base % divisor != 0 ? result + 1 : result;

  static int _ceilWide(int base, int exponent) =>
      !base.isNegative && base != 0 ? 1 : 0;

  static int _truncateStep(int base, int result, int divisor) => result;

  static int _truncateWide(int base, int exponent) => 0;

  static int _awayFromZeroStep(int base, int result, int divisor) =>
      base % divisor != 0 ? result + base.sign : result;

  static int _awayFromZeroWide(int base, int exponent) => base.sign;

  ShortDecimal _dropFraction(
    int fractionDigits,
    int Function(int base, int result, int divisor) callback, {
    required int Function(int base, int exponent) onDivisorOverflow,
  }) {
    _checkDigits(fractionDigits, 'fractionDigits');

    if (scale <= fractionDigits) {
      return this;
    }

    final exponent = scale - fractionDigits;

    // The exponent is a difference of two int64 numbers and can leave int64
    // itself: a scale at the ceiling with a negative number of digits asks for
    // a power past everything, and the wrapped one indexed the table with a
    // negative number. Either way the whole value stands to the right of the
    // position asked for, which is the road below.
    final wide = (scale ^ fractionDigits) < 0 && (exponent ^ scale) < 0;

    // There is no divisor to divide by above 10^18, and no need for one: it is
    // bigger than any base, so the quotient is zero and the remainder is the
    // whole base. What is left is the rule of the calling method.
    if (wide || exponent > _maxPow10Exponent) {
      return ShortDecimal._pack(
        onDivisorOverflow(base, wide ? 9223372036854775807 : exponent),
        fractionDigits,
      );
    }

    final divisor = _pow10(exponent);
    final result = callback(base, base ~/ divisor, divisor);

    return ShortDecimal._pack(result, fractionDigits);
  }
}

/// Thrown by [ShortDecimal.operator /] when the result has no finite decimal
/// form.
///
/// One divided by three cannot be written down in full, and the package does
/// not round behind the caller's back. The exception carries everything that
/// could have been wanted instead of the exact answer, so that catching it is a
/// way of asking again rather than a dead end:
///
/// ```dart
/// try {
///   print(ShortDecimal(1) / ShortDecimal(3));
/// } on ShortDecimalDivideException catch (e) {
///   print(e.fraction); // 1/3
///   print(e.round(4)); // 0.3333
/// }
/// ```
///
/// Catching is the slow way round, though: [ShortDecimal.divideOrNull] asks the
/// same question more than a hundred times faster — a throw costs about a
/// microsecond, an int64 division a few nanoseconds — and [ShortDecimal.divide]
/// rounds in one call.
final class ShortDecimalDivideException implements Exception {
  /// The number that was divided.
  final ShortDecimal dividend;

  /// The number it was divided by.
  final ShortDecimal divisor;

  const ShortDecimalDivideException._(this.dividend, this.divisor);

  /// Builds an instance directly; the package raises the real ones itself.
  ///
  /// Refuses a zero divisor. The package never raises this exception for one —
  /// division by zero throws [UnsupportedError] long before — and an instance
  /// holding one would answer every one of its own questions, [toString]
  /// included, by throwing. An exception whose message cannot be read is the
  /// worst thing to meet inside a `catch`.
  @visibleForTesting
  ShortDecimalDivideException.forTest(this.dividend, this.divisor) {
    if (divisor.isZero) {
      throw ArgumentError.value(
        divisor,
        'divisor',
        'The value must not be zero',
      );
    }
  }

  /// The exact result, as a fraction.
  ShortFraction get fraction => dividend.divideToFraction(divisor);

  /// The whole quotient and what is left of the dividend.
  ShortDivision get quotientWithRemainder =>
      dividend.divideWithRemainder(divisor);

  /// The exact result rounded towards minus infinity, [fractionDigits] digits.
  ShortDecimal floor([int fractionDigits = 0]) =>
      _rounded(fractionDigits, _Rounding.floor);

  /// The exact result rounded to [fractionDigits] digits, halves away from
  /// zero.
  ShortDecimal round([int fractionDigits = 0]) =>
      _rounded(fractionDigits, _Rounding.round);

  /// The exact result rounded to [fractionDigits] digits, halves to even.
  ShortDecimal roundToEven([int fractionDigits = 0]) =>
      _rounded(fractionDigits, _Rounding.roundToEven);

  /// The exact result rounded towards plus infinity, [fractionDigits] digits.
  ShortDecimal ceil([int fractionDigits = 0]) =>
      _rounded(fractionDigits, _Rounding.ceil);

  /// The exact result with everything past [fractionDigits] digits cut off.
  ShortDecimal truncate([int fractionDigits = 0]) =>
      _rounded(fractionDigits, _Rounding.truncate);

  /// The exact result rounded away from zero, [fractionDigits] digits.
  ShortDecimal roundAwayFromZero([int fractionDigits = 0]) =>
      _rounded(fractionDigits, _Rounding.awayFromZero);

  /// The pair this exception was raised on, rounded as it is.
  ///
  /// Not through [fraction]: a divisor of 2^63 leaves the denominator nowhere
  /// to be positive, so `1 / int.min` has no fraction in int64 — while its
  /// rounded value is an ordinary number, and refusing to give it turned every
  /// way of asking again into a dead end. The pair is rounded on the road
  /// [ShortDecimal.divide] takes for the same case.
  ShortDecimal _rounded(int fractionDigits, _Rounding rounding) {
    ShortDecimal._checkDigits(fractionDigits, 'fractionDigits');

    // The same short road [ShortDecimal.divide] takes, and for the same
    // reason: past that gap the exact result is smaller in magnitude than half
    // the last digit asked for, so the quotient is nothing and only the rule
    // of the mode can move it — a floor takes it to minus one of the last
    // digit, a ceiling to one. Found out from the scales, without building a
    // power of ten of the width of the gap.
    final gap = dividend._scaleGap(divisor);
    if (gap > ShortDecimal._maxPow10Exponent && gap - 20 >= fractionDigits) {
      return ShortDecimal._pack(
        // A remainder there is, and half of the last digit it is not. The
        // quotient is zero, which is even — the default the rest of the file
        // relies on too.
        rounding.correction(
          sign: dividend.base.sign * divisor.base.sign,
          hasRemainder: true,
          atLeastHalf: false,
        ),
        fractionDigits,
      );
    }

    final (numerator, denominator) = dividend._fractionPair(divisor);

    return ShortFraction._roundExactly(
      numerator,
      denominator,
      fractionDigits,
      rounding,
    );
  }

  @override
  String toString() {
    // Never throws: an exception that cannot be printed hides the very
    // failure it reports, and its own dartdoc promises a way of asking again
    // rather than a dead end. Every line that needs building is built
    // defensively — the pair is always there, the rest may not be.
    final buffer = StringBuffer('$ShortDecimalDivideException:'
        ' The result of division cannot be represented as $ShortDecimal:');

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

/// Conversion from `int`.
extension ShortDecimalIntExtension on int {
  /// This integer as a [ShortDecimal].
  ///
  /// ```dart
  /// print(42.toShortDecimal()); // 42
  /// ```
  ShortDecimal toShortDecimal() => ShortDecimal._pack(this, 0);
}
