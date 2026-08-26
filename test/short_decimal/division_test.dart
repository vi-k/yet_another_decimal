// ignore_for_file: avoid_js_rounded_ints

/// `ShortDivision` — деление с остатком на `int`.
///
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';

void main() {
  group('ShortDivision', () {
    test('create', () {
      expect(
        () => ShortDivision(ShortDecimal.zero, ShortDecimal.zero),
        throwsA(
          predicate(
            (error) =>
                error is UnsupportedError &&
                error.message == 'division by zero',
          ),
        ),
      );

      expectShortDivide(ShortDecimal(0), ShortDecimal(7), '0');
      expectShortDivide(ShortDecimal(1), ShortDecimal(7), '0 remainder 1');
      expectShortDivide(ShortDecimal(-1), ShortDecimal(7), '0 remainder -1');
      expectShortDivide(ShortDecimal(1), ShortDecimal(-7), '0 remainder 1');
      expectShortDivide(ShortDecimal(-1), ShortDecimal(-7), '0 remainder -1');

      expectShortDivide(
        ShortDecimal.parse('123.456'),
        ShortDecimal.parse('7.7'),
        '16 remainder 0.256',
      );

      expectShortDivide(
        ShortDecimal.parse('-111111111.111111111'),
        ShortDecimal.parse('1234567.1234567'),
        '-90 remainder -70.000008111',
      );

      expectShortDivide(
        ShortDecimal.parse('1234567890.123456789'),
        ShortDecimal.parse('-333333333.1'),
        '-3 remainder 234567890.823456789',
      );

      expectShortDivide(
        ShortDecimal.parse('12333333324.7'),
        ShortDecimal.parse('-333333333.1'),
        '-37',
      );
    });

    test('равенство', () {
      final division = ShortDivision(ShortDecimal(7), ShortDecimal(2));
      final same = ShortDivision(ShortDecimal(7), ShortDecimal(2));

      expect(division == same, isTrue);
      expect(division.hashCode, same.hashCode);
      expect(division == division, isTrue);
      expect(
        division == ShortDivision(ShortDecimal(9), ShortDecimal(2)),
        isFalse,
      );
      expect(
        division == ShortDivision(ShortDecimal(7), ShortDecimal(3)),
        isFalse,
      );
      expect(division == Object(), isFalse);
      expect({division, same}, hasLength(1));
    });

    test('печать без остатка и с остатком', () {
      expect(ShortDivision(ShortDecimal(6), ShortDecimal(3)).toString(), '2');
      expect(
        ShortDivision(ShortDecimal(7), ShortDecimal(3)).toString(),
        '2 remainder 1',
      );
    });
  });
}
