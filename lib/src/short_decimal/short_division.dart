part of 'short_decimal.dart';

@immutable

/// A whole quotient together with the remainder that did not fit into it.
///
/// ```dart
/// final d = ShortDecimal.parse('7.5').divideWithRemainder(ShortDecimal(2));
/// print(d);           // 3 remainder 1.5
/// print(d.quotient);  // 3
/// print(d.remainder); // 1.5
/// ```
final class ShortDivision {
  /// Integer quotient.
  final int quotient;

  /// Remainder.
  final ShortDecimal remainder;

  /// Divides [dividend] by [divisor] and keeps the quotient whole.
  ///
  /// Throws `UnsupportedError` when [divisor] is zero.
  factory ShortDivision(ShortDecimal dividend, ShortDecimal divisor) {
    if (divisor.isZero) {
      throw UnsupportedError('division by zero');
    }

    // The scale of an aligned pair is negative for round numbers, and the
    // public constructor asserts it is not. The remainder is built by the
    // internal one for that reason.
    final aligned = dividend._alignOrNull(divisor);
    if (aligned != null) {
      final (a, b, scale) = aligned;

      return ShortDivision._(a ~/ b, ShortDecimal._pack(a.remainder(b), scale));
    }

    final (a, b, scale) = dividend._alignExactly(divisor);

    return ShortDivision._(
      (a ~/ b).toInt(),
      ShortDecimal._pack(a.remainder(b).toInt(), scale),
    );
  }

  const ShortDivision._(this.quotient, this.remainder);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShortDivision &&
          quotient == other.quotient &&
          remainder == other.remainder;

  @override
  int get hashCode => Object.hash(quotient, remainder);

  @override
  String toString() =>
      remainder.isZero ? '$quotient' : '$quotient remainder $remainder';
}
