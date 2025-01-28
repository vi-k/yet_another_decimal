// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:math';

import 'decimal.dart';
import 'short_decimal.dart';

extension BigIntInternals on BigInt {
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

extension StringInternals on String {
  (String, String) splitByIndex(int index) =>
      (substring(0, index), substring(index));
}

extension DecimalInternals on Decimal {
  static final _bigInt10 = BigInt.from(10);

  static BigInt pow10(int exponent) => _bigInt10.pow(exponent);

  /// Aligning decimals by decimal point.
  (BigInt, BigInt, int) align(Decimal other) {
    final as = scale;
    final bs = other.scale;

    if (as == bs) {
      return (value, other.value, as);
    }

    if (as > bs) {
      return (value, other.value * pow10(as - bs), as);
    }

    return (value * pow10(bs - as), other.value, bs);
  }
}

extension ShortDecimalInternals on ShortDecimal {
  static int pow10(int exponent) => pow(10, exponent) as int;

  /// Aligning decimals by decimal point.
  (int, int, int) align(ShortDecimal other) {
    final as = scale;
    final bs = other.scale;

    if (as == bs) {
      return (value, other.value, as);
    }

    if (as > bs) {
      return (value, other.value * pow10(as - bs), as);
    }

    return (value * pow10(bs - as), other.value, bs);
  }
}
