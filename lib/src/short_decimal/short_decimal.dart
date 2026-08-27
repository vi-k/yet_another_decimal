import 'dart:math' as math;

import 'package:meta/meta.dart';

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
/// does not fit in int64 wraps round instead of throwing. Where the magnitudes
/// are not known in advance, use `Decimal`, which has no such limit, and cross
/// over with `toDecimal()` when it turns out to be needed.
///
/// Division is the one operation that cannot always answer — one third has no
/// finite decimal form. [divideOrNull] returns null there, [divide] rounds to
/// as many digits as it is told, [isDivisibleBy] asks the question in advance,
/// and [operator /] throws [ShortDecimalDivideException].
///
/// One bound beside the width of int64: a number of digits. Rounding,
/// printing, an inexact division and a shift all take one, and past a million
/// the power of ten behind it is a number nobody can hold —
/// `round(-1000000000)` asks for ten to the billionth. Such a request is
/// refused with `ArgumentError`, and `ShortDecimal.parse` refuses to read a
/// number that would need one.
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

    while (base % 10 == 0) {
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
  @override
  int get exponent => -scale;

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
  @override
  ShortDecimal operator -() => ShortDecimal._asIs(-base, scale);

  /// Adds [other] to this decimal.
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

    return ShortDecimal._pack(a + b, scale);
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

    return ShortDecimal._pack(a - b, scale);
  }

  /// Multiplies this decimal by [other].
  @override
  ShortDecimal operator *(ShortDecimal other) {
    final a = base;
    final b = other.base;

    // The approximate product decides the common case: a double is off by a
    // part in 2^52 at worst, which against the gap between the threshold and
    // int.max — more than 2·10^17 — is nothing. Everything close to the
    // boundary goes the careful way, where the check costs a division.
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
      throw ArgumentError.value(by, name, _scaleOutOfRange);
    }

    return _checkedScale(result, by, name);
  }

  /// The scale moved the other way, with the same refusal.
  static int _scaleMinus(int scale, int by, String name) {
    final result = scale - by;
    if ((scale ^ by) < 0 && (result ^ scale) < 0) {
      throw ArgumentError.value(by, name, _scaleOutOfRange);
    }

    return _checkedScale(result, by, name);
  }

  /// The scale repeated [by] times, with the same refusal.
  static int _scaleTimes(int scale, int by, String name) {
    if (scale == 0 || by == 0) {
      return 0;
    }

    final result = scale * by;
    // The wrap is caught before the range and not by it: two times int.max
    // lands on minus two, which is inside the range and is not the answer.
    if (result ~/ by != scale) {
      throw ArgumentError.value(by, name, _scaleOutOfRange);
    }

    return _checkedScale(result, by, name);
  }

  /// The scale, if a number carrying it can still be printed and rounded.
  ///
  /// The bound is the one the BigInt family needs — a scale is a power of ten
  /// waiting to be built — and this family keeps it for the sake of one
  /// contract, not because int64 minds: printing a scale of a billion asks for
  /// a billion characters here just as it asks for a billion digits there.
  static int _checkedScale(int scale, int argument, String name) {
    if (scale < -maxDecimalExponent || scale > maxDecimalExponent) {
      throw ArgumentError.value(argument, name, _scaleOutOfRange);
    }

    return scale;
  }

  static const _scaleOutOfRange =
      'The scale must stay within a million of zero';

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
    var scale = this.scale - other.scale;

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

        if (twos <= _maxPow5Exponent) {
          base *= _pow5Table[twos];
        } else {
          // 5^28 does not fit int64, so neither does the result. Overflow
          // stays silent here, as everywhere else in this family.
          for (var i = 0; i < twos; i++) {
            base *= 5;
          }
        }

        scale += twos;
      } else if (divisor % 5 == 0) {
        var fives = 0;
        do {
          divisor = divisor ~/ 5;
          fives++;
        } while (divisor % 5 == 0);

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

    final (dividend, divisor) = _fractionPair(other);
    final fraction = ShortFraction._orNull(dividend, divisor);
    if (fraction != null) {
      return fraction.round(scaleOnInfinitePrecision);
    }

    // A divisor of 2^63 has no fraction to be rounded: int64 has no room for
    // that denominator with a positive sign. The rounded quotient is an
    // ordinary number all the same, so it is taken from the pair itself.
    return ShortFraction._roundExactly(
      BigInt.from(dividend),
      BigInt.from(divisor),
      scaleOnInfinitePrecision,
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

    return ShortFraction(dividend, divisor);
  }

  /// The pair a fraction of this division is built from.
  (int, int) _fractionPair(ShortDecimal other) {
    if (other.isZero) {
      throw UnsupportedError('division by zero');
    }

    final aligned = _alignOrNull(other);
    if (aligned != null) {
      final (dividend, divisor, _) = aligned;

      return (dividend, divisor);
    }

    // Reduced first: the aligned pair can leave int64 while the same ratio in
    // lowest terms fits it comfortably.
    final (a, b, _) = _alignExactly(other);
    final gcd = a.fastGcd(b);

    return ((a ~/ gcd).toInt(), (b ~/ gcd).toInt());
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
        (result, divisor) =>
            isNegative && base % divisor != 0 ? result - 1 : result,
        onDivisorOverflow: (_) => isNegative ? -1 : 0,
      );

  /// Rounds to the closest decimal with [fractionDigits].
  @override
  ShortDecimal round([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) {
          final remainder = base.remainder(divisor).abs();
          return remainder >= divisor - remainder ? result + base.sign : result;
        },
        onDivisorOverflow: (exponent) {
          // Half of the divisor still fits into int64 at the exponent of
          // 19 only: 10^19 / 2 is 5·10^18 while int64 holds about
          // 9.22·10^18. Above that every base is closer to zero than to the
          // divisor.
          if (exponent > _maxPow10Exponent + 1) {
            return 0;
          }

          // The same as |base| >= 5·10^18, written without a number that a
          // JavaScript one cannot hold.
          final halves = base ~/ _pow10Table[_maxPow10Exponent];

          return halves >= 5 || halves <= -5 ? base.sign : 0;
        },
      );

  /// Rounds the decimal towards infinity to [fractionDigits].
  @override
  ShortDecimal ceil([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) =>
            !isNegative && base % divisor != 0 ? result + 1 : result,
        onDivisorOverflow: (_) => !isNegative && base != 0 ? 1 : 0,
      );

  /// Rounds the decimal towards zero to [fractionDigits].
  @override
  ShortDecimal truncate([int fractionDigits = 0]) => _dropFraction(
        fractionDigits,
        (result, divisor) => result,
        onDivisorOverflow: (_) => 0,
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
  /// finite decimal form, [UnsupportedError] on zero.
  ///
  /// ```dart
  /// print(ShortDecimal(2).pow(-2)); // 0.25
  /// ```
  @override
  ShortDecimal pow(int exponent) {
    if (exponent >= 0) {
      return ShortDecimal._pack(
        math.pow(base, exponent) as int,
        _scaleTimes(scale, exponent, 'exponent'),
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
      if (scale >= 0) {
        return ShortFraction(power, base);
      }

      final denominator = _productOrNull(base, power);
      if (denominator != null) {
        return ShortFraction(1, denominator);
      }
    }

    throw UnsupportedError('The inverse of $this has no fraction in int64');
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

    return truncated.scale < 0
        ? base * BigInt.from(10).pow(-truncated.scale)
        : base;
  }

  /// Returns [int], discarding all fractional digits from this decimal.
  @override
  int toInt() {
    final t = truncate();

    return t.base * _pow10(-t.scale);
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
  /// Decimal keeps the printed form for the next call; this family cannot.
  /// Its constructors are const — `zero`, `one`, `two` and `ten` are compile
  /// time constants — and a const object has no field to write into. The work
  /// here is on machine words anyway, not on BigInt.
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
  /// print(ShortDecimal.parse('1234.5678').toStringAsPrecision(6)); // 1234.57
  /// print(ShortDecimal.parse('0.05').toStringAsPrecision(3)); // 0.0500
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
      throw ArgumentError.value(
        value,
        name,
        'The number of digits must be within a million of zero',
      );
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

    return as > bs
        ? _compareScaled(base, other.base, as - bs)
        : -_compareScaled(other.base, base, bs - as);
  }

  /// The two bases brought to a common scale, or null when the shift itself
  /// does not fit into int64.
  ///
  /// [_align] shifts with [_pow10], which wraps silently past an exponent of
  /// eighteen — and wraps the base of whichever operand had the smaller scale,
  /// which is the one that was not going to move the answer. Where the answer
  /// is still representable, callers fall back to [_alignExactly].
  (int, int, int)? _alignOrNull(ShortDecimal other) {
    final as = scale;
    final bs = other.scale;

    if (as == bs) {
      return (base, other.base, as);
    }

    if (as > bs) {
      final scaled = _scaledOrNull(other.base, as - bs);

      return scaled == null ? null : (base, scaled, as);
    }

    final scaled = _scaledOrNull(base, bs - as);

    return scaled == null ? null : (scaled, other.base, bs);
  }

  /// The same pair in `BigInt`, where the shift cannot overflow.
  ///
  /// The road [_alignOrNull] falls back to. A scale gap wider than eighteen
  /// leaves int64 behind, but the answer to the operation that needed the
  /// alignment often does not: `2e19 ~/ 4` is `5e18`, and int64 holds it with
  /// room to spare.
  (BigInt, BigInt, int) _alignExactly(ShortDecimal other) {
    final as = scale;
    final bs = other.scale;
    final a = BigInt.from(base);
    final b = BigInt.from(other.base);

    if (as == bs) {
      return (a, b, as);
    }

    return as > bs
        ? (a, b * _bigInt10.pow(as - bs), as)
        : (a * _bigInt10.pow(bs - as), b, bs);
  }

  (int, int, int) _align(ShortDecimal other) {
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

  ShortDecimal _dropFraction(
    int fractionDigits,
    int Function(int result, int divisor) callback, {
    required int Function(int exponent) onDivisorOverflow,
  }) {
    _checkDigits(fractionDigits, 'fractionDigits');

    if (scale <= fractionDigits) {
      return this;
    }

    final exponent = scale - fractionDigits;

    // There is no divisor to divide by above 10^18, and no need for one: it is
    // bigger than any base, so the quotient is zero and the remainder is the
    // whole base. What is left is the rule of the calling method.
    if (exponent > _maxPow10Exponent) {
      return ShortDecimal._pack(onDivisorOverflow(exponent), fractionDigits);
    }

    final divisor = _pow10(exponent);
    final result = callback(base ~/ divisor, divisor);

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
      fraction.floor(fractionDigits);

  /// The exact result rounded to [fractionDigits] digits, halves away from
  /// zero.
  ShortDecimal round([int fractionDigits = 0]) =>
      fraction.round(fractionDigits);

  /// The exact result rounded towards plus infinity, [fractionDigits] digits.
  ShortDecimal ceil([int fractionDigits = 0]) => fraction.ceil(fractionDigits);

  /// The exact result with everything past [fractionDigits] digits cut off.
  ShortDecimal truncate([int fractionDigits = 0]) =>
      fraction.truncate(fractionDigits);

  @override
  String toString() => '$ShortDecimalDivideException:'
      ' The result of division cannot be represented as $ShortDecimal:'
      '\n$dividend / $divisor = $quotientWithRemainder'
      '\n$dividend / $divisor = $fraction';
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
