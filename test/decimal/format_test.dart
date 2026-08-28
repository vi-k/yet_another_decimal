/// Вывод `Decimal` строкой и заполнение канонической формы.
///
/// Здесь сверка `base` и `scale` уместна: `toString` обязан снимать хвостовые
/// нули, не трогая представление, а `normalized()` — отдавать каноническую
/// форму значением, не меняя того, у кого его спросили.
library;

import 'package:denary/denary.dart';
import 'package:test/test.dart';

import '../support/expect.dart';

void main() {
  group('Decimal', () {
    group('toString', () {
      test('Decimal(0)', () {
        expectDecimal(
          Decimal(0),
          '0',
          base: BigInt.from(0),
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('Decimal(0) >> 1', () {
        expectDecimal(
          Decimal(0) >> 1,
          '0',
          base: BigInt.from(0),
          scale: 1,
          fractionDigits: 0,
        );
      });

      test('Decimal(0) >> 2', () {
        expectDecimal(
          Decimal(0) >> 2,
          '0',
          base: BigInt.from(0),
          scale: 2,
          fractionDigits: 0,
        );
      });

      test('Decimal(0) >> 3', () {
        expectDecimal(
          Decimal(0) >> 3,
          '0',
          base: BigInt.from(0),
          scale: 3,
          fractionDigits: 0,
        );
      });

      test('Decimal(1)', () {
        expectDecimal(
          Decimal(1),
          '1',
          base: BigInt.from(1),
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('Decimal(1) >> 1', () {
        expectDecimal(
          Decimal(1) >> 1,
          '0.1',
          base: BigInt.from(1),
          scale: 1,
          fractionDigits: 1,
        );
      });

      test('Decimal(1) >> 2', () {
        expectDecimal(
          Decimal(1) >> 2,
          '0.01',
          base: BigInt.from(1),
          scale: 2,
          fractionDigits: 2,
        );
      });

      test('Decimal(1) >> 3', () {
        expectDecimal(
          Decimal(1) >> 3,
          '0.001',
          base: BigInt.from(1),
          scale: 3,
          fractionDigits: 3,
        );
      });

      test('Decimal(10)', () {
        expectDecimal(
          Decimal(10),
          '10',
          base: BigInt.from(10),
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('Decimal(1) << 1', () {
        expectDecimal(
          Decimal(1) << 1,
          '10',
          base: BigInt.from(1),
          scale: -1,
          fractionDigits: 0,
        );
      });

      test('Decimal(100)', () {
        expectDecimal(
          Decimal(100),
          '100',
          base: BigInt.from(100),
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('Decimal(1) << 2', () {
        expectDecimal(
          Decimal(1) << 2,
          '100',
          base: BigInt.from(1),
          scale: -2,
          fractionDigits: 0,
        );
      });

      test('Decimal(1000)', () {
        expectDecimal(
          Decimal(1000),
          '1000',
          base: BigInt.from(1000),
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('Decimal(1) << 3', () {
        expectDecimal(
          Decimal(1) << 3,
          '1000',
          base: BigInt.from(1),
          scale: -3,
          fractionDigits: 0,
        );
      });

      test('Decimal(1000) >> 1', () {
        expectDecimal(
          Decimal(1000) >> 1,
          '100',
          base: BigInt.from(1000),
          scale: 1,
          fractionDigits: 0,
        );
      });

      test('Decimal(1000) >> 2', () {
        expectDecimal(
          Decimal(1000) >> 2,
          '10',
          base: BigInt.from(1000),
          scale: 2,
          fractionDigits: 0,
        );
      });

      test('Decimal(1000) >> 3', () {
        expectDecimal(
          Decimal(1000) >> 3,
          '1',
          base: BigInt.from(1000),
          scale: 3,
          fractionDigits: 0,
        );
      });

      test('Decimal(1000) >> 4', () {
        expectDecimal(
          Decimal(1000) >> 4,
          '0.1',
          base: BigInt.from(1000),
          scale: 4,
          fractionDigits: 1,
        );
      });

      test('Decimal(1000) >> 5', () {
        expectDecimal(
          Decimal(1000) >> 5,
          '0.01',
          base: BigInt.from(1000),
          scale: 5,
          fractionDigits: 2,
        );
      });

      test('Decimal(1000) >> 6', () {
        expectDecimal(
          Decimal(1000) >> 6,
          '0.001',
          base: BigInt.from(1000),
          scale: 6,
          fractionDigits: 3,
        );
      });

      test('Decimal(1234567890)', () {
        expectDecimal(
          Decimal(1234567890),
          '1234567890',
          base: BigInt.from(1234567890),
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('Decimal(1234567890) >> 1', () {
        expectDecimal(
          Decimal(1234567890) >> 1,
          '123456789',
          base: BigInt.from(1234567890),
          scale: 1,
          fractionDigits: 0,
        );
      });

      test('Decimal(1234567890) >> 2', () {
        expectDecimal(
          Decimal(1234567890) >> 2,
          '12345678.9',
          base: BigInt.from(1234567890),
          scale: 2,
          fractionDigits: 1,
        );
      });

      test('Decimal(1234567890) >> 3', () {
        expectDecimal(
          Decimal(1234567890) >> 3,
          '1234567.89',
          base: BigInt.from(1234567890),
          scale: 3,
          fractionDigits: 2,
        );
      });

      test('Decimal(1234567890) >> 4', () {
        expectDecimal(
          Decimal(1234567890) >> 4,
          '123456.789',
          base: BigInt.from(1234567890),
          scale: 4,
          fractionDigits: 3,
        );
      });

      test('Decimal(1234567890) >> 5', () {
        expectDecimal(
          Decimal(1234567890) >> 5,
          '12345.6789',
          base: BigInt.from(1234567890),
          scale: 5,
          fractionDigits: 4,
        );
      });

      test('Decimal(1234567890) >> 6', () {
        expectDecimal(
          Decimal(1234567890) >> 6,
          '1234.56789',
          base: BigInt.from(1234567890),
          scale: 6,
          fractionDigits: 5,
        );
      });

      test('Decimal(1234567890) >> 7', () {
        expectDecimal(
          Decimal(1234567890) >> 7,
          '123.456789',
          base: BigInt.from(1234567890),
          scale: 7,
          fractionDigits: 6,
        );
      });

      test('Decimal(1234567890) >> 8', () {
        expectDecimal(
          Decimal(1234567890) >> 8,
          '12.3456789',
          base: BigInt.from(1234567890),
          scale: 8,
          fractionDigits: 7,
        );
      });

      test('Decimal(1234567890) >> 9', () {
        expectDecimal(
          Decimal(1234567890) >> 9,
          '1.23456789',
          base: BigInt.from(1234567890),
          scale: 9,
          fractionDigits: 8,
        );
      });

      test('Decimal(1234567890) >> 10', () {
        expectDecimal(
          Decimal(1234567890) >> 10,
          '0.123456789',
          base: BigInt.from(1234567890),
          scale: 10,
          fractionDigits: 9,
        );
      });

      test('Decimal(1234567890) >> 11', () {
        expectDecimal(
          Decimal(1234567890) >> 11,
          '0.0123456789',
          base: BigInt.from(1234567890),
          scale: 11,
          fractionDigits: 10,
        );
      });

      test('Decimal(1234567890) >> 12', () {
        expectDecimal(
          Decimal(1234567890) >> 12,
          '0.00123456789',
          base: BigInt.from(1234567890),
          scale: 12,
          fractionDigits: 11,
        );
      });

      test('Decimal(1234567890) >> 13', () {
        expectDecimal(
          Decimal(1234567890) >> 13,
          '0.000123456789',
          base: BigInt.from(1234567890),
          scale: 13,
          fractionDigits: 12,
        );
      });
    });
    group('toStringAsFixed', () {
      test('0', () {
        expect(0.0.toStringAsFixed(0), '0');
        expect(Decimal(0).toStringAsFixed(0), '0');

        expect(0.0.toStringAsFixed(1), '0.0');
        expect(Decimal(0).toStringAsFixed(1), '0.0');

        expect(0.0.toStringAsFixed(2), '0.00');
        expect(Decimal(0).toStringAsFixed(2), '0.00');

        final v = Decimal(0, shiftRight: 2);
        expectDecimal(v, '0', base: BigInt.zero, scale: 2, fractionDigits: 0);
        expect(v.toStringAsFixed(0), '0');
        expect(v.toStringAsFixed(1), '0.0');
        expect(v.toStringAsFixed(2), '0.00');
      });

      test('small', () {
        // +n
        var v1 = 3.75;
        var v2 = Decimal.parse('3.75');
        var v3 = Decimal(37500, shiftRight: 4);
        expectDecimal(
          v3,
          '3.75',
          base: BigInt.from(37500),
          scale: 4,
          fractionDigits: 2,
        );

        expect(v1.toStringAsFixed(0), '4');
        expect(v2.toStringAsFixed(0), '4');
        expect(v3.toStringAsFixed(0), '4');

        expect(v1.toStringAsFixed(1), '3.8');
        expect(v2.toStringAsFixed(1), '3.8');
        expect(v3.toStringAsFixed(1), '3.8');

        expect(v1.toStringAsFixed(2), '3.75');
        expect(v2.toStringAsFixed(2), '3.75');
        expect(v3.toStringAsFixed(2), '3.75');

        expect(v1.toStringAsFixed(3), '3.750');
        expect(v2.toStringAsFixed(3), '3.750');
        expect(v3.toStringAsFixed(3), '3.750');

        // -n
        v1 = -3.75;
        v2 = Decimal.parse('-3.75');
        v3 = Decimal(-37500, shiftRight: 4);
        expectDecimal(
          v3,
          '-3.75',
          base: BigInt.from(-37500),
          scale: 4,
          fractionDigits: 2,
        );

        expect(v1.toStringAsFixed(0), '-4');
        expect(v2.toStringAsFixed(0), '-4');
        expect(v3.toStringAsFixed(0), '-4');

        expect(v1.toStringAsFixed(1), '-3.8');
        expect(v2.toStringAsFixed(1), '-3.8');
        expect(v3.toStringAsFixed(1), '-3.8');

        expect(v1.toStringAsFixed(2), '-3.75');
        expect(v2.toStringAsFixed(2), '-3.75');
        expect(v3.toStringAsFixed(2), '-3.75');

        expect(v1.toStringAsFixed(3), '-3.750');
        expect(v2.toStringAsFixed(3), '-3.750');
        expect(v3.toStringAsFixed(3), '-3.750');
      });

      test('big', () {
        // +n
        var v1 = Decimal.parse('12345678901234567890.12345678901234567890');
        var v2 = Decimal.fromBigInt(
          BigInt.parse('12345678901234567890123456789012345678900000000000'),
          shiftRight: 30,
        );
        expectDecimal(
          v2,
          '12345678901234567890.1234567890123456789',
          base: BigInt.parse(
            '12345678901234567890123456789012345678900000000000',
          ),
          scale: 30,
          fractionDigits: 19,
        );

        expect(v1.toStringAsFixed(0), '12345678901234567890');
        expect(v2.toStringAsFixed(0), '12345678901234567890');

        expect(v1.toStringAsFixed(10), '12345678901234567890.1234567890');
        expect(v2.toStringAsFixed(10), '12345678901234567890.1234567890');

        expect(
          v1.toStringAsFixed(20),
          '12345678901234567890.12345678901234567890',
        );
        expect(
          v2.toStringAsFixed(20),
          '12345678901234567890.12345678901234567890',
        );

        expect(
          v1.toStringAsFixed(30),
          '12345678901234567890.123456789012345678900000000000',
        );
        expect(
          v2.toStringAsFixed(30),
          '12345678901234567890.123456789012345678900000000000',
        );

        // -n
        v1 = Decimal.parse('-12345678901234567890.12345678901234567890');
        v2 = Decimal.fromBigInt(
          BigInt.parse('-12345678901234567890123456789012345678900000000000'),
          shiftRight: 30,
        );
        expectDecimal(
          v2,
          '-12345678901234567890.1234567890123456789',
          base: BigInt.parse(
            '-12345678901234567890123456789012345678900000000000',
          ),
          scale: 30,
          fractionDigits: 19,
        );

        expect(v1.toStringAsFixed(0), '-12345678901234567890');
        expect(v2.toStringAsFixed(0), '-12345678901234567890');

        expect(v1.toStringAsFixed(10), '-12345678901234567890.1234567890');
        expect(v2.toStringAsFixed(10), '-12345678901234567890.1234567890');

        expect(
          v1.toStringAsFixed(20),
          '-12345678901234567890.12345678901234567890',
        );
        expect(
          v2.toStringAsFixed(20),
          '-12345678901234567890.12345678901234567890',
        );

        expect(
          v1.toStringAsFixed(30),
          '-12345678901234567890.123456789012345678900000000000',
        );
        expect(
          v2.toStringAsFixed(30),
          '-12345678901234567890.123456789012345678900000000000',
        );
      });
    });

    // `normalized()` fills the internal cache of the canonical form. Nothing
    // observable may change in the receiver: neither the value, nor the stored
    // form, nor the result of a repeated call.
    group('normalized', () {
      for (final source in [
        '0',
        '0.000',
        '1',
        '1.100',
        '-1.100',
        '1000',
        '12345678901234567890.1234567890',
      ]) {
        test(source, () {
          final value = Decimal.parse(source);
          final base = value.base;
          final scale = value.scale;
          final fractionDigits = value.fractionDigits;
          final str = value.toString();

          value.normalized();
          expectDecimal(
            value,
            str,
            base: base,
            scale: scale,
            fractionDigits: fractionDigits,
          );

          value.normalized();
          expectDecimal(
            value,
            str,
            base: base,
            scale: scale,
            fractionDigits: fractionDigits,
          );
        });
      }

      test('со снятой канонической формой равен тому, у кого её не спрашивали',
          () {
        final packed = Decimal(1000) >> 5;
        final asIs = Decimal(1000) >> 5;
        packed.normalized();

        expect(packed == asIs, isTrue);
        expect(packed.hashCode == asIs.hashCode, isTrue);
        expect(packed.compareTo(asIs), 0);
      });
    });

    test('debugToString показывает представление', () {
      expect(
        Decimal.parse('1.50').debugToString(),
        'Decimal(base: 150, scale: 2)',
      );
      expect((Decimal(1) << 3).debugToString(), 'Decimal(base: 1, scale: -3)');
    });

    test('toStringAsFixed при отрицательном масштабе', () {
      expect((Decimal(1) << 3).toStringAsFixed(0), '1000');
      expect((Decimal(1) << 3).toStringAsFixed(2), '1000.00');
      expect((Decimal(-1) << 3).toStringAsFixed(2), '-1000.00');
      expect((Decimal(0) << 3).toStringAsFixed(2), '0.00');
    });

    test('toStringAsFixed не принимает отрицательный аргумент', () {
      expect(
        () => Decimal(1).toStringAsFixed(-1),
        throwsA(isA<ArgumentError>()),
      );
    });

    // Реализованы в волне 4; до неё бросали UnimplementedError. Семантика
    // взята у `double` и сверяется с ним же там, где значение представимо.
    group('toStringAsExponential', () {
      for (final (source, digits) in [
        ('0', 0),
        ('0', 2),
        ('1', 0),
        ('1', 3),
        ('100', 0),
        ('1234.5', 2),
        ('-1234.5', 2),
        ('0.00123', 1),
        ('0.5', 1),
        ('-0.5', 0),
        ('9.99', 1),
        ('99999', 2),
      ]) {
        test('$source с $digits знаками', () {
          expect(
            Decimal.parse(source).toStringAsExponential(digits),
            double.parse(source).toStringAsExponential(digits),
          );
        });
      }

      test('отрицательный аргумент не принимается', () {
        expect(
          () => Decimal.parse('1').toStringAsExponential(-1),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('toStringAsPrecision', () {
      for (final (source, precision, expected) in [
        ('0', 1, '0'),
        ('0', 3, '0.00'),
        ('1', 1, '1'),
        ('1', 3, '1.00'),
        ('1234.5678', 6, '1234.57'),
        ('-1234.5678', 6, '-1234.57'),
        ('0.05', 3, '0.0500'),
        ('123456', 2, '120000'),
        ('9.99', 2, '10'),
        ('0.000000001', 2, '0.0000000010'),
      ]) {
        test('$source с $precision знаками даёт $expected', () {
          expect(
            Decimal.parse(source).toStringAsPrecision(precision),
            expected,
          );
        });
      }

      test('нулевая точность не принимается', () {
        expect(
          () => Decimal.parse('1').toStringAsPrecision(0),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
