/// The contract both decimal families keep.
///
/// Not exported from `yet_another_decimal.dart` in 1.2.0: a public interface
/// freezes, and this one is here for the compiler rather than for the user.
/// Forgetting a member in the second family becomes an error at build time
/// instead of a reviewer's finding a year later — there were twenty-five such
/// divergences before it existed, two of which quietly spoiled values.
///
/// The name is chosen to survive going public one day, in the role `num` plays
/// for `int` and `double`: a number with a fixed point is exactly what both
/// types are, and it promises nothing more.
///
/// The type parameter is self-bounded, so `Decimal` and `ShortDecimal` are
/// unrelated types and cannot be mixed in one expression. That is a decision,
/// not an omission: mixing would have to pick a result type, and either choice
/// is wrong half of the time. Crossing over is explicit, through the bridge.
///
/// What the interface does not cover is the static side — constructors,
/// `parse`, `tryParse`, constants — and members whose type differs between the
/// families (`divideToFraction`, `inverse`, `operator ~/`). Those are held
/// together by the symmetry test instead.
library;

/// The members both `Decimal` and `ShortDecimal` have to have.
///
/// The reasoning behind the interface — why it exists, why it is not exported
/// and what it deliberately leaves out — is in the comment on the library
/// above.
abstract interface class FixedPoint<T extends FixedPoint<T>>
    implements Comparable<T> {
  /// The number of digits after the decimal point.
  int get fractionDigits;

  /// The number of digits in the unscaled value.
  int get precision;

  /// The power of ten the unscaled value is multiplied by.
  ///
  /// The number is `unscaledValue × 10^exponent`, and both come from the
  /// canonical form, so equal values answer equally.
  int get exponent;

  /// The sign: -1, 0 or 1.
  int get sign;

  /// Whether this is less than zero.
  bool get isNegative;

  /// Whether this is greater than zero.
  bool get isPositive;

  /// Whether this has no fractional part.
  bool get isInteger;

  /// Whether this is zero.
  bool get isZero;

  /// The negation of this.
  T operator -();

  /// Adds [other] to this.
  T operator +(T other);

  /// Subtracts [other] from this.
  T operator -(T other);

  /// Multiplies this by [other].
  T operator *(T other);

  /// Divides this by [other], throwing when the result has no finite form.
  T operator /(T other);

  /// Divides this by [other], or returns null.
  T? divideOrNull(T other);

  /// Divides this by [other], rounding what has no finite form.
  T divide(T other, {int? scaleOnInfinitePrecision});

  /// Whether dividing by [other] has a finite decimal form.
  bool isDivisibleBy(T other);

  /// The result of division as a [double].
  double divideToDouble(T other);

  /// The euclidean modulo of this by [other].
  T operator %(T other);

  /// The remainder of the truncating division of this by [other].
  T remainder(T other);

  /// Whether this is smaller than [other].
  bool operator <(T other);

  /// Whether this is smaller than or equal to [other].
  bool operator <=(T other);

  /// Whether this is greater than [other].
  bool operator >(T other);

  /// Whether this is greater than or equal to [other].
  bool operator >=(T other);

  /// Shifts this relative to the decimal point to the left.
  T operator <<(int shiftAmount);

  /// Shifts this relative to the decimal point to the right.
  T operator >>(int shiftAmount);

  /// This value divided by `10^places`: the point moves left.
  T movePointLeft(int places);

  /// This value multiplied by `10^places`: the point moves right.
  T movePointRight(int places);

  /// This value in its canonical form.
  T normalized();

  /// The absolute value of this.
  T abs();

  /// Rounds towards negative infinity to [fractionDigits].
  T floor([int fractionDigits]);

  /// Rounds to the closest value with [fractionDigits].
  T round([int fractionDigits]);

  /// Rounds towards infinity to [fractionDigits].
  T ceil([int fractionDigits]);

  /// Rounds towards zero to [fractionDigits].
  T truncate([int fractionDigits]);

  /// This clamped to be in the range [lowerLimit]-[upperLimit].
  T clamp(T lowerLimit, T upperLimit);

  /// This to the power of [exponent].
  T pow(int exponent);

  /// This as an [int], discarding all fractional digits.
  int toInt();

  /// This as a [BigInt], discarding all fractional digits.
  BigInt toBigInt();

  /// This as a [double].
  double toDouble();

  /// A JSON representation: the string [toString] returns.
  String toJson();

  /// A string with exactly [fractionDigits] digits after the point.
  String toStringAsFixed(int fractionDigits);

  /// An exponential string with [fractionDigits] digits after the point.
  String toStringAsExponential([int fractionDigits]);

  /// A string with [precision] significant digits.
  String toStringAsPrecision(int precision);
}
