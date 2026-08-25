/// `Division` — деление с остатком на `BigInt`.
///
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';

void main() {
  group('Division', () {
    test('create', () {
      expect(
        () => Division(Decimal.zero, Decimal.zero),
        throwsA(
          predicate(
            (error) =>
                error is UnsupportedError &&
                error.message == 'division by zero',
          ),
        ),
      );

      expectDivide(Decimal(0), Decimal(7), '0');
      expectDivide(Decimal(1), Decimal(7), '0 remainder 1');
      expectDivide(Decimal(-1), Decimal(7), '0 remainder -1');
      expectDivide(Decimal(1), Decimal(-7), '0 remainder 1');
      expectDivide(Decimal(-1), Decimal(-7), '0 remainder -1');

      expectDivide(
        Decimal.parse('123.456'),
        Decimal.parse('7.7'),
        '16 remainder 0.256',
      );

      expectDivide(
        Decimal.parse('-1111111111.1111111111'),
        Decimal.parse('1234567.1234567'),
        '-900 remainder -700.0000811111',
      );

      expectDivide(
        Decimal.parse('12345678901234567890.1234567890'),
        Decimal.parse('-333333333333333333.1'),
        '-37 remainder 12345567901234565.423456789',
      );

      expectDivide(
        Decimal.parse('12345678901234567890.1234567890') -
            Decimal.parse('12345567901234565.423456789'),
        Decimal.parse('-333333333333333333.1'),
        '-37',
      );

      expectDivide(
        Decimal.parse('-12345678901234567890.1234567890'),
        Decimal.parse('333333333333333333.1'),
        '-37 remainder -12345567901234565.423456789',
      );

      expectDivide(
        Decimal.parse('-12345678901234567890.1234567890') -
            Decimal.parse('-12345567901234565.423456789'),
        Decimal.parse('333333333333333333.1'),
        '-37',
      );
    });
  });
}
