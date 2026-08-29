/// The BigInt family alone: [Decimal], its fraction, its division, its
/// exception.
///
/// The same [Decimal] the umbrella `denary.dart` exports, without
/// `ShortDecimal` and without the bridge between the two. Import this one where
/// the magnitudes are not known in advance and the int64 family would only be
/// dead weight.
///
/// ```dart
/// import 'package:denary/decimal.dart';
///
/// final price = Decimal.parse('19.99');
/// print(price * Decimal(3)); // 59.97
/// ```
library;

// Imported, and not only exported, so that the references in the comment
// above resolve: a library's own scope does not include what it re-exports.
import 'src/decimal/decimal.dart';

export 'src/decimal/decimal.dart';
export 'src/errors.dart';
