/// Деление `Decimal` и `DecimalDivideException`.
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';
import '../support/reference.dart';

void main() {
  group('Decimal', () {
    group('divide', () {
      test('success', () {
        expectDecimal(
          Decimal(24, shiftRight: 1) / Decimal(12, shiftRight: 1),
          '2',
          fractionDigits: 0,
        );

        var value = Decimal.parse('3540570200530940.541182574329856');
        expectDecimal(
          value /= Decimal(123456),
          '28678802168.634497644363776',
          fractionDigits: 15,
        );
        expectDecimal(
          value /= Decimal.parse('12345.6'),
          '2322997.84284558852096',
          fractionDigits: 14,
        );
        expectDecimal(
          value /= Decimal.parse('1234.56'),
          '1881.640295202816',
          fractionDigits: 12,
        );
        expectDecimal(
          value /= Decimal.parse('123.456'),
          '15.241383936',
          fractionDigits: 9,
        );
        expectDecimal(
          value /= Decimal.parse('12.3456'),
          '1.23456',
          fractionDigits: 5,
        );
        expectDecimal(
          value /= Decimal.parse('1.23456'),
          '1',
          fractionDigits: 0,
        );

        value = Decimal.one;
        for (var i = 0; i < 60; i++) {
          value /= Decimal(10);
        }
        expectDecimal(
          value,
          '0.000000000000000000000000000000000000000000000000000000000001',
          fractionDigits: 60,
        );

        expectDecimal(Decimal(1) / Decimal(100), '0.01', fractionDigits: 2);
        expectDecimal(
          Decimal(1) / Decimal(1000, shiftRight: 1),
          '0.01',
          fractionDigits: 2,
        );
        expectDecimal(
          Decimal(1) / Decimal(10000, shiftRight: 2),
          '0.01',
          fractionDigits: 2,
        );

        expect(
          () => Decimal(15129, shiftRight: 1) / Decimal(86100),
          throwsA(
            predicate(
              (error) =>
                  error is DecimalDivideException &&
                  error.fraction.toString() == '123/7000',
            ),
          ),
        );
      });

      group('DecimalDivideException', () {
        test('0.5', () {
          // round
          expect(0.5.round(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), Decimal(2)).round(),
            '1',
          );

          expect((-0.5).round(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), Decimal(2)).round(),
            '-1',
          );

          expect((-1.5).round(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-3), Decimal(2)).round(),
            '-2',
          );

          // floor
          expect(0.5.floor(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), Decimal(2)).floor(),
            '0',
          );

          expect((-0.5).floor(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), Decimal(2)).floor(),
            '-1',
          );

          expect((-1.5).floor(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-3), Decimal(2)).floor(),
            '-2',
          );

          // ceil
          expect(0.5.ceil(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), Decimal(2)).ceil(),
            '1',
          );

          expect((-0.5).ceil(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), Decimal(2)).ceil(),
            '0',
          );

          expect((-1.5).ceil(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-3), Decimal(2)).ceil(),
            '-1',
          );

          // truncate
          expect(0.5.truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), Decimal(2)).truncate(),
            '0',
          );

          expect((-0.5).truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), Decimal(2)).truncate(),
            '0',
          );

          expect((-1.5).truncate(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-3), Decimal(2)).truncate(),
            '-1',
          );
        });

        test('0.1', () {
          // round
          expect(0.1.round(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), Decimal(10)).round(),
            '0',
          );

          expect((-0.1).round(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), Decimal(10)).round(),
            '0',
          );

          expect((-1.1).round(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-11), Decimal(10)).round(),
            '-1',
          );

          // floor
          expect(0.1.floor(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), Decimal(10)).floor(),
            '0',
          );

          expect((-0.1).floor(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), Decimal(10)).floor(),
            '-1',
          );

          expect((-1.1).floor(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-11), Decimal(10)).floor(),
            '-2',
          );

          // ceil
          expect(0.1.ceil(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), Decimal(10)).ceil(),
            '1',
          );

          expect((-0.1).ceil(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), Decimal(10)).ceil(),
            '0',
          );

          expect((-1.1).ceil(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-11), Decimal(10)).ceil(),
            '-1',
          );

          // truncate
          expect(0.1.truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), Decimal(10)).floor(),
            '0',
          );

          expect((-0.1).truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), Decimal(10)).truncate(),
            '0',
          );

          expect((-1.1).truncate(), -1);
          expectDecimal(
            DecimalDivideException.forTest(
              Decimal(-11),
              Decimal(10),
            ).truncate(),
            '-1',
          );
        });

        test('0.9', () {
          // round
          expect(0.9.round(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(9), Decimal(10)).round(),
            '1',
          );

          expect((-0.9).round(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-9), Decimal(10)).round(),
            '-1',
          );

          expect((-1.9).round(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-19), Decimal(10)).round(),
            '-2',
          );

          // floor
          expect(0.9.floor(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(9), Decimal(10)).floor(),
            '0',
          );

          expect((-0.9).floor(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-9), Decimal(10)).floor(),
            '-1',
          );

          expect((-1.9).floor(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-19), Decimal(10)).floor(),
            '-2',
          );

          // ceil
          expect(0.9.ceil(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(9), Decimal(10)).ceil(),
            '1',
          );

          expect((-0.9).ceil(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-9), Decimal(10)).ceil(),
            '0',
          );

          expect((-1.9).ceil(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-19), Decimal(10)).ceil(),
            '-1',
          );

          // truncate
          expect(0.9.truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(9), Decimal(10)).floor(),
            '0',
          );

          expect((-0.9).truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-9), Decimal(10)).truncate(),
            '0',
          );

          expect((-1.1).truncate(), -1);
          expectDecimal(
            DecimalDivideException.forTest(
              Decimal(-19),
              Decimal(10),
            ).truncate(),
            '-1',
          );
        });

        test('+n / +n', () {
          final v1 = Decimal(15129, shiftRight: 1);
          final v2 = Decimal(86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expect(v1 ~/ v2, BigInt.zero);
            expectDecimal(v1 % v2, '1512.9');

            // 0.017(5)
            expect((1512.9 * 1000 / 86100).floor(), 17);
            expectDecimal(e.floor(3), '0.017');

            expect((1512.9 * 1000 / 86100).round(), 18);
            expectDecimal(e.round(3), '0.018');

            expect((1512.9 * 1000 / 86100).ceil(), 18);
            expectDecimal(e.ceil(3), '0.018');

            expect((1512.9 * 1000 / 86100).truncate(), 17);
            expectDecimal(e.truncate(5), '0.01757');

            // 0.017571(4)
            expect((1512.9 * 1000000 / 86100).floor(), 17571);
            expectDecimal(e.floor(6), '0.017571');
            expect((1512.9 * 1000000 / 86100).round(), 17571);
            expectDecimal(e.round(6), '0.017571');
            expect((1512.9 * 1000000 / 86100).ceil(), 17572);
            expectDecimal(e.ceil(6), '0.017572');
            expect((1512.9 * 1000000 / 86100).truncate(), 17571);
            expectDecimal(e.truncate(6), '0.017571');

            // 0.017571428(5)
            expect((1512.9 * 1000000000 / 86100).floor(), 17571428);
            expectDecimal(e.floor(9), '0.017571428');
            expect((1512.9 * 1000000000 / 86100).round(), 17571429);
            expectDecimal(e.round(9), '0.017571429');
            expect((1512.9 * 1000000000 / 86100).ceil(), 17571429);
            expectDecimal(e.ceil(9), '0.017571429');
            expect((1512.9 * 1000000000 / 86100).truncate(), 17571428);
            expectDecimal(e.truncate(9), '0.017571428');
          }
        });

        test('+n / -n', () {
          final v1 = Decimal(15129, shiftRight: 1);
          final v2 = Decimal(-86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expect(v1 ~/ v2, BigInt.zero);
            expectDecimal(v1 % v2, '1512.9');

            // -0.017(5)
            expect((1512.9 * 1000 / -86100).floor(), -18);
            expectDecimal(e.floor(3), '-0.018');
            expect((1512.9 * 1000 / -86100).round(), -18);
            expectDecimal(e.round(3), '-0.018');
            expect((1512.9 * 1000 / -86100).ceil(), -17);
            expectDecimal(e.ceil(3), '-0.017');
            expect((1512.9 * 1000 / -86100).truncate(), -17);
            expectDecimal(e.truncate(3), '-0.017');

            // -0.017571(4)
            expect((1512.9 * 1000000 / -86100).floor(), -17572);
            expectDecimal(e.floor(6), '-0.017572');
            expect((1512.9 * 1000000 / -86100).round(), -17571);
            expectDecimal(e.round(6), '-0.017571');
            expect((1512.9 * 1000000 / -86100).ceil(), -17571);
            expectDecimal(e.ceil(6), '-0.017571');
            expect((1512.9 * 1000000 / -86100).truncate(), -17571);
            expectDecimal(e.truncate(6), '-0.017571');

            // -0.017571428(5)
            expect((1512.9 * 1000000000 / -86100).floor(), -17571429);
            expectDecimal(e.floor(9), '-0.017571429');
            expect((1512.9 * 1000000000 / -86100).round(), -17571429);
            expectDecimal(e.round(9), '-0.017571429');
            expect((1512.9 * 1000000000 / -86100).ceil(), -17571428);
            expectDecimal(e.ceil(9), '-0.017571428');
            expect((1512.9 * 1000000000 / -86100).truncate(), -17571428);
            expectDecimal(e.truncate(9), '-0.017571428');
          }
        });

        test('-n / +n', () {
          final v1 = Decimal(-15129, shiftRight: 1);
          final v2 = Decimal(86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expect(v1 ~/ v2, BigInt.zero);
            expectDecimal(v1 % v2, '84587.1');

            // -0.017(5)
            expect((-1512.9 * 1000 / 86100).floor(), -18);
            expectDecimal(e.floor(3), '-0.018');
            expect((-1512.9 * 1000 / 86100).round(), -18);
            expectDecimal(e.round(3), '-0.018');
            expect((-1512.9 * 1000 / 86100).ceil(), -17);
            expectDecimal(e.ceil(3), '-0.017');
            expect((-1512.9 * 1000 / 86100).truncate(), -17);
            expectDecimal(e.truncate(3), '-0.017');

            // -0.017571(4)
            expect((-1512.9 * 1000000 / 86100).floor(), -17572);
            expectDecimal(e.floor(6), '-0.017572');
            expect((-1512.9 * 1000000 / 86100).round(), -17571);
            expectDecimal(e.round(6), '-0.017571');
            expect((-1512.9 * 1000000 / 86100).ceil(), -17571);
            expectDecimal(e.ceil(6), '-0.017571');
            expect((-1512.9 * 1000000 / 86100).truncate(), -17571);
            expectDecimal(e.truncate(6), '-0.017571');

            // -0.017571428(5)
            expect((-1512.9 * 1000000000 / 86100).floor(), -17571429);
            expectDecimal(e.floor(9), '-0.017571429');
            expect((-1512.9 * 1000000000 / 86100).round(), -17571429);
            expectDecimal(e.round(9), '-0.017571429');
            expect((-1512.9 * 1000000000 / 86100).ceil(), -17571428);
            expectDecimal(e.ceil(9), '-0.017571428');
            expect((-1512.9 * 1000000000 / 86100).truncate(), -17571428);
            expectDecimal(e.truncate(9), '-0.017571428');
          }
        });

        test('-n / -n', () {
          final v1 = Decimal(-15129, shiftRight: 1);
          final v2 = Decimal(-86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expect(v1 ~/ v2, BigInt.zero);
            expectDecimal(v1 % v2, '84587.1');

            // 0.017(5)
            expect((-1512.9 * 1000 / -86100).floor(), 17);
            expectDecimal(e.floor(3), '0.017');
            expect((-1512.9 * 1000 / -86100).round(), 18);
            expectDecimal(e.round(3), '0.018');
            expect((-1512.9 * 1000 / -86100).ceil(), 18);
            expectDecimal(e.ceil(3), '0.018');
            expect((-1512.9 * 1000 / -86100).truncate(), 17);
            expectDecimal(e.truncate(5), '0.01757');

            // 0.017571(4)
            expect((-1512.9 * 1000000 / -86100).floor(), 17571);
            expectDecimal(e.floor(6), '0.017571');
            expect((-1512.9 * 1000000 / -86100).round(), 17571);
            expectDecimal(e.round(6), '0.017571');
            expect((-1512.9 * 1000000 / -86100).ceil(), 17572);
            expectDecimal(e.ceil(6), '0.017572');
            expect((-1512.9 * 1000000 / -86100).truncate(), 17571);
            expectDecimal(e.truncate(6), '0.017571');

            // 0.017571428(5)
            expect((-1512.9 * 1000000000 / -86100).floor(), 17571428);
            expectDecimal(e.floor(9), '0.017571428');
            expect((-1512.9 * 1000000000 / -86100).round(), 17571429);
            expectDecimal(e.round(9), '0.017571429');
            expect((-1512.9 * 1000000000 / -86100).ceil(), 17571429);
            expectDecimal(e.ceil(9), '0.017571429');
            expect((-1512.9 * 1000000000 / -86100).truncate(), 17571428);
            expectDecimal(e.truncate(9), '0.017571428');
          }
        });

        test('big / small', () {
          // 8733 / 0.0086100 = 1014285.(714285)…
          // modulo: 0.00615
          // 1014285 * 0.00861 = 8732.99385
          // 8732.99385 + 0.00615 = 8733
          var v1 = Decimal(8733);
          var v2 = Decimal.parse('0.0086100');
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expectDecimal(e.floor(), '1014285');
            expectDecimal(e.round(), '1014286');
            expectDecimal(e.ceil(), '1014286');
            expectDecimal(e.truncate(), '1014285');

            expectFraction(e.fraction, '7100000/7');
            expectDivision(
              e.quotientWithRemainder,
              '1014285 remainder 0.00615',
            );
          }

          expect(v1 ~/ v2, BigInt.from(1014285));
          expectDecimal(v1 % v2, '0.00615', fractionDigits: 5);

          // +n / -n
          v1 = Decimal(8733);
          v2 = Decimal.parse('-0.0086100');
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expectDecimal(e.floor(), '-1014286');
            expectDecimal(e.round(), '-1014286');
            expectDecimal(e.ceil(), '-1014285');
            expectDecimal(e.truncate(), '-1014285');

            expectFraction(e.fraction, '-7100000/7');
            expectDivision(
              e.quotientWithRemainder,
              '-1014285 remainder 0.00615',
            );
          }

          expect(v1 ~/ v2, BigInt.from(-1014285));
          expectDecimal(v1 % v2, '0.00615', fractionDigits: 5);
        });

        test('small / big', () {
          // 94833 / 86100.00 = 1.1014285(714285)…
          // modulo: 8733
          // 1 * 86100 = 86100
          // 86100 + 8733 = 94833
          final v1 = Decimal(94833);
          final v2 = Decimal.parse('86100.00');
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expectDecimal(e.floor(6), '1.101428');
            expectDecimal(e.round(6), '1.101429');
            expectDecimal(e.ceil(6), '1.101429');
            expectDecimal(e.truncate(6), '1.101428');
            expectDecimal(e.truncate(12), '1.101428571428');

            expectFraction(e.fraction, '771/700');
            expectDivision(e.quotientWithRemainder, '1 remainder 8733');
          }

          expect(v1 ~/ v2, BigInt.one);
          expectDecimal(v1 % v2, '8733', fractionDigits: 0);
        });
      });
    });

    test('деление на очень большую степень двойки', () {
      // Показатель за пределом кеша степеней пятёрки: путь редкий, но точный.
      final divisor = Decimal.fromBigInt(BigInt.two.pow(130));
      final result = Decimal(1) / divisor;

      expect(result * divisor, Decimal(1));
      expect(result.toString().length, greaterThan(130));
    });

    test('печать исключения содержит и остаток, и дробь', () {
      try {
        final unused = Decimal(1) / Decimal(3);
        fail('ожидалось DecimalDivideException, получено $unused');
      } on DecimalDivideException catch (error) {
        final text = error.toString();

        expect(text, contains('1 / 3 = 0 remainder 1'));
        expect(text, contains('1 / 3 = 1/3'));
        expect(error.dividend, Decimal(1));
        expect(error.divisor, Decimal(3));
      }
    });

    // Волна 4: тотальные формы деления. Ловля исключения стоит около 800 нс,
    // чтение null — доли наносекунды, а заглавный путь пакета не должен быть
    // его самым медленным.
    group('тотальное деление', () {
      test('divideOrNull возвращает результат или null', () {
        expectDecimal(Decimal(1).divideOrNull(Decimal(4))!, '0.25');
        expectDecimal(Decimal(6).divideOrNull(Decimal(3))!, '2');
        expectDecimal(Decimal(1).divideOrNull(Decimal(-2))!, '-0.5');
        expect(Decimal(1).divideOrNull(Decimal(3)), isNull);
        expect(Decimal(1).divideOrNull(Decimal(7)), isNull);
      });

      test('divide округляет так же, как дробь, на знаках и краях', () {
        // Округление у divide — то же самое, что у Fraction.round: это его
        // определение, и прямой путь обязан его сохранять.
        for (final (dividend, divisor, digits) in <(String, String, int)>[
          ('1', '3', 4),
          ('-1', '3', 4),
          ('1', '-3', 4),
          ('-1', '-3', 4),
          ('2', '3', 0),
          ('-2', '3', 0),
          ('12345', '7', -2),
          ('-12345', '7', -2),
          ('0.000001', '3', 8),
          ('1e30', '7', -20),
          ('1', '3', 0),
          ('-1', '3', 0),
        ]) {
          final a = Decimal.parse(dividend);
          final b = Decimal.parse(divisor);
          expect(
            a.divide(b, scaleOnInfinitePrecision: digits),
            a.divideToFraction(b).round(digits),
            reason: '$dividend / $divisor до $digits знаков',
          );
        }
      });

      test('divide с отрицательным числом знаков округляет к десяткам', () {
        // Отрицательное scaleOnInfinitePrecision — рабочий режим, как и
        // отрицательный масштаб: 12345/7 это 1763.57…, к сотням — 1800.
        expectDecimal(
          Decimal(12345).divide(Decimal(7), scaleOnInfinitePrecision: -2),
          '1800',
        );
        expectDecimal(
          Decimal(-12345).divide(Decimal(7), scaleOnInfinitePrecision: -2),
          '-1800',
        );
        expectDecimal(
          Decimal(149).divide(Decimal(3), scaleOnInfinitePrecision: -2),
          '0',
        );
      });

      test('на ноль все деления бросают один и тот же тип', () {
        // До 1.2.0 `~/`, `%` и `remainder` бросали
        // IntegerDivisionByZeroException, а `/` — UnsupportedError: одна
        // ошибка, два типа. Старый тип в SDK помечен устаревшим и сам
        // реализует UnsupportedError, так что ловившие второй ничего не
        // заметили.
        final one = Decimal(1);
        final zero = Decimal(0);

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
          () => Decimal(1).divideOrNull(Decimal(0)),
          throwsA(isA<UnsupportedError>()),
        );
        expect(
          () => Decimal(1).divide(Decimal(0), scaleOnInfinitePrecision: 2),
          throwsA(isA<UnsupportedError>()),
        );
        expect(
          () => Decimal(1).isDivisibleBy(Decimal(0)),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('divide округляет непредставимое', () {
        expectDecimal(
          Decimal(1).divide(Decimal(3), scaleOnInfinitePrecision: 4),
          '0.3333',
        );
        expectDecimal(
          Decimal(2).divide(Decimal(3), scaleOnInfinitePrecision: 4),
          '0.6667',
        );
        expectDecimal(
          Decimal(-2).divide(Decimal(3), scaleOnInfinitePrecision: 0),
          '-1',
        );

        // Представимое не округляется, даже если попросили меньше знаков.
        expectDecimal(
          Decimal(1).divide(Decimal(8), scaleOnInfinitePrecision: 1),
          '0.125',
        );
      });

      test('divide без аргумента бросает то же, что оператор', () {
        expect(
          () => Decimal(1).divide(Decimal(3)),
          throwsA(isA<DecimalDivideException>()),
        );
        expectDecimal(Decimal(1).divide(Decimal(4)), '0.25');
      });

      test('isDivisibleBy отвечает про конечную запись, а не про целое', () {
        expect(Decimal(3).isDivisibleBy(Decimal(2)), isTrue);
        expect(Decimal(1).isDivisibleBy(Decimal(4)), isTrue);
        expect(Decimal(1).isDivisibleBy(Decimal(3)), isFalse);
        expect(Decimal(1).isDivisibleBy(Decimal(6)), isFalse);
        expect(Decimal(0).isDivisibleBy(Decimal(7)), isTrue);
      });

      test('согласовано с моделью на множестве случаев', () {
        // Сверять три члена пакета друг с другом мало: они сходились бы и на
        // общей ошибке. Ожидание берётся у точной рациональной модели, а
        // согласованность между членами проверяется поверх него.
        for (var a = -20; a <= 20; a++) {
          for (var b = -20; b <= 20; b++) {
            if (b == 0) continue;
            final left = Decimal(a);
            final right = Decimal(b);
            final model = Ref.fromInt(a) / Ref.fromInt(b);
            final total = left.divideOrNull(right);
            final why = '$a / $b';

            expect(
              left.isDivisibleBy(right),
              model.hasFiniteDecimal,
              reason: why,
            );

            if (model.hasFiniteDecimal) {
              expect(total?.toString(), model.toDecimalString(), reason: why);
              expect(
                (left / right).toString(),
                model.toDecimalString(),
                reason: why,
              );
            } else {
              expect(total, isNull, reason: why);
              expect(
                () => left / right,
                throwsA(isA<DecimalDivideException>()),
                reason: why,
              );
            }
          }
        }
      });
    });
  });
}
