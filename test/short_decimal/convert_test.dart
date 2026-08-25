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
        base: 1234567890123456789,
        scale: 9,
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
    test('isInteger', () {
      for (final p in [
        (ShortDecimal(0), isTrue),
        (ShortDecimal(0) >> 10, isTrue),
        (ShortDecimal(2), isTrue),
        (ShortDecimal(2) >> 1, isFalse),
        (ShortDecimal(-2), isTrue),
        (ShortDecimal(-2) >> 1, isFalse),
        (ShortDecimal(1111111111111111110), isTrue),
        (ShortDecimal(1111111111111111110) >> 1, isTrue),
        (ShortDecimal(1111111111111111110) >> 2, isFalse),
        (ShortDecimal(-1111111111111111110), isTrue),
        (ShortDecimal(-1111111111111111110) >> 1, isTrue),
        (ShortDecimal(-1111111111111111110) >> 2, isFalse),
      ]) {
        expect(p.$1.isInteger, p.$2);
      }
    });
  });
}
