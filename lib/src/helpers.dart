// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'decimal.dart';

extension BigIntInternals on BigInt {
  static final _bigInt10 = BigInt.from(10);

  BigInt mult10N(int count) {
    var result = this;
    for (var i = count; i > 0; i--) {
      result *= _bigInt10;
    }

    return result;
  }

  // https://github.com/dart-lang/sdk/issues/46180
  BigInt fastGcd(BigInt other) {
    var gcd = this;
    while (other != BigInt.zero) {
      final tmp = other;
      other = gcd % other;
      gcd = tmp;
    }

    return gcd.abs();
  }
}

extension StringInternals on String {
  (String, String) splitByIndex(int index) =>
      (substring(0, index), substring(index));
}

extension DecimalInternals on Decimal {
  /// Aligning decimals by decimal point.
  (BigInt, BigInt, int) align(Decimal other) {
    final as = scale;
    final bs = other.scale;

    if (as == bs) {
      return (value, other.value, as);
    }

    if (as > bs) {
      return (value, other.value.mult10N(as - bs), as);
    }

    return (value.mult10N(bs - as), other.value, bs);
  }
}
