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
    group('toString', () {
      test('ShortDecimal(0)', () {
        expectShortDecimal(
          ShortDecimal(0),
          '0',
          base: 0,
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(0) >> 1', () {
        expectShortDecimal(
          ShortDecimal(0) >> 1,
          '0',
          base: 0,
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(0) >> 2', () {
        expectShortDecimal(
          ShortDecimal(0) >> 2,
          '0',
          base: 0,
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(0) >> 3', () {
        expectShortDecimal(
          ShortDecimal(0) >> 3,
          '0',
          base: 0,
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1)', () {
        expectShortDecimal(
          ShortDecimal(1),
          '1',
          base: 1,
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1) >> 1', () {
        expectShortDecimal(
          ShortDecimal(1) >> 1,
          '0.1',
          base: 1,
          scale: 1,
          fractionDigits: 1,
        );
      });

      test('ShortDecimal(1) >> 2', () {
        expectShortDecimal(
          ShortDecimal(1) >> 2,
          '0.01',
          base: 1,
          scale: 2,
          fractionDigits: 2,
        );
      });

      test('ShortDecimal(1) >> 3', () {
        expectShortDecimal(
          ShortDecimal(1) >> 3,
          '0.001',
          base: 1,
          scale: 3,
          fractionDigits: 3,
        );
      });

      test('ShortDecimal(10)', () {
        expectShortDecimal(
          ShortDecimal(10),
          '10',
          base: 1,
          scale: -1,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1) << 1', () {
        expectShortDecimal(
          ShortDecimal(1) << 1,
          '10',
          base: 1,
          scale: -1,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(100)', () {
        expectShortDecimal(
          ShortDecimal(100),
          '100',
          base: 1,
          scale: -2,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1) << 2', () {
        expectShortDecimal(
          ShortDecimal(1) << 2,
          '100',
          base: 1,
          scale: -2,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1000)', () {
        expectShortDecimal(
          ShortDecimal(1000),
          '1000',
          base: 1,
          scale: -3,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1) << 3', () {
        expectShortDecimal(
          ShortDecimal(1) << 3,
          '1000',
          base: 1,
          scale: -3,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1000) >> 1', () {
        expectShortDecimal(
          ShortDecimal(1000) >> 1,
          '100',
          base: 1,
          scale: -2,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1000) >> 2', () {
        expectShortDecimal(
          ShortDecimal(1000) >> 2,
          '10',
          base: 1,
          scale: -1,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1000) >> 3', () {
        expectShortDecimal(
          ShortDecimal(1000) >> 3,
          '1',
          base: 1,
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1000) >> 4', () {
        expectShortDecimal(
          ShortDecimal(1000) >> 4,
          '0.1',
          base: 1,
          scale: 1,
          fractionDigits: 1,
        );
      });

      test('ShortDecimal(1000) >> 5', () {
        expectShortDecimal(
          ShortDecimal(1000) >> 5,
          '0.01',
          base: 1,
          scale: 2,
          fractionDigits: 2,
        );
      });

      test('ShortDecimal(1000) >> 6', () {
        expectShortDecimal(
          ShortDecimal(1000) >> 6,
          '0.001',
          base: 1,
          scale: 3,
          fractionDigits: 3,
        );
      });

      test('ShortDecimal(1234567890)', () {
        expectShortDecimal(
          ShortDecimal(1234567890),
          '1234567890',
          base: 123456789,
          scale: -1,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1234567890) >> 1', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 1,
          '123456789',
          base: 123456789,
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1234567890) >> 2', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 2,
          '12345678.9',
          base: 123456789,
          scale: 1,
          fractionDigits: 1,
        );
      });

      test('ShortDecimal(1234567890) >> 3', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 3,
          '1234567.89',
          base: 123456789,
          scale: 2,
          fractionDigits: 2,
        );
      });

      test('ShortDecimal(1234567890) >> 4', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 4,
          '123456.789',
          base: 123456789,
          scale: 3,
          fractionDigits: 3,
        );
      });

      test('ShortDecimal(1234567890) >> 5', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 5,
          '12345.6789',
          base: 123456789,
          scale: 4,
          fractionDigits: 4,
        );
      });

      test('ShortDecimal(1234567890) >> 6', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 6,
          '1234.56789',
          base: 123456789,
          scale: 5,
          fractionDigits: 5,
        );
      });

      test('ShortDecimal(1234567890) >> 7', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 7,
          '123.456789',
          base: 123456789,
          scale: 6,
          fractionDigits: 6,
        );
      });

      test('ShortDecimal(1234567890) >> 8', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 8,
          '12.3456789',
          base: 123456789,
          scale: 7,
          fractionDigits: 7,
        );
      });

      test('ShortDecimal(1234567890) >> 9', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 9,
          '1.23456789',
          base: 123456789,
          scale: 8,
          fractionDigits: 8,
        );
      });

      test('ShortDecimal(1234567890) >> 10', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 10,
          '0.123456789',
          base: 123456789,
          scale: 9,
          fractionDigits: 9,
        );
      });

      test('ShortDecimal(1234567890) >> 11', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 11,
          '0.0123456789',
          base: 123456789,
          scale: 10,
          fractionDigits: 10,
        );
      });

      test('ShortDecimal(1234567890) >> 12', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 12,
          '0.00123456789',
          base: 123456789,
          scale: 11,
          fractionDigits: 11,
        );
      });

      test('ShortDecimal(1234567890) >> 13', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 13,
          '0.000123456789',
          base: 123456789,
          scale: 12,
          fractionDigits: 12,
        );
      });

      test('ShortDecimal(9223372036854775807)', () {
        expectShortDecimal(
          ShortDecimal(9223372036854775807),
          '9223372036854775807',
          base: 9223372036854775807,
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(-9223372036854775808)', () {
        expectShortDecimal(
          ShortDecimal(-9223372036854775808),
          '-9223372036854775808',
          base: -9223372036854775808,
          scale: 0,
          fractionDigits: 0,
        );
      });
    });
  });
}
