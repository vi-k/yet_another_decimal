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
        base: 1,
        scale: -7,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(1000000),
        '11000000',
        base: 11,
        scale: -6,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(100000),
        '11100000',
        base: 111,
        scale: -5,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(10000),
        '11110000',
        base: 1111,
        scale: -4,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(1000),
        '11111000',
        base: 11111,
        scale: -3,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(100),
        '11111100',
        base: 111111,
        scale: -2,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(10),
        '11111110',
        base: 1111111,
        scale: -1,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(1),
        '11111111',
        base: 11111111,
        scale: 0,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 1),
        '11111111.1',
        base: 111111111,
        scale: 1,
        fractionDigits: 1,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 2),
        '11111111.11',
        base: 1111111111,
        scale: 2,
        fractionDigits: 2,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 3),
        '11111111.111',
        base: 11111111111,
        scale: 3,
        fractionDigits: 3,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 4),
        '11111111.1111',
        base: 111111111111,
        scale: 4,
        fractionDigits: 4,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 5),
        '11111111.11111',
        base: 1111111111111,
        scale: 5,
        fractionDigits: 5,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 6),
        '11111111.111111',
        base: 11111111111111,
        scale: 6,
        fractionDigits: 6,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 7),
        '11111111.1111111',
        base: 111111111111111,
        scale: 7,
        fractionDigits: 7,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 8),
        '11111111.11111111',
        base: 1111111111111111,
        scale: 8,
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
      expectShortDecimal(
        value,
        '11111111.11111111',
        base: 1111111111111111,
        scale: 8,
        fractionDigits: 8,
      );
    });
    test('multiply', () {
      expectShortDecimal(
        ShortDecimal(123, shiftRight: 2) * ShortDecimal(456, shiftRight: 1),
        '56.088',
        base: 56088,
        scale: 3,
        fractionDigits: 3,
      );
      expectShortDecimal(
        ShortDecimal(-123, shiftRight: 2) * ShortDecimal(456, shiftRight: 1),
        '-56.088',
        base: -56088,
        scale: 3,
        fractionDigits: 3,
      );
      expectShortDecimal(
        ShortDecimal(123, shiftRight: 2) * ShortDecimal(-456, shiftRight: 1),
        '-56.088',
        base: -56088,
        scale: 3,
        fractionDigits: 3,
      );
      expectShortDecimal(
        ShortDecimal(-123, shiftRight: 2) * ShortDecimal(-456, shiftRight: 1),
        '56.088',
        base: 56088,
        scale: 3,
        fractionDigits: 3,
      );

      // big positive values
      var m = ShortDecimal(123000);
      var value = ShortDecimal.one;
      expectShortDecimal(
        value *= m,
        '123000',
        base: 123,
        scale: -3,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '15129000000',
        base: 15129,
        scale: -6,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '1860867000000000',
        base: 1860867,
        scale: -9,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '228886641000000000000',
        base: 228886641,
        scale: -12,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '28153056843000000000000000',
        base: 28153056843,
        scale: -15,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '3462825991689000000000000000000',
        base: 3462825991689,
        scale: -18,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '425927596977747000000000000000000000',
        base: 425927596977747,
        scale: -21,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '52389094428262881000000000000000000000000',
        base: 52389094428262881,
        scale: -24,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '6443858614676334363000000000000000000000000000',
        base: 6443858614676334363,
        scale: -27,
        fractionDigits: 0,
      );

      // big negative values
      m = ShortDecimal(-123000);
      value = ShortDecimal.one;
      expectShortDecimal(
        value *= m,
        '-123000',
        base: -123,
        scale: -3,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '15129000000',
        base: 15129,
        scale: -6,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '-1860867000000000',
        base: -1860867,
        scale: -9,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '228886641000000000000',
        base: 228886641,
        scale: -12,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '-28153056843000000000000000',
        base: -28153056843,
        scale: -15,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '3462825991689000000000000000000',
        base: 3462825991689,
        scale: -18,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '-425927596977747000000000000000000000',
        base: -425927596977747,
        scale: -21,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '52389094428262881000000000000000000000000',
        base: 52389094428262881,
        scale: -24,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '-6443858614676334363000000000000000000000000000',
        base: -6443858614676334363,
        scale: -27,
        fractionDigits: 0,
      );

      // small positive values
      m = ShortDecimal(123, shiftRight: 4);
      value = ShortDecimal.one;
      expectShortDecimal(
        value *= m,
        '0.0123',
        base: 123,
        scale: 4,
        fractionDigits: 4,
      );
      expectShortDecimal(
        value *= m,
        '0.00015129',
        base: 15129,
        scale: 8,
        fractionDigits: 8,
      );
      expectShortDecimal(
        value *= m,
        '0.000001860867',
        base: 1860867,
        scale: 12,
        fractionDigits: 12,
      );
      expectShortDecimal(
        value *= m,
        '0.0000000228886641',
        base: 228886641,
        scale: 16,
        fractionDigits: 16,
      );
      expectShortDecimal(
        value *= m,
        '0.00000000028153056843',
        base: 28153056843,
        scale: 20,
        fractionDigits: 20,
      );
      expectShortDecimal(
        value *= m,
        '0.000000000003462825991689',
        base: 3462825991689,
        scale: 24,
        fractionDigits: 24,
      );
      expectShortDecimal(
        value *= m,
        '0.0000000000000425927596977747',
        base: 425927596977747,
        scale: 28,
        fractionDigits: 28,
      );
      expectShortDecimal(
        value *= m,
        '0.00000000000000052389094428262881',
        base: 52389094428262881,
        scale: 32,
        fractionDigits: 32,
      );
      expectShortDecimal(
        value *= m,
        '0.000000000000000006443858614676334363',
        base: 6443858614676334363,
        scale: 36,
        fractionDigits: 36,
      );

      // small negative values
      m = ShortDecimal(-123, shiftRight: 4);
      value = ShortDecimal.one;
      expectShortDecimal(
        value *= m,
        '-0.0123',
        base: -123,
        scale: 4,
        fractionDigits: 4,
      );
      expectShortDecimal(
        value *= m,
        '0.00015129',
        base: 15129,
        scale: 8,
        fractionDigits: 8,
      );
      expectShortDecimal(
        value *= m,
        '-0.000001860867',
        base: -1860867,
        scale: 12,
        fractionDigits: 12,
      );
      expectShortDecimal(
        value *= m,
        '0.0000000228886641',
        base: 228886641,
        scale: 16,
        fractionDigits: 16,
      );
      expectShortDecimal(
        value *= m,
        '-0.00000000028153056843',
        base: -28153056843,
        scale: 20,
        fractionDigits: 20,
      );
      expectShortDecimal(
        value *= m,
        '0.000000000003462825991689',
        base: 3462825991689,
        scale: 24,
        fractionDigits: 24,
      );
      expectShortDecimal(
        value *= m,
        '-0.0000000000000425927596977747',
        base: -425927596977747,
        scale: 28,
        fractionDigits: 28,
      );
      expectShortDecimal(
        value *= m,
        '0.00000000000000052389094428262881',
        base: 52389094428262881,
        scale: 32,
        fractionDigits: 32,
      );
      expectShortDecimal(
        value *= m,
        '-0.000000000000000006443858614676334363',
        base: -6443858614676334363,
        scale: 36,
        fractionDigits: 36,
      );
    });
    test('abs', () {
      expectShortDecimal(
        ShortDecimal(2).abs(),
        '2',
        base: 2,
        scale: 0,
        fractionDigits: 0,
      );

      expectShortDecimal(
        ShortDecimal(-2).abs(),
        '2',
        base: 2,
        scale: 0,
        fractionDigits: 0,
      );

      expectShortDecimal(
        ShortDecimal.parse('-1234567890.123456789').abs(),
        '1234567890.123456789',
        base: 1234567890123456789,
        scale: 9,
        fractionDigits: 9,
      );
    });
    test('pow', () {
      expectShortDecimal(
        ShortDecimal(2).pow(4),
        '16',
        base: 16,
        scale: 0,
        fractionDigits: 0,
      );

      expectShortDecimal(
        ShortDecimal(2, shiftRight: 1).pow(4),
        '0.0016',
        base: 16,
        scale: 4,
        fractionDigits: 4,
      );
    });
  });
}
