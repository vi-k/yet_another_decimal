import 'dart:typed_data';

/// The low half of a machine word.
const int _mask32 = 0xFFFFFFFF;

/// The low quarter of a machine word.
const int _mask16 = 0xFFFF;

/// The sign bit of a machine word.
///
/// Flipping it on both sides of a `<` turns a signed comparison into an
/// unsigned one, which is what the low half of a 128-bit value needs.
const int _signBit = 1 << 63;

/// How many 16-bit limbs a 128-bit value takes.
const int _wideLimbs = 8;

/// The dividend of [udivmod128by64], in 16-bit limbs.
///
/// Kept at file level, not built per call: an allocation on every division
/// would eat the whole gain. The function runs straight through and never
/// re-enters itself, and statics in Dart are per isolate, so the sharing is
/// safe. Neither buffer is a field of `ShortDecimal`, so `vm:deeply-immutable`
/// is not touched.
final Int32List _dividend = Int32List(_wideLimbs + 2);

/// The divisor of [udivmod128by64], in 16-bit limbs. See [_dividend].
final Int32List _divisor = Int32List(5);

/// The signed 128-bit product of [a] and [b], as `(high, low)`.
///
/// Dart has neither a 64x64 to 128 multiply nor an integer wider than a
/// machine word, so the product is assembled out of four multiplications of
/// 32-bit halves. That is dear next to the single instruction a machine has
/// for it, and cheap next to the 40 ns of the same product through `BigInt`:
/// 4.7 ns measured on Dart 3.13.0, AOT.
///
/// The halves multiply as unsigned, and the two corrections at the end put the
/// sign back — the identity `signed(x) == unsigned(x) - 2^64 * (x < 0)`
/// applied to each operand in turn.
@pragma('vm:prefer-inline')
(int, int) mul128(int a, int b) {
  final aLow = a & _mask32;
  final aHigh = a >>> 32;
  final bLow = b & _mask32;
  final bHigh = b >>> 32;
  final lowByLow = aLow * bLow;
  final lowByHigh = aLow * bHigh;
  final highByLow = aHigh * bLow;
  final highByHigh = aHigh * bHigh;
  final middle =
      (lowByLow >>> 32) + (lowByHigh & _mask32) + (highByLow & _mask32);
  var high =
      highByHigh + (lowByHigh >>> 32) + (highByLow >>> 32) + (middle >>> 32);
  if (a < 0) {
    high -= b;
  }
  if (b < 0) {
    high -= a;
  }

  return (high, (lowByLow & _mask32) | ((middle & _mask32) << 32));
}

/// Whether the product of [a] and [b] fits into a machine word.
///
/// Exact, and cheaper than the approximation in `double` it replaces: a
/// 128-bit product fits into 64 bits exactly when its high half is the sign
/// extension of its low half, which is one multiply and one comparison rather
/// than a rounding and a division to undo it.
@pragma('vm:prefer-inline')
bool productFits(int a, int b) {
  final (high, low) = mul128(a, b);

  return high == (low >> 63);
}

/// [x] read as unsigned and divided by ten: `(quotient, remainder)`.
///
/// Unsigned because the caller is a sum that has already run past `int.max`
/// and is being read by its bit pattern, not by its value. Splitting into two
/// 32-bit halves keeps both divisions inside the range where `~/` answers
/// exactly.
@pragma('vm:prefer-inline')
(int, int) udivmod10(int x) {
  final high = x >>> 32;
  final low = x & _mask32;
  final highQuotient = high ~/ 10;
  final rest = ((high - highQuotient * 10) << 32) | low;
  final lowQuotient = rest ~/ 10;

  return ((highQuotient << 32) | lowQuotient, rest - lowQuotient * 10);
}

/// Compares two signed 128-bit values given as `(high, low)` pairs.
///
/// Answers -1, 0 or 1. The high halves compare as signed words, the low halves
/// as unsigned ones — hence the flipped sign bit.
@pragma('vm:prefer-inline')
int compare128(int highLeft, int lowLeft, int highRight, int lowRight) {
  if (highLeft != highRight) {
    return highLeft < highRight ? -1 : 1;
  }
  if (lowLeft == lowRight) {
    return 0;
  }

  return (lowLeft ^ _signBit) < (lowRight ^ _signBit) ? -1 : 1;
}

/// Limb [index] of the 128-bit value `(high, low)`, 16 bits wide.
@pragma('vm:prefer-inline')
int _limb(int high, int low, int index) =>
    (index < 4 ? low >>> (16 * index) : high >>> (16 * (index - 4))) & _mask16;

