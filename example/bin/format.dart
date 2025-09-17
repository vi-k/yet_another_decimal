// import 'dart:math' as math;

// import 'package:intl/intl.dart';
// import 'package:intl/number_symbols.dart';
// import 'package:yet_another_decimal/yet_another_decimal.dart';

// void main() {
//   // Intl.defaultLocale = 'de_DE';
//   // Intl.defaultLocale = 'bn';
//   // Intl.defaultLocale = 'ar_EG';

//   // final decimal = Decimal.parse('12345.6789');
//   final decimal = Decimal.parse('1234567890123456789012345678901234567890');
//   Intl.defaultLocale = 'ru_RU';
//   for (final format in [
//     NumberFormat.compact(),
//     NumberFormat.compactCurrency(),
//     NumberFormat.compactLong(),
//     NumberFormat.compactSimpleCurrency(),
//     NumberFormat.currency(),
//     NumberFormat.decimalPattern()..minimumFractionDigits = 21,
//     NumberFormat.decimalPatternDigits(),
//     NumberFormat.decimalPercentPattern(),
//     NumberFormat.percentPattern(),
//     // NumberFormat.scientificPattern()
//     // ..minimumExponentDigits = 3
//     // ..minimumSignificantDigits = 10
//     // ..minimumSignificantDigitsStrict = true
//     // ,
//     NumberFormat.simpleCurrency(),
//   ]) {
//     // print(format.format(Num(decimal.toDouble())));
//     print(format.format(DecimalNum(decimal)));
//   }
//   // var format = NumberFormat.compact(locale: 'ru_RU');
//   // var format = NumberFormat.compactCurrency(locale: 'ru_RU');
//   // var format = NumberFormat.compactLong(locale: 'ru_RU');
//   // var format = NumberFormat.compactSimpleCurrency(locale: 'ru_RU');
//   // var format = NumberFormat.currency(locale: 'ru_RU');
//   // var format = NumberFormat.decimalPattern('ru_RU');
//   // print(format.toDebugString());
//   // print(format.format(12345.6789));
//   // print(format.format(_DecimalIntl(d)));

//   // print('');
//   // format = NumberFormat.decimalPattern('en_US');
//   // print(format.toDebugString());
//   // print(format.format(12345.6789));

//   // print('');
//   // format = NumberFormat.decimalPattern('bn');
//   // print(format.toDebugString());
//   // print(format.format(12345.6789));

//   // print('');
//   // format = NumberFormat.decimalPattern('ar_EG');
//   // print(format.toDebugString());
//   // print(format.format(12345.6789));
// }

// extension NumberFormatExtension on NumberFormat {
//   String toDebugString() {
//     final result = <String, Object?>{
//       'currencyName': currencyName,
//       'currencySymbol': currencySymbol,
//       'decimalDigits': decimalDigits,
//       'maximumFractionDigits': maximumFractionDigits,
//       'maximumIntegerDigits': maximumIntegerDigits,
//       'maximumSignificantDigits': maximumSignificantDigits,
//       'minimumExponentDigits': minimumExponentDigits,
//       'minimumFractionDigits': minimumFractionDigits,
//       'minimumIntegerDigits': minimumIntegerDigits,
//       'minimumSignificantDigits': minimumSignificantDigits,
//       'minimumSignificantDigitsStrict': minimumSignificantDigitsStrict,
//       'multiplier': multiplier,
//       'negativePrefix': negativePrefix,
//       'negativeSuffix': negativeSuffix,
//       'positivePrefix': positivePrefix,
//       'positiveSuffix': positiveSuffix,
//       'significantDigitsInUse': significantDigitsInUse,
//       'symbols': symbols.toDebugString(),
//     }.entries.map((e) => '${e.key}: ${e.value}').join(', ');

//     return '$NumberFormat($result)';
//   }
// }

