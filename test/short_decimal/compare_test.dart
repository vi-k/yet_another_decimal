// ignore_for_file: avoid_js_rounded_ints

/// Сравнение `ShortDecimal` и `clamp`.
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';

void main() {
  group('ShortDecimal', () {
    group('compare', () {
      // Decimal выдерживает шестьдесят нулей, ShortDecimal — восемнадцать:
      // дальше база не помещается в int64.
      test('hashCode for different scales', () {
        final hashCode = ShortDecimal(1).hashCode;
        for (var i = 1; i <= 18; i++) {
          expect(
            hashCode == ShortDecimal.parse('1.${'0' * i}').hashCode,
            isTrue,
            reason: 'нулей после точки: $i',
          );
        }
      });

      test('operator ==', () {
        final v = ShortDecimal(1);
        for (var i = 1; i <= 18; i++) {
          expect(
            v == ShortDecimal.parse('1.${'0' * i}'),
            isTrue,
            reason: 'нулей после точки: $i',
          );
        }
      });

      test('compareTo', () {
        expect(
          ShortDecimal.parse(
            '2.000000000000004',
          ).compareTo(ShortDecimal.parse('2.000000000000009')),
          -1,
        );
        expect(
          ShortDecimal.parse(
            '2.000000000000004',
          ).compareTo(ShortDecimal.parse('2.000000000000001')),
          1,
        );
        expect(
          ShortDecimal.parse(
            '2.000000000000004',
          ).compareTo(ShortDecimal.parse('2.000000000000004')),
          0,
        );

        expect(
          ShortDecimal.parse(
            '-2.000000000000004',
          ).compareTo(ShortDecimal.parse('-2.000000000000009')),
          1,
        );
        expect(
          ShortDecimal.parse(
            '-2.000000000000004',
          ).compareTo(ShortDecimal.parse('-2.000000000000001')),
          -1,
        );
        expect(
          ShortDecimal.parse(
            '-2.000000000000004',
          ).compareTo(ShortDecimal.parse('-2.000000000000004')),
          0,
        );

        expect(
          ShortDecimal(
            1000000000000,
            shiftRight: 9,
          ).compareTo(ShortDecimal(1000)),
          0,
        );
        expect(
          ShortDecimal(
            100000000000,
            shiftRight: 8,
          ).compareTo(ShortDecimal(1000)),
          0,
        );
        expect(
          ShortDecimal(
            10000000000,
            shiftRight: 7,
          ).compareTo(ShortDecimal(1000)),
          0,
        );
        expect(
          ShortDecimal(1000000000, shiftRight: 6).compareTo(ShortDecimal(1000)),
          0,
        );
        expect(
          ShortDecimal(100000000, shiftRight: 5).compareTo(ShortDecimal(1000)),
          0,
        );
        expect(
          ShortDecimal(10000000, shiftRight: 4).compareTo(ShortDecimal(1000)),
          0,
        );
        expect(
          ShortDecimal(1000000, shiftRight: 3).compareTo(ShortDecimal(1000)),
          0,
        );
        expect(
          ShortDecimal(100000, shiftRight: 2).compareTo(ShortDecimal(1000)),
          0,
        );
        expect(
          ShortDecimal(10000, shiftRight: 1).compareTo(ShortDecimal(1000)),
          0,
        );
        expect(ShortDecimal(1000).compareTo(ShortDecimal(1000)), 0);
      });

      test('operators', () {
        final a = ShortDecimal.parse('2.000000000000004');
        final less = ShortDecimal.parse('2.000000000000001');
        final greater = ShortDecimal.parse('2.000000000000009');

        expect(a < a, isFalse);
        expect(a <= a, isTrue);
        expect(a > a, isFalse);
        expect(a >= a, isTrue);

        expect(a < less, isFalse);
        expect(a <= less, isFalse);
        expect(a > less, isTrue);
        expect(a >= less, isTrue);

        expect(a < greater, isTrue);
        expect(a <= greater, isTrue);
        expect(a > greater, isFalse);
        expect(a >= greater, isFalse);
      });
    });

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

    // Д2: домножение при выравнивании переполняется не только при большом
    // разрыве масштабов, но и при большой базе.
    group('сравнение, когда домножение не помещается', () {
      const max = 9223372036854775807;

      test('большая база против малого масштаба', () {
        final big = ShortDecimal(9000000000000000000);
        final small = ShortDecimal(1, shiftRight: 5);

        expect(big.compareTo(small), 1);
        expect(small.compareTo(big), -1);
        expect(big > small, isTrue);
        expect(small < big, isTrue);
        expect(big == small, isFalse);
      });

      test('знак учитывается', () {
        final negative = ShortDecimal(-9000000000000000000);
        final small = ShortDecimal(1, shiftRight: 5);

        expect(negative.compareTo(small), -1);
        expect(small.compareTo(negative), 1);
      });

      test('совпадает с Decimal на тех же значениях', () {
        const bases = [1, -1, max, -max, 9000000000000000000, 5, 0];
        const scales = [0, 1, 5, 18, 19, 25];
        for (final ab in bases) {
          for (final as_ in scales) {
            for (final bb in bases) {
              for (final bs in scales) {
                final why = '$ab e$as_ против $bb e$bs';
                expect(
                  ShortDecimal(
                    ab,
                    shiftRight: as_,
                  ).compareTo(ShortDecimal(bb, shiftRight: bs)),
                  Decimal(
                    ab,
                    shiftRight: as_,
                  ).compareTo(Decimal(bb, shiftRight: bs)),
                  reason: why,
                );
              }
            }
          }
        }
      });
    });
  });
}
