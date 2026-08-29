/// Типизированные отказы: те же ошибки, что и раньше, но с именем.
///
/// Оба класса — наследники `ArgumentError`, и это часть их контракта: код,
/// который ловил `ArgumentError` или читал у него `name`, `invalidValue` и
/// `message`, продолжает работать. Тип добавлен для тех, кому нужно отличить
/// один отказ от другого, не разбирая текст.
library;

import 'package:denary/denary.dart';
import 'package:test/test.dart';

void main() {
  group('ScaleOutOfRangeError', () {
    const max = 9223372036854775807;

    test('сдвиг за край масштаба, обе семьи', () {
      expect(
        () => (Decimal.one >> max) >> 1,
        throwsA(isA<ScaleOutOfRangeError>()),
      );
      expect(
        () => (ShortDecimal.one >> max) >> 1,
        throwsA(isA<ScaleOutOfRangeError>()),
      );
    });

    test('остаётся ArgumentError со всеми его полями', () {
      expect(
        () => (Decimal.one >> max) >> 1,
        throwsA(
          isA<ScaleOutOfRangeError>()
              .having((e) => e.name, 'name', 'shiftAmount')
              .having((e) => e.invalidValue, 'invalidValue', 1)
              .having(
                (e) => e.message,
                'message',
                'The scale would leave int64',
              )
              .having(
                (e) => e.toString(),
                'toString',
                contains('The scale would leave int64'),
              ),
        ),
      );
    });

    test('ловится и как ArgumentError', () {
      expect(() => (ShortDecimal.one >> max) >> 1, throwsArgumentError);
    });

    test('у показателя на дне масштаба тот же тип', () {
      final value = ShortDecimal(10, shiftLeft: max);

      expect(() => value.exponent, throwsA(isA<ScaleOutOfRangeError>()));
    });
  });

  group('DecimalDigitsOutOfRangeError', () {
    const huge = 1000000000;

    test('число знаков за миллионом, обе семьи', () {
      expect(
        () => Decimal.one.round(-huge),
        throwsA(isA<DecimalDigitsOutOfRangeError>()),
      );
      expect(
        () => ShortDecimal.one.toStringAsFixed(huge),
        throwsA(isA<DecimalDigitsOutOfRangeError>()),
      );
      expect(
        () => Fraction(BigInt.one, BigInt.from(3)).truncate(huge),
        throwsA(isA<DecimalDigitsOutOfRangeError>()),
      );
      expect(
        () => ShortFraction(1, 3).round(-huge),
        throwsA(isA<DecimalDigitsOutOfRangeError>()),
      );
    });

    test('остаётся ArgumentError со всеми его полями', () {
      expect(
        () => Decimal.one.round(-huge),
        throwsA(
          isA<DecimalDigitsOutOfRangeError>()
              .having((e) => e, 'сам по себе', isA<ArgumentError>())
              .having((e) => e.name, 'name', 'fractionDigits')
              .having((e) => e.invalidValue, 'invalidValue', -huge)
              .having(
                (e) => e.message,
                'message',
                'The number of digits must be within a million of zero',
              ),
        ),
      );
    });

    test('степень десятки, которую не построить, — тот же тип', () {
      // Показатель приходит не от вызывающего, а из разрыва масштабов, и
      // сообщение у него своё.
      const max = 9223372036854775807;
      final wide = Decimal(1) >> max;

      expect(
        () => wide + Decimal.one,
        throwsA(
          isA<DecimalDigitsOutOfRangeError>().having(
            (e) => e.message,
            'message',
            'Ten to this power is a number too large to build',
          ),
        ),
      );
    });
  });
}