// extension NumberSymbolsExtexnsion on NumberSymbols {
//   String toDebugString() {
//     final result = <String, Object?>{
//       'CURRENCY_PATTERN': CURRENCY_PATTERN,
//       'DECIMAL_PATTERN': DECIMAL_PATTERN,
//       'DECIMAL_SEP': DECIMAL_SEP,
//       'DEF_CURRENCY_CODE': DEF_CURRENCY_CODE,
//       'EXP_SYMBOL': EXP_SYMBOL,
//       'GROUP_SEP': GROUP_SEP,
//       'INFINITY': INFINITY,
//       'MINUS_SIGN': MINUS_SIGN,
//       'NAME': NAME,
//       'NAN': NAN,
//       'PERCENT': PERCENT,
//       'PERCENT_PATTERN': PERCENT_PATTERN,
//       'PERMILL': PERMILL,
//       'PLUS_SIGN': PLUS_SIGN,
//       'SCIENTIFIC_PATTERN': SCIENTIFIC_PATTERN,
//       'ZERO_DIGIT': ZERO_DIGIT,
//       'digits': digits(ZERO_DIGIT),
//     }.entries.map((e) => '${e.key}: ${e.value}').join(', ');

//     return '$NumberSymbols($result)';
//   }
// }

// String digits(String zeroDigit) {
//   final zeroCharCode = zeroDigit.codeUnitAt(0);

//   return String.fromCharCodes(
//     List.generate(10, (index) => zeroCharCode + index),
//   );
// }

// final class DecimalNum implements Num {
//   final Decimal value;

//   const DecimalNum(this.value);

//   @override
//   bool get isInfinite => false;

//   @override
//   bool get isNaN => false;

//   @override
//   bool get isZero => value.isZero;

//   @override
//   bool get isNegative => value.isNegative;

//   @override
//   DecimalNum abs() => DecimalNum(value.abs());

//   @override
//   bool operator <(Num other) => switch (other) {
//         DecimalNum() => value < other.value,
//         IntNum() => value < Decimal(other.value),
//         BigIntNum() => value < Decimal.fromBigInt(other.value),
//         _ => throw UnimplementedError(),
//       };

//   @override
//   bool operator <=(Num other) => switch (other) {
//         DecimalNum() => value <= other.value,
//         IntNum() => value <= Decimal(other.value),
//         BigIntNum() => value <= Decimal.fromBigInt(other.value),
//         _ => throw UnimplementedError(),
//       };

//   @override
//   bool operator >(Num other) => switch (other) {
//         DecimalNum() => value > other.value,
//         IntNum() => value > Decimal(other.value),
//         BigIntNum() => value > Decimal.fromBigInt(other.value),
//         _ => throw UnimplementedError(),
//       };

//   @override
//   bool operator >=(Num other) => switch (other) {
//         DecimalNum() => value >= other.value,
//         IntNum() => value >= Decimal(other.value),
//         BigIntNum() => value >= Decimal.fromBigInt(other.value),
//         _ => throw UnimplementedError(),
//       };

//   @override
//   DecimalNum operator +(Num other) => switch (other) {
//         DecimalNum() => DecimalNum(value + other.value),
//         IntNum() => DecimalNum(value + Decimal(other.value)),
//         BigIntNum() => DecimalNum(value + Decimal.fromBigInt(other.value)),
//         _ => throw UnimplementedError(),
//       };

//   @override
//   DecimalNum operator -(Num other) => switch (other) {
//         DecimalNum() => DecimalNum(value - other.value),
//         IntNum() => DecimalNum(value - Decimal(other.value)),
//         BigIntNum() => DecimalNum(value - Decimal.fromBigInt(other.value)),
//         _ => throw UnimplementedError(),
//       };

//   @override
//   Num reversedSubstract(Num other) => switch (other) {
//         DecimalNum() => DecimalNum(other.value - value),
//         IntNum() => DecimalNum(Decimal(other.value) - value),
//         BigIntNum() => DecimalNum(Decimal.fromBigInt(other.value) - value),
//         _ => throw UnimplementedError(),
//       };

//   @override
//   DecimalNum operator *(Num other) => switch (other) {
//         DecimalNum() => DecimalNum(value * other.value),
//         IntNum() => DecimalNum(value * Decimal(other.value)),
//         BigIntNum() => DecimalNum(value * Decimal.fromBigInt(other.value)),
//         _ => throw UnimplementedError(),
//       };

