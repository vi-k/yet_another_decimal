part of 'decimal.dart';

@immutable
final class Division {
  /// Integer quotient.
  final BigInt quotient;

  /// Remainder.
  final Decimal remainder;

  factory Division(Decimal dividend, Decimal divisor) {
    if (divisor.isZero) {
      throw UnsupportedError('division by zero');
    }

    final (a, b, scale) = dividend._align(divisor);

    return Division._(
      a ~/ b,
      Decimal.fromBigInt(
        a.remainder(b),
        shiftRight: scale,
      ),
    );
  }

  const Division._(this.quotient, this.remainder);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Division &&
          quotient == other.quotient &&
          remainder == other.remainder;

  @override
  int get hashCode => Object.hash(quotient, remainder);

  @override
  String toString() =>
      remainder.isZero ? '$quotient' : '$quotient remainder $remainder';
}
