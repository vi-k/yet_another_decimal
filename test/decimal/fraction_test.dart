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
  });
}