//   @override
//   DecimalNum operator /(Num other) {
//     try {
//       return switch (other) {
//         DecimalNum() => DecimalNum(value / other.value),
//         IntNum() => DecimalNum(value / Decimal(other.value)),
//         BigIntNum() => DecimalNum(value / Decimal.fromBigInt(other.value)),
//         _ => throw UnimplementedError(),
//       };
//     } on DecimalDivideException catch (e) {
//       return DecimalNum(
//         e.round(e.dividend.fractionDigits + e.divisor.fractionDigits),
//       );
//     }
//   }

//   @override
//   Num reversedDivide(Num other) => switch (other) {
//         DecimalNum() => DecimalNum(other.value / value),
//         IntNum() => DecimalNum(Decimal(other.value) / value),
//         BigIntNum() => DecimalNum(Decimal.fromBigInt(other.value) / value),
//         _ => throw UnimplementedError(),
//       };

//   @override
//   Num operator ~/(Num denominator) => switch (denominator) {
//         DecimalNum() => BigIntNum(value ~/ denominator.value),
//         IntNum() => BigIntNum(value ~/ Decimal(denominator.value)),
//         BigIntNum() =>
//           BigIntNum(value ~/ Decimal.fromBigInt(denominator.value)),
//         _ => throw UnimplementedError(),
//       };

//   @override
//   Num reversedTrauncatedDivide(Num other) => switch (other) {
//         DecimalNum() => BigIntNum(other.value ~/ value),
//         IntNum() => BigIntNum(Decimal(other.value) ~/ value),
//         BigIntNum() => BigIntNum(Decimal.fromBigInt(other.value) ~/ value),
//         _ => throw UnimplementedError(),
//       };

//   @override
//   DecimalNum operator %(Num other) => switch (other) {
//         DecimalNum() => DecimalNum(value % other.value),
//         IntNum() => DecimalNum(value % Decimal(other.value)),
//         BigIntNum() => DecimalNum(value % Decimal.fromBigInt(other.value)),
//         _ => throw UnimplementedError(),
//       };

//   @override
//   Num reversedModulo(Num other) => switch (other) {
//         DecimalNum() => DecimalNum(other.value % value),
//         IntNum() => DecimalNum(Decimal(other.value) % value),
//         BigIntNum() => DecimalNum(Decimal.fromBigInt(other.value) % value),
//         _ => throw UnimplementedError(),
//       };

//   @override
//   Num remainder(Num other) => switch (other) {
//         DecimalNum() => DecimalNum(value.remainder(other.value)),
//         IntNum() => DecimalNum(value.remainder(Decimal(other.value))),
//         BigIntNum() =>
//           DecimalNum(value.remainder(Decimal.fromBigInt(other.value))),
//         _ => throw UnimplementedError(),
//       };

//   @override
//   Num reversedRemainder(Num other) => switch (other) {
//         DecimalNum() => DecimalNum(other.value.remainder(value)),
//         IntNum() => DecimalNum(Decimal(other.value).remainder(value)),
//         BigIntNum() =>
//           DecimalNum(Decimal.fromBigInt(other.value).remainder(value)),
//         _ => throw UnimplementedError(),
//       };

//   @override
//   int toInt() => value.toBigInt().toInt();

//   @override
//   BigInt toBigInt() => value.toBigInt();

//   @override
//   double toDouble() => value.toDouble();

//   @override
//   num toNum() => value.toDouble();

//   @override
//   IntegerNum toInteger() => BigIntNum(value.toBigInt());

//   @override
//   DecimalNum ceil() => DecimalNum(value.ceil());

//   @override
//   DecimalNum floor() => DecimalNum(value.floor());

//   @override
//   DecimalNum round() => DecimalNum(value.round());

//   @override
//   DecimalNum truncate() => DecimalNum(value.truncate());

//   @override
//   DoubleNum log() => DoubleNum(math.log(value.toDouble()));

//   @override
//   DecimalNum pow(int exponent) => DecimalNum(value.pow(exponent));

//   @override
//   String toString() => value.toString();

//   @override
//   String toDebugString() => '$DecimalNum($value)';
// }
