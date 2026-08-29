import 'dart:math' as math;

/// What the package needs of `BigInt` and the standard library does not have.
extension BigIntInternals on BigInt {
  /// The greatest common divisor of this and [other].
  ///
  /// A pair that fits into machine words goes to [IntInternals.fastGcd], which
  /// beats `int.gcd` by more than three times. Division of money values is
  /// twice as fast for it, and the nine divisions of the divide-small
  /// benchmark a third faster.
  ///
  /// The rest walk Euclid through `%`. The binary gcd of the SDK was tried
  /// here on the thresholds the review recommends — operands over eighty bits
  /// and within a quarter of each other — and it lost: fractions of sixty
  /// digits came out twice slower. See
  /// https://github.com/dart-lang/sdk/issues/46180, still open.
  BigInt fastGcd(BigInt other) {
    if (isValidInt && other.isValidInt) {
      return BigInt.from(toInt().fastGcd(other.toInt()));
    }

    var result = this;
    var rest = other;
    while (rest != BigInt.zero) {
      final tmp = rest;
      rest = result % rest;
      result = tmp;
    }

    return result.abs();
  }

  /// The ratio of two integers as the nearest double, ties to even.
  ///
  /// Doing it the obvious way rounds more than once, and every extra rounding
  /// is a chance to land on the wrong double. `numerator / denominator` rounds
  /// three times — each end on its way to a double, then the division itself.
  /// Taking a fixed number of bits of the quotient and putting the exponent
  /// back afterwards rounds twice, and below `2^-1074` the exponent itself
  /// underflows to zero, which turned every subnormal answer into a plain `0`.
  ///
  /// So the quotient is taken at exactly the precision the answer will keep —
  /// fifty-three bits while the result is normal, fewer once it is not —
  /// rounded once with the remainder standing in for the sticky bit, and only
  /// then scaled by a power of two, which is exact.
  double ratioToDouble(BigInt denominator) {
    if (this == BigInt.zero) {
      return 0;
    }

    final negative = isNegative != denominator.isNegative;
    final n = abs();
    final d = denominator.abs();

    // Where both ends are exactly representable, the SDK is already correct —
    // IEEE division rounds once — and much faster than the road below.
    if (n.bitLength <= _doubleMantissaBits &&
        d.bitLength <= _doubleMantissaBits) {
      final result = n.toDouble() / d.toDouble();

      return negative ? -result : result;
    }

    // floor(log2(n / d)). The bit lengths give it to within one, and the
    // comparison below settles which.
    var log2 = n.bitLength - d.bitLength;
    if (log2 >= 0 ? n < (d << log2) : (n << -log2) < d) {
      log2--;
    }

    // The exponent of the lowest bit the answer can hold: fifty-two below the
    // leading one while the result is normal, and 2^-1074 once it is not.
    final lowest =
        math.max(log2 - (_doubleMantissaBits - 1), _doubleMinSubnormalExponent);

    // mantissa = round(n / d / 2^lowest), halves to even.
    final shift = -lowest;
    final scaledNumerator = shift >= 0 ? n << shift : n;
    final scaledDenominator = shift >= 0 ? d : d << -shift;
    var mantissa = scaledNumerator ~/ scaledDenominator;
    final twiceRemainder =
        (scaledNumerator - mantissa * scaledDenominator) << 1;
    if (twiceRemainder > scaledDenominator ||
        (twiceRemainder == scaledDenominator && mantissa.isOdd)) {
      mantissa += BigInt.one;
    }

    // The mantissa holds at most fifty-three bits, so it converts exactly, and
    // every step of the scaling below stays between it and the answer — so no
    // step loses a bit either. An answer out of range becomes infinity here,
    // which is what it should be.
    final result = _scaleByPowerOfTwo(mantissa.toDouble(), lowest);

    return negative ? -result : result;
  }
}

