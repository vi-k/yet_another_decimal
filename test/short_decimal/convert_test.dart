// ignore_for_file: avoid_js_rounded_ints

/// Преобразования `ShortDecimal` в другие типы и `isInteger`.
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';

void main() {
  group('ShortDecimal', () {
    test('toInt', () {
      expect(ShortDecimal.parse('3.75').toInt(), 3);
      expect(ShortDecimal.parse('-3.75').toInt(), -3);

      expectShortDecimal(
        ShortDecimal.parse('1234567890.123456789'),
        '1234567890.123456789',
        fractionDigits: 9,
      );
      expect(ShortDecimal.parse('1234567890.123456789').toInt(), 1234567890);
      expect(ShortDecimal.parse('1234567890.9').toInt(), 1234567890);
    });
    test('toDouble', () {
      expectDouble(ShortDecimal.parse('0').toDouble(), 0, '0.0');
      expectDouble(ShortDecimal.parse('0.1').toDouble(), 0.1, '0.1');
      expectDouble(ShortDecimal.parse('0.01').toDouble(), 0.01, '0.01');
      expectDouble(ShortDecimal.parse('0.001').toDouble(), 0.001, '0.001');
      expectDouble(ShortDecimal.parse('0.0001').toDouble(), 0.0001, '0.0001');
      expectDouble(
        ShortDecimal.parse('0.00001').toDouble(),
        0.00001,
        '0.00001',
      );
      expectDouble(
        ShortDecimal.parse('0.000001').toDouble(),
        0.000001,
        '0.000001',
      );
      expectDouble(
        ShortDecimal.parse('0.0000001').toDouble(),
        0.0000001,
        '1e-7',
      );
      expectDouble(
        ShortDecimal.parse('0.00000001').toDouble(),
        0.00000001,
        '1e-8',
      );
      expectDouble(
        ShortDecimal.parse('0.000000001').toDouble(),
        0.000000001,
        '1e-9',
      );
      expectDouble(
        ShortDecimal.parse('0.0000000001').toDouble(),
        0.0000000001,
        '1e-10',
      );

      expectDouble(ShortDecimal.parse('0.12').toDouble(), 0.12, '0.12');
      expectDouble(ShortDecimal.parse('0.123').toDouble(), 0.123, '0.123');
      expectDouble(ShortDecimal.parse('0.1234').toDouble(), 0.1234, '0.1234');
      expectDouble(
        ShortDecimal.parse('0.12345').toDouble(),
        0.12345,
        '0.12345',
      );
      expectDouble(
        ShortDecimal.parse('0.123456').toDouble(),
        0.123456,
        '0.123456',
      );
      expectDouble(
        ShortDecimal.parse('0.1234567').toDouble(),
        0.1234567,
        '0.1234567',
      );
      expectDouble(
        ShortDecimal.parse('0.12345678').toDouble(),
        0.12345678,
        '0.12345678',
      );
      expectDouble(
        ShortDecimal.parse('0.123456789').toDouble(),
        0.123456789,
        '0.123456789',
      );
      expectDouble(
        ShortDecimal.parse('0.1234567890').toDouble(),
        0.123456789,
        '0.123456789',
      );
      expectDouble(
        ShortDecimal.parse('0.12345678901').toDouble(),
        0.12345678901,
        '0.12345678901',
      );
      expectDouble(
        ShortDecimal.parse('0.123456789012').toDouble(),
        0.123456789012,
        '0.123456789012',
      );
      expectDouble(
        ShortDecimal.parse('0.1234567890123').toDouble(),
        0.1234567890123,
        '0.1234567890123',
      );
      expectDouble(
        ShortDecimal.parse('0.12345678901234').toDouble(),
        0.12345678901234,
        '0.12345678901234',
      );
      expectDouble(
        ShortDecimal.parse('0.123456789012345').toDouble(),
        0.123456789012345,
        '0.123456789012345',
      );
      expectDouble(
        ShortDecimal.parse('0.1234567890123456').toDouble(),
        0.1234567890123456,
        '0.1234567890123456',
      );
      // Loss of precision.
      expectDouble(
        ShortDecimal.parse('0.12345678901234567').toDouble(),
        0.12345678901234566,
        '0.12345678901234566',
      );
      expectDouble(
        ShortDecimal.parse('0.123456789012345678').toDouble(),
        0.12345678901234568,
        '0.12345678901234568',
      );

      // Loss of precision.

      const d = 1234567890123456789.0;
      const str = '1234567890123456800.0';
      expectDouble(
        ShortDecimal(1234567890123456640).toDouble(),
        d,
        str,
        isValid: false,
      );
      expectDouble(ShortDecimal(1234567890123456641).toDouble(), d, str);
      expectDouble(ShortDecimal(1234567890123456895).toDouble(), d, str);
      expectDouble(
        ShortDecimal(1234567890123456896).toDouble(),
        d,
        str,
        isValid: false,
      );
    });
    group('isInteger', () {
      test('ShortDecimal(0)', () {
        expect(ShortDecimal(0).isInteger, isTrue);
      });

      test('ShortDecimal(0) >> 10', () {
        expect((ShortDecimal(0) >> 10).isInteger, isTrue);
      });

      test('ShortDecimal(2)', () {
        expect(ShortDecimal(2).isInteger, isTrue);
      });

      test('ShortDecimal(2) >> 1', () {
        expect((ShortDecimal(2) >> 1).isInteger, isFalse);
      });

      test('ShortDecimal(-2)', () {
        expect(ShortDecimal(-2).isInteger, isTrue);
      });

      test('ShortDecimal(-2) >> 1', () {
        expect((ShortDecimal(-2) >> 1).isInteger, isFalse);
      });

      test('ShortDecimal(1111111111111111110)', () {
        expect(ShortDecimal(1111111111111111110).isInteger, isTrue);
      });

      test('ShortDecimal(1111111111111111110) >> 1', () {
        expect((ShortDecimal(1111111111111111110) >> 1).isInteger, isTrue);
      });

      test('ShortDecimal(1111111111111111110) >> 2', () {
        expect((ShortDecimal(1111111111111111110) >> 2).isInteger, isFalse);
      });

      test('ShortDecimal(-1111111111111111110)', () {
        expect(ShortDecimal(-1111111111111111110).isInteger, isTrue);
      });

      test('ShortDecimal(-1111111111111111110) >> 1', () {
        expect((ShortDecimal(-1111111111111111110) >> 1).isInteger, isTrue);
      });

      test('ShortDecimal(-1111111111111111110) >> 2', () {
        expect((ShortDecimal(-1111111111111111110) >> 2).isInteger, isFalse);
      });
    });

    // Д2: делитель округления не помещается в int64, когда разрыв масштабов
    // больше восемнадцати. Частное тогда заведомо ноль, а ответ даёт правило
    // самого метода.
    group('округление почти-нуля', () {
      final dust = ShortDecimal.parse('0.0000000000000000001');
      final negativeDust = ShortDecimal.parse('-0.0000000000000000001');

      test('floor', () {
        expectShortDecimal(dust.floor(), '0');
        expectShortDecimal(negativeDust.floor(), '-1');
      });

      test('ceil', () {
        expectShortDecimal(dust.ceil(), '1');
        expectShortDecimal(negativeDust.ceil(), '0');
      });

      test('round и truncate', () {
        expectShortDecimal(dust.round(), '0');
        expectShortDecimal(dust.truncate(), '0');
        expectShortDecimal(negativeDust.round(), '0');
        expectShortDecimal(negativeDust.truncate(), '0');
      });

      test('совпадает с Decimal', () {
        for (final source in [
          '0.0000000000000000001',
          '-0.0000000000000000001',
          '0.9223372036854775807',
          '-0.9223372036854775807',
        ]) {
          final short = ShortDecimal.parse(source);
          final wide = Decimal.parse(source);
          expect(
            '${short.floor()}',
            '${wide.floor()}',
            reason: 'floor $source',
          );
          expect('${short.ceil()}', '${wide.ceil()}', reason: 'ceil $source');
          expect(
            '${short.round()}',
            '${wide.round()}',
            reason: 'round $source',
          );
          expect(
            '${short.truncate()}',
            '${wide.truncate()}',
            reason: 'truncate $source',
          );
        }
      });
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
            final value = ShortDecimal(base) >> scale;
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
          final value = ShortDecimal.parse(source);

          expect(
            value.toDouble(),
            double.parse(value.toString()),
            reason: source,
          );
        }
      });
    });

    group('unscaledValue и exponent', () {
      for (final (source, value, exponent) in [
        ('0', 0, 0),
        ('1', 1, 0),
        ('1.5', 15, -1),
        ('1.50', 15, -1),
        ('100', 1, 2),
        ('-0.05', -5, -2),
      ]) {
        test('$source даёт $value и $exponent', () {
          final d = ShortDecimal.parse(source);
          expect(d.unscaledValue, value);
          expect(d.exponent, exponent);
        });
      }

      test('пара восстанавливает значение', () {
        for (final source in ['0', '1.5', '1.50', '100', '-0.05']) {
          final d = ShortDecimal.parse(source);
          expect(ShortDecimal(d.unscaledValue) << d.exponent, d,
              reason: source);
        }
      });
    });

    group('normalized', () {
      test('отдаёт то же самое: форма здесь канонична всегда', () {
        for (final source in ['0', '1.5', '1.50', '100', '-0.05']) {
          final d = ShortDecimal.parse(source);
          expect(identical(d.normalized(), d), isTrue, reason: source);
        }
      });
    });

    group('movePointLeft и movePointRight', () {
      for (final (source, places) in [
        ('1', 2),
        ('100', 2),
        ('1.5', 3),
        ('-0.05', 1),
        ('0', 5),
        ('12345', -3),
      ]) {
        test('$source на $places совпадает с операторами', () {
          final d = ShortDecimal.parse(source);
          expect(d.movePointLeft(places), d >> places);
          expect(d.movePointRight(places), d << places);
        });
      }
    });

    group('precision', () {
      for (final (source, expected) in [
        ('0', 1),
        ('-0', 1),
        ('1', 1),
        ('1.5', 2),
        ('0.5', 2),
        ('0.05', 3),
        ('-0.05', 3),
        ('100', 3),
        ('100.00', 3),
        ('1234.5678', 8),
        ('-1234.5678', 8),
        ('-1', 1),
      ]) {
        test('$source даёт $expected', () {
          expect(ShortDecimal.parse(source).precision, expected);
        });
      }
    });

    test('isPositive', () {
      expect(ShortDecimal.parse('1').isPositive, isTrue);
      expect(ShortDecimal.parse('0.0001').isPositive, isTrue);
      expect(ShortDecimal.parse('0').isPositive, isFalse);
      expect(ShortDecimal.parse('-0').isPositive, isFalse);
      expect(ShortDecimal.parse('-1').isPositive, isFalse);

      // Ноль не положителен и не отрицателен.
      expect(ShortDecimal.parse('0').isNegative, isFalse);
    });

    test('inverse даёт точную дробь', () {
      expect(ShortDecimal.parse('0.5').inverse.toString(), '2');
      expect(ShortDecimal.parse('2').inverse.toString(), '1/2');
      expect(ShortDecimal.parse('3').inverse.toString(), '1/3');
      expect(ShortDecimal.parse('100').inverse.toString(), '1/100');
      expect(ShortDecimal.parse('-0.25').inverse.toString(), '-4');

      // Отрицательный масштаб: значение хранится сдвинутым влево.
      expect((ShortDecimal(1) << 2).inverse.toString(), '1/100');
      expect((ShortDecimal(3) << 1).inverse.toString(), '1/30');

      expect(
        () => ShortDecimal.parse('0').inverse,
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('toJson и fromJson', () {
      for (final source in ['0', '1.5', '-0.05', '1234.5678', '100']) {
        final value = ShortDecimal.parse(source);

        expect(value.toJson(), value.toString());
        expect(ShortDecimal.fromJson(value.toJson()), value);
      }

      expect(
        () => ShortDecimal.fromJson('мусор'),
        throwsA(isA<FormatException>()),
      );
    });

    test('toBigInt рядом с toInt', () {
      expect(ShortDecimal.parse('1.9').toBigInt(), BigInt.one);
      expect(ShortDecimal.parse('-1.9').toBigInt(), -BigInt.one);
      expect((ShortDecimal(1) << 3).toBigInt(), BigInt.from(1000));

      // Согласовано с семейством на BigInt.
      expect(
        ShortDecimal.parse('-1.9').toBigInt(),
        Decimal.parse('-1.9').toBigInt(),
      );

      // toInt переполняется там, где toBigInt точен.
      final huge = ShortDecimal(1) << 25;
      expect(huge.toBigInt(), BigInt.parse('1${'0' * 25}'));
    });
  });
}
