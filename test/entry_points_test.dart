/// Каждая точка входа отдаёт своё семейство целиком.
///
/// Импорты здесь — предмет проверки, а не средство: файл не собирается, если
/// узкая точка входа перестала экспортировать хоть один тип семейства.
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/decimal.dart';
import 'package:yet_another_decimal/short_decimal.dart';

void main() {
  group('точки входа', () {
    test('decimal.dart отдаёт семейство на BigInt целиком', () {
      final value = Decimal.parse('19.99');
      expect(value * Decimal(3), Decimal.parse('59.97'));

      final third = Decimal(1).divideToFraction(Decimal(3));
      expect(third, isA<Fraction>());
      expect(third.toString(), '1/3');

      final division = Decimal.parse('7.5').divideWithRemainder(Decimal(2));
      expect(division, isA<Division>());
      expect(division.toString(), '3 remainder 1.5');

      expect(
        () => Decimal(1) / Decimal(3),
        throwsA(isA<DecimalDivideException>()),
      );
    });

    test('short_decimal.dart отдаёт семейство на int целиком', () {
      final value = ShortDecimal.parse('19.99');
      expect(value * ShortDecimal(3), ShortDecimal.parse('59.97'));

      final third = ShortDecimal(1).divideToFraction(ShortDecimal(3));
      expect(third, isA<ShortFraction>());
      expect(third.toString(), '1/3');

      final division = ShortDecimal.parse(
        '7.5',
      ).divideWithRemainder(ShortDecimal(2));
      expect(division, isA<ShortDivision>());
      expect(division.toString(), '3 remainder 1.5');

      expect(
        () => ShortDecimal(1) / ShortDecimal(3),
        throwsA(isA<ShortDecimalDivideException>()),
      );
    });

    test('моста в узких точках входа нет — он про оба семейства', () {
      // Проверяется тем, что этот файл не импортирует общую точку входа:
      // будь `toDecimal()` виден отсюда, строка ниже не понадобилась бы.
      expect(ShortDecimal(1), isNot(isA<Decimal>()));
    });
  });
}