/// What the package needs of `int` and the standard library does not have.
extension IntInternals on int {
  /// The greatest common divisor of this and [other], by Euclid.
  ///
  /// Faster than `int.gcd` on machine words, and the reason
  /// [BigIntInternals.fastGcd] hands small pairs over to it.
  int fastGcd(int other) {
    var gcd = this;
    while (other != 0) {
      final tmp = other;
      other = gcd % other;
      gcd = tmp;
    }

    return gcd.abs();
  }
}

/// How many bits a double keeps, the implicit leading one included.
const _doubleMantissaBits = 53;

/// The exponent of the smallest subnormal double, `2^-1074`.
const _doubleMinSubnormalExponent = -1074;

/// [value] multiplied by `2^exponent`, in steps small enough to stay in range.
///
/// A single `pow(2.0, exponent)` is not enough: the factor itself can
/// underflow to zero or overflow to infinity while the product is a perfectly
/// good double.
double _scaleByPowerOfTwo(double value, int exponent) {
  const step = 500;
  final down = math.pow(2.0, -step) as double;
  final up = math.pow(2.0, step) as double;

  var result = value;
  var rest = exponent;
  while (rest <= -step) {
    result *= down;
    rest += step;
  }
  while (rest >= step) {
    result *= up;
    rest -= step;
  }

  return result * (math.pow(2.0, rest) as double);
}

const _char0 = 0x30;
const _char5 = 0x35;
const _char9 = 0x39;
const _charDot = 0x2e;
const _charPlus = 0x2b;
const _charMinus = 0x2d;
const _charE = 0x65;
const _charCapitalE = 0x45;

/// The largest exponent this package will build a power of ten for.
///
/// The scale itself is just an int and holds far more, but a number has to
/// remain printable: a million digits is a megabyte of text, and a billion of
/// them takes the stack down inside `BigInt.parse` on the way back. No real
/// notation comes anywhere near this.
///
/// Reading a number stops here; so does every member that takes a number of
/// digits from the caller — rounding, printing, the scale of an inexact
/// division — and so does the building of the power itself, which is where a
/// scale driven past the bound by shifting is caught. Ten to the millionth is
/// a `BigInt` of a megabyte and the package will build one; ten to the
/// billionth is a number nobody can hold, and `Decimal.one.round(-1000000000)`
/// used to go looking for it.
const maxDecimalExponent = 1000000;

/// What the package needs of `String` and the standard library does not have.
extension StringInternals on String {
  /// This string cut in two at [index].
  (String, String) splitByIndex(int index) =>
      (substring(0, index), substring(index));

  /// The first [keep] of these digits, rounded by the one that follows them.
  ///
  /// Returns the digits and whether the carry took a place: `999` kept to two
  /// digits is `10`, one power of ten above what it was. A string with fewer
  /// digits than asked for comes back as it is — padding it is the caller's
  /// business, and printing to a million digits should not allocate a million
  /// of them twice. Halves go away from zero; the sign lives elsewhere, so a
  /// digit of five or more decides on its own.
  ///
  /// This is what exponential notation rounds with. Rounding the value instead
  /// asks for ten to the power of everything dropped: printing `1e-1000000` to
  /// three digits went looking for a million of them and refused, naming an
  /// argument the caller never passed, while a number of fifty thousand digits
  /// paid a division by ten to the fifty thousandth to show three.
  (String, bool) roundDigits(int keep) {
    assert(keep > 0, 'At least one digit has to be kept');

    if (keep >= length) {
      return (this, false);
    }

    if (codeUnitAt(keep) < _char5) {
      return (substring(0, keep), false);
    }

    final digits = substring(0, keep).codeUnits.toList();
    for (var index = keep - 1; index >= 0; index--) {
      if (digits[index] != _char9) {
        digits[index]++;

        return (String.fromCharCodes(digits), false);
      }

      digits[index] = _char0;
    }

    // Every digit was a nine, so the whole run rolled over into a one.
    return ('1${'0' * (keep - 1)}', true);
  }

