/// Сравнение `Decimal` и `clamp`.
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';

void main() {
  group('Decimal', () {
    group('compare', () {
      test('hashCode for different scales', () {
        final hashCode = Decimal(1).hashCode;
        for (var i = 1; i <= 60; i++) {
          expect(hashCode == Decimal.parse('1.${'0' * i}').hashCode, isTrue);
        }
      });

      test('operator ==', () {
        final v = Decimal(1);
        for (var i = 1; i <= 60; i++) {
          expect(v == Decimal.parse('1.${'0' * i}'), isTrue);
        }
      });

      test('compareTo', () {
        expect(
          Decimal.parse(
            '2.000000000000000000004',
          ).compareTo(Decimal.parse('2.000000000000000000009')),
          -1,
        );
        expect(
          Decimal.parse(
            '2.000000000000000000004',
          ).compareTo(Decimal.parse('2.000000000000000000001')),
          1,
        );
        expect(
          Decimal.parse(
            '2.000000000000000000004',
          ).compareTo(Decimal.parse('2.000000000000000000004')),
          0,
        );

        expect(
          Decimal.parse(
            '-2.000000000000000000004',
          ).compareTo(Decimal.parse('-2.000000000000000000009')),
          1,
        );
        expect(
          Decimal.parse(
            '-2.000000000000000000004',
          ).compareTo(Decimal.parse('-2.000000000000000000001')),
          -1,
        );
        expect(
          Decimal.parse(
            '-2.000000000000000000004',
          ).compareTo(Decimal.parse('-2.000000000000000000004')),
          0,
        );

        expect(
          Decimal(1000000000000, shiftRight: 9).compareTo(Decimal(1000)),
          0,
        );
        expect(
          Decimal(100000000000, shiftRight: 8).compareTo(Decimal(1000)),
          0,
        );
        expect(Decimal(10000000000, shiftRight: 7).compareTo(Decimal(1000)), 0);
        expect(Decimal(1000000000, shiftRight: 6).compareTo(Decimal(1000)), 0);
        expect(Decimal(100000000, shiftRight: 5).compareTo(Decimal(1000)), 0);
        expect(Decimal(10000000, shiftRight: 4).compareTo(Decimal(1000)), 0);
        expect(Decimal(1000000, shiftRight: 3).compareTo(Decimal(1000)), 0);
        expect(Decimal(100000, shiftRight: 2).compareTo(Decimal(1000)), 0);
        expect(Decimal(10000, shiftRight: 1).compareTo(Decimal(1000)), 0);
        expect(Decimal(1000).compareTo(Decimal(1000)), 0);
      });

      test('operators', () {
        expect(
          Decimal.parse('2.000000000000000000004') <
              Decimal.parse('2.000000000000000000004'),
          isFalse,
        );
        expect(
          Decimal.parse('2.000000000000000000004') <=
              Decimal.parse('2.000000000000000000004'),
          isTrue,
        );
        expect(
          Decimal.parse('2.000000000000000000004') >
              Decimal.parse('2.000000000000000000004'),
          isFalse,
        );
        expect(
          Decimal.parse('2.000000000000000000004') >=
              Decimal.parse('2.000000000000000000004'),
          isTrue,
        );

        expect(
          Decimal.parse('2.000000000000000000004') <
              Decimal.parse('2.000000000000000000001'),
          isFalse,
        );
        expect(
          Decimal.parse('2.000000000000000000004') <=
              Decimal.parse('2.000000000000000000001'),
          isFalse,
        );
        expect(
          Decimal.parse('2.000000000000000000004') >
              Decimal.parse('2.000000000000000000001'),
          isTrue,
        );
        expect(
          Decimal.parse('2.000000000000000000004') >=
              Decimal.parse('2.000000000000000000001'),
          isTrue,
        );

        expect(
          Decimal.parse('2.000000000000000000004') <
              Decimal.parse('2.000000000000000000009'),
          isTrue,
        );
        expect(
          Decimal.parse('2.000000000000000000004') <=
              Decimal.parse('2.000000000000000000009'),
          isTrue,
        );
        expect(
          Decimal.parse('2.000000000000000000004') >
              Decimal.parse('2.000000000000000000009'),
          isFalse,
        );
        expect(
          Decimal.parse('2.000000000000000000004') >=
              Decimal.parse('2.000000000000000000009'),
          isFalse,
        );
      });
    });
    test('clamp', () {
      for (final p in [
        (Decimal(5), Decimal(3), Decimal(7), '5'),
        (Decimal(3), Decimal(3), Decimal(7), '3'),
        (Decimal(1), Decimal(3), Decimal(7), '3'),
        (Decimal(7), Decimal(3), Decimal(7), '7'),
        (Decimal(9), Decimal(3), Decimal(7), '7'),
        (Decimal(-5), Decimal(-7), Decimal(-3), '-5'),
        (Decimal(-3), Decimal(-7), Decimal(-3), '-3'),
        (Decimal(-1), Decimal(-7), Decimal(-3), '-3'),
        (Decimal(-7), Decimal(-7), Decimal(-3), '-7'),
        (Decimal(-9), Decimal(-7), Decimal(-3), '-7'),
        (Decimal(500), Decimal(4) << 2, Decimal(6) << 2, '500'),
        (
          Decimal(5) >> 2,
          Decimal.parse('0.0400'),
          Decimal.parse('0.060000'),
          '0.05',
        ),
      ]) {
        expectDecimal(p.$1.clamp(p.$2, p.$3), p.$4);
      }

      expect(
        () => Decimal(0).clamp(Decimal(2), Decimal(1)),
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
