// ignore_for_file: avoid_js_rounded_ints

/// Сравнение `ShortDecimal` и `clamp`.
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';

void main() {
  group('ShortDecimal', () {
    group('clamp', () {
      test('ShortDecimal(5) in [ShortDecimal(3), ShortDecimal(7)]', () {
        expectShortDecimal(
          ShortDecimal(5).clamp(ShortDecimal(3), ShortDecimal(7)),
          '5',
        );
      });

      test('ShortDecimal(3) in [ShortDecimal(3), ShortDecimal(7)]', () {
        expectShortDecimal(
          ShortDecimal(3).clamp(ShortDecimal(3), ShortDecimal(7)),
          '3',
        );
      });

      test('ShortDecimal(1) in [ShortDecimal(3), ShortDecimal(7)]', () {
        expectShortDecimal(
          ShortDecimal(1).clamp(ShortDecimal(3), ShortDecimal(7)),
          '3',
        );
      });

      test('ShortDecimal(7) in [ShortDecimal(3), ShortDecimal(7)]', () {
        expectShortDecimal(
          ShortDecimal(7).clamp(ShortDecimal(3), ShortDecimal(7)),
          '7',
        );
      });

      test('ShortDecimal(9) in [ShortDecimal(3), ShortDecimal(7)]', () {
        expectShortDecimal(
          ShortDecimal(9).clamp(ShortDecimal(3), ShortDecimal(7)),
          '7',
        );
      });

      test('ShortDecimal(-5) in [ShortDecimal(-7), ShortDecimal(-3)]', () {
        expectShortDecimal(
          ShortDecimal(-5).clamp(ShortDecimal(-7), ShortDecimal(-3)),
          '-5',
        );
      });

      test('ShortDecimal(-3) in [ShortDecimal(-7), ShortDecimal(-3)]', () {
        expectShortDecimal(
          ShortDecimal(-3).clamp(ShortDecimal(-7), ShortDecimal(-3)),
          '-3',
        );
      });

      test('ShortDecimal(-1) in [ShortDecimal(-7), ShortDecimal(-3)]', () {
        expectShortDecimal(
          ShortDecimal(-1).clamp(ShortDecimal(-7), ShortDecimal(-3)),
          '-3',
        );
      });

      test('ShortDecimal(-7) in [ShortDecimal(-7), ShortDecimal(-3)]', () {
        expectShortDecimal(
          ShortDecimal(-7).clamp(ShortDecimal(-7), ShortDecimal(-3)),
          '-7',
        );
      });

      test('ShortDecimal(-9) in [ShortDecimal(-7), ShortDecimal(-3)]', () {
        expectShortDecimal(
          ShortDecimal(-9).clamp(ShortDecimal(-7), ShortDecimal(-3)),
          '-7',
        );
      });

      test(
        'ShortDecimal(500) in [ShortDecimal(4) << 2, ShortDecimal(6) << 2]',
        () {
          expectShortDecimal(
            ShortDecimal(500).clamp(ShortDecimal(4) << 2, ShortDecimal(6) << 2),
            '500',
          );
        },
      );

      test('ShortDecimal(5) >> 2 in [0.0400, 0.060000]', () {
        expectShortDecimal(
          (ShortDecimal(5) >> 2).clamp(
            ShortDecimal.parse('0.0400'),
            ShortDecimal.parse('0.060000'),
          ),
          '0.05',
        );
      });

      test('lowerLimit greater than upperLimit', () {
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
  });
}
