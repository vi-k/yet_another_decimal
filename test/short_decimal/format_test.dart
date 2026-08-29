// ignore_for_file: avoid_js_rounded_ints

/// Вывод `ShortDecimal` строкой.
///
/// Здесь сверка `base` и `scale` уместна: `toString` обязан снимать хвостовые
/// нули, не трогая представление.
library;

import 'package:denary/denary.dart';
import 'package:test/test.dart';

import '../support/expect.dart';

void main() {
  group('ShortDecimal', () {
    group('toString', () {
      test('ShortDecimal(0)', () {
        expectShortDecimal(
          ShortDecimal(0),
          '0',
          base: 0,
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(0) >> 1', () {
        expectShortDecimal(
          ShortDecimal(0) >> 1,
          '0',
          base: 0,
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(0) >> 2', () {
        expectShortDecimal(
          ShortDecimal(0) >> 2,
          '0',
          base: 0,
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(0) >> 3', () {
        expectShortDecimal(
          ShortDecimal(0) >> 3,
          '0',
          base: 0,
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1)', () {
        expectShortDecimal(
          ShortDecimal(1),
          '1',
          base: 1,
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1) >> 1', () {
        expectShortDecimal(
          ShortDecimal(1) >> 1,
          '0.1',
          base: 1,
          scale: 1,
          fractionDigits: 1,
        );
      });

      test('ShortDecimal(1) >> 2', () {
        expectShortDecimal(
          ShortDecimal(1) >> 2,
          '0.01',
          base: 1,
          scale: 2,
          fractionDigits: 2,
        );
      });

      test('ShortDecimal(1) >> 3', () {
        expectShortDecimal(
          ShortDecimal(1) >> 3,
          '0.001',
          base: 1,
          scale: 3,
          fractionDigits: 3,
        );
      });

      test('ShortDecimal(10)', () {
        expectShortDecimal(
          ShortDecimal(10),
          '10',
          base: 1,
          scale: -1,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1) << 1', () {
        expectShortDecimal(
          ShortDecimal(1) << 1,
          '10',
          base: 1,
          scale: -1,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(100)', () {
        expectShortDecimal(
          ShortDecimal(100),
          '100',
          base: 1,
          scale: -2,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1) << 2', () {
        expectShortDecimal(
          ShortDecimal(1) << 2,
          '100',
          base: 1,
          scale: -2,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1000)', () {
        expectShortDecimal(
          ShortDecimal(1000),
          '1000',
          base: 1,
          scale: -3,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1) << 3', () {
        expectShortDecimal(
          ShortDecimal(1) << 3,
          '1000',
          base: 1,
          scale: -3,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1000) >> 1', () {
        expectShortDecimal(
          ShortDecimal(1000) >> 1,
          '100',
          base: 1,
          scale: -2,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1000) >> 2', () {
        expectShortDecimal(
          ShortDecimal(1000) >> 2,
          '10',
          base: 1,
          scale: -1,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1000) >> 3', () {
        expectShortDecimal(
          ShortDecimal(1000) >> 3,
          '1',
          base: 1,
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1000) >> 4', () {
        expectShortDecimal(
          ShortDecimal(1000) >> 4,
          '0.1',
          base: 1,
          scale: 1,
          fractionDigits: 1,
        );
      });

      test('ShortDecimal(1000) >> 5', () {
        expectShortDecimal(
          ShortDecimal(1000) >> 5,
          '0.01',
          base: 1,
          scale: 2,
          fractionDigits: 2,
        );
      });

      test('ShortDecimal(1000) >> 6', () {
        expectShortDecimal(
          ShortDecimal(1000) >> 6,
          '0.001',
          base: 1,
          scale: 3,
          fractionDigits: 3,
        );
      });

      test('ShortDecimal(1234567890)', () {
        expectShortDecimal(
          ShortDecimal(1234567890),
          '1234567890',
          base: 123456789,
          scale: -1,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1234567890) >> 1', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 1,
          '123456789',
          base: 123456789,
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(1234567890) >> 2', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 2,
          '12345678.9',
          base: 123456789,
          scale: 1,
          fractionDigits: 1,
        );
      });

      test('ShortDecimal(1234567890) >> 3', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 3,
          '1234567.89',
          base: 123456789,
          scale: 2,
          fractionDigits: 2,
        );
      });

      test('ShortDecimal(1234567890) >> 4', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 4,
          '123456.789',
          base: 123456789,
          scale: 3,
          fractionDigits: 3,
        );
      });

      test('ShortDecimal(1234567890) >> 5', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 5,
          '12345.6789',
          base: 123456789,
          scale: 4,
          fractionDigits: 4,
        );
      });

      test('ShortDecimal(1234567890) >> 6', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 6,
          '1234.56789',
          base: 123456789,
          scale: 5,
          fractionDigits: 5,
        );
      });

      test('ShortDecimal(1234567890) >> 7', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 7,
          '123.456789',
          base: 123456789,
          scale: 6,
          fractionDigits: 6,
        );
      });

      test('ShortDecimal(1234567890) >> 8', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 8,
          '12.3456789',
          base: 123456789,
          scale: 7,
          fractionDigits: 7,
        );
      });

      test('ShortDecimal(1234567890) >> 9', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 9,
          '1.23456789',
          base: 123456789,
          scale: 8,
          fractionDigits: 8,
        );
      });

      test('ShortDecimal(1234567890) >> 10', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 10,
          '0.123456789',
          base: 123456789,
          scale: 9,
          fractionDigits: 9,
        );
      });

      test('ShortDecimal(1234567890) >> 11', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 11,
          '0.0123456789',
          base: 123456789,
          scale: 10,
          fractionDigits: 10,
        );
      });

      test('ShortDecimal(1234567890) >> 12', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 12,
          '0.00123456789',
          base: 123456789,
          scale: 11,
          fractionDigits: 11,
        );
      });

      test('ShortDecimal(1234567890) >> 13', () {
        expectShortDecimal(
          ShortDecimal(1234567890) >> 13,
          '0.000123456789',
          base: 123456789,
          scale: 12,
          fractionDigits: 12,
        );
      });

      test('ShortDecimal(9223372036854775807)', () {
        expectShortDecimal(
          ShortDecimal(9223372036854775807),
          '9223372036854775807',
          base: 9223372036854775807,
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('ShortDecimal(-9223372036854775808)', () {
        expectShortDecimal(
          ShortDecimal(-9223372036854775808),
          '-9223372036854775808',
          base: -9223372036854775808,
          scale: 0,
          fractionDigits: 0,
        );
      });
    });

    group('toStringAsFixed', () {
      test('0', () {
        expect(0.0.toStringAsFixed(0), '0');
        expect(ShortDecimal(0).toStringAsFixed(0), '0');

        expect(0.0.toStringAsFixed(1), '0.0');
        expect(ShortDecimal(0).toStringAsFixed(1), '0.0');

        expect(0.0.toStringAsFixed(2), '0.00');
        expect(ShortDecimal(0).toStringAsFixed(2), '0.00');

        // В отличие от Decimal, здесь нормализация немедленная: ноль всегда
        // хранится как (0, 0), масштаба у него не остаётся.
        final v = ShortDecimal(0, shiftRight: 2);
        expectShortDecimal(v, '0', base: 0, scale: 0, fractionDigits: 0);
        expect(v.toStringAsFixed(0), '0');
        expect(v.toStringAsFixed(1), '0.0');
        expect(v.toStringAsFixed(2), '0.00');
      });

      test('small', () {
        // +n
        var v1 = 3.75;
        var v2 = ShortDecimal.parse('3.75');
        var v3 = ShortDecimal(37500, shiftRight: 4);
        expectShortDecimal(v3, '3.75', base: 375, scale: 2, fractionDigits: 2);

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
        v2 = ShortDecimal.parse('-3.75');
        v3 = ShortDecimal(-37500, shiftRight: 4);
        expectShortDecimal(
          v3,
          '-3.75',
          base: -375,
          scale: 2,
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
        // Предел здесь — int64, поэтому значение короче, чем у Decimal:
        // база 123456789123456789 — восемнадцать знаков.
        // +n
        var v1 = ShortDecimal.parse('123456789.123456789');
        var v2 = ShortDecimal(1234567891234567890, shiftRight: 10);
        expectShortDecimal(
          v2,
          '123456789.123456789',
          base: 123456789123456789,
          scale: 9,
          fractionDigits: 9,
        );

        expect(v1.toStringAsFixed(0), '123456789');
        expect(v2.toStringAsFixed(0), '123456789');

        expect(v1.toStringAsFixed(5), '123456789.12346');
        expect(v2.toStringAsFixed(5), '123456789.12346');

        expect(v1.toStringAsFixed(9), '123456789.123456789');
        expect(v2.toStringAsFixed(9), '123456789.123456789');

        expect(v1.toStringAsFixed(12), '123456789.123456789000');
        expect(v2.toStringAsFixed(12), '123456789.123456789000');

        // -n
        v1 = ShortDecimal.parse('-123456789.123456789');
        v2 = ShortDecimal(-1234567891234567890, shiftRight: 10);
        expectShortDecimal(
          v2,
          '-123456789.123456789',
          base: -123456789123456789,
          scale: 9,
          fractionDigits: 9,
        );

        expect(v1.toStringAsFixed(0), '-123456789');
        expect(v2.toStringAsFixed(0), '-123456789');

        expect(v1.toStringAsFixed(5), '-123456789.12346');
        expect(v2.toStringAsFixed(5), '-123456789.12346');

        expect(v1.toStringAsFixed(9), '-123456789.123456789');
        expect(v2.toStringAsFixed(9), '-123456789.123456789');

        expect(v1.toStringAsFixed(12), '-123456789.123456789000');
        expect(v2.toStringAsFixed(12), '-123456789.123456789000');
      });
    });

    test('debugToString показывает представление', () {
      expect(
        ShortDecimal.parse('1.5').debugToString(),
        'ShortDecimal(base: 15, scale: 1)',
      );
      expect(
        (ShortDecimal(1) << 3).debugToString(),
        'ShortDecimal(base: 1, scale: -3)',
      );
    });

    test('toStringAsFixed не принимает отрицательный аргумент', () {
      expect(
        () => ShortDecimal(1).toStringAsFixed(-1),
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
            ShortDecimal.parse(source).toStringAsExponential(digits),
            double.parse(source).toStringAsExponential(digits),
          );
        });
      }

      test('отрицательный аргумент не принимается', () {
        expect(
          () => ShortDecimal.parse('1').toStringAsExponential(-1),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('toStringAsEngineering', () {
      for (final (source, digits, expected) in [
        ('0', 0, '0e+0'),
        ('0', 2, '0.00e+0'),
        ('1', 0, '1e+0'),
        ('1', 3, '1.000e+0'),
        ('1000', 0, '1e+3'),
        ('12345', 2, '12.35e+3'),
        ('-12345', 2, '-12.35e+3'),
        ('123456789', 0, '123e+6'),
        ('1e4', 2, '10.00e+3'),
        ('0.5', 2, '500.00e-3'),
        ('-0.5', 0, '-500e-3'),
        ('0.000001', 3, '1.000e-6'),
        ('0.00001234', 1, '12.3e-6'),
        // Перенос при округлении: 999.99 к одному знаку — это тысяча.
        ('999.99', 1, '1.0e+3'),
      ]) {
        test('$source с $digits знаками даёт $expected', () {
          expect(
            ShortDecimal.parse(source).toStringAsEngineering(digits),
            expected,
          );
        });
      }

      test('отрицательный аргумент не принимается', () {
        expect(
          () => ShortDecimal.parse('1').toStringAsEngineering(-1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('у дна показателя кратного трём под ним нет', () {
        const max = 9223372036854775807;

        // Показатель ведущей цифры здесь -(2^63-1), а ближайшее кратное трём
        // снизу — уже за int64.
        expect(
          () => ShortDecimal(1, shiftRight: max).toStringAsEngineering(2),
          throwsArgumentError,
        );
      });

      test('перенос двигает показатель только из своей тройки', () {
        const max = 9223372036854775807;

        // 9.99e+max — это 99.9 при показателе max−1, и округление до 100
        // остаётся при том же показателе: целых цифр у мантиссы до трёх.
        expect(
          (ShortDecimal(999) << (max - 2)).toStringAsEngineering(),
          '100e+9223372036854775806',
        );

        // А 999.9 округляется до 1000 — и вот здесь показателю нужен
        // следующий, которого нет.
        expect(
          (ShortDecimal(9999) << (max - 2)).toStringAsEngineering,
          throwsA(isA<ScaleOutOfRangeError>()),
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
            ShortDecimal.parse(source).toStringAsPrecision(precision),
            expected,
          );
        });
      }

      test('нулевая точность не принимается', () {
        expect(
          () => ShortDecimal.parse('1').toStringAsPrecision(0),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
