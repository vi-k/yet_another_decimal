import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../helpers.dart';

part 'short_fraction.dart';
part 'short_division.dart';

@immutable
final class ShortDecimal implements Comparable<ShortDecimal> {
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

  @visibleForTesting
  final int base;

  @visibleForTesting
  final int scale;

  /// Returns [ShortDecimal] from integer [base].
  ///
  /// Parameter [shiftRight] shifts [base] to the right relative to the decimal
  /// point:
  ///
  /// ```dart
  /// Decimal(1); // 1
  /// Decimal(1, shiftRight: 1); // 0.1
  /// Decimal(1, shiftRight: 2); // 0.01
  /// ```
  ///
  /// Parameter [shiftLeft] shifts [base] to the left relative to the decimal
  /// point:
  ///
  /// ```dart
  /// Decimal(1); // 1
  /// Decimal(1, shiftLeft: 1); // 10
  /// Decimal(1, shiftLeft: 2); // 100
  /// ```
  factory ShortDecimal(int base, {int shiftLeft = 0, int shiftRight = 0}) {
    assert(
      shiftLeft == 0 || shiftRight == 0,
      'Use either `shiftLeft` or `shiftRight`',
    );
    assert(
      shiftLeft >= 0,
      'Use `shiftRight` instead of the negative `shiftLeft`',
    );
    assert(
      shiftRight >= 0,
      'Use `shiftLeft` instead of the negative `shiftRight`',
    );

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
  /// Returns null on failure.
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

  /// Returns number of digits after the decimal point.
  int get fractionDigits {
    final scale = this.scale;
    return scale >= 0 ? scale : 0;
  }

  /// Returns the sign of this decimal.
  ///
  /// Returns 0 for zero, -1 for values less than zero and +1 for values
  /// greater than zero.
  int get sign => base.sign;

  /// Whether this decimal is negative.
  bool get isNegative => base.isNegative;

  /// Whether this decimal is an integer.
  bool get isInteger => scale <= 0;

  /// Whether this decimal is zero.
  bool get isZero => base == 0;

  /// Returns the negative value of this decimal.
  ShortDecimal operator -() => ShortDecimal._asIs(-base, scale);

  /// Adds [other] to this decimal.
  ShortDecimal operator +(ShortDecimal other) {
    final (a, b, scale) = _align(other);

    return ShortDecimal._pack(a + b, scale);
  }

  /// Subtracts [other] from this decimal.
  ShortDecimal operator -(ShortDecimal other) {
    final (a, b, scale) = _align(other);

    return ShortDecimal._pack(a - b, scale);
  }

  /// Multiplies this decimal by [other].
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
  /// decimal with a finite number of digits.
  ShortDecimal operator /(ShortDecimal other) {
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
      // Every ten in the divisor is a shift of the scale and nothing more.
      while (divisor % 10 == 0) {
        divisor = divisor ~/ 10;
        scale++;
      }

      // What is left is either odd or free of fives, so only one of the two
      // steps below does anything.
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
        throw ShortDecimalDivideException._(this, other);
      }
    }

