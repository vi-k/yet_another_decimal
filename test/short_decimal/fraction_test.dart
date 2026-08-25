// ignore_for_file: avoid_js_rounded_ints

/// `ShortFraction` — рациональная дробь на `int`.
///
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';

void main() {
  group('ShortFraction', () {
    test('create', () {
      expect(
        () => ShortFraction(0, 0),
        throwsA(
          predicate(
            (error) =>
                error is UnsupportedError &&
                error.message == 'division by zero',
          ),
        ),
      );

      expectShortFraction(ShortFraction(123, 123), '1');
      expectShortFraction(ShortFraction(-123, 123), '-1');
      expectShortFraction(ShortFraction(123, -123), '-1');
      expectShortFraction(ShortFraction(-123, -123), '1');

      expectShortFraction(ShortFraction(123, 7), '123/7');
      expectShortFraction(ShortFraction(-123, 7), '-123/7');
      expectShortFraction(ShortFraction(123, -7), '-123/7');
      expectShortFraction(ShortFraction(-123, -7), '123/7');

      expectShortFraction(ShortFraction(123, 1230), '1/10');
      expectShortFraction(ShortFraction(1230, 123), '10');
    });

    test('parse', () {
      expect(
        () => ShortFraction.parse('0/0'),
        throwsA(
          predicate(
            (error) =>
                error is UnsupportedError &&
                error.message == 'division by zero',
          ),
        ),
      );

      expectShortFraction(ShortFraction.parse('123/123'), '1');
      expectShortFraction(ShortFraction.parse('-123/123'), '-1');
      expectShortFraction(ShortFraction.parse('123/-123'), '-1');
      expectShortFraction(ShortFraction.parse('-123/-123'), '1');

      expectShortFraction(ShortFraction.parse('123/7'), '123/7');
      expectShortFraction(ShortFraction.parse('-123/7'), '-123/7');
      expectShortFraction(ShortFraction.parse('123/-7'), '-123/7');
      expectShortFraction(ShortFraction.parse('-123/-7'), '123/7');

      expectShortFraction(ShortFraction.parse('123/1230'), '1/10');
      expectShortFraction(ShortFraction.parse('1230/123'), '10');
    });

    test('to Decimal', () {
      var f = ShortDecimal.parse(
        '1.2',
      ).divideToFraction(ShortDecimal.parse('2.1'));
      expectShortFraction(f, '4/7');

      expectShortDecimal(f.floor(), '0');
      expectShortDecimal(f.floor(1), '0.5');
      expectShortDecimal(f.floor(2), '0.57');

      expectShortDecimal(f.round(), '1');
      expectShortDecimal(f.round(1), '0.6');
      expectShortDecimal(f.round(2), '0.57');

      expectShortDecimal(f.ceil(), '1');
      expectShortDecimal(f.ceil(1), '0.6');
      expectShortDecimal(f.ceil(2), '0.58');

      expectShortDecimal(f.truncate(), '0');
      expectShortDecimal(f.truncate(1), '0.5');
      expectShortDecimal(f.truncate(2), '0.57');

      f = ShortDecimal.parse(
        '-1.2',
      ).divideToFraction(ShortDecimal.parse('2.1'));
      expectShortFraction(f, '-4/7');

      expectShortDecimal(f.floor(), '-1');
      expectShortDecimal(f.floor(1), '-0.6');
      expectShortDecimal(f.floor(2), '-0.58');

      expectShortDecimal(f.round(), '-1');
      expectShortDecimal(f.round(1), '-0.6');
      expectShortDecimal(f.round(2), '-0.57');

      expectShortDecimal(f.ceil(), '0');
      expectShortDecimal(f.ceil(1), '-0.5');
      expectShortDecimal(f.ceil(2), '-0.57');

      expectShortDecimal(f.truncate(), '0');
      expectShortDecimal(f.truncate(1), '-0.5');
      expectShortDecimal(f.truncate(2), '-0.57');
    });
  });
}
