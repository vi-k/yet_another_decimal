// ignore_for_file: avoid_js_rounded_ints

/// Сравнение `ShortDecimal` и `clamp`.
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';

void main() {
  group('ShortDecimal', () {
    test('clamp', () {
      for (final p in [
        (ShortDecimal(5), ShortDecimal(3), ShortDecimal(7), '5'),
        (ShortDecimal(3), ShortDecimal(3), ShortDecimal(7), '3'),
        (ShortDecimal(1), ShortDecimal(3), ShortDecimal(7), '3'),
        (ShortDecimal(7), ShortDecimal(3), ShortDecimal(7), '7'),
        (ShortDecimal(9), ShortDecimal(3), ShortDecimal(7), '7'),
        (ShortDecimal(-5), ShortDecimal(-7), ShortDecimal(-3), '-5'),
        (ShortDecimal(-3), ShortDecimal(-7), ShortDecimal(-3), '-3'),
        (ShortDecimal(-1), ShortDecimal(-7), ShortDecimal(-3), '-3'),
        (ShortDecimal(-7), ShortDecimal(-7), ShortDecimal(-3), '-7'),
        (ShortDecimal(-9), ShortDecimal(-7), ShortDecimal(-3), '-7'),
        (ShortDecimal(500), ShortDecimal(4) << 2, ShortDecimal(6) << 2, '500'),
        (
          ShortDecimal(5) >> 2,
          ShortDecimal.parse('0.0400'),
          ShortDecimal.parse('0.060000'),
          '0.05',
        ),
      ]) {
        expectShortDecimal(p.$1.clamp(p.$2, p.$3), p.$4);
      }

      expect(
        () => ShortDecimal(0).clamp(ShortDecimal(2), ShortDecimal(1)),
        throwsA(
          predicate(
            (error) =>
                error is ArgumentError &&
                error.message ==
                    'The lowerLimit must be no greater than upperLimit',
          ),
        ),
      );
    });
  });
}