/// Unsigned `(high, low)` divided by [divisor], quotient and remainder at once.
///
/// Answers `(quotientHigh, quotientLow, remainder)`, the quotient again a
/// 128-bit pair — a small divisor leaves more than a machine word of it.
/// Everything here is unsigned: `divisor` may be `int.min`, which is 2^63 read
/// by its bits, and the caller is expected to have taken the signs out
/// beforehand.
///
/// Knuth's algorithm D on **16-bit** limbs. The width is not laziness: with
/// 32-bit limbs, estimating the next digit of the quotient means dividing a
/// 64-bit value by a 32-bit one, and Dart's signed `~/` answers wrongly on
/// dividends above 2^63. On 16-bit limbs every intermediate stays below 2^32,
/// where `~/` is exact across the whole range.
///
/// A divisor below 2^16 takes short division in eight steps instead — 28 ns
/// against the 110 ns of the full algorithm.
(int, int, int) udivmod128by64(int high, int low, int divisor) {
  assert(divisor != 0, 'division by zero');

  var limbs = 4;
  while (limbs > 1 && ((divisor >>> (16 * (limbs - 1))) & _mask16) == 0) {
    limbs--;
  }

  if (limbs == 1) {
    final short = divisor & _mask16;
    var remainder = 0;
    var quotientHigh = 0;
    var quotientLow = 0;
    for (var i = _wideLimbs - 1; i >= 0; i--) {
      final current = (remainder << 16) | _limb(high, low, i);
      final digit = current ~/ short;
      remainder = current - digit * short;
      if (i >= 4) {
        quotientHigh |= digit << (16 * (i - 4));
      } else {
        quotientLow |= digit << (16 * i);
      }
    }

    return (quotientHigh, quotientLow, remainder);
  }

  // Normalization: the top limb of the divisor has to have its high bit set,
  // or the estimate of a quotient digit is allowed to be off by more than the
  // one step the algorithm corrects.
  var shift = 0;
  final top = (divisor >>> (16 * (limbs - 1))) & _mask16;
  while (((top << shift) & 0x8000) == 0) {
    shift++;
  }

  for (var i = 0; i < limbs; i++) {
    final current = (divisor >>> (16 * i)) & _mask16;
    final previous = i > 0 ? (divisor >>> (16 * (i - 1))) & _mask16 : 0;
    _divisor[i] =
        ((current << shift) | (shift == 0 ? 0 : previous >>> (16 - shift))) &
            _mask16;
  }
  for (var i = 0; i < _wideLimbs; i++) {
    final current = _limb(high, low, i);
    final previous = i > 0 ? _limb(high, low, i - 1) : 0;
    _dividend[i] =
        ((current << shift) | (shift == 0 ? 0 : previous >>> (16 - shift))) &
            _mask16;
  }
  _dividend[_wideLimbs] =
      shift == 0 ? 0 : _limb(high, low, _wideLimbs - 1) >>> (16 - shift);

  var quotientHigh = 0;
  var quotientLow = 0;
  for (var j = _wideLimbs - limbs; j >= 0; j--) {
    final head = (_dividend[j + limbs] << 16) | _dividend[j + limbs - 1];
    var estimate = head ~/ _divisor[limbs - 1];
    var rest = head - estimate * _divisor[limbs - 1];
    while (estimate > _mask16 ||
        estimate * _divisor[limbs - 2] >
            ((rest << 16) | _dividend[j + limbs - 2])) {
      estimate--;
      rest += _divisor[limbs - 1];
      if (rest > _mask16) {
        break;
      }
    }

    // Subtract the estimated multiple of the divisor, borrowing as we go.
    var borrow = 0;
    for (var i = 0; i < limbs; i++) {
      final product = estimate * _divisor[i];
      final digit = _dividend[i + j] - borrow - (product & _mask16);
      _dividend[i + j] = digit & _mask16;
      borrow = (product >> 16) - (digit >> 16);
    }
    final top = _dividend[j + limbs] - borrow;
    _dividend[j + limbs] = top & _mask16;

    // One estimate in a few billion comes out too large by one. It shows as a
    // borrow out of the top limb, and the divisor is added back once.
    if (top < 0) {
      estimate--;
      var carry = 0;
      for (var i = 0; i < limbs; i++) {
        final sum = _dividend[i + j] + _divisor[i] + carry;
        _dividend[i + j] = sum & _mask16;
        carry = sum >> 16;
      }
      _dividend[j + limbs] = (_dividend[j + limbs] + carry) & _mask16;
    }

    if (j >= 4) {
      quotientHigh |= estimate << (16 * (j - 4));
    } else {
      quotientLow |= estimate << (16 * j);
    }
  }

  var remainder = 0;
  for (var i = limbs - 1; i >= 0; i--) {
    remainder = (remainder << 16) | _dividend[i];
  }

  return (quotientHigh, quotientLow, remainder >>> shift);
}
