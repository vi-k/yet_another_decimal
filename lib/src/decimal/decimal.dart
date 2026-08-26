import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../helpers.dart';

part 'division.dart';
part 'fraction.dart';

final class Decimal implements Comparable<Decimal> {
  static final _char0 = '0'.codeUnitAt(0);
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

  /// Ten to the power of [exponent].
  static BigInt _pow10(int exponent) {
    assert(exponent >= 0, "exponent can't be negative");

    if (exponent >= _pow10CacheLimit) {
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

  @visibleForTesting
  final BigInt base;

  @visibleForTesting
  final int scale;

  /// It's to maximize performance.
  ///
  /// The Decimal class can never be constant, since BigInt is not constant.
  /// So we use the trick of preserving the intermediate optimal result.
  Decimal? _packed;

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
  Decimal(int base, {int shiftRight = 0})
    : this.fromBigInt(BigInt.from(base), shiftRight: shiftRight);

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
  Decimal.fromBigInt(this.base, {int shiftRight = 0})
    : assert(shiftRight >= 0, 'shiftRight must be positive'),
      scale = shiftRight;

  /// Parse the [string] to [Decimal].
  ///
  /// Throw [FormatException] on failure.
  factory Decimal.parse(String string) =>
      tryParse(string) ??
      (throw FormatException('Could not parse $Decimal: $string'));

  Decimal._asIs(this.base, this.scale);

  /// Parse the [string] to [Decimal].
  ///
  /// Accepts an optional sign, an optional exponent and surrounding
  /// whitespace: `'1'`, `'-0.5'`, `'.5'`, `'+1e21'`. Returns null on anything
  /// else — hexadecimal included, which [BigInt.parse] would have accepted.
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
  int get fractionDigits => scale <= 0 ? 0 : math.max(_requirePacked.scale, 0);

  /// Returns the sign of this decimal.
  ///
  /// Returns 0 for zero, -1 for values less than zero and +1 for values
  /// greater than zero.
  int get sign => base.sign;

  /// Whether this decimal is negative.
  bool get isNegative => base.isNegative;

  /// Whether this decimal is an integer.
  bool get isInteger => scale <= 0 || _requirePacked.scale <= 0;

  /// Whether this decimal is zero.
  bool get isZero => base == BigInt.zero;

  /// Returns the negative value of this decimal.
  Decimal operator -() => Decimal._asIs(-base, scale);

  /// Adds [other] to this decimal.
  Decimal operator +(Decimal other) {
    final (a, b, scale) = _align(other);

    return Decimal._asIs(a + b, scale);
  }

  /// Subtracts [other] from this decimal.
  Decimal operator -(Decimal other) {
    final (a, b, scale) = _align(other);

    return Decimal._asIs(a - b, scale);
  }

  /// Multiplies this decimal by [other].
  Decimal operator *(Decimal other) =>
      Decimal._asIs(base * other.base, scale + other.scale);

  /// Divides this decimal by [other].
  ///
  /// Throws [UnsupportedError] if [other] is zero and
  /// [DecimalDivideException] if the result cannot be written down as a
  /// decimal with a finite number of digits.
  Decimal operator /(Decimal other) {
    var divisor = other.base;

    if (divisor == BigInt.zero) {
      throw UnsupportedError('division by zero');
    }

    var base = this.base;
    var scale = this.scale - other.scale;

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

    final gcd = base.fastGcd(divisor);
    if (gcd != BigInt.one) {
      base ~/= gcd;
      divisor ~/= gcd;
    }

    if (divisor != BigInt.one) {
      var k = BigInt.one;
      while (divisor % _bigInt5 == BigInt.zero) {
        k *= BigInt.two;
        scale++;
        divisor = divisor ~/ _bigInt5;
      }

      while (divisor % BigInt.two == BigInt.zero) {
        k *= _bigInt5;
        scale++;
        divisor = divisor ~/ BigInt.two;
      }

      if (divisor != BigInt.one) {
        throw DecimalDivideException._(this, other);
      }

      base *= k;
    }

    return Decimal._asIs(negate ? -base : base, scale);
  }

  /// Performs truncating division of this decimal by [other].
  ///
  /// Truncating division is division where a fractional result is converted to
  /// an integer by rounding towards zero.
  BigInt operator ~/(Decimal other) {
    final (a, b, _) = _align(other);

    return a ~/ b;
  }

  /// Calculates the result of division as double.
  double divideToDouble(Decimal other) {
    final fraction = divideToFraction(other);

    return _ratioToDouble(fraction.numerator, fraction.denominator);
  }

  /// The value of `numerator / denominator` as a [double].
  ///
  /// `BigInt.operator /` is `toDouble() / other.toDouble()`, so once both ends
  /// pass `double.maxFinite` it computes `Infinity / Infinity` and answers NaN
  /// for a ratio that is perfectly ordinary. Numbers of high precision reach
  /// that point easily: aligning the scales grows both ends at once.
  static double _ratioToDouble(BigInt numerator, BigInt denominator) {
    final numeratorBits = numerator.abs().bitLength;
    final denominatorBits = denominator.abs().bitLength;

    // Both ends survive the conversion: let the SDK do the work.
    if (numeratorBits < 1024 && denominatorBits < 1024) {
      return numerator / denominator;
    }

    // Otherwise take 64 significant bits of the ratio — eleven more than a
    // double keeps — and put the exponent back afterwards. An exponent out of
    // range turns into zero or infinity here, which is the right answer for a
    // ratio out of range.
    const bits = 64;
    final shift = bits + denominatorBits - numeratorBits;
    final scaled = shift >= 0
        ? (numerator << shift) ~/ denominator
        : numerator ~/ (denominator << -shift);

    // The base has to be a double: `pow` with two ints answers with an int,
    // and 2^2596 as an int is zero.
    return scaled.toDouble() * math.pow(2.0, -shift);
  }

  /// Calculates the result of division as fraction.
  Fraction divideToFraction(Decimal other) {
    final (dividend, divisor, _) = _align(other);

    return Fraction(dividend, divisor);
  }

  /// Calculates the result of division as an integer quotient and remainder.
  Division divideWithRemainder(Decimal other) => Division(this, other);

  /// Euclidean modulo of this number by [other].
  ///
  /// The sign of the returned value is always positive.
  Decimal operator %(Decimal other) {
    final (a, b, scale) = _align(other);

    return Decimal._asIs(a % b, scale);
  }

  /// The remainder of the truncating division of this by [other].
  ///
  /// The result r of this operation satisfies:
  /// this == (this ~/ other) * other + r. As a consequence, the remainder r
  /// has the same sign as the dividend this.
  Decimal remainder(Decimal other) {
    final (a, b, scale) = _align(other);

    return Decimal._asIs(a.remainder(b), scale);
  }

  /// Whether this decimal is smaller than [other].
  bool operator <(Decimal other) {
    final (a, b, _) = _align(other);

    return a < b;
  }

  /// Whether this decimal is smaller than or equal to [other].
  bool operator <=(Decimal other) {
    final (a, b, _) = _align(other);

    return a <= b;
  }

  /// Whether this decimal is greater than [other].
  bool operator >(Decimal other) {
    final (a, b, _) = _align(other);

    return a > b;
  }

  /// Whether this decimal is greater than or equal to [other].
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
  Decimal operator <<(int shiftAmount) =>
      Decimal._asIs(base, scale - shiftAmount);

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
  Decimal operator >>(int shiftAmount) =>
      Decimal._asIs(base, scale + shiftAmount);

  /// Optimize number to improve performance.
  void optimize() {
    _requirePacked;
  }

  /// Returns the absolute value of this decimal.
  Decimal abs() => base.isNegative ? Decimal._asIs(-base, scale) : this;

  /// Rounds the decimal towards negative infinity to [fractionDigits].
  Decimal floor([int fractionDigits = 0]) => _dropFraction(
    fractionDigits,
    (result, divisor) => isNegative && base % divisor != BigInt.zero
        ? result - BigInt.one
        : result,
  );

  /// Rounds to the closest decimal with [fractionDigits].
  Decimal round([int fractionDigits = 0]) =>
      _dropFraction(fractionDigits, (result, divisor) {
        final remainder = base.remainder(divisor).abs();
        return remainder >= divisor - remainder
            ? result + BigInt.from(base.sign)
            : result;
      });

  /// Rounds the decimal towards infinity to [fractionDigits].
  Decimal ceil([int fractionDigits = 0]) => _dropFraction(
    fractionDigits,
    (result, divisor) => !isNegative && base % divisor != BigInt.zero
        ? result + BigInt.one
        : result,
  );

  /// Rounds the decimal towards zero to [fractionDigits].
  Decimal truncate([int fractionDigits = 0]) =>
      _dropFraction(fractionDigits, (result, divisor) => result);

  /// Returns this decimal clamped to be in the range [lowerLimit]-[upperLimit].
  ///
  /// The arguments [lowerLimit] and [upperLimit] must form a valid range where
  /// lowerLimit <= upperLimit.
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
  Decimal pow(int exponent) {
    _checkNonNegativeArgument(exponent, 'exponent');

    return Decimal._asIs(base.pow(exponent), scale * exponent);
  }

  /// Returns [BigInt], discarding all fractional digits from this decimal.
  BigInt toBigInt() {
    final truncated = truncate();
    final scale = truncated.scale;

    // The scale is never positive after truncate. A negative one is a shift to
    // the left and has to be materialized, exactly as ShortDecimal.toInt does:
    // the base alone is not the value.
    return scale < 0 ? truncated.base * _pow10(-scale) : truncated.base;
  }

  /// Converts this decimal to [double].
  double toDouble() => double.parse(toString());

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

  @visibleForTesting
  String debugToString() => '$Decimal(base: $base, scale: $scale)';

  /// Returns a string representation of this decimal.
  @override
  String toString() {
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

  // TODO(vi.k): do it.
  String toStringAsExponential([int fractionDigits = 0]) =>
      throw UnimplementedError();

  // TODO(vi.k): do it.
  //
  // 1234567 (6) -> 1.23457e+6 ?
  String toStringAsPrecision(int precision) => throw UnimplementedError();

  static void _checkNonNegativeArgument(int value, String name) {
    if (value < 0) {
      throw ArgumentError.value(value, name, 'The value must be >= 0');
    }
  }

  Decimal get _requirePacked => _packed ??= _dropTrailingZeros(base, scale);

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
  static Decimal _dropTrailingZeros(BigInt base, int scale) {
    // A trailing zero needs both a two and a five, so an odd base has none.
    if (base.isOdd) {
      return Decimal._asIs(base, scale);
    }

    if (base == BigInt.zero) {
      return Decimal._asIs(base, 0);
    }

    if (base % _bigInt10 != BigInt.zero) {
      return Decimal._asIs(base, scale);
    }

    var rest = base ~/ _bigInt10;
    var zeros = 1;
    while (zeros < _linearZeros) {
      if (rest % _bigInt10 != BigInt.zero) {
        return Decimal._asIs(rest, scale - zeros);
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

    return Decimal._asIs(base ~/ _pow10(low), scale - low);
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
    if (scale <= fractionDigits) {
      return this;
    }

    final divisor = _pow10(scale - fractionDigits);
    final result = callback(base ~/ divisor, divisor);

    return Decimal._asIs(result, fractionDigits);
  }
}

final class DecimalDivideException implements Exception {
  final Decimal dividend;
  final Decimal divisor;

  const DecimalDivideException._(this.dividend, this.divisor);

  @visibleForTesting
  DecimalDivideException.forTest(this.dividend, this.divisor);

  Fraction get fraction => dividend.divideToFraction(divisor);

  Division get quotientWithRemainder => dividend.divideWithRemainder(divisor);

  Decimal floor([int fractionDigits = 0]) => fraction.floor(fractionDigits);

  Decimal round([int fractionDigits = 0]) => fraction.round(fractionDigits);

  Decimal ceil([int fractionDigits = 0]) => fraction.ceil(fractionDigits);

  Decimal truncate([int fractionDigits = 0]) =>
      fraction.truncate(fractionDigits);

  @override
  String toString() =>
      '$DecimalDivideException:'
      ' The result of division cannot be represented as $Decimal:'
      '\n$dividend / $divisor = $quotientWithRemainder'
      '\n$dividend / $divisor = $fraction';
}

extension DecimalBigIntExtension on BigInt {
  Decimal toDecimal() => Decimal.fromBigInt(this);
}

extension DecimalIntExtension on int {
  Decimal toDecimal() => Decimal(this);
}
