part of 'decimal.dart';

@immutable

/// A whole quotient together with the remainder that did not fit into it.
///
/// ```dart
/// final d = Decimal.parse('7.5').divideWithRemainder(Decimal(2));
/// print(d);           // 3 remainder 1.5
/// print(d.quotient);  // 3
/// print(d.remainder); // 1.5
/// ```
final class Division {
  /// Integer quotient.
  final BigInt quotient;

  /// Remainder.
  final Decimal remainder;

  /// Divides [dividend] by [divisor] and keeps the quotient whole.
  ///
  /// Throws `UnsupportedError` when [divisor] is zero.
  factory Division(Decimal dividend, Decimal divisor) {
    if (divisor.isZero) {
      throw UnsupportedError('division by zero');
    }

    final (a, b, scale) = dividend._align(divisor);

    // The scale of an aligned pair is negative for round numbers, and the
    // public constructor asserts it is not. The remainder is built by the
    // internal one for that reason.
    return Division._(a ~/ b, Decimal._asIs(a.remainder(b), scale));
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
