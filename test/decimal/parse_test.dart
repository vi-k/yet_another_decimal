/// Разбор строк и конструкторы `Decimal`.
///
/// Здесь сверка `base` и `scale` уместна: `parse` обязан сохранить форму
/// записи как есть, а не нормализовать её.
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';

void main() {
  group('Decimal', () {
    group('parse', () {
      group('0', () {
        test('0', () {
          expectDecimal(
            Decimal.parse('0'),
            '0',
            base: BigInt.zero,
            scale: 0,
            fractionDigits: 0,
          );
        });

        test('0.0', () {
          expectDecimal(
            Decimal.parse('0.0'),
            '0',
            base: BigInt.zero,
            scale: 1,
            fractionDigits: 0,
          );
        });

        test('.0', () {
          expectDecimal(
            Decimal.parse('.0'),
            '0',
            base: BigInt.zero,
            scale: 1,
            fractionDigits: 0,
          );
        });

        test('00000.00000', () {
          expectDecimal(
            Decimal.parse('00000.00000'),
            '0',
            base: BigInt.zero,
            scale: 5,
            fractionDigits: 0,
          );
        });

        test(' 0', () {
          expectDecimal(
            Decimal.parse(' 0'),
            '0',
            base: BigInt.zero,
            scale: 0,
            fractionDigits: 0,
          );
        });

        test('0 ', () {
          expectDecimal(
            Decimal.parse('0 '),
            '0',
            base: BigInt.zero,
            scale: 0,
            fractionDigits: 0,
          );
        });

        test(' 0 ', () {
          expectDecimal(
            Decimal.parse(' 0 '),
            '0',
            base: BigInt.zero,
            scale: 0,
            fractionDigits: 0,
          );
        });

        test(' 0.0', () {
          expectDecimal(
            Decimal.parse(' 0.0'),
            '0',
            base: BigInt.zero,
            scale: 1,
            fractionDigits: 0,
          );
        });

        test('0.0 ', () {
          expectDecimal(
            Decimal.parse('0.0 '),
            '0',
            base: BigInt.zero,
            scale: 1,
            fractionDigits: 0,
          );
        });

        test(' 0.0 ', () {
          expectDecimal(
            Decimal.parse(' 0.0 '),
            '0',
            base: BigInt.zero,
            scale: 1,
            fractionDigits: 0,
          );
        });

        test('Decimal(0) >> 10', () {
          expectDecimal(
            Decimal(0) >> 10,
            '0',
            base: BigInt.zero,
            scale: 10,
            fractionDigits: 0,
          );
        });

        test('Decimal(0) << 10', () {
          expectDecimal(
            Decimal(0) << 10,
            '0',
            base: BigInt.zero,
            scale: -10,
            fractionDigits: 0,
          );
        });

        test('-0', () {
          expectDecimal(
            Decimal.parse('-0'),
            '0',
            base: BigInt.zero,
            scale: 0,
            fractionDigits: 0,
          );
        });

        test('-0.0', () {
          expectDecimal(
            Decimal.parse('-0.0'),
            '0',
            base: BigInt.zero,
            scale: 1,
            fractionDigits: 0,
          );
        });

        test('-.0', () {
          expectDecimal(
            Decimal.parse('-.0'),
            '0',
            base: BigInt.zero,
            scale: 1,
            fractionDigits: 0,
          );
        });

        test('-00000.00000', () {
          expectDecimal(
            Decimal.parse('-00000.00000'),
            '0',
            base: BigInt.zero,
            scale: 5,
            fractionDigits: 0,
          );
        });

        test('0. throws', () {
          expect(
            () => Decimal.parse('0.'),
            throwsA(
              predicate(
                (error) =>
                    error is FormatException &&
                    error.message == 'Could not parse $Decimal: 0.',
              ),
            ),
          );
        });

        test('0.0. throws', () {
          expect(
            () => Decimal.parse('0.0.'),
            throwsA(
              predicate(
                (error) =>
                    error is FormatException &&
                    error.message == 'Could not parse $Decimal: 0.0.',
              ),
            ),
          );
        });

        test('0..0 throws', () {
          expect(
            () => Decimal.parse('0..0'),
            throwsA(
              predicate(
                (error) =>
                    error is FormatException &&
                    error.message == 'Could not parse $Decimal: 0..0',
              ),
            ),
          );
        });
      });

      test('1', () {
        expectDecimal(
          Decimal.parse('1'),
          '1',
          base: BigInt.one,
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('0.1'),
          '0.1',
          base: BigInt.one,
          scale: 1,
          fractionDigits: 1,
        );
        expectDecimal(
          Decimal.parse('.1'),
          '0.1',
          base: BigInt.one,
          scale: 1,
          fractionDigits: 1,
        );
        expectDecimal(
          Decimal.parse('0.01'),
          '0.01',
          base: BigInt.one,
          scale: 2,
          fractionDigits: 2,
        );
        expectDecimal(
          Decimal.parse('0.001'),
          '0.001',
          base: BigInt.one,
          scale: 3,
          fractionDigits: 3,
        );
        expectDecimal(
          Decimal.parse('1.0'),
          '1',
          base: BigInt.from(10),
          scale: 1,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('1.00'),
          '1',
          base: BigInt.from(100),
          scale: 2,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('1.000'),
          '1',
          base: BigInt.from(1000),
          scale: 3,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('10'),
          '10',
          base: BigInt.from(10),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('100'),
          '100',
          base: BigInt.from(100),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('1000'),
          '1000',
          base: BigInt.from(1000),
          scale: 0,
          fractionDigits: 0,
        );

        expect(
          () => Decimal.parse('0.1 0'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $Decimal: 0.1 0',
            ),
          ),
        );

        expect(
          () => Decimal.parse('1..0'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $Decimal: 1..0',
            ),
          ),
        );

        expect(
          () => Decimal.parse('1 000'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $Decimal: 1 000',
            ),
          ),
        );

        expect(
          () => Decimal.parse('1,000.0'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $Decimal: 1,000.0',
            ),
          ),
        );

        expect(
          () => Decimal.parse("1'000.0"),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == "Could not parse $Decimal: 1'000.0",
            ),
          ),
        );

        expectDecimal(
          Decimal.parse('-1'),
          '-1',
          base: -BigInt.one,
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-0.1'),
          '-0.1',
          base: -BigInt.one,
          scale: 1,
          fractionDigits: 1,
        );
        expectDecimal(
          Decimal.parse('-0.01'),
          '-0.01',
          base: -BigInt.one,
          scale: 2,
          fractionDigits: 2,
        );
        expectDecimal(
          Decimal.parse('-0.001'),
          '-0.001',
          base: -BigInt.one,
          scale: 3,
          fractionDigits: 3,
        );
        expectDecimal(
          Decimal.parse('-1.0'),
          '-1',
          base: BigInt.from(-10),
          scale: 1,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-1.00'),
          '-1',
          base: BigInt.from(-100),
          scale: 2,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-1.000'),
          '-1',
          base: BigInt.from(-1000),
          scale: 3,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-10'),
          '-10',
          base: BigInt.from(-10),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-100'),
          '-100',
          base: BigInt.from(-100),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-1000'),
          '-1000',
          base: BigInt.from(-1000),
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('int', () {
        expectDecimal(
          Decimal.parse('1234567890'),
          '1234567890',
          base: BigInt.from(1234567890),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('123456789.0'),
          '123456789',
          base: BigInt.from(1234567890),
          scale: 1,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('12345678.90'),
          '12345678.9',
          base: BigInt.from(1234567890),
          scale: 2,
          fractionDigits: 1,
        );
        expectDecimal(
          Decimal.parse('1234567.890'),
          '1234567.89',
          base: BigInt.from(1234567890),
          scale: 3,
          fractionDigits: 2,
        );
        expectDecimal(
          Decimal.parse('123456.7890'),
          '123456.789',
          base: BigInt.from(1234567890),
          scale: 4,
          fractionDigits: 3,
        );
        expectDecimal(
          Decimal.parse('12345.67890'),
          '12345.6789',
          base: BigInt.from(1234567890),
          scale: 5,
          fractionDigits: 4,
        );
        expectDecimal(
          Decimal.parse('1234.567890'),
          '1234.56789',
          base: BigInt.from(1234567890),
          scale: 6,
          fractionDigits: 5,
        );
        expectDecimal(
          Decimal.parse('123.4567890'),
          '123.456789',
          base: BigInt.from(1234567890),
          scale: 7,
          fractionDigits: 6,
        );
        expectDecimal(
          Decimal.parse('12.34567890'),
          '12.3456789',
          base: BigInt.from(1234567890),
          scale: 8,
          fractionDigits: 7,
        );
        expectDecimal(
          Decimal.parse('1.234567890'),
          '1.23456789',
          base: BigInt.from(1234567890),
          scale: 9,
          fractionDigits: 8,
        );
        expectDecimal(
          Decimal.parse('0.1234567890'),
          '0.123456789',
          base: BigInt.from(1234567890),
          scale: 10,
          fractionDigits: 9,
        );
        expectDecimal(
          Decimal.parse('0.01234567890'),
          '0.0123456789',
          base: BigInt.from(1234567890),
          scale: 11,
          fractionDigits: 10,
        );
        expectDecimal(
          Decimal.parse('0.001234567890'),
          '0.00123456789',
          base: BigInt.from(1234567890),
          scale: 12,
          fractionDigits: 11,
        );
        expectDecimal(
          Decimal.parse('0.0001234567890'),
          '0.000123456789',
          base: BigInt.from(1234567890),
          scale: 13,
          fractionDigits: 12,
        );

        expectDecimal(
          Decimal.parse('-1234567890'),
          '-1234567890',
          base: BigInt.from(-1234567890),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-123456789.0'),
          '-123456789',
          base: BigInt.from(-1234567890),
          scale: 1,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-12345678.90'),
          '-12345678.9',
          base: BigInt.from(-1234567890),
          scale: 2,
          fractionDigits: 1,
        );
        expectDecimal(
          Decimal.parse('-1234567.890'),
          '-1234567.89',
          base: BigInt.from(-1234567890),
          scale: 3,
          fractionDigits: 2,
        );
        expectDecimal(
          Decimal.parse('-123456.7890'),
          '-123456.789',
          base: BigInt.from(-1234567890),
          scale: 4,
          fractionDigits: 3,
        );
        expectDecimal(
          Decimal.parse('-12345.67890'),
          '-12345.6789',
          base: BigInt.from(-1234567890),
          scale: 5,
          fractionDigits: 4,
        );
        expectDecimal(
          Decimal.parse('-1234.567890'),
          '-1234.56789',
          base: BigInt.from(-1234567890),
          scale: 6,
          fractionDigits: 5,
        );
        expectDecimal(
          Decimal.parse('-123.4567890'),
          '-123.456789',
          base: BigInt.from(-1234567890),
          scale: 7,
          fractionDigits: 6,
        );
        expectDecimal(
          Decimal.parse('-12.34567890'),
          '-12.3456789',
          base: BigInt.from(-1234567890),
          scale: 8,
          fractionDigits: 7,
        );
        expectDecimal(
          Decimal.parse('-1.234567890'),
          '-1.23456789',
          base: BigInt.from(-1234567890),
          scale: 9,
          fractionDigits: 8,
        );
        expectDecimal(
          Decimal.parse('-0.1234567890'),
          '-0.123456789',
          base: BigInt.from(-1234567890),
          scale: 10,
          fractionDigits: 9,
        );
        expectDecimal(
          Decimal.parse('-0.01234567890'),
          '-0.0123456789',
          base: BigInt.from(-1234567890),
          scale: 11,
          fractionDigits: 10,
        );
        expectDecimal(
          Decimal.parse('-0.001234567890'),
          '-0.00123456789',
          base: BigInt.from(-1234567890),
          scale: 12,
          fractionDigits: 11,
        );
        expectDecimal(
          Decimal.parse('-0.0001234567890'),
          '-0.000123456789',
          base: BigInt.from(-1234567890),
          scale: 13,
          fractionDigits: 12,
        );
      });

      test('BigInt', () {
        // BigInt
        expectDecimal(
          Decimal.parse('1234567890123456789012345678901234567890'),
          '1234567890123456789012345678901234567890',
          base: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('123456789012345678901234567890.1234567890'),
          '123456789012345678901234567890.123456789',
          base: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 10,
          fractionDigits: 9,
        );
        expectDecimal(
          Decimal.parse('12345678901234567890.12345678901234567890'),
          '12345678901234567890.1234567890123456789',
          base: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 20,
          fractionDigits: 19,
        );
        expectDecimal(
          Decimal.parse('1234567890.123456789012345678901234567890'),
          '1234567890.12345678901234567890123456789',
          base: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 30,
          fractionDigits: 29,
        );
        expectDecimal(
          Decimal.parse('0.1234567890123456789012345678901234567890'),
          '0.123456789012345678901234567890123456789',
          base: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 40,
          fractionDigits: 39,
        );
        expectDecimal(
          Decimal.parse('0.00000000001234567890123456789012345678901234567890'),
          '0.0000000000123456789012345678901234567890123456789',
          base: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 50,
          fractionDigits: 49,
        );

        expectDecimal(
          Decimal.parse('-1234567890123456789012345678901234567890'),
          '-1234567890123456789012345678901234567890',
          base: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-123456789012345678901234567890.1234567890'),
          '-123456789012345678901234567890.123456789',
          base: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 10,
          fractionDigits: 9,
        );
        expectDecimal(
          Decimal.parse('-12345678901234567890.12345678901234567890'),
          '-12345678901234567890.1234567890123456789',
          base: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 20,
          fractionDigits: 19,
        );
        expectDecimal(
          Decimal.parse('-1234567890.123456789012345678901234567890'),
          '-1234567890.12345678901234567890123456789',
          base: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 30,
          fractionDigits: 29,
        );
        expectDecimal(
          Decimal.parse('-0.1234567890123456789012345678901234567890'),
          '-0.123456789012345678901234567890123456789',
          base: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 40,
          fractionDigits: 39,
        );
        expectDecimal(
          Decimal.parse(
            '-0.00000000001234567890123456789012345678901234567890',
          ),
          '-0.0000000000123456789012345678901234567890123456789',
          base: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 50,
          fractionDigits: 49,
        );

        expectDecimal(
          Decimal.parse('1000000000000000000000000000000'),
          '1000000000000000000000000000000',
          base: BigInt.parse('1000000000000000000000000000000'),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('100000000000000000000.0000000000'),
          '100000000000000000000',
          base: BigInt.parse('1000000000000000000000000000000'),
          scale: 10,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('10000000000.00000000000000000000'),
          '10000000000',
          base: BigInt.parse('1000000000000000000000000000000'),
          scale: 20,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('1.000000000000000000000000000000'),
          '1',
          base: BigInt.parse('1000000000000000000000000000000'),
          scale: 30,
          fractionDigits: 0,
        );
      });
    });

    group('конструктор', () {
      test('отрицательный сдвиг отвергается, а не проверяется ассертом', () {
        // Р16: проверка стояла `assert`, то есть в release её не было вовсе,
        // и `Decimal(1, shiftRight: -3)` молча считался за 1000.
        expect(() => Decimal(1, shiftRight: -3), throwsArgumentError);
        expect(
          () => Decimal.fromBigInt(BigInt.one, shiftRight: -1),
          throwsArgumentError,
        );

        expectDecimal(Decimal(1), '1');
        expectDecimal(Decimal(1, shiftRight: 3), '0.001');
      });
    });
  });
}