  /// Reads a whole number and returns it with its sign, ready for parsing.
  ///
  /// `' -42 '` reads as `'-42'`; a dot, an exponent, a hexadecimal prefix, an
  /// inner space and a bare sign all read as null. Surrounding whitespace is
  /// allowed, exactly as [scanDecimal] allows it.
  ///
  /// This is what the two sides of a fraction are written with. Handing them
  /// to [BigInt.parse] or [int.parse] instead — which is what this replaces —
  /// let hexadecimal through, and a fraction was reading `'0x10'` as sixteen
  /// while a decimal had stopped doing so.
  String? scanInteger() {
    final source = trim();
    final length = source.length;
    var index = 0;

    if (index < length) {
      final code = source.codeUnitAt(index);
      if (code == _charMinus || code == _charPlus) {
        index++;
      }
    }

    final digitsStart = index;
    while (index < length && _isDigit(source.codeUnitAt(index))) {
      index++;
    }

    // At least one digit, and nothing after them.
    if (index == digitsStart || index != length) {
      return null;
    }

    return source;
  }

  /// Reads a decimal number and returns its digits and their scale.
  ///
  /// The digits come with their sign and without the dot; the scale is what
  /// the digits have to be shifted right by, so `'1.5e3'` reads as `('15',
  /// -2)`. Returns null when the string is not a decimal number.
  ///
  /// The grammar:
  ///
  /// ```
  /// number   := sign? ( digits ('.' digits)? | '.' digits ) exponent?
  /// sign     := '+' | '-'
  /// digits   := [0-9]+
  /// exponent := ('e' | 'E') sign? digits
  /// ```
  ///
  /// Surrounding whitespace is allowed and nothing else is. Handing the string
  /// to [BigInt.parse] or [int.parse] instead — which is what this replaces —
  /// let hexadecimal, a bare sign and an inner tab through.
  (String, int)? scanDecimal() {
    final source = trim();
    final length = source.length;
    var index = 0;
    var negative = false;

    if (index < length) {
      final code = source.codeUnitAt(index);
      if (code == _charMinus || code == _charPlus) {
        negative = code == _charMinus;
        index++;
      }
    }

    final integerStart = index;
    while (index < length && _isDigit(source.codeUnitAt(index))) {
      index++;
    }
    final integerEnd = index;

    var fractionStart = index;
    var fractionEnd = index;
    if (index < length && source.codeUnitAt(index) == _charDot) {
      index++;
      fractionStart = index;
      while (index < length && _isDigit(source.codeUnitAt(index))) {
        index++;
      }
      fractionEnd = index;

      // '1.' and '.' are not numbers.
      if (fractionEnd == fractionStart) {
        return null;
      }
    }

    // At least one digit is required.
    if (integerEnd == integerStart && fractionEnd == fractionStart) {
      return null;
    }

    var exponent = 0;
    if (index < length) {
      final code = source.codeUnitAt(index);
      if (code != _charE && code != _charCapitalE) {
        return null;
      }
      index++;

      var exponentNegative = false;
      if (index < length) {
        final sign = source.codeUnitAt(index);
        if (sign == _charMinus || sign == _charPlus) {
          exponentNegative = sign == _charMinus;
          index++;
        }
      }

      final exponentStart = index;
      while (index < length && _isDigit(source.codeUnitAt(index))) {
        index++;
      }

      if (index == exponentStart || index != length) {
        return null;
      }

      final digits = int.tryParse(source.substring(exponentStart, index));
      if (digits == null || digits > maxDecimalExponent) {
        return null;
      }

      exponent = exponentNegative ? -digits : digits;
    }

    // The exponent is held to a million above, and the digits after the point
    // are the same thing written the long way: `1e-1000001` and a point with
    // a million and one digits behind it ask for the same scale. Reading one
    // and refusing the other left values that could be built but not compared,
    // rounded or printed. Decided 2026-08-29.
    final scale = fractionEnd - fractionStart - exponent;
    if (scale < -maxDecimalExponent || scale > maxDecimalExponent) {
      return null;
    }

    final digits = '${source.substring(integerStart, integerEnd)}'
        '${source.substring(fractionStart, fractionEnd)}';

    return (negative ? '-$digits' : digits, scale);
  }

  static bool _isDigit(int code) => code >= _char0 && code <= _char9;
}
