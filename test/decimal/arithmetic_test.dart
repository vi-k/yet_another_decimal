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

    test('константы', () {
      expectDecimal(Decimal.zero, '0');
      expectDecimal(Decimal.one, '1');
      expectDecimal(Decimal.two, '2');
      expectDecimal(Decimal.ten, '10');

      expect(Decimal.ten == Decimal(10), isTrue);
      expect(Decimal.ten.hashCode, Decimal(10).hashCode);
      expect({Decimal.ten, Decimal(10)}, hasLength(1));
    });

    test('знак', () {
      expect(Decimal(5).sign, 1);
      expect(Decimal(-5).sign, -1);
      expect(Decimal(0).sign, 0);
      expect(Decimal.parse('0.5').sign, 1);
      expect(Decimal.parse('-0.5').sign, -1);
    });

    test('унарный минус', () {
      expectDecimal(-Decimal(5), '-5');
      expectDecimal(-Decimal(-5), '5');
      expectDecimal(-Decimal(0), '0');
      expectDecimal(-Decimal.parse('1.5'), '-1.5');
    });

    test('отрицательный показатель pow', () {
      expectDecimal(Decimal(2).pow(-1), '0.5');
      expectDecimal(Decimal(2).pow(-2), '0.25');
      expectDecimal(Decimal(10).pow(-3), '0.001');
      expectDecimal(Decimal.parse('0.5').pow(-1), '2');

      // Бросает ровно то же, что деление.
      expect(() => Decimal(3).pow(-1), throwsA(isA<DecimalDivideException>()));
      expect(() => Decimal(0).pow(-1), throwsA(isA<UnsupportedError>()));
      expect(
        () => Decimal(2).pow(-9223372036854775808),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('масштаб не заворачивается', () {
      // Р24: `scale * exponent` переполнялся молча, и 0.01 в степени int.max
      // печаталось как 100. Проверяется именно заворот: сам по себе большой
      // масштаб — это просто далёкая точка, а вот степень десятки, которую он
      // однажды потребует, ограничена отдельно (см. тест ниже).
      const max = 9223372036854775807;
      const min = -9223372036854775807 - 1;

      expect(() => Decimal.parse('0.01').pow(max), throwsArgumentError);
      expect(() => Decimal(1) << min, throwsArgumentError);
      expect(() => (Decimal(1) >> max) >> 1, throwsArgumentError);
      expect(() => Decimal(1).movePointRight(min), throwsArgumentError);

      // Всё, что помещается, по-прежнему считается.
      expectDecimal(Decimal.parse('0.01').pow(3), '0.000001');
      expect((Decimal(1) >> max).scale, max);
    });

    test('степень десятки за миллионом отвергается, откуда бы ни пришла', () {
      // Число знаков проверяется на входе, но потребовать невозможной степени
      // можно и не передавая её: у числа с масштабом в миллиард её попросит
      // любое выравнивание. Отсюда вторая проверка — там, где степень
      // строится, — и там она стоит на редком пути, мимо кеша.
      final huge = Decimal(1) >> 1000000000;

      expect(() => huge + Decimal(1), throwsArgumentError);
      expect(huge.round, throwsArgumentError);
      expect(huge.toInt, throwsArgumentError);
      expect(() => huge < Decimal(1), throwsArgumentError);

      // Миллион — ещё считается: масштаб такой получает всякий, кто разобрал
      // строку с показателем на пределе.
      expect((Decimal.parse('1e-1000000') + Decimal(1)).scale, 1000000);
    });

    test('число знаков за миллионом отвергается, а не считается', () {
      // Ревью, раздел про надёжность: `Decimal.one.round(-1000000000)` строил
      // 10^(10^9) и съедал память. Граница — та же, что у показателя при
      // разборе строки, и на ней ответ ещё считается (замерено: 415 мс).
      const huge = 1000000000;
      final third = Fraction(BigInt.one, BigInt.from(3));

      final calls = <String, void Function()>{
        'round': () => Decimal.one.round(-huge),
        'floor': () => Decimal.one.floor(-huge),
        'ceil': () => Decimal.one.ceil(-huge),
        'truncate': () => Decimal.one.truncate(-huge),
        'round вверх': () => Decimal.one.round(huge),
        'divide': () =>
            Decimal.one.divide(Decimal(3), scaleOnInfinitePrecision: huge),
        'toStringAsFixed': () => Decimal.one.toStringAsFixed(huge),
        'toStringAsExponential': () => Decimal.one.toStringAsExponential(huge),
        'toStringAsPrecision': () => Decimal.one.toStringAsPrecision(huge),
        'Fraction.round': () => third.round(-huge),
        'Fraction.truncate': () => third.truncate(huge),
      };

      for (final entry in calls.entries) {
        expect(entry.value, throwsArgumentError, reason: entry.key);
      }

      // Внутри границы — обычная работа; сверху она достаётся даром, потому
      // что просить больше знаков, чем есть, значит ничего не менять.
      expectDecimal(Decimal.parse('1.5').round(1000000), '1.5');
      expectDecimal(Decimal.parse('123.4').round(-1), '120');
    });
  });
}
