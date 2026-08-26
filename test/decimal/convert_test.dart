/// Преобразования `Decimal` в другие типы и `isInteger`.
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';

void main() {
  group('Decimal', () {
    test('toBigInt', () {
      expect(Decimal.parse('3.75').toBigInt(), BigInt.from(3));
      expect(Decimal.parse('-3.75').toBigInt(), BigInt.from(-3));

      expect(
        Decimal.parse('12345678901234567890.12345678901234567890').toBigInt(),
        BigInt.parse('12345678901234567890'),
      );
      expect(
        Decimal.parse('12345678901234567890.9').toBigInt(),
        BigInt.parse('12345678901234567890'),
      );
    });
    test('toDouble', () {
      expectDouble(Decimal.parse('0').toDouble(), 0, '0.0');
      expectDouble(Decimal.parse('0.1').toDouble(), 0.1, '0.1');
      expectDouble(Decimal.parse('0.01').toDouble(), 0.01, '0.01');
      expectDouble(Decimal.parse('0.001').toDouble(), 0.001, '0.001');
      expectDouble(Decimal.parse('0.0001').toDouble(), 0.0001, '0.0001');
      expectDouble(Decimal.parse('0.00001').toDouble(), 0.00001, '0.00001');
      expectDouble(Decimal.parse('0.000001').toDouble(), 0.000001, '0.000001');
      expectDouble(Decimal.parse('0.0000001').toDouble(), 0.0000001, '1e-7');
      expectDouble(Decimal.parse('0.00000001').toDouble(), 0.00000001, '1e-8');
      expectDouble(
        Decimal.parse('0.000000001').toDouble(),
        0.000000001,
        '1e-9',
      );
      expectDouble(
        Decimal.parse('0.0000000001').toDouble(),
        0.0000000001,
        '1e-10',
      );

      expectDouble(Decimal.parse('0.12').toDouble(), 0.12, '0.12');
      expectDouble(Decimal.parse('0.123').toDouble(), 0.123, '0.123');
      expectDouble(Decimal.parse('0.1234').toDouble(), 0.1234, '0.1234');
      expectDouble(Decimal.parse('0.12345').toDouble(), 0.12345, '0.12345');
      expectDouble(Decimal.parse('0.123456').toDouble(), 0.123456, '0.123456');
      expectDouble(
        Decimal.parse('0.1234567').toDouble(),
        0.1234567,
        '0.1234567',
      );
      expectDouble(
        Decimal.parse('0.12345678').toDouble(),
        0.12345678,
        '0.12345678',
      );
      expectDouble(
        Decimal.parse('0.123456789').toDouble(),
        0.123456789,
        '0.123456789',
      );
      expectDouble(
        Decimal.parse('0.1234567890').toDouble(),
        0.123456789,
        '0.123456789',
      );
      expectDouble(
        Decimal.parse('0.12345678901').toDouble(),
        0.12345678901,
        '0.12345678901',
      );
      expectDouble(
        Decimal.parse('0.123456789012').toDouble(),
        0.123456789012,
        '0.123456789012',
      );
      expectDouble(
        Decimal.parse('0.1234567890123').toDouble(),
        0.1234567890123,
        '0.1234567890123',
      );
      expectDouble(
        Decimal.parse('0.12345678901234').toDouble(),
        0.12345678901234,
        '0.12345678901234',
      );
      expectDouble(
        Decimal.parse('0.123456789012345').toDouble(),
        0.123456789012345,
        '0.123456789012345',
      );
      expectDouble(
        Decimal.parse('0.1234567890123456').toDouble(),
        0.1234567890123456,
        '0.1234567890123456',
      );
      // Loss of precision.
      expectDouble(
        Decimal.parse('0.12345678901234567').toDouble(),
        0.12345678901234566,
        '0.12345678901234566',
      );
      expectDouble(
        Decimal.parse('0.123456789012345678').toDouble(),
        0.12345678901234568,
        '0.12345678901234568',
      );

      // Loss of precision.

      var d = 12345678901234567890.0;
      var str = '12345678901234567000.0';
      expectDouble(
        Decimal.parse('12345678901234566144').toDouble(),
        d,
        str,
        isValid: false,
      );
      expectDouble(Decimal.parse('12345678901234566145').toDouble(), d, str);
      expectDouble(Decimal.parse('12345678901234568191').toDouble(), d, str);
      expectDouble(
        Decimal.parse('12345678901234568192').toDouble(),
        d,
        str,
        isValid: false,
      );

      d = 123456789012345678901234567890.0;
      str = '1.2345678901234568e+29';
      expectDouble(
        Decimal.parse('123456789012345669081626574847').toDouble(),
        d,
        str,
        isValid: false,
      );
      expectDouble(
        Decimal.parse('123456789012345669081626574848').toDouble(),
        d,
        str,
      );
      expectDouble(
        Decimal.parse('123456789012345686673812619264').toDouble(),
        d,
        str,
      );
      expectDouble(
        Decimal.parse('123456789012345686673812619265').toDouble(),
        d,
        str,
        isValid: false,
      );
    });
    group('isInteger', () {
      test('Decimal(0)', () {
        expect(Decimal(0).isInteger, isTrue);
      });

      test('Decimal(0) >> 10', () {
        expect((Decimal(0) >> 10).isInteger, isTrue);
      });

      test('Decimal(2)', () {
        expect(Decimal(2).isInteger, isTrue);
      });

      test('Decimal(2) >> 1', () {
        expect((Decimal(2) >> 1).isInteger, isFalse);
      });

      test('Decimal(-2)', () {
        expect(Decimal(-2).isInteger, isTrue);
      });

      test('Decimal(-2) >> 1', () {
        expect((Decimal(-2) >> 1).isInteger, isFalse);
      });

      test('12345678901234567890', () {
        expect(Decimal.parse('12345678901234567890').isInteger, isTrue);
      });

      test('12345678901234567890 >> 1', () {
        expect((Decimal.parse('12345678901234567890') >> 1).isInteger, isTrue);
      });

      test('12345678901234567890 >> 2', () {
        expect((Decimal.parse('12345678901234567890') >> 2).isInteger, isFalse);
      });

      test('-12345678901234567890', () {
        expect(Decimal.parse('-12345678901234567890').isInteger, isTrue);
      });

      test('-12345678901234567890 >> 1', () {
        expect((Decimal.parse('-12345678901234567890') >> 1).isInteger, isTrue);
      });

      test('-12345678901234567890 >> 2', () {
        expect(
          (Decimal.parse('-12345678901234567890') >> 2).isInteger,
          isFalse,
        );
      });
    });

    group('divideToDouble', () {
      test('обычные значения', () {
        expect(Decimal(1).divideToDouble(Decimal(2)), 0.5);
        expect(Decimal(0).divideToDouble(Decimal(3)), 0.0);
        expect(Decimal(1).divideToDouble(Decimal(3)), 1 / 3);
        expect(Decimal(-1).divideToDouble(Decimal(3)), -1 / 3);
        expect(Decimal(2).divideToDouble(Decimal(3)), 2 / 3);
      });

      // Д8: BigInt.operator / — это toDouble() / toDouble(), и на числах
      // высокой точности оба конца становятся Infinity.
      test('высокая точность не даёт NaN', () {
        final a = Decimal.parse('0.${'1234567890' * 40}');
        final b = Decimal.parse('0.${'2345678901' * 40}');
        final result = a.divideToDouble(b);

        expect(result.isNaN, isFalse);
        expect(result, closeTo(0.5263158, 1e-6));
      });

      test('за пределом double', () {
        final huge = Decimal.parse('1e400');
        final tiny = Decimal.parse('1e-400');

        expect(huge.divideToDouble(tiny), double.infinity);
        expect((-huge).divideToDouble(tiny), double.negativeInfinity);
        expect(tiny.divideToDouble(huge), 0.0);
      });
    });

    test('расширения int и BigInt', () {
      expectDecimal(5.toDecimal(), '5');
      expectDecimal((-5).toDecimal(), '-5');
      expectDecimal(BigInt.from(5).toDecimal(), '5');
      expectDecimal(
        BigInt.parse('12345678901234567890').toDecimal(),
        '12345678901234567890',
      );
    });

    // П4: прямой путь `base / 10^scale` вместо разбора строки. Оба операнда
    // точны в double, поэтому округление одно — и ответ обязан совпасть с
    // разбором строки **побитово**, а не приблизительно. Границы 2^53 и 10^22
    // — то место, где легко молча потерять точность.
    group('toDouble совпадает с разбором строки', () {
      const bases = [
        0, 1, -1, 123456789, 999999999999999,
        4503599627370496, // 2^52
        9007199254740991, // 2^53 - 1
        9007199254740992, // 2^53
        // 2^53 + 1 — первое целое, которого в double уже нет. Пишется
        // сложением, чтобы не вносить в тест литерал, который сам не
        // переживает JavaScript-число.
        9007199254740992 + 1,
        -9007199254740991, -9007199254740992, -9007199254740992 - 1,
      ];

      for (final base in bases) {
        test('база $base на масштабах от -25 до 25', () {
          for (var scale = -25; scale <= 25; scale++) {
            // Сдвиг оператором, а не аргументом: `shiftRight` не берёт
            // отрицательное.
            final value = Decimal(base) >> scale;
            final viaString = double.parse(value.toString());

            expect(
              value.toDouble(),
              viaString,
              reason: 'база $base, масштаб $scale',
            );
            expect(
              value.toDouble().toString(),
              viaString.toString(),
              reason: 'побитово, база $base, масштаб $scale',
            );
          }
        });
      }

      test('за границами быстрого пути — тот же ответ', () {
        for (final source in [
          '1${'0' * 30}.5',
          '0.${'0' * 30}1',
          '123456789012345678901234567890',
          '1e23',
          '1e-23',
        ]) {
          final value = Decimal.parse(source);

          expect(
            value.toDouble(),
            double.parse(value.toString()),
            reason: source,
          );
        }
      });

      test('значения, на которых double обычно врёт', () {
        for (final source in [
          '0.1',
          '0.2',
          '0.3',
          '1.005',
          '2.675',
          '1234.5678',
          '-1234.5678',
          '0.000001',
          '1e22',
          '1e-22',
        ]) {
          final value = Decimal.parse(source);

          expect(
            value.toDouble(),
            double.parse(value.toString()),
            reason: source,
          );
        }
      });
    });
  });
}
