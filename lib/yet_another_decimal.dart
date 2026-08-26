/// Decimal numbers with a fixed point and no loss of precision.
///
/// Two independent families, one contract:
///
/// - [Decimal] keeps the unscaled value in a `BigInt`. No bound on magnitude,
///   no bound on the number of digits, nothing overflows.
/// - [ShortDecimal] keeps it in an `int`. Several times faster and smaller,
///   and in exchange it overflows silently, exactly as `int` does.
///
/// Both hold a value as `base × 10^-scale` and add, multiply, compare and
/// round it exactly: `0.1 + 0.2` is `0.3`, and a sum of money stays the sum it
/// was.
///
/// ```dart
/// final price = Decimal.parse('19.99');
/// final tax = price * Decimal.parse('0.2');
/// print(price + tax); // 23.988
/// ```
///
/// Division is the one operation that cannot always answer — one third has no
/// finite decimal form. Pick how to be told:
///
/// ```dart
/// Decimal(1).divideOrNull(Decimal(3));                        // null
/// Decimal(1).divide(Decimal(3), scaleOnInfinitePrecision: 4); // 0.3333
/// Decimal(1).isDivisibleBy(Decimal(3));                       // false
/// Decimal(1) / Decimal(3);            // throws DecimalDivideException
/// ```
///
/// The families do not mix in one expression: crossing over is explicit, with
/// [ShortDecimalBridge.toDecimal] and
/// [DecimalBridge.toShortDecimalOrNull].
library;

// Imported, and not only exported, so that the references in the comment above
// resolve: a library's own scope does not include what it re-exports.
import 'src/bridge.dart';
import 'src/decimal/decimal.dart';
import 'src/short_decimal/short_decimal.dart';

export 'src/bridge.dart';
export 'src/decimal/decimal.dart';
export 'src/short_decimal/short_decimal.dart';
