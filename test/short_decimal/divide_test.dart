// ignore_for_file: avoid_js_rounded_ints

/// Деление `ShortDecimal` и `ShortDecimalDivideException`.
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';

void main() {
  group('ShortDecimal', () {
    group('divide', () {
      test('success', () {
        expectShortDecimal(
          ShortDecimal(24, shiftRight: 1) / ShortDecimal(12, shiftRight: 1),
          '2',
          fractionDigits: 0,
        );

        var value = ShortDecimal(6443858614676334363, shiftLeft: 27);
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '52389094428262881000000000000000000000000',
          fractionDigits: 0,
        );
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '425927596977747000000000000000000000',
          fractionDigits: 0,
        );
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '3462825991689000000000000000000',
          fractionDigits: 0,
        );
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '28153056843000000000000000',
          fractionDigits: 0,
        );
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '228886641000000000000',
          fractionDigits: 0,
        );
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '1860867000000000',
          fractionDigits: 0,
        );
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '15129000000',
          fractionDigits: 0,
        );
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '123000',
          fractionDigits: 0,
        );
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '1',
          fractionDigits: 0,
        );

        value = ShortDecimal.one;
        for (var i = 0; i < 60; i++) {
          value /= ShortDecimal(10);
        }
        expectShortDecimal(
          value,
          '0.000000000000000000000000000000000000000000000000000000000001',
          fractionDigits: 60,
        );

        expect(
          () => ShortDecimal(15129, shiftRight: 1) / ShortDecimal(86100),
          throwsA(
            predicate(
              (error) =>
                  error is ShortDecimalDivideException &&
                  error.fraction.toString() == '123/7000',
            ),
          ),
        );
      });

      group('ShortDecimalDivideException', () {
        test('0.5', () {
          // round
          expect(0.5.round(), 1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(1),
              ShortDecimal(2),
            ).round(),
            '1',
          );

          expect((-0.5).round(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-1),
              ShortDecimal(2),
            ).round(),
            '-1',
          );

          expect((-1.5).round(), -2);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-3),
              ShortDecimal(2),
            ).round(),
            '-2',
          );

          // floor
          expect(0.5.floor(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(1),
              ShortDecimal(2),
            ).floor(),
            '0',
          );

          expect((-0.5).floor(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-1),
              ShortDecimal(2),
            ).floor(),
            '-1',
          );

          expect((-1.5).floor(), -2);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-3),
              ShortDecimal(2),
            ).floor(),
            '-2',
          );

          // ceil
          expect(0.5.ceil(), 1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(1),
              ShortDecimal(2),
            ).ceil(),
            '1',
          );

          expect((-0.5).ceil(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-1),
              ShortDecimal(2),
            ).ceil(),
            '0',
          );

          expect((-1.5).ceil(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-3),
              ShortDecimal(2),
            ).ceil(),
            '-1',
          );

          // truncate
          expect(0.5.truncate(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(1),
              ShortDecimal(2),
            ).truncate(),
            '0',
          );

          expect((-0.5).truncate(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-1),
              ShortDecimal(2),
            ).truncate(),
            '0',
          );

          expect((-1.5).truncate(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-3),
              ShortDecimal(2),
            ).truncate(),
            '-1',
          );
        });

        test('0.1', () {
          // round
          expect(0.1.round(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(1),
              ShortDecimal(10),
            ).round(),
            '0',
          );

          expect((-0.1).round(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-1),
              ShortDecimal(10),
            ).round(),
            '0',
          );

          expect((-1.1).round(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-11),
              ShortDecimal(10),
            ).round(),
            '-1',
          );

          // floor
          expect(0.1.floor(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(1),
              ShortDecimal(10),
            ).floor(),
            '0',
          );

          expect((-0.1).floor(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-1),
              ShortDecimal(10),
            ).floor(),
            '-1',
          );

          expect((-1.1).floor(), -2);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-11),
              ShortDecimal(10),
            ).floor(),
            '-2',
          );

          // ceil
          expect(0.1.ceil(), 1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(1),
              ShortDecimal(10),
            ).ceil(),
            '1',
          );

          expect((-0.1).ceil(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-1),
              ShortDecimal(10),
            ).ceil(),
            '0',
          );

          expect((-1.1).ceil(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-11),
              ShortDecimal(10),
            ).ceil(),
            '-1',
          );

          // truncate
          expect(0.1.truncate(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(1),
              ShortDecimal(10),
            ).floor(),
            '0',
          );

          expect((-0.1).truncate(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-1),
              ShortDecimal(10),
            ).truncate(),
            '0',
          );

          expect((-1.1).truncate(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-11),
              ShortDecimal(10),
            ).truncate(),
            '-1',
          );
        });

        test('0.9', () {
          // round
          expect(0.9.round(), 1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(9),
              ShortDecimal(10),
            ).round(),
            '1',
          );

          expect((-0.9).round(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-9),
              ShortDecimal(10),
            ).round(),
            '-1',
          );

          expect((-1.9).round(), -2);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-19),
              ShortDecimal(10),
            ).round(),
            '-2',
          );

          // floor
          expect(0.9.floor(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(9),
              ShortDecimal(10),
            ).floor(),
            '0',
          );

          expect((-0.9).floor(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-9),
              ShortDecimal(10),
            ).floor(),
            '-1',
          );

          expect((-1.9).floor(), -2);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-19),
              ShortDecimal(10),
            ).floor(),
            '-2',
          );

          // ceil
          expect(0.9.ceil(), 1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(9),
              ShortDecimal(10),
            ).ceil(),
            '1',
          );

          expect((-0.9).ceil(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-9),
              ShortDecimal(10),
            ).ceil(),
            '0',
          );

          expect((-1.9).ceil(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-19),
              ShortDecimal(10),
            ).ceil(),
            '-1',
          );

          // truncate
          expect(0.9.truncate(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(9),
              ShortDecimal(10),
            ).floor(),
            '0',
          );

          expect((-0.9).truncate(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-9),
              ShortDecimal(10),
            ).truncate(),
            '0',
          );

          expect((-1.1).truncate(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-19),
              ShortDecimal(10),
            ).truncate(),
            '-1',
          );
        });

        test('+n / +n', () {
          final v1 = ShortDecimal(15129, shiftRight: 1);
          final v2 = ShortDecimal(86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on ShortDecimalDivideException catch (e) {
            expect(v1 ~/ v2, 0);
            expectShortDecimal(v1 % v2, '1512.9');

            // 0.017(5)
            expect((1512.9 * 1000 / 86100).floor(), 17);
            expectShortDecimal(e.floor(3), '0.017');

            expect((1512.9 * 1000 / 86100).round(), 18);
            expectShortDecimal(e.round(3), '0.018');

            expect((1512.9 * 1000 / 86100).ceil(), 18);
            expectShortDecimal(e.ceil(3), '0.018');

            expect((1512.9 * 1000 / 86100).truncate(), 17);
            expectShortDecimal(e.truncate(5), '0.01757');

            // 0.017571(4)
            expect((1512.9 * 1000000 / 86100).floor(), 17571);
            expectShortDecimal(e.floor(6), '0.017571');
            expect((1512.9 * 1000000 / 86100).round(), 17571);
            expectShortDecimal(e.round(6), '0.017571');
            expect((1512.9 * 1000000 / 86100).ceil(), 17572);
            expectShortDecimal(e.ceil(6), '0.017572');
            expect((1512.9 * 1000000 / 86100).truncate(), 17571);
            expectShortDecimal(e.truncate(6), '0.017571');

            // 0.017571428(5)
            expect((1512.9 * 1000000000 / 86100).floor(), 17571428);
            expectShortDecimal(e.floor(9), '0.017571428');
            expect((1512.9 * 1000000000 / 86100).round(), 17571429);
            expectShortDecimal(e.round(9), '0.017571429');
            expect((1512.9 * 1000000000 / 86100).ceil(), 17571429);
            expectShortDecimal(e.ceil(9), '0.017571429');
            expect((1512.9 * 1000000000 / 86100).truncate(), 17571428);
            expectShortDecimal(e.truncate(9), '0.017571428');
          }
        });

        test('+n / -n', () {
          final v1 = ShortDecimal(15129, shiftRight: 1);
          final v2 = ShortDecimal(-86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on ShortDecimalDivideException catch (e) {
            expect(v1 ~/ v2, 0);
            expectShortDecimal(v1 % v2, '1512.9');

            // -0.017(5)
            expect((1512.9 * 1000 / -86100).floor(), -18);
            expectShortDecimal(e.floor(3), '-0.018');
            expect((1512.9 * 1000 / -86100).round(), -18);
            expectShortDecimal(e.round(3), '-0.018');
            expect((1512.9 * 1000 / -86100).ceil(), -17);
            expectShortDecimal(e.ceil(3), '-0.017');
            expect((1512.9 * 1000 / -86100).truncate(), -17);
            expectShortDecimal(e.truncate(3), '-0.017');

            // -0.017571(4)
            expect((1512.9 * 1000000 / -86100).floor(), -17572);
            expectShortDecimal(e.floor(6), '-0.017572');
            expect((1512.9 * 1000000 / -86100).round(), -17571);
            expectShortDecimal(e.round(6), '-0.017571');
            expect((1512.9 * 1000000 / -86100).ceil(), -17571);
            expectShortDecimal(e.ceil(6), '-0.017571');
            expect((1512.9 * 1000000 / -86100).truncate(), -17571);
            expectShortDecimal(e.truncate(6), '-0.017571');

            // -0.017571428(5)
            expect((1512.9 * 1000000000 / -86100).floor(), -17571429);
            expectShortDecimal(e.floor(9), '-0.017571429');
            expect((1512.9 * 1000000000 / -86100).round(), -17571429);
            expectShortDecimal(e.round(9), '-0.017571429');
            expect((1512.9 * 1000000000 / -86100).ceil(), -17571428);
            expectShortDecimal(e.ceil(9), '-0.017571428');
            expect((1512.9 * 1000000000 / -86100).truncate(), -17571428);
            expectShortDecimal(e.truncate(9), '-0.017571428');
          }
        });

        test('-n / +n', () {
          final v1 = ShortDecimal(-15129, shiftRight: 1);
          final v2 = ShortDecimal(86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on ShortDecimalDivideException catch (e) {
            expect(v1 ~/ v2, 0);
            expectShortDecimal(v1 % v2, '84587.1');

            // -0.017(5)
            expect((-1512.9 * 1000 / 86100).floor(), -18);
            expectShortDecimal(e.floor(3), '-0.018');
            expect((-1512.9 * 1000 / 86100).round(), -18);
            expectShortDecimal(e.round(3), '-0.018');
            expect((-1512.9 * 1000 / 86100).ceil(), -17);
            expectShortDecimal(e.ceil(3), '-0.017');
            expect((-1512.9 * 1000 / 86100).truncate(), -17);
            expectShortDecimal(e.truncate(3), '-0.017');

            // -0.017571(4)
            expect((-1512.9 * 1000000 / 86100).floor(), -17572);
            expectShortDecimal(e.floor(6), '-0.017572');
            expect((-1512.9 * 1000000 / 86100).round(), -17571);
            expectShortDecimal(e.round(6), '-0.017571');
            expect((-1512.9 * 1000000 / 86100).ceil(), -17571);
            expectShortDecimal(e.ceil(6), '-0.017571');
            expect((-1512.9 * 1000000 / 86100).truncate(), -17571);
            expectShortDecimal(e.truncate(6), '-0.017571');

            // -0.017571428(5)
            expect((-1512.9 * 1000000000 / 86100).floor(), -17571429);
            expectShortDecimal(e.floor(9), '-0.017571429');
            expect((-1512.9 * 1000000000 / 86100).round(), -17571429);
            expectShortDecimal(e.round(9), '-0.017571429');
            expect((-1512.9 * 1000000000 / 86100).ceil(), -17571428);
            expectShortDecimal(e.ceil(9), '-0.017571428');
            expect((-1512.9 * 1000000000 / 86100).truncate(), -17571428);
            expectShortDecimal(e.truncate(9), '-0.017571428');
          }
        });

        test('-n / -n', () {
          final v1 = ShortDecimal(-15129, shiftRight: 1);
          final v2 = ShortDecimal(-86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on ShortDecimalDivideException catch (e) {
            expect(v1 ~/ v2, 0);
            expectShortDecimal(v1 % v2, '84587.1');

            // 0.017(5)
            expect((-1512.9 * 1000 / -86100).floor(), 17);
            expectShortDecimal(e.floor(3), '0.017');
            expect((-1512.9 * 1000 / -86100).round(), 18);
            expectShortDecimal(e.round(3), '0.018');
            expect((-1512.9 * 1000 / -86100).ceil(), 18);
            expectShortDecimal(e.ceil(3), '0.018');
            expect((-1512.9 * 1000 / -86100).truncate(), 17);
            expectShortDecimal(e.truncate(5), '0.01757');

            // 0.017571(4)
            expect((-1512.9 * 1000000 / -86100).floor(), 17571);
            expectShortDecimal(e.floor(6), '0.017571');
            expect((-1512.9 * 1000000 / -86100).round(), 17571);
            expectShortDecimal(e.round(6), '0.017571');
            expect((-1512.9 * 1000000 / -86100).ceil(), 17572);
            expectShortDecimal(e.ceil(6), '0.017572');
            expect((-1512.9 * 1000000 / -86100).truncate(), 17571);
            expectShortDecimal(e.truncate(6), '0.017571');

            // 0.017571428(5)
            expect((-1512.9 * 1000000000 / -86100).floor(), 17571428);
            expectShortDecimal(e.floor(9), '0.017571428');
            expect((-1512.9 * 1000000000 / -86100).round(), 17571429);
            expectShortDecimal(e.round(9), '0.017571429');
            expect((-1512.9 * 1000000000 / -86100).ceil(), 17571429);
            expectShortDecimal(e.ceil(9), '0.017571429');
            expect((-1512.9 * 1000000000 / -86100).truncate(), 17571428);
            expectShortDecimal(e.truncate(9), '0.017571428');
          }
        });

        test('big / small', () {
          // 8733 / 0.0086100 = 1014285.(714285)…
          // modulo: 0.00615
          // 1014285 * 0.00861 = 8732.99385
          // 8732.99385 + 0.00615 = 8733
          var v1 = ShortDecimal(8733);
          var v2 = ShortDecimal.parse('0.0086100');
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on ShortDecimalDivideException catch (e) {
            expectShortDecimal(e.floor(), '1014285');
            expectShortDecimal(e.round(), '1014286');
            expectShortDecimal(e.ceil(), '1014286');
            expectShortDecimal(e.truncate(), '1014285');

            expectShortFraction(e.fraction, '7100000/7');
            expectShortDivision(
              e.quotientWithRemainder,
              '1014285 remainder 0.00615',
            );
          }

          expect(v1 ~/ v2, 1014285);
          expectShortDecimal(v1 % v2, '0.00615', fractionDigits: 5);

          // +n / -n
          v1 = ShortDecimal(8733);
          v2 = ShortDecimal.parse('-0.0086100');
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on ShortDecimalDivideException catch (e) {
            expectShortDecimal(e.floor(), '-1014286');
            expectShortDecimal(e.round(), '-1014286');
            expectShortDecimal(e.ceil(), '-1014285');
            expectShortDecimal(e.truncate(), '-1014285');

            expectShortFraction(e.fraction, '-7100000/7');
            expectShortDivision(
              e.quotientWithRemainder,
              '-1014285 remainder 0.00615',
            );
          }

          expect(v1 ~/ v2, -1014285);
          expectShortDecimal(v1 % v2, '0.00615', fractionDigits: 5);
        });

        test('small / big', () {
          // 94833 / 86100.00 = 1.1014285(714285)…
          // modulo: 8733
          // 1 * 86100 = 86100
          // 86100 + 8733 = 94833
          final v1 = ShortDecimal(94833);
          final v2 = ShortDecimal.parse('86100.00');
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on ShortDecimalDivideException catch (e) {
            expectShortDecimal(e.floor(6), '1.101428');
            expectShortDecimal(e.round(6), '1.101429');
            expectShortDecimal(e.ceil(6), '1.101429');
            expectShortDecimal(e.truncate(6), '1.101428');
            expectShortDecimal(e.truncate(12), '1.101428571428');

            expectShortFraction(e.fraction, '771/700');
            expectShortDivision(e.quotientWithRemainder, '1 remainder 8733');
          }

          expect(v1 ~/ v2, 1);
          expectShortDecimal(v1 % v2, '8733', fractionDigits: 0);
        });
      });
    });

    test('деление на пятёрку', () {
      expectShortDecimal(ShortDecimal(1) / ShortDecimal(5), '0.2');
      expectShortDecimal(ShortDecimal(1) / ShortDecimal(25), '0.04');
      expectShortDecimal(ShortDecimal(3) / ShortDecimal(50), '0.06');
    });

    test('divideToDouble', () {
      expect(ShortDecimal(1).divideToDouble(ShortDecimal(2)), 0.5);
      expect(ShortDecimal(1).divideToDouble(ShortDecimal(3)), 1 / 3);
      expect(ShortDecimal(-1).divideToDouble(ShortDecimal(3)), -1 / 3);
      expect(ShortDecimal(0).divideToDouble(ShortDecimal(3)), 0.0);
    });

    test('деление на степень двойки за пределом таблицы', () {
      // 5^28 в int64 не помещается, значит и результат тоже: переполнение
      // остаётся молчаливым — но не падением.
      expect(() => ShortDecimal(1) / ShortDecimal(268435456), returnsNormally);
    });

    test('печать исключения содержит и остаток, и дробь', () {
      try {
        final unused = ShortDecimal(1) / ShortDecimal(3);
        fail('ожидалось ShortDecimalDivideException, получено $unused');
      } on ShortDecimalDivideException catch (error) {
        final text = error.toString();

        expect(text, contains('1 / 3 = 0 remainder 1'));
        expect(text, contains('1 / 3 = 1/3'));
        expect(error.dividend, ShortDecimal(1));
        expect(error.divisor, ShortDecimal(3));
      }
    });

    // Выравнивание масштабов за пределом таблицы степеней переполняется молча:
    // это контракт типа, а не дефект. Проверяем, что оно хотя бы не падает.
    test('выравнивание за пределом таблицы не бросает', () {
      final dust = ShortDecimal.parse('0.0000000000000000001');

      expect(() => dust.remainder(ShortDecimal(3)), returnsNormally);
      expect(() => dust % ShortDecimal(3), returnsNormally);
      expect(() => dust ~/ ShortDecimal(3), returnsNormally);
    });

    // Волна 4: тотальные формы деления. Ловля исключения стоит около 800 нс,
    // чтение null — доли наносекунды, а заглавный путь пакета не должен быть
    // его самым медленным.
    group('тотальное деление', () {
      test('divideOrNull возвращает результат или null', () {
        expectShortDecimal(
          ShortDecimal(1).divideOrNull(ShortDecimal(4))!,
          '0.25',
        );
        expectShortDecimal(ShortDecimal(6).divideOrNull(ShortDecimal(3))!, '2');
        expectShortDecimal(
          ShortDecimal(1).divideOrNull(ShortDecimal(-2))!,
          '-0.5',
        );
        expect(ShortDecimal(1).divideOrNull(ShortDecimal(3)), isNull);
        expect(ShortDecimal(1).divideOrNull(ShortDecimal(7)), isNull);
      });

      test('разрыв масштабов больше 18 не портит представимый ответ', () {
        // Р2: выравнивание переполнялось, и `~/` расходился с `/` на одних и
        // тех же данных, хотя верный ответ укладывается в int64.
        final big = ShortDecimal(2, shiftLeft: 19); // 2e19

        expect(
          big.divideOrNull(ShortDecimal(4)),
          ShortDecimal(5, shiftLeft: 18),
        );
        expect(big ~/ ShortDecimal(4), 5000000000000000000);
        expect(big % ShortDecimal(4), ShortDecimal.zero);
        expect(big.remainder(ShortDecimal(4)), ShortDecimal.zero);
        expect(
          big.divideWithRemainder(ShortDecimal(4)).toString(),
          '5000000000000000000',
        );
        expect(
          big.divideToFraction(ShortDecimal(4)),
          ShortFraction(5000000000000000000, 1),
        );

        // Инвариант деления с остатком держится и здесь.
        final d = ShortDecimal(1, shiftLeft: 19).divideWithRemainder(
          ShortDecimal(3),
        );
        expect(d.quotient, 3333333333333333333);
        expect(d.remainder, ShortDecimal(1));

        // Согласовано с семейством на BigInt.
        expect(
          big ~/ ShortDecimal(4),
          ((Decimal(2) << 19) ~/ Decimal(4)).toInt(),
        );
      });

      test('divideToDouble не теряет знак на разрыве масштабов', () {
        // Тот же корень: результат представим в double, а промежуточное — нет.
        expect(
          ShortDecimal.parse('1e-19').divideToDouble(ShortDecimal.one),
          1e-19,
        );
        expect(
          ShortDecimal(2, shiftLeft: 19).divideToDouble(ShortDecimal(4)),
          5e18,
        );
        // И округляет к ближайшему, а не через два округления подряд.
        expect(
          ShortDecimal(9007199254740993).divideToDouble(ShortDecimal(7)),
          1286742750677284.8,
        );
      });

      test('делитель int.min: знак не теряется', () {
        // Р3: `-int.min == int.min`, поэтому знак не снимался, а результат
        // отрицался — то есть дважды.
        const min = -9223372036854775808;

        expect(ShortDecimal(min) / ShortDecimal(min), ShortDecimal(1));
        expect(
          ShortDecimal(min).divideWithRemainder(ShortDecimal(min)).toString(),
          '1',
        );
        expect(ShortDecimal(min).isDivisibleBy(ShortDecimal(min)), isTrue);

        // 2^62 / -2^63 = -0.5 — представимо, а отбрасывалось как null.
        expectShortDecimal(
          ShortDecimal(4611686018427387904).divideOrNull(ShortDecimal(min))!,
          '-0.5',
        );

        // Нечётное делимое: точный ответ требует 5^63 и в int64 не влезает.
        expect(ShortDecimal(3).divideOrNull(ShortDecimal(min)), isNull);

        // Согласовано с семейством на BigInt.
        expect(
          (ShortDecimal(min) / ShortDecimal(min)).toString(),
          (Decimal.parse('$min') / Decimal.parse('$min')).toString(),
        );
      });

      test('прибавление нуля не меняет значения', () {
        // Р1: при разрыве масштабов больше 18 выравнивание переполнялось, и
        // домножалась база самого числа, а не нуля.
        for (final shift in [0, 5, 18, 19, 25, 60]) {
          final v = ShortDecimal(1, shiftLeft: shift);
          expect(v + ShortDecimal.zero, v, reason: '1e$shift + 0');
          expect(ShortDecimal.zero + v, v, reason: '0 + 1e$shift');
          expect(v - ShortDecimal.zero, v, reason: '1e$shift - 0');
          expect(ShortDecimal.zero - v, -v, reason: '0 - 1e$shift');
        }

        // Сумма списка через fold — обычный способ, и он не должен портиться.
        final values = [
          ShortDecimal(1, shiftLeft: 19),
          ShortDecimal(2, shiftLeft: 19),
        ];
        expect(
          values.fold(ShortDecimal.zero, (a, b) => a + b),
          ShortDecimal(3, shiftLeft: 19),
        );
      });

      test('на ноль все деления бросают один и тот же тип', () {
        // До 1.2.0 `~/`, `%` и `remainder` бросали
        // IntegerDivisionByZeroException, а `/` — UnsupportedError: одна
        // ошибка, два типа. Старый тип в SDK помечен устаревшим и сам
        // реализует UnsupportedError, так что ловившие второй ничего не
        // заметили.
        final one = ShortDecimal(1);
        final zero = ShortDecimal(0);

        for (final (name, body) in <(String, void Function())>[
          ('/', () => one / zero),
          ('~/', () => one ~/ zero),
          ('%', () => one % zero),
          ('remainder', () => one.remainder(zero)),
          ('divideOrNull', () => one.divideOrNull(zero)),
          ('divideToFraction', () => one.divideToFraction(zero)),
          ('divideToDouble', () => one.divideToDouble(zero)),
          ('divideWithRemainder', () => one.divideWithRemainder(zero)),
          ('isDivisibleBy', () => one.isDivisibleBy(zero)),
        ]) {
          expect(body, throwsA(isA<UnsupportedError>()), reason: name);
        }
      });

      test('деление на ноль по-прежнему бросает', () {
        expect(
          () => ShortDecimal(1).divideOrNull(ShortDecimal(0)),
          throwsA(isA<UnsupportedError>()),
        );
        expect(
          () => ShortDecimal(
            1,
          ).divide(ShortDecimal(0), scaleOnInfinitePrecision: 2),
          throwsA(isA<UnsupportedError>()),
        );
        expect(
          () => ShortDecimal(1).isDivisibleBy(ShortDecimal(0)),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('divide округляет непредставимое', () {
        expectShortDecimal(
          ShortDecimal(1).divide(ShortDecimal(3), scaleOnInfinitePrecision: 4),
          '0.3333',
        );
        expectShortDecimal(
          ShortDecimal(2).divide(ShortDecimal(3), scaleOnInfinitePrecision: 4),
          '0.6667',
        );
        expectShortDecimal(
          ShortDecimal(-2).divide(ShortDecimal(3), scaleOnInfinitePrecision: 0),
          '-1',
        );

        // Представимое не округляется, даже если попросили меньше знаков.
        expectShortDecimal(
          ShortDecimal(1).divide(ShortDecimal(8), scaleOnInfinitePrecision: 1),
          '0.125',
        );
      });

      test('divide без аргумента бросает то же, что оператор', () {
        expect(
          () => ShortDecimal(1).divide(ShortDecimal(3)),
          throwsA(isA<ShortDecimalDivideException>()),
        );
        expectShortDecimal(ShortDecimal(1).divide(ShortDecimal(4)), '0.25');
      });

      test('isDivisibleBy отвечает про конечную запись, а не про целое', () {
        expect(ShortDecimal(3).isDivisibleBy(ShortDecimal(2)), isTrue);
        expect(ShortDecimal(1).isDivisibleBy(ShortDecimal(4)), isTrue);
        expect(ShortDecimal(1).isDivisibleBy(ShortDecimal(3)), isFalse);
        expect(ShortDecimal(1).isDivisibleBy(ShortDecimal(6)), isFalse);
        expect(ShortDecimal(0).isDivisibleBy(ShortDecimal(7)), isTrue);
      });

      test('согласовано с оператором на множестве случаев', () {
        for (var a = -20; a <= 20; a++) {
          for (var b = -20; b <= 20; b++) {
            if (b == 0) continue;
            final left = ShortDecimal(a);
            final right = ShortDecimal(b);
            final total = left.divideOrNull(right);
            final why = '$a / $b';

            if (total == null) {
              expect(left.isDivisibleBy(right), isFalse, reason: why);
              expect(
                () => left / right,
                throwsA(isA<ShortDecimalDivideException>()),
                reason: why,
              );
            } else {
              expect(left.isDivisibleBy(right), isTrue, reason: why);
              expect((left / right).toString(), total.toString(), reason: why);
            }
          }
        }
      });
    });
  });
}
