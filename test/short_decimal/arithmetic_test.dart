// ignore_for_file: avoid_js_rounded_ints

/// Арифметика `ShortDecimal`: сложение, умножение, модуль, степень.
///
/// Форма хранения результата здесь не сверяется — она артефакт алгоритма.
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';

void main() {
  group('ShortDecimal', () {
    test('add', () {
      var value = ShortDecimal.zero;
      expectShortDecimal(
        value += ShortDecimal(10000000),
        '10000000',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(1000000),
        '11000000',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(100000),
        '11100000',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(10000),
        '11110000',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(1000),
        '11111000',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(100),
        '11111100',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(10),
        '11111110',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(1),
        '11111111',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 1),
        '11111111.1',
        fractionDigits: 1,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 2),
        '11111111.11',
        fractionDigits: 2,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 3),
        '11111111.111',
        fractionDigits: 3,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 4),
        '11111111.1111',
        fractionDigits: 4,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 5),
        '11111111.11111',
        fractionDigits: 5,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 6),
        '11111111.111111',
        fractionDigits: 6,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 7),
        '11111111.1111111',
        fractionDigits: 7,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 8),
        '11111111.11111111',
        fractionDigits: 8,
      );

      final values = List<ShortDecimal>.generate(
        16,
        (index) => ShortDecimal(10000000, shiftRight: index),
        growable: false,
      );
      value = values[0];
      for (final v in values.skip(1)) {
        value += v;
      }
      expectShortDecimal(value, '11111111.11111111', fractionDigits: 8);
    });
    test('multiply', () {
      expectShortDecimal(
        ShortDecimal(123, shiftRight: 2) * ShortDecimal(456, shiftRight: 1),
        '56.088',
        fractionDigits: 3,
      );
      expectShortDecimal(
        ShortDecimal(-123, shiftRight: 2) * ShortDecimal(456, shiftRight: 1),
        '-56.088',
        fractionDigits: 3,
      );
      expectShortDecimal(
        ShortDecimal(123, shiftRight: 2) * ShortDecimal(-456, shiftRight: 1),
        '-56.088',
        fractionDigits: 3,
      );
      expectShortDecimal(
        ShortDecimal(-123, shiftRight: 2) * ShortDecimal(-456, shiftRight: 1),
        '56.088',
        fractionDigits: 3,
      );

      // big positive values
      var m = ShortDecimal(123000);
      var value = ShortDecimal.one;
      expectShortDecimal(value *= m, '123000', fractionDigits: 0);
      expectShortDecimal(value *= m, '15129000000', fractionDigits: 0);
      expectShortDecimal(value *= m, '1860867000000000', fractionDigits: 0);
      expectShortDecimal(
        value *= m,
        '228886641000000000000',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '28153056843000000000000000',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '3462825991689000000000000000000',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '425927596977747000000000000000000000',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '52389094428262881000000000000000000000000',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '6443858614676334363000000000000000000000000000',
        fractionDigits: 0,
      );

      // big negative values
      m = ShortDecimal(-123000);
      value = ShortDecimal.one;
      expectShortDecimal(value *= m, '-123000', fractionDigits: 0);
      expectShortDecimal(value *= m, '15129000000', fractionDigits: 0);
      expectShortDecimal(value *= m, '-1860867000000000', fractionDigits: 0);
      expectShortDecimal(
        value *= m,
        '228886641000000000000',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '-28153056843000000000000000',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '3462825991689000000000000000000',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '-425927596977747000000000000000000000',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '52389094428262881000000000000000000000000',
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '-6443858614676334363000000000000000000000000000',
        fractionDigits: 0,
      );

      // small positive values
      m = ShortDecimal(123, shiftRight: 4);
      value = ShortDecimal.one;
      expectShortDecimal(value *= m, '0.0123', fractionDigits: 4);
      expectShortDecimal(value *= m, '0.00015129', fractionDigits: 8);
      expectShortDecimal(value *= m, '0.000001860867', fractionDigits: 12);
      expectShortDecimal(value *= m, '0.0000000228886641', fractionDigits: 16);
      expectShortDecimal(
        value *= m,
        '0.00000000028153056843',
        fractionDigits: 20,
      );
      expectShortDecimal(
        value *= m,
        '0.000000000003462825991689',
        fractionDigits: 24,
      );
      expectShortDecimal(
        value *= m,
        '0.0000000000000425927596977747',
        fractionDigits: 28,
      );
      expectShortDecimal(
        value *= m,
        '0.00000000000000052389094428262881',
        fractionDigits: 32,
      );
      expectShortDecimal(
        value *= m,
        '0.000000000000000006443858614676334363',
        fractionDigits: 36,
      );

      // small negative values
      m = ShortDecimal(-123, shiftRight: 4);
      value = ShortDecimal.one;
      expectShortDecimal(value *= m, '-0.0123', fractionDigits: 4);
      expectShortDecimal(value *= m, '0.00015129', fractionDigits: 8);
      expectShortDecimal(value *= m, '-0.000001860867', fractionDigits: 12);
      expectShortDecimal(value *= m, '0.0000000228886641', fractionDigits: 16);
      expectShortDecimal(
        value *= m,
        '-0.00000000028153056843',
        fractionDigits: 20,
      );
      expectShortDecimal(
        value *= m,
        '0.000000000003462825991689',
        fractionDigits: 24,
      );
      expectShortDecimal(
        value *= m,
        '-0.0000000000000425927596977747',
        fractionDigits: 28,
      );
      expectShortDecimal(
        value *= m,
        '0.00000000000000052389094428262881',
        fractionDigits: 32,
      );
      expectShortDecimal(
        value *= m,
        '-0.000000000000000006443858614676334363',
        fractionDigits: 36,
      );
    });
    test('abs', () {
      expectShortDecimal(ShortDecimal(2).abs(), '2', fractionDigits: 0);

      expectShortDecimal(ShortDecimal(-2).abs(), '2', fractionDigits: 0);

      expectShortDecimal(
        ShortDecimal.parse('-1234567890.123456789').abs(),
        '1234567890.123456789',
        fractionDigits: 9,
      );
    });
    test('pow', () {
      expectShortDecimal(ShortDecimal(2).pow(4), '16', fractionDigits: 0);

      expectShortDecimal(
        ShortDecimal(2, shiftRight: 1).pow(4),
        '0.0016',
        fractionDigits: 4,
      );
    });

    test('константы', () {
      expectShortDecimal(ShortDecimal.zero, '0');
      expectShortDecimal(ShortDecimal.one, '1');
      expectShortDecimal(ShortDecimal.two, '2');
      expectShortDecimal(ShortDecimal.ten, '10');

      expect(ShortDecimal.ten == ShortDecimal(10), isTrue);
      expect(ShortDecimal.ten.hashCode, ShortDecimal(10).hashCode);
      expect({ShortDecimal.ten, ShortDecimal(10)}, hasLength(1));
    });

    test('знак', () {
      expect(ShortDecimal(5).sign, 1);
      expect(ShortDecimal(-5).sign, -1);
      expect(ShortDecimal(0).sign, 0);
      expect(ShortDecimal.parse('0.5').sign, 1);
    });

    test('унарный минус', () {
      expectShortDecimal(-ShortDecimal(5), '-5');
      expectShortDecimal(-ShortDecimal(-5), '5');
      expectShortDecimal(-ShortDecimal(0), '0');
      expectShortDecimal(-ShortDecimal.parse('1.5'), '-1.5');
    });

    // Д13: произведение переполнялось до нормализации. Двойка с одной стороны
    // и пятёрка с другой дают десятку, а её место — в масштабе.
    test('вычитание из числа с большим масштабом переполняется молча', () {
      // Пример из README: у 922337203685477580700000000000000000000000 база
      // помещается в int64, а вот работать с ним в другом масштабе уже нельзя
      // — точный ответ непредставим, и переполнение остаётся молчаливым по
      // решению владельца. В отличие от прибавления нуля: там ответ был
      // представим, и это чинилось.
      final big = ShortDecimal(9223372036854775807) << 23;

      expectShortDecimal(
        big - (ShortDecimal(1) << 23),
        '922337203685477580600000000000000000000000',
      );
      expect((big - ShortDecimal(1)).toString(), '-200376420520689665');
    });

    group('умножение на границе int64', () {
      test('двойка слева, пятёрка справа', () {
        expectShortDecimal(
          ShortDecimal(4611686018427387904) * ShortDecimal(5),
          '23058430092136939520',
        );
      });

      test('пятёрка слева, двойка справа', () {
        expectShortDecimal(
          ShortDecimal(5000000000000000000) * ShortDecimal(2),
          '10000000000000000000',
        );
      });

      test('совпадает с Decimal всюду, где результат представим', () {
        const bases = [
          2,
          5,
          1000000,
          4611686018427387904,
          5000000000000000000,
          9223372036854775807,
          -9223372036854775808,
        ];
        for (final a in bases) {
          for (final b in bases) {
            final exact = (Decimal(a) * Decimal(b)).toString();
            final representable = ShortDecimal.tryParse(exact);
            if (representable == null) continue;

            expect(
              (ShortDecimal(a) * ShortDecimal(b)).toString(),
              exact,
              reason: '$a * $b',
            );
          }
        }
      });
    });

    test('остаток', () {
      expectShortDecimal(ShortDecimal(7).remainder(ShortDecimal(3)), '1');
      expectShortDecimal(ShortDecimal(-7).remainder(ShortDecimal(3)), '-1');
      expectShortDecimal(
        ShortDecimal.parse('7.5').remainder(ShortDecimal(2)),
        '1.5',
      );
    });

    test('отрицательный показатель pow', () {
      expectShortDecimal(ShortDecimal(2).pow(-1), '0.5');
      expectShortDecimal(ShortDecimal(2).pow(-2), '0.25');
      expectShortDecimal(ShortDecimal(10).pow(-3), '0.001');
      expectShortDecimal(ShortDecimal.parse('0.5').pow(-1), '2');

      // Бросает ровно то же, что деление.
      expect(
        () => ShortDecimal(3).pow(-1),
        throwsA(isA<ShortDecimalDivideException>()),
      );
      expect(() => ShortDecimal(0).pow(-1), throwsA(isA<UnsupportedError>()));
      expect(
        () => ShortDecimal(2).pow(-9223372036854775808),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('масштаб не заворачивается', () {
      // Р24: `scale * exponent` переполнялся молча, и 0.01 в степени int.max
      // печаталось как 100.
      const max = 9223372036854775807;
      const min = -9223372036854775807 - 1;

      expect(() => ShortDecimal.parse('0.01').pow(max), throwsArgumentError);
      expect(() => ShortDecimal(1) << min, throwsArgumentError);
      expect(() => (ShortDecimal(1) >> max) >> 1, throwsArgumentError);
      expect(() => ShortDecimal(1).movePointRight(min), throwsArgumentError);

      // Всё, что помещается, по-прежнему считается.
      expectShortDecimal(ShortDecimal.parse('0.01').pow(3), '0.000001');
      expect((ShortDecimal(1) >> max).scale, max);
    });

    test('расширение int', () {
      expectShortDecimal(5.toShortDecimal(), '5');
      expectShortDecimal((-5).toShortDecimal(), '-5');
      expectShortDecimal(100.toShortDecimal(), '100');
    });
  });
}
