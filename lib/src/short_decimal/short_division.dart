part of 'short_decimal.dart';

@immutable
final class ShortDivision {
  /// Integer quotient.
  final int quotient;

  /// Remainder.
  final ShortDecimal remainder;

  factory ShortDivision(ShortDecimal dividend, ShortDecimal divisor) {
    if (divisor.isZero) {
      throw UnsupportedError('division by zero');
    }

    final (a, b, scale) = dividend._align(divisor);

    return ShortDivision._(
      a ~/ b,
      ShortDecimal(
        a.remainder(b),
        shiftRight: scale,
      ),
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
