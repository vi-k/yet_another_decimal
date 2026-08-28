/// `Division` — деление с остатком на `BigInt`.
///
library;

import 'package:denary/denary.dart';
import 'package:test/test.dart';

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

    test('равенство', () {
      final division = Division(Decimal(7), Decimal(2));
      final same = Division(Decimal(7), Decimal(2));

      expect(division == same, isTrue);
      expect(division.hashCode, same.hashCode);
      expect(division == division, isTrue);
      expect(division == Division(Decimal(9), Decimal(2)), isFalse);
      expect(division == Division(Decimal(7), Decimal(3)), isFalse);
      expect(division == Object(), isFalse);
      expect({division, same}, hasLength(1));
    });

    test('печать без остатка и с остатком', () {
      expect(Division(Decimal(6), Decimal(3)).toString(), '2');
      expect(Division(Decimal(7), Decimal(3)).toString(), '2 remainder 1');
    });
  });
}
