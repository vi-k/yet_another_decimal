// ignore_for_file: avoid_js_rounded_ints

/// `ShortFraction` — рациональная дробь на `int`.
///
library;

import 'package:denary/denary.dart';
import 'package:test/test.dart';

import '../support/expect.dart';

void main() {
  group('ShortFraction', () {
    test('create', () {
      expect(
        () => ShortFraction(0, 0),
        throwsA(
          predicate(
            (error) =>
                error is UnsupportedError &&
                error.message == 'division by zero',
          ),
        ),
      );

      expectShortFraction(ShortFraction(123, 123), '1');
      expectShortFraction(ShortFraction(-123, 123), '-1');
      expectShortFraction(ShortFraction(123, -123), '-1');
      expectShortFraction(ShortFraction(-123, -123), '1');

      expectShortFraction(ShortFraction(123, 7), '123/7');
      expectShortFraction(ShortFraction(-123, 7), '-123/7');
      expectShortFraction(ShortFraction(123, -7), '-123/7');
      expectShortFraction(ShortFraction(-123, -7), '123/7');

      expectShortFraction(ShortFraction(123, 1230), '1/10');
      expectShortFraction(ShortFraction(1230, 123), '10');
    });

    test('parse', () {
      expect(
        () => ShortFraction.parse('0/0'),
        throwsA(
          predicate(
            (error) =>
                error is UnsupportedError &&
                error.message == 'division by zero',
          ),
        ),
      );

      expectShortFraction(ShortFraction.parse('123/123'), '1');
      expectShortFraction(ShortFraction.parse('-123/123'), '-1');
      expectShortFraction(ShortFraction.parse('123/-123'), '-1');
      expectShortFraction(ShortFraction.parse('-123/-123'), '1');

      expectShortFraction(ShortFraction.parse('123/7'), '123/7');
      expectShortFraction(ShortFraction.parse('-123/7'), '-123/7');
      expectShortFraction(ShortFraction.parse('123/-7'), '-123/7');
      expectShortFraction(ShortFraction.parse('-123/-7'), '123/7');

      expectShortFraction(ShortFraction.parse('123/1230'), '1/10');
      expectShortFraction(ShortFraction.parse('1230/123'), '10');
    });

    test('to Decimal', () {
      var f = ShortDecimal.parse(
        '1.2',
      ).divideToFraction(ShortDecimal.parse('2.1'));
      expectShortFraction(f, '4/7');

      expectShortDecimal(f.floor(), '0');
      expectShortDecimal(f.floor(1), '0.5');
      expectShortDecimal(f.floor(2), '0.57');

      expectShortDecimal(f.round(), '1');
      expectShortDecimal(f.round(1), '0.6');
      expectShortDecimal(f.round(2), '0.57');

      expectShortDecimal(f.ceil(), '1');
      expectShortDecimal(f.ceil(1), '0.6');
      expectShortDecimal(f.ceil(2), '0.58');

      expectShortDecimal(f.truncate(), '0');
      expectShortDecimal(f.truncate(1), '0.5');
      expectShortDecimal(f.truncate(2), '0.57');

      f = ShortDecimal.parse(
        '-1.2',
      ).divideToFraction(ShortDecimal.parse('2.1'));
      expectShortFraction(f, '-4/7');

      expectShortDecimal(f.floor(), '-1');
      expectShortDecimal(f.floor(1), '-0.6');
      expectShortDecimal(f.floor(2), '-0.58');

      expectShortDecimal(f.round(), '-1');
      expectShortDecimal(f.round(1), '-0.6');
      expectShortDecimal(f.round(2), '-0.57');

      expectShortDecimal(f.ceil(), '0');
      expectShortDecimal(f.ceil(1), '-0.5');
      expectShortDecimal(f.ceil(2), '-0.57');

      expectShortDecimal(f.truncate(), '0');
      expectShortDecimal(f.truncate(1), '-0.5');
      expectShortDecimal(f.truncate(2), '-0.57');
    });

    test('parse без дробной черты', () {
      expectShortFraction(ShortFraction.parse('123'), '123');
      expectShortFraction(ShortFraction.parse('-123'), '-123');
    });

    test('parse принимает пробелы вокруг, как и числа', () {
      expectShortFraction(ShortFraction.parse(' 3 / 4 '), '3/4');
      expectShortFraction(ShortFraction.parse('\t-3\n'), '-3');
    });

    test('parse не принимает того, чего не принимают числа', () {
      // Р9: разбор шёл через `int.parse`, а тот берёт шестнадцатеричное — то
      // самое, что для чисел закрыто дефектом Д10.
      for (final source in [
        '0x10',
        '-0x10',
        '0X1F',
        '0x3/4',
        '3/0x4',
        '',
        '/',
        '3/',
        '/4',
        '+',
        '-/4',
        '3 4',
        '1.5',
        '1e3',
        '3/4/5',
      ]) {
        expect(
          () => ShortFraction.parse(source),
          throwsFormatException,
          reason: 'на "$source"',
        );
      }
    });

    group('операторы', () {
      test('умножение сокращает', () {
        expectShortFraction(ShortFraction(1, 2) * ShortFraction(2, 3), '1/3');
        expectShortFraction(ShortFraction(-1, 2) * ShortFraction(2, 3), '-1/3');
        expectShortFraction(ShortFraction(4, 7) * ShortFraction(7, 4), '1');
      });

      test('деление', () {
        expectShortFraction(ShortFraction(1, 2) / ShortFraction(3, 4), '2/3');
        expectShortFraction(ShortFraction(1, 2) / ShortFraction(-1, 2), '-1');
      });

      test('сложение приводит к общему знаменателю', () {
        expectShortFraction(ShortFraction(1, 2) + ShortFraction(1, 3), '5/6');
        expectShortFraction(ShortFraction(1, 2) + ShortFraction(1, 2), '1');
      });

      test('вычитание', () {
        expectShortFraction(ShortFraction(1, 2) - ShortFraction(1, 3), '1/6');
        expectShortFraction(ShortFraction(1, 2) - ShortFraction(1, 2), '0');
      });
    });

    // Д13, Д14: промежуточное значение переполняется, а точный результат в
    // int64 помещается. Эталон — то же самое на BigInt.
    test('ноль на отрицательное — обычная дробь', () {
      // Р10: проверка «x == -x» ловила и ноль, а ноль, делённый на что угодно
      // отрицательное, — это ноль, и у семейства на BigInt так и было.
      expect(ShortFraction(0, -5).toString(), '0');
      expect(ShortFraction.parse('0/-5').toString(), '0');
      expect(
        ShortDecimal.zero.divideToFraction(ShortDecimal(-5)).toString(),
        Decimal.zero.divideToFraction(Decimal(-5)).toString(),
      );
      expect(ShortDecimal.zero.divideToDouble(ShortDecimal(-5)), 0.0);
    });

    group('точность на границе int64', () {
      const max = 9223372036854775807;
      const min = -9223372036854775808;

      test('умножение сокращает перекрёстно', () {
        expectShortFraction(
          ShortFraction(max, 2) * ShortFraction(2, max - 2),
          '$max/${max - 2}',
        );
      });

      test('деление сокращает перекрёстно', () {
        expectShortFraction(
          ShortFraction(max, 2) / ShortFraction(max, 3),
          '3/2',
        );
      });

      test('сложение не переполняется на промежуточном', () {
        // (1 + max) / 2 — это 2^62, ровно на границе.
        expectShortFraction(
          ShortFraction(1, 2) + ShortFraction(max, 2),
          '4611686018427387904',
        );
        expectShortFraction(
          ShortFraction(7, max) + ShortFraction(100, 7),
          '2689029748354162043/188232082384791343',
        );
      });

      test('вычитание не переполняется на промежуточном', () {
        expectShortFraction(
          ShortFraction(-1, 2) - ShortFraction(max, 2),
          '-4611686018427387904',
        );
      });

      test('вычитаемое с числителем int.min', () {
        // Числитель нельзя отрицать в int64, поэтому сумма считается точно.
        expectShortFraction(
          ShortFraction(-max, 7) - ShortFraction(min, 7),
          '1/7',
        );
      });

      test('непредставимая сумма переполняется молча, но не падает', () {
        // Точный ответ (max + 1) в int64 не помещается ничем: переполнение
        // остаётся молчаливым, как и всюду в этом семействе.
        expect(
          () => ShortFraction(1, 1) + ShortFraction(max, 1),
          returnsNormally,
        );
      });

      test('совпадает с Fraction всюду, где результат представим', () {
        const pairs = [
          (1, 2, max, 2),
          (7, max, 100, 7),
          (max, 2, 2, max - 2),
          (-1, 2, max, 2),
          (max - 1, max, 1, max),
          (max, 3, max, 5),
          (-max, 7, min, 7),
        ];
        for (final (a, b, c, d) in pairs) {
          final short = ShortFraction(a, b);
          final other = ShortFraction(c, d);
          final wide = Fraction(BigInt.from(a), BigInt.from(b));
          final wideOther = Fraction(BigInt.from(c), BigInt.from(d));

          final operations = <String, (ShortFraction Function(), Fraction)>{
            '+': (() => short + other, wide + wideOther),
            '-': (() => short - other, wide - wideOther),
            '*': (() => short * other, wide * wideOther),
            '/': (() => short / other, wide / wideOther),
          };

          for (final entry in operations.entries) {
            final sign = entry.key;
            final (compute, want) = entry.value;
            final representable =
                want.numerator.isValidInt && want.denominator.isValidInt;
            final why = '($a/$b) $sign ($c/$d) = $want';

            // Там, где точный ответ в int64 не помещается, переполнение
            // остаётся молчаливым — сверять нечего.
            if (representable) {
              expect('${compute()}', '$want', reason: why);
            }
          }
        }
      });
    });

    // Д11: числитель домножался на степень десяти до деления.
    group('округление к 19 знакам и дальше', () {
      test('совпадает с Fraction', () {
        final short = ShortFraction(4, 7);
        final wide = Fraction(BigInt.from(4), BigInt.from(7));
        for (final digits in [17, 18, 19]) {
          expect(
            short.round(digits).toString(),
            wide.round(digits).toString(),
            reason: 'round($digits)',
          );
          expect(
            short.floor(digits).toString(),
            wide.floor(digits).toString(),
            reason: 'floor($digits)',
          );
          expect(
            short.ceil(digits).toString(),
            wide.ceil(digits).toString(),
            reason: 'ceil($digits)',
          );
          expect(
            short.truncate(digits).toString(),
            wide.truncate(digits).toString(),
            reason: 'truncate($digits)',
          );
        }
      });

      test('за пределом int64 — ближайшее представимое, а не мусор', () {
        // Точный ответ на 20 знаков в int64 не помещается. Возвращается
        // ближайшее представимое: те же 19 знаков.
        final rounded = ShortFraction(4, 7).round(20);
        expect(rounded.isNegative, isFalse);
        expect(rounded.toString(), '0.5714285714285714286');

        final negative = ShortFraction(-4, 7).round(20);
        expect(negative.isNegative, isTrue);
        expect(negative.toString(), '-0.5714285714285714286');
      });

      test('округление почти-единицы даёт единицу', () {
        const max = 9223372036854775807;
        expectShortDecimal(ShortFraction(max, max - 2).round(1), '1');
      });
    });

    test('знак', () {
      expect(ShortFraction(-1, 2).isNegative, isTrue);
      expect(ShortFraction(1, 2).isNegative, isFalse);
      expect(ShortFraction(0, 2).isNegative, isFalse);

      expect(ShortFraction(-1, 2).sign, -1);
      expect(ShortFraction(1, 2).sign, 1);
      expect(ShortFraction(0, 2).sign, 0);
    });

    test('равенство', () {
      final half = ShortFraction(1, 2);

      expect(half == ShortFraction(2, 4), isTrue);
      expect(half.hashCode, ShortFraction(2, 4).hashCode);
      expect(half == half, isTrue);
      expect(half == ShortFraction(1, 3), isFalse);
      expect(half == Object(), isFalse);
      expect({half, ShortFraction(2, 4)}, hasLength(1));
    });

    // Д15: знак нормализуется после сокращения, иначе int.min остаётся
    // отрицательным знаменателем.
    group('int.min в знаменателе', () {
      test('сокращаемая дробь нормализуется', () {
        expectShortFraction(
          ShortFraction(2, -9223372036854775808),
          '-1/4611686018427387904',
        );
        expectShortFraction(
          ShortFraction(-2, -9223372036854775808),
          '1/4611686018427387904',
        );
      });

      test('несокращаемая бросает ArgumentError', () {
        expect(
          () => ShortFraction(1, -9223372036854775808),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => ShortFraction(-9223372036854775808, -1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('деление на ноль по-прежнему UnsupportedError', () {
        expect(() => ShortFraction(1, 0), throwsA(isA<UnsupportedError>()));
      });
    });

    group('отрицательный fractionDigits', () {
      final fraction = ShortFraction(1234, 10);

      test('совпадает с Fraction на том же значении', () {
        final wide = Fraction(BigInt.from(1234), BigInt.from(10));
        for (final digits in [-3, -2, -1, 0, 1]) {
          expect(
            fraction.floor(digits).toString(),
            wide.floor(digits).toString(),
            reason: 'floor($digits)',
          );
          expect(
            fraction.ceil(digits).toString(),
            wide.ceil(digits).toString(),
            reason: 'ceil($digits)',
          );
          expect(
            fraction.round(digits).toString(),
            wide.round(digits).toString(),
            reason: 'round($digits)',
          );
          expect(
            fraction.truncate(digits).toString(),
            wide.truncate(digits).toString(),
            reason: 'truncate($digits)',
          );
        }
      });

      test('масштаб знаменателя за пределом int64', () {
        // 10^20 в int64 не помещается: считается точным путём.
        expectShortDecimal(ShortFraction(1234, 10).floor(-20), '0');
        expectShortDecimal(
          ShortFraction(-1234, 10).floor(-20),
          '-100000000000000000000',
        );
      });
    });

    test('модуль', () {
      expectShortFraction(ShortFraction(-1, 2).abs(), '1/2');
      expectShortFraction(ShortFraction(1, 2).abs(), '1/2');
      expectShortFraction(ShortFraction(0, 2).abs(), '0');

      // Числитель int.min: положительного двойника у него нет.
      expect(
        () => ShortFraction(-9223372036854775808, 7).abs(),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('обратная дробь', () {
      expectShortFraction(ShortFraction(1, 2).inverse, '2');
      expectShortFraction(ShortFraction(-3, 4).inverse, '-4/3');
      expect(
        () => ShortFraction(0, 2).inverse,
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('сравнение', () {
      const max = 9223372036854775807;
      final half = ShortFraction(1, 2);
      final third = ShortFraction(1, 3);

      expect(half.compareTo(third), 1);
      expect(third.compareTo(half), -1);
      expect(half.compareTo(ShortFraction(2, 4)), 0);
      final minusThird = ShortFraction(-1, 3);
      expect(ShortFraction(-1, 2).compareTo(third), -1);

      final sorted = [half, minusThird, third]..sort();
      expect(sorted.map((e) => '$e').toList(), ['-1/3', '1/3', '1/2']);

      // Перекрёстное произведение не помещается в int64 — ответ всё равно
      // точный.
      expect(ShortFraction(max, 2).compareTo(ShortFraction(max - 2, 2)), 1);
      expect(
        ShortFraction(max, max - 1).compareTo(ShortFraction(max - 1, max)),
        1,
      );
      expect(
        ShortFraction(max, max - 1).compareTo(ShortFraction(max, max - 1)),
        0,
      );
    });

    test('в double и в ShortDecimal', () {
      expect(ShortFraction(1, 2).toDouble(), 0.5);
      expect(ShortFraction(1, 3).toDouble(), 1 / 3);
      expect(ShortFraction(0, 2).toDouble(), 0.0);

      expectShortDecimal(ShortFraction(1, 2).toShortDecimal(), '0.5');
      expectShortDecimal(ShortFraction(10, 4).toShortDecimal(), '2.5');
      expect(
        () => ShortFraction(1, 3).toShortDecimal(),
        throwsA(isA<ShortDecimalDivideException>()),
      );
    });
  });
}
