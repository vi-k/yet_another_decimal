// ignore_for_file: avoid_js_rounded_ints

/// Разбор строк и конструкторы `ShortDecimal`.
///
/// Здесь сверка `base` и `scale` уместна: `parse` обязан сохранить форму
/// записи как есть, а не нормализовать её.
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';

void main() {
  group('ShortDecimal', () {
    group('parse', () {
      test('0', () {
        for (final p in [
          (ShortDecimal.parse('0'), '0', 0, 0, 0),
          (ShortDecimal.parse('0.0'), '0', 0, 0, 0),
          (ShortDecimal.parse('.0'), '0', 0, 0, 0),
          (ShortDecimal.parse('00000.00000'), '0', 0, 0, 0),
          (ShortDecimal.parse(' 0'), '0', 0, 0, 0),
          (ShortDecimal.parse('0 '), '0', 0, 0, 0),
          (ShortDecimal.parse(' 0 '), '0', 0, 0, 0),
          (ShortDecimal.parse(' 0.0'), '0', 0, 0, 0),
          (ShortDecimal.parse('0.0 '), '0', 0, 0, 0),
          (ShortDecimal.parse(' 0.0 '), '0', 0, 0, 0),
          (ShortDecimal(0) >> 10, '0', 0, 0, 0),
          (ShortDecimal(0) << 10, '0', 0, 0, 0),
          (ShortDecimal.parse('-0'), '0', 0, 0, 0),
          (ShortDecimal.parse('-0.0'), '0', 0, 0, 0),
          (ShortDecimal.parse('-.0'), '0', 0, 0, 0),
          (ShortDecimal.parse('-00000.00000'), '0', 0, 0, 0),
        ]) {
          expectShortDecimal(
            p.$1,
            p.$2,
            base: p.$3,
            scale: p.$4,
            fractionDigits: p.$5,
          );
        }

        expect(
          () => ShortDecimal.parse('0.'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $ShortDecimal: 0.',
            ),
          ),
        );

        expect(
          () => ShortDecimal.parse('0.0.'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $ShortDecimal: 0.0.',
            ),
          ),
        );

        expect(
          () => ShortDecimal.parse('0..0'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $ShortDecimal: 0..0',
            ),
          ),
        );
      });

      test('1', () {
        expectShortDecimal(
          ShortDecimal.parse('1'),
          '1',
          base: 1,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('0.1'),
          '0.1',
          base: 1,
          scale: 1,
          fractionDigits: 1,
        );
        expectShortDecimal(
          ShortDecimal.parse('.1'),
          '0.1',
          base: 1,
          scale: 1,
          fractionDigits: 1,
        );
        expectShortDecimal(
          ShortDecimal.parse('0.01'),
          '0.01',
          base: 1,
          scale: 2,
          fractionDigits: 2,
        );
        expectShortDecimal(
          ShortDecimal.parse('0.001'),
          '0.001',
          base: 1,
          scale: 3,
          fractionDigits: 3,
        );
        expectShortDecimal(
          ShortDecimal.parse('1.0'),
          '1',
          base: 1,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('1.00'),
          '1',
          base: 1,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('1.000'),
          '1',
          base: 1,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('10'),
          '10',
          base: 1,
          scale: -1,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('100'),
          '100',
          base: 1,
          scale: -2,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('1000'),
          '1000',
          base: 1,
          scale: -3,
          fractionDigits: 0,
        );

        expect(
          () => ShortDecimal.parse('0.1 0'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $ShortDecimal: 0.1 0',
            ),
          ),
        );

        expect(
          () => ShortDecimal.parse('1..0'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $ShortDecimal: 1..0',
            ),
          ),
        );

        expect(
          () => ShortDecimal.parse('1 000'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $ShortDecimal: 1 000',
            ),
          ),
        );

        expect(
          () => ShortDecimal.parse('1,000.0'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $ShortDecimal: 1,000.0',
            ),
          ),
        );

        expect(
          () => ShortDecimal.parse("1'000.0"),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == "Could not parse $ShortDecimal: 1'000.0",
            ),
          ),
        );

        expectShortDecimal(
          ShortDecimal.parse('-1'),
          '-1',
          base: -1,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('-0.1'),
          '-0.1',
          base: -1,
          scale: 1,
          fractionDigits: 1,
        );
        expectShortDecimal(
          ShortDecimal.parse('-0.01'),
          '-0.01',
          base: -1,
          scale: 2,
          fractionDigits: 2,
        );
        expectShortDecimal(
          ShortDecimal.parse('-0.001'),
          '-0.001',
          base: -1,
          scale: 3,
          fractionDigits: 3,
        );
        expectShortDecimal(
          ShortDecimal.parse('-1.0'),
          '-1',
          base: -1,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('-1.00'),
          '-1',
          base: -1,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('-1.000'),
          '-1',
          base: -1,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('-10'),
          '-10',
          base: -1,
          scale: -1,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('-100'),
          '-100',
          base: -1,
          scale: -2,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('-1000'),
          '-1000',
          base: -1,
          scale: -3,
          fractionDigits: 0,
        );
      });

      test('int', () {
        expectShortDecimal(
          ShortDecimal.parse('1234567890'),
          '1234567890',
          base: 123456789,
          scale: -1,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('123456789.0'),
          '123456789',
          base: 123456789,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('12345678.90'),
          '12345678.9',
          base: 123456789,
          scale: 1,
          fractionDigits: 1,
        );
        expectShortDecimal(
          ShortDecimal.parse('1234567.890'),
          '1234567.89',
          base: 123456789,
          scale: 2,
          fractionDigits: 2,
        );
        expectShortDecimal(
          ShortDecimal.parse('123456.7890'),
          '123456.789',
          base: 123456789,
          scale: 3,
          fractionDigits: 3,
        );
        expectShortDecimal(
          ShortDecimal.parse('12345.67890'),
          '12345.6789',
          base: 123456789,
          scale: 4,
          fractionDigits: 4,
        );
        expectShortDecimal(
          ShortDecimal.parse('1234.567890'),
          '1234.56789',
          base: 123456789,
          scale: 5,
          fractionDigits: 5,
        );
        expectShortDecimal(
          ShortDecimal.parse('123.4567890'),
          '123.456789',
          base: 123456789,
          scale: 6,
          fractionDigits: 6,
        );
        expectShortDecimal(
          ShortDecimal.parse('12.34567890'),
          '12.3456789',
          base: 123456789,
          scale: 7,
          fractionDigits: 7,
        );
        expectShortDecimal(
          ShortDecimal.parse('1.234567890'),
          '1.23456789',
          base: 123456789,
          scale: 8,
          fractionDigits: 8,
        );
        expectShortDecimal(
          ShortDecimal.parse('0.1234567890'),
          '0.123456789',
          base: 123456789,
          scale: 9,
          fractionDigits: 9,
        );
        expectShortDecimal(
          ShortDecimal.parse('0.01234567890'),
          '0.0123456789',
          base: 123456789,
          scale: 10,
          fractionDigits: 10,
        );
        expectShortDecimal(
          ShortDecimal.parse('0.001234567890'),
          '0.00123456789',
          base: 123456789,
          scale: 11,
          fractionDigits: 11,
        );
        expectShortDecimal(
          ShortDecimal.parse('0.0001234567890'),
          '0.000123456789',
          base: 123456789,
          scale: 12,
          fractionDigits: 12,
        );

        expectShortDecimal(
          ShortDecimal.parse('-1234567890'),
          '-1234567890',
          base: -123456789,
          scale: -1,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('-123456789.0'),
          '-123456789',
          base: -123456789,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('-12345678.90'),
          '-12345678.9',
          base: -123456789,
          scale: 1,
          fractionDigits: 1,
        );
        expectShortDecimal(
          ShortDecimal.parse('-1234567.890'),
          '-1234567.89',
          base: -123456789,
          scale: 2,
          fractionDigits: 2,
        );
        expectShortDecimal(
          ShortDecimal.parse('-123456.7890'),
          '-123456.789',
          base: -123456789,
          scale: 3,
          fractionDigits: 3,
        );
        expectShortDecimal(
          ShortDecimal.parse('-12345.67890'),
          '-12345.6789',
          base: -123456789,
          scale: 4,
          fractionDigits: 4,
        );
        expectShortDecimal(
          ShortDecimal.parse('-1234.567890'),
          '-1234.56789',
          base: -123456789,
          scale: 5,
          fractionDigits: 5,
        );
        expectShortDecimal(
          ShortDecimal.parse('-123.4567890'),
          '-123.456789',
          base: -123456789,
          scale: 6,
          fractionDigits: 6,
        );
        expectShortDecimal(
          ShortDecimal.parse('-12.34567890'),
          '-12.3456789',
          base: -123456789,
          scale: 7,
          fractionDigits: 7,
        );
        expectShortDecimal(
          ShortDecimal.parse('-1.234567890'),
          '-1.23456789',
          base: -123456789,
          scale: 8,
          fractionDigits: 8,
        );
        expectShortDecimal(
          ShortDecimal.parse('-0.1234567890'),
          '-0.123456789',
          base: -123456789,
          scale: 9,
          fractionDigits: 9,
        );
        expectShortDecimal(
          ShortDecimal.parse('-0.01234567890'),
          '-0.0123456789',
          base: -123456789,
          scale: 10,
          fractionDigits: 10,
        );
        expectShortDecimal(
          ShortDecimal.parse('-0.001234567890'),
          '-0.00123456789',
          base: -123456789,
          scale: 11,
          fractionDigits: 11,
        );
        expectShortDecimal(
          ShortDecimal.parse('-0.0001234567890'),
          '-0.000123456789',
          base: -123456789,
          scale: 12,
          fractionDigits: 12,
        );

        expectShortDecimal(
          ShortDecimal.parse('-9223372036854775808'),
          '-9223372036854775808',
          base: -9223372036854775808,
          scale: 0,
          fractionDigits: 0,
        );

        expectShortDecimal(
          ShortDecimal.parse('-922337203685477580.8'),
          '-922337203685477580.8',
          base: -9223372036854775808,
          scale: 1,
          fractionDigits: 1,
        );
      });
    });
  });
}
