/// The bridge between the two families.
///
/// `base` and `scale` are marked `@visibleForTesting` because the tests check
/// the stored form, not because they are private to their library — the bridge
/// is package code and reads them on purpose. That is what the ignores below
/// are for; there is no annotation in `meta` for "visible inside the package"
/// that would also keep the pair out of the public documentation.
library;

import 'decimal/decimal.dart';
import 'short_decimal/short_decimal.dart';

/// Conversion from the int64 family to the BigInt one.
extension ShortDecimalBridge on ShortDecimal {
  /// This decimal as a [Decimal].
  ///
  /// Always exact: every int64 value is a BigInt value.
  ///
  /// ```dart
  /// print(ShortDecimal.parse('1.5').toDecimal()); // 1.5
  /// ```
  Decimal toDecimal() {
    // ignore: invalid_use_of_visible_for_testing_member
    final (base, scale) = (this.base, this.scale);

    return Decimal.fromBigInt(BigInt.from(base)) >> scale;
  }
}

/// Conversion from the BigInt family to the int64 one.
extension DecimalBridge on Decimal {
  /// This decimal as a [ShortDecimal], or null when it does not fit.
  ///
  /// The conversion down has to be able to fail: a [Decimal] holds numbers no
  /// int64 can. Null is returned rather than an exception because a value out
  /// of range is a normal answer here, not a mistake.
  ///
  /// ```dart
  /// print(Decimal.parse('1.5').toShortDecimalOrNull()); // 1.5
  /// print(Decimal.parse('1e30').toShortDecimalOrNull()); // null
  /// ```
  ShortDecimal? toShortDecimalOrNull() {
    // ignore: invalid_use_of_visible_for_testing_member
    final (base, scale) = (this.base, this.scale);

    if (base.isValidInt) {
      return ShortDecimal(base.toInt()) >> scale;
    }

    // The stored pair does not fit, but the packed one still can: ten to the
    // twentieth is a base of one with a scale of minus twenty. The printed
    // form is the only packed form reachable from outside the class, and it is
    // kept between calls anyway.
    return ShortDecimal.tryParse(toString());
  }
}
