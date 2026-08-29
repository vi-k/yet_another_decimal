/// The int64 family alone: [ShortDecimal], its fraction, its division, its
/// exception.
///
/// The same [ShortDecimal] the umbrella `denary.dart` exports,
/// without `Decimal` and without the bridge between the two. Import this one
/// where the values are known to be small and the speed is the point —
/// remembering that overflow here is silent.
///
/// ```dart
/// import 'package:denary/short_decimal.dart';
///
/// final price = ShortDecimal.parse('19.99');
/// print(price * ShortDecimal(3)); // 59.97
/// ```
library;

// Imported, and not only exported, so that the references in the comment
// above resolve: a library's own scope does not include what it re-exports.
import 'src/short_decimal/short_decimal.dart';

export 'src/errors.dart';
export 'src/short_decimal/short_decimal.dart';
