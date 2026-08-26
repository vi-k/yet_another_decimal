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
}

extension IntInternals on int {
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

const _char0 = 0x30;
const _char9 = 0x39;
const _charDot = 0x2e;
const _charPlus = 0x2b;
const _charMinus = 0x2d;
const _charE = 0x65;
const _charCapitalE = 0x45;

/// The largest exponent a decimal number is read with.
///
/// The scale itself is just an int and holds far more, but a number this
/// string produces has to remain printable: a million digits is a megabyte of
/// text, and a billion of them takes the stack down inside `BigInt.parse` on
/// the way back. No real notation comes anywhere near this.
const _maxExponent = 1000000;

extension StringInternals on String {
  (String, String) splitByIndex(int index) =>
      (substring(0, index), substring(index));

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
      if (digits == null || digits > _maxExponent) {
        return null;
      }

      exponent = exponentNegative ? -digits : digits;
    }

    final digits =
        '${source.substring(integerStart, integerEnd)}'
        '${source.substring(fractionStart, fractionEnd)}';

    return (
      negative ? '-$digits' : digits,
      fractionEnd - fractionStart - exponent,
    );
  }

  static bool _isDigit(int code) => code >= _char0 && code <= _char9;
}
