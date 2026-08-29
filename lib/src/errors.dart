/// The refusals this package makes about numbers of its own, typed.
///
/// Both live in the `ArgumentError` family, so code that already catches
/// `ArgumentError` — or reads `name`, `invalidValue` and `message` off it —
/// keeps working. The type is there for the code that wants to tell one
/// refusal from another without reading the message.
library;

/// A scale that would leave int64.
///
/// The scale is the one number in this package that cannot grow to fit: the
/// unscaled value is a `BigInt` in one family and an `int` in the other, and
/// the scale is a plain `int` in both. An operation that would take it out of
/// int64 refuses instead of coming back with the wrong order of magnitude —
/// `Decimal.parse('0.01').pow(int.max)` used to print `100`.
///
/// ```dart
/// try {
///   Decimal.one >> 9223372036854775807 >> 1;
/// } on ScaleOutOfRangeError catch (e) {
///   print(e.name); // shiftAmount
/// }
/// ```
final class ScaleOutOfRangeError extends ArgumentError {
  /// The refusal, naming the argument that asked for it.
  ScaleOutOfRangeError(Object? value, [String? name])
      : super.value(value, name, 'The scale would leave int64');
}

/// A number of digits, or a power of ten, past what this package will build.
///
/// The bound is a million, and it is the same one everywhere: the number of
/// digits a caller asks for when rounding, dividing or printing, the exponent
/// a string is read with, and the power of ten an operation needs on the way.
/// Ten to the billionth is a number nobody can hold, and going for it took the
/// memory of the process rather than answering.
///
/// ```dart
/// try {
///   Decimal.one.round(-1000000000);
/// } on DecimalDigitsOutOfRangeError catch (e) {
///   print(e.invalidValue); // -1000000000
/// }
/// ```
final class DecimalDigitsOutOfRangeError extends ArgumentError {
  /// The refusal, naming the argument that asked for it.
  ///
  /// The [message] is spelled out where the number asked for is not the
  /// caller's own — a power of ten that an operation went looking for.
  DecimalDigitsOutOfRangeError(
    Object? value, [
    String? name,
    String? message,
  ]) : super.value(
          value,
          name,
          message ?? 'The number of digits must be within a million of zero',
        );
}