    return ShortDecimal._pack(negate ? -base : base, scale);
  }

  /// Performs truncating division of this decimal by [other].
  ///
  /// Truncating division is division where a fractional result is converted to
  /// an integer by rounding towards zero.
  int operator ~/(ShortDecimal other) {
    final (a, b, _) = _align(other);

    return a ~/ b;
  }

  /// Calculates the result of division as double.
  ///
  /// Decimal needs a scaled division here to keep the ratio out of NaN; this
  /// family does not: both ends of the fraction are int64 and always convert.
  double divideToDouble(ShortDecimal other) {
    final fraction = divideToFraction(other);

    return fraction.numerator / fraction.denominator;
  }

  /// Calculates the result of division as fraction.
  ShortFraction divideToFraction(ShortDecimal other) {
    final (dividend, divisor, _) = _align(other);

    return ShortFraction(dividend, divisor);
  }

  /// Calculates the result of division as an integer quotient and remainder.
  ShortDivision divideWithRemainder(ShortDecimal other) =>
      ShortDivision(this, other);

  /// Euclidean modulo of this number by [other].
  ///
  /// The sign of the returned value is always positive.
  ShortDecimal operator %(ShortDecimal other) {
    final (a, b, scale) = _align(other);

    return ShortDecimal._pack(a % b, scale);
  }

  /// The remainder of the truncating division of this by [other].
  ///
  /// The result r of this operation satisfies:
  /// this == (this ~/ other) * other + r. As a consequence, the remainder r
  /// has the same sign as the dividend this.
  ShortDecimal remainder(ShortDecimal other) {
    final (a, b, scale) = _align(other);

    return ShortDecimal._pack(a.remainder(b), scale);
  }

  /// Whether this decimal is smaller than [other].
  bool operator <(ShortDecimal other) => _compare(other) < 0;

  /// Whether this decimal is smaller than or equal to [other].
  bool operator <=(ShortDecimal other) => _compare(other) <= 0;

  /// Whether this decimal is greater than [other].
  bool operator >(ShortDecimal other) => _compare(other) > 0;

  /// Whether this decimal is greater than or equal to [other].
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
  ShortDecimal operator <<(int shiftAmount) =>
      base == 0 ? this : ShortDecimal._asIs(base, scale - shiftAmount);

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
  ShortDecimal operator >>(int shiftAmount) =>
      base == 0 ? this : ShortDecimal._pack(base, scale + shiftAmount);

  /// Returns the absolute value of this decimal.
  ///
  /// Integer overflow may cause the result of -value to stay negative:
  ///
  /// ```dart
  /// print(ShortDecimal(-9223372036854775808).abs() ==
  ///     ShortDecimal(-9223372036854775808)); // true
  /// ```
  ShortDecimal abs() =>
      base.isNegative ? ShortDecimal._asIs(-base, scale) : this;

  /// Rounds the decimal towards negative infinity to [fractionDigits].
  ShortDecimal floor([int fractionDigits = 0]) => _dropFraction(
    fractionDigits,
    (result, divisor) =>
        isNegative && base % divisor != 0 ? result - 1 : result,
    onDivisorOverflow: (_) => isNegative ? -1 : 0,
  );

  /// Rounds to the closest decimal with [fractionDigits].
  ShortDecimal round([int fractionDigits = 0]) => _dropFraction(
    fractionDigits,
    (result, divisor) {
      final remainder = base.remainder(divisor).abs();
      return remainder >= divisor - remainder ? result + base.sign : result;
    },
    onDivisorOverflow: (exponent) {
      // Half of the divisor still fits into int64 at the exponent of 19 only:
      // 10^19 / 2 is 5·10^18 while int64 holds about 9.22·10^18. Above that
      // every base is closer to zero than to the divisor.
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
  ShortDecimal ceil([int fractionDigits = 0]) => _dropFraction(
    fractionDigits,
    (result, divisor) =>
        !isNegative && base % divisor != 0 ? result + 1 : result,
    onDivisorOverflow: (_) => !isNegative && base != 0 ? 1 : 0,
  );

  /// Rounds the decimal towards zero to [fractionDigits].
  ShortDecimal truncate([int fractionDigits = 0]) => _dropFraction(
    fractionDigits,
    (result, divisor) => result,
    onDivisorOverflow: (_) => 0,
  );

  /// Returns this decimal clamped to be in the range [lowerLimit]-[upperLimit].
  ///
  /// The arguments [lowerLimit] and [upperLimit] must form a valid range where
  /// lowerLimit <= upperLimit.
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
  ShortDecimal pow(int exponent) {
    if (exponent >= 0) {
      return ShortDecimal._pack(
        math.pow(base, exponent) as int,
        scale * exponent,
      );
    }

    // The minimum integer has no positive counterpart to raise to.
    if (exponent == -exponent) {
      throw ArgumentError.value(exponent, 'exponent', 'The value is too small');
    }

    return one / pow(-exponent);
  }

  /// The number of digits in the unscaled value.
  ///
  /// Zero has a precision of one, the same as `decimal` reports.
  ///
  /// ```dart
  /// print(ShortDecimal.parse('0').precision); // 1
  /// print(ShortDecimal.parse('1.5').precision); // 2
  /// print(ShortDecimal.parse('0.05').precision); // 3
  /// ```
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
  bool get isPositive => base.sign > 0;

  /// One divided by this decimal, as an exact [ShortFraction].
  ///
  /// A fraction rather than a decimal because the inverse of three has no
  /// finite decimal form.
  ///
  /// Throws [UnsupportedError] if this decimal is zero.
  ShortFraction get inverse => scale >= 0
      ? ShortFraction(_pow10(scale), base)
      : ShortFraction(1, base * _pow10(-scale));

  /// A JSON representation of this decimal: the string [toString] returns.
  String toJson() => toString();

  /// Returns [BigInt], discarding all fractional digits from this decimal.
  ///
  /// Unlike [toInt] this one never overflows: a decimal shifted far to the
  /// left holds a value no int64 can.
  BigInt toBigInt() {
    final truncated = truncate();
    final base = BigInt.from(truncated.base);

    return truncated.scale < 0
        ? base * BigInt.from(10).pow(-truncated.scale)
        : base;
  }

  /// Returns [int], discarding all fractional digits from this decimal.
  int toInt() {
    final t = truncate();

    return t.base * _pow10(-t.scale);
  }

  /// Converts this decimal to [double].
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

  /// Returns a string representation of this decimal using new
  /// [fractionDigits].
  ///
  /// If [fractionDigits] is less than `this.fractionDigits`, the [round]
  /// method is used.
  String toStringAsFixed(int fractionDigits) {
    _checkNonNegativeArgument(fractionDigits, 'fractionDigits');

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
  String toStringAsExponential([int fractionDigits = 0]) {
    _checkNonNegativeArgument(fractionDigits, 'fractionDigits');

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
  String toStringAsPrecision(int precision) {
    if (precision <= 0) {
      throw ArgumentError.value(
        precision,
        'precision',
        'The value must be > 0',
      );
    }

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

  /// Ten to the power of [exponent].
  ///
  /// Only the powers that fit into int64 are tabulated: 10^19 already wraps
  /// around into a negative number, and `math.pow` reports that silently.
  /// Callers that can be given a bigger exponent have to handle it themselves
  /// — see [_compareScaled] and [_dropFraction].
  static int _pow10(int exponent) {
    assert(exponent >= 0, "exponent can't be negative");

    // TODO(vi.k): ShortFraction is the last caller that can overflow here.
    return exponent <= _maxPow10Exponent
        ? _pow10Table[exponent]
        : math.pow(10, exponent) as int;
  }

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

final class ShortDecimalDivideException implements Exception {
  final ShortDecimal dividend;
  final ShortDecimal divisor;

  const ShortDecimalDivideException._(this.dividend, this.divisor);

  @visibleForTesting
  ShortDecimalDivideException.forTest(this.dividend, this.divisor);

  ShortFraction get fraction => dividend.divideToFraction(divisor);

  ShortDivision get quotientWithRemainder =>
      dividend.divideWithRemainder(divisor);

  ShortDecimal floor([int fractionDigits = 0]) =>
      fraction.floor(fractionDigits);

  ShortDecimal round([int fractionDigits = 0]) =>
      fraction.round(fractionDigits);

  ShortDecimal ceil([int fractionDigits = 0]) => fraction.ceil(fractionDigits);

  ShortDecimal truncate([int fractionDigits = 0]) =>
      fraction.truncate(fractionDigits);

  @override
  String toString() =>
      '$ShortDecimalDivideException:'
      ' The result of division cannot be represented as $ShortDecimal:'
      '\n$dividend / $divisor = $quotientWithRemainder'
      '\n$dividend / $divisor = $fraction';
}

extension ShortDecimalIntExtension on int {
  ShortDecimal toShortDecimal() => ShortDecimal._pack(this, 0);
}
