// ignore_for_file: avoid_js_rounded_ints

/// Вывод `ShortDecimal` строкой.
///
/// Здесь сверка `base` и `scale` уместна: `toString` обязан снимать хвостовые
/// нули, не трогая представление.
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';

void main() {
  group('ShortDecimal', () {
    test('toString', () {
      for (final p in [
        (ShortDecimal(0), '0', 0, 0, 0),
        (ShortDecimal(0) >> 1, '0', 0, 0, 0),
        (ShortDecimal(0) >> 2, '0', 0, 0, 0),
        (ShortDecimal(0) >> 3, '0', 0, 0, 0),
        (ShortDecimal(1), '1', 1, 0, 0),
        (ShortDecimal(1) >> 1, '0.1', 1, 1, 1),
        (ShortDecimal(1) >> 2, '0.01', 1, 2, 2),
        (ShortDecimal(1) >> 3, '0.001', 1, 3, 3),
        (ShortDecimal(10), '10', 1, -1, 0),
        (ShortDecimal(1) << 1, '10', 1, -1, 0),
        (ShortDecimal(100), '100', 1, -2, 0),
        (ShortDecimal(1) << 2, '100', 1, -2, 0),
        (ShortDecimal(1000), '1000', 1, -3, 0),
        (ShortDecimal(1) << 3, '1000', 1, -3, 0),
        (ShortDecimal(1000) >> 1, '100', 1, -2, 0),
        (ShortDecimal(1000) >> 2, '10', 1, -1, 0),
        (ShortDecimal(1000) >> 3, '1', 1, 0, 0),
        (ShortDecimal(1000) >> 4, '0.1', 1, 1, 1),
        (ShortDecimal(1000) >> 5, '0.01', 1, 2, 2),
        (ShortDecimal(1000) >> 6, '0.001', 1, 3, 3),
        (ShortDecimal(1234567890), '1234567890', 123456789, -1, 0),
        (ShortDecimal(1234567890) >> 1, '123456789', 123456789, 0, 0),
        (ShortDecimal(1234567890) >> 2, '12345678.9', 123456789, 1, 1),
        (ShortDecimal(1234567890) >> 3, '1234567.89', 123456789, 2, 2),
        (ShortDecimal(1234567890) >> 4, '123456.789', 123456789, 3, 3),
        (ShortDecimal(1234567890) >> 5, '12345.6789', 123456789, 4, 4),
        (ShortDecimal(1234567890) >> 6, '1234.56789', 123456789, 5, 5),
        (ShortDecimal(1234567890) >> 7, '123.456789', 123456789, 6, 6),
        (ShortDecimal(1234567890) >> 8, '12.3456789', 123456789, 7, 7),
        (ShortDecimal(1234567890) >> 9, '1.23456789', 123456789, 8, 8),
        (ShortDecimal(1234567890) >> 10, '0.123456789', 123456789, 9, 9),
        (ShortDecimal(1234567890) >> 11, '0.0123456789', 123456789, 10, 10),
        (ShortDecimal(1234567890) >> 12, '0.00123456789', 123456789, 11, 11),
        (ShortDecimal(1234567890) >> 13, '0.000123456789', 123456789, 12, 12),
        (
          ShortDecimal(9223372036854775807),
          '9223372036854775807',
          9223372036854775807,
          0,
          0,
        ),
        (
          ShortDecimal(-9223372036854775808),
          '-9223372036854775808',
          -9223372036854775808,
          0,
          0,
        ),
      ]) {
        expectShortDecimal(
          p.$1,
          p.$2,
          base: p.$3,
          scale: p.$4,
          fractionDigits: p.$5,
        );
      }
    });
  });
}
