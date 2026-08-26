/// `Fraction` — рациональная дробь на `BigInt`.
///
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';

void main() {
  group('Fraction', () {
    test('create', () {
      expect(
        () => Fraction(BigInt.zero, BigInt.zero),
        throwsA(
          predicate(
            (error) =>
                error is UnsupportedError &&
                error.message == 'division by zero',
          ),
        ),
      );

      expectFraction(Fraction(BigInt.from(123), BigInt.from(123)), '1');
      expectFraction(Fraction(BigInt.from(-123), BigInt.from(123)), '-1');
      expectFraction(Fraction(BigInt.from(123), BigInt.from(-123)), '-1');
      expectFraction(Fraction(BigInt.from(-123), BigInt.from(-123)), '1');

      expectFraction(Fraction(BigInt.from(123), BigInt.from(7)), '123/7');
      expectFraction(Fraction(BigInt.from(-123), BigInt.from(7)), '-123/7');
      expectFraction(Fraction(BigInt.from(123), BigInt.from(-7)), '-123/7');
      expectFraction(Fraction(BigInt.from(-123), BigInt.from(-7)), '123/7');

      expectFraction(Fraction(BigInt.from(123), BigInt.from(1230)), '1/10');
      expectFraction(Fraction(BigInt.from(1230), BigInt.from(123)), '10');
    });

    test('parse', () {
      expect(
        () => Fraction.parse('0/0'),
        throwsA(
          predicate(
            (error) =>
                error is UnsupportedError &&
                error.message == 'division by zero',
          ),
        ),
      );

      expectFraction(Fraction.parse('123/123'), '1');
      expectFraction(Fraction.parse('-123/123'), '-1');
      expectFraction(Fraction.parse('123/-123'), '-1');
      expectFraction(Fraction.parse('-123/-123'), '1');

      expectFraction(Fraction.parse('123/7'), '123/7');
      expectFraction(Fraction.parse('-123/7'), '-123/7');
      expectFraction(Fraction.parse('123/-7'), '-123/7');
      expectFraction(Fraction.parse('-123/-7'), '123/7');

      expectFraction(Fraction.parse('123/1230'), '1/10');
      expectFraction(Fraction.parse('1230/123'), '10');
    });

    test('to Decimal', () {
      var f = Decimal.parse('1.2').divideToFraction(Decimal.parse('2.1'));
      expectFraction(f, '4/7');

      expectDecimal(f.floor(), '0');
      expectDecimal(f.floor(1), '0.5');
      expectDecimal(f.floor(2), '0.57');

      expectDecimal(f.round(), '1');
      expectDecimal(f.round(1), '0.6');
      expectDecimal(f.round(2), '0.57');

      expectDecimal(f.ceil(), '1');
      expectDecimal(f.ceil(1), '0.6');
      expectDecimal(f.ceil(2), '0.58');

      expectDecimal(f.truncate(), '0');
      expectDecimal(f.truncate(1), '0.5');
      expectDecimal(f.truncate(2), '0.57');

      f = Decimal.parse('-1.2').divideToFraction(Decimal.parse('2.1'));
      expectFraction(f, '-4/7');

      expectDecimal(f.floor(), '-1');
      expectDecimal(f.floor(1), '-0.6');
      expectDecimal(f.floor(2), '-0.58');

      expectDecimal(f.round(), '-1');
      expectDecimal(f.round(1), '-0.6');
      expectDecimal(f.round(2), '-0.57');

      expectDecimal(f.ceil(), '0');
      expectDecimal(f.ceil(1), '-0.5');
      expectDecimal(f.ceil(2), '-0.57');

      expectDecimal(f.truncate(), '0');
      expectDecimal(f.truncate(1), '-0.5');
      expectDecimal(f.truncate(2), '-0.57');
    });

    test('parse без дробной черты', () {
      expectFraction(Fraction.parse('123'), '123');
      expectFraction(Fraction.parse('-123'), '-123');
    });

    group('операторы', () {
      test('умножение сокращает', () {
        expectFraction(
          Fraction(BigInt.one, BigInt.two) *
              Fraction(BigInt.two, BigInt.from(3)),
          '1/3',
        );
        expectFraction(
          Fraction(-BigInt.one, BigInt.two) *
              Fraction(BigInt.two, BigInt.from(3)),
          '-1/3',
        );
        expectFraction(
          Fraction(BigInt.from(4), BigInt.from(7)) *
              Fraction(BigInt.from(7), BigInt.from(4)),
          '1',
        );
      });

      test('деление', () {
        expectFraction(
          Fraction(BigInt.one, BigInt.two) /
              Fraction(BigInt.from(3), BigInt.from(4)),
          '2/3',
        );
        expectFraction(
          Fraction(BigInt.one, BigInt.two) / Fraction(-BigInt.one, BigInt.two),
          '-1',
        );
      });

      test('сложение приводит к общему знаменателю', () {
        expectFraction(
          Fraction(BigInt.one, BigInt.two) +
              Fraction(BigInt.one, BigInt.from(3)),
          '5/6',
        );
        expectFraction(
          Fraction(BigInt.one, BigInt.two) + Fraction(BigInt.one, BigInt.two),
          '1',
        );
      });

      test('вычитание', () {
        expectFraction(
          Fraction(BigInt.one, BigInt.two) -
              Fraction(BigInt.one, BigInt.from(3)),
          '1/6',
        );
        expectFraction(
          Fraction(BigInt.one, BigInt.two) - Fraction(BigInt.one, BigInt.two),
          '0',
        );
      });
    });

    test('знак', () {
      expect(Fraction(-BigInt.one, BigInt.two).isNegative, isTrue);
      expect(Fraction(BigInt.one, BigInt.two).isNegative, isFalse);
      expect(Fraction(BigInt.zero, BigInt.two).isNegative, isFalse);

      expect(Fraction(-BigInt.one, BigInt.two).sign, -1);
      expect(Fraction(BigInt.one, BigInt.two).sign, 1);
      expect(Fraction(BigInt.zero, BigInt.two).sign, 0);
    });

    test('равенство', () {
      final half = Fraction(BigInt.one, BigInt.two);

      expect(half == Fraction(BigInt.two, BigInt.from(4)), isTrue);
      expect(half.hashCode, Fraction(BigInt.two, BigInt.from(4)).hashCode);
      expect(half == half, isTrue);
      expect(half == Fraction(BigInt.one, BigInt.from(3)), isFalse);
      expect(half == Object(), isFalse);
      expect({half, Fraction(BigInt.two, BigInt.from(4))}, hasLength(1));
    });

    test('в Decimal', () {
      expectDecimal(Fraction(BigInt.from(3), BigInt.two).toDecimal(), '1.5');
      expectDecimal(Fraction(BigInt.from(10), BigInt.two).toDecimal(), '5');
    });

    // Д9: отрицательный fractionDigits — округление до десятков и выше, как
    // это умеет Decimal.
    group('отрицательный fractionDigits', () {
      final fraction = Fraction(BigInt.from(1234), BigInt.from(10));

      test('floor', () {
        expectDecimal(fraction.floor(-1), '120');
        expectDecimal(fraction.floor(-2), '100');
        expectDecimal(fraction.floor(-3), '0');
      });

      test('ceil', () {
        expectDecimal(fraction.ceil(-1), '130');
        expectDecimal(fraction.ceil(-2), '200');
      });

      test('round', () {
        expectDecimal(fraction.round(-1), '120');
        expectDecimal(fraction.round(-2), '100');
      });

      test('truncate', () {
        expectDecimal(fraction.truncate(-1), '120');
        expectDecimal(fraction.truncate(-2), '100');
      });

      test('совпадает с Decimal на том же значении', () {
        final value = Decimal.parse('123.4');
        for (final digits in [-3, -2, -1, 0, 1]) {
          expect(
            fraction.floor(digits).toString(),
            value.floor(digits).toString(),
            reason: 'floor($digits)',
          );
          expect(
            fraction.ceil(digits).toString(),
            value.ceil(digits).toString(),
            reason: 'ceil($digits)',
          );
          expect(
            fraction.round(digits).toString(),
            value.round(digits).toString(),
            reason: 'round($digits)',
          );
          expect(
            fraction.truncate(digits).toString(),
            value.truncate(digits).toString(),
            reason: 'truncate($digits)',
          );
        }
      });
    });

    test('модуль', () {
      expectFraction(Fraction(BigInt.from(-1), BigInt.two).abs(), '1/2');
      expectFraction(Fraction(BigInt.one, BigInt.two).abs(), '1/2');
      expectFraction(Fraction(BigInt.zero, BigInt.two).abs(), '0');
    });

    test('обратная дробь', () {
      expectFraction(Fraction(BigInt.one, BigInt.two).inverse, '2');
      expectFraction(Fraction(BigInt.from(-3), BigInt.from(4)).inverse, '-4/3');
      expect(
        () => Fraction(BigInt.zero, BigInt.two).inverse,
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('сравнение', () {
      final half = Fraction(BigInt.one, BigInt.two);
      final third = Fraction(BigInt.one, BigInt.from(3));

      expect(half.compareTo(third), 1);
      expect(third.compareTo(half), -1);
      expect(half.compareTo(Fraction(BigInt.two, BigInt.from(4))), 0);
      final minusThird = Fraction(BigInt.from(-1), BigInt.from(3));
      final minusHalf = Fraction(BigInt.from(-1), BigInt.two);
      expect(half.compareTo(minusThird), 1);
      expect(minusHalf.compareTo(third), -1);

      final sorted = [half, minusThird, third]..sort();
      expect(sorted.map((e) => '$e').toList(), ['-1/3', '1/3', '1/2']);
    });

    test('в double', () {
      expect(Fraction(BigInt.one, BigInt.two).toDouble(), 0.5);
      expect(Fraction(BigInt.one, BigInt.from(3)).toDouble(), 1 / 3);
      expect(Fraction(BigInt.from(-1), BigInt.from(3)).toDouble(), -1 / 3);
      expect(Fraction(BigInt.zero, BigInt.two).toDouble(), 0.0);
    });
  });
}
