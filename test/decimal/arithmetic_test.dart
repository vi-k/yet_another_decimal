/// Арифметика `Decimal`: сложение, умножение, модуль, степень.
///
/// Форма хранения результата здесь не сверяется — она артефакт алгоритма.
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';

void main() {
  group('Decimal', () {
    test('add', () {
      var value = Decimal(10000);
      expectDecimal(value += Decimal(1000), '11000', fractionDigits: 0);
      expectDecimal(value += Decimal(100), '11100', fractionDigits: 0);
      expectDecimal(value += Decimal(10), '11110', fractionDigits: 0);
      expectDecimal(
        value += Decimal(10000, shiftRight: 4), // 1
        '11111',
        fractionDigits: 0,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 1),
        '11111.1',
        fractionDigits: 1,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 2),
        '11111.11',
        fractionDigits: 2,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 3),
        '11111.111',
        fractionDigits: 3,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 4),
        '11111.1111',
        fractionDigits: 4,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 5),
        '11111.11111',
        fractionDigits: 5,
      );

      final values = List<Decimal>.generate(
        40,
        (index) => Decimal.fromBigInt(
          BigInt.parse('10000000000000000000'),
          shiftRight: index,
        ),
        growable: false,
      );
      value = values[0];
      for (final v in values.skip(1)) {
        value += v;
      }
      expectDecimal(
        value,
        '11111111111111111111.11111111111111111111',
        fractionDigits: 20,
      );
    });
    test('multiply', () {
      expectDecimal(
        Decimal(123, shiftRight: 2) * Decimal(456, shiftRight: 1),
        '56.088',
        fractionDigits: 3,
      );
      expectDecimal(
        Decimal(-123, shiftRight: 2) * Decimal(456, shiftRight: 1),
        '-56.088',
        fractionDigits: 3,
      );
      expectDecimal(
        Decimal(123, shiftRight: 2) * Decimal(-456, shiftRight: 1),
        '-56.088',
        fractionDigits: 3,
      );
      expectDecimal(
        Decimal(-123, shiftRight: 2) * Decimal(-456, shiftRight: 1),
        '56.088',
        fractionDigits: 3,
      );

      var value = Decimal.parse('123456.00');
      expectDecimal(
        value *= Decimal.parse('12345.6'),
        '1524138393.6',
        fractionDigits: 1,
      );
      expectDecimal(
        value *= Decimal.parse('1234.56'),
        '1881640295202.816',
        fractionDigits: 3,
      );
      expectDecimal(
        value *= Decimal.parse('123.456'),
        '232299784284558.852096',
        fractionDigits: 6,
      );
      expectDecimal(
        value *= Decimal.parse('12.3456'),
        '2867880216863449.7644363776',
        fractionDigits: 10,
      );
      expectDecimal(
        value *= Decimal.parse('1.23456'),
        '3540570200530940.541182574329856',
        fractionDigits: 15,
      );

      value = Decimal.parse('-123456');
      expectDecimal(
        value *= Decimal.parse('12345.6'),
        '-1524138393.6',
        fractionDigits: 1,
      );
      expectDecimal(
        value *= Decimal.parse('-1234.56'),
        '1881640295202.816',
        fractionDigits: 3,
      );
      expectDecimal(
        value *= Decimal.parse('-123.456'),
        '-232299784284558.852096',
        fractionDigits: 6,
      );
      expectDecimal(
        value *= Decimal.parse('-12.3456'),
        '2867880216863449.7644363776',
        fractionDigits: 10,
      );
      expectDecimal(
        value *= Decimal.parse('-1.23456'),
        '-3540570200530940.541182574329856',
        fractionDigits: 15,
      );
    });
    test('abs', () {
      expectDecimal(Decimal(2).abs(), '2', fractionDigits: 0);

      expectDecimal(Decimal(-2).abs(), '2', fractionDigits: 0);

      expectDecimal(
        Decimal.parse('-12345678901234567890.12345678901234567890').abs(),
        '12345678901234567890.1234567890123456789',
        fractionDigits: 19,
      );
    });
    test('pow', () {
      expectDecimal(Decimal(2).pow(4), '16', fractionDigits: 0);

      expectDecimal(
        Decimal(2, shiftRight: 1).pow(4),
        '0.0016',
        fractionDigits: 4,
      );
    });
  });
}
