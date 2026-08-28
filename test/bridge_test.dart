/// Мост между семействами.
///
/// Смысл двух типов — связка «быстрый для операций, большой для накопления»,
/// и до волны 4 перейти между ними можно было только через строку.
library;

import 'package:denary/denary.dart';
import 'package:test/test.dart';

import 'support/expect.dart';

void main() {
  group('ShortDecimal в Decimal', () {
    for (final source in [
      '0',
      '1',
      '-1',
      '1.5',
      '-0.05',
      '1234.5678',
      '100',
      '9223372036854775807',
      '-9223372036854775808',
      '0.000000000000000001',
    ]) {
      test(source, () {
        final short = ShortDecimal.parse(source);
        final wide = short.toDecimal();

        expectDecimal(wide, short.toString());
        expect(wide, Decimal.parse(source));
      });
    }

    test('масштаб сохраняется в обе стороны', () {
      final shifted = ShortDecimal(1) << 5;
      expectDecimal(shifted.toDecimal(), '100000');
      expect(shifted.toDecimal().toShortDecimalOrNull(), shifted);
    });
  });

  group('Decimal в ShortDecimal', () {
    for (final source in ['0', '1', '-1', '1.5', '-0.05', '1234.5678', '100']) {
      test(source, () {
        final wide = Decimal.parse(source);
        final short = wide.toShortDecimalOrNull();

        expect(short, isNotNull, reason: '$source обязано помещаться');
        expectShortDecimal(short!, wide.toString());
        expect(short, ShortDecimal.parse(source));
      });
    }

    test('непредставимое даёт null', () {
      // Не помещается значащая часть — а она и есть ограничение типа.
      expect(
        Decimal.parse('12345678901234567890123').toShortDecimalOrNull(),
        isNull,
      );
      expect(
        Decimal.parse('0.12345678901234567890123').toShortDecimalOrNull(),
        isNull,
      );
    });

    test('круглое большое помещается: значащая часть коротка', () {
      // 10^30 — это база 1 при масштабе -30, и это законное значение типа.
      expectShortDecimal(
        Decimal.parse('1e30').toShortDecimalOrNull()!,
        '1${'0' * 30}',
      );
      // Сырая база сюда не помещается, а упакованная — да.
      expectShortDecimal(
        Decimal.parse('1${'0' * 20}').toShortDecimalOrNull()!,
        '1${'0' * 20}',
      );
    });

    test('граница int64', () {
      expect(
        Decimal.parse('9223372036854775807').toShortDecimalOrNull(),
        ShortDecimal(9223372036854775807),
      );
      expect(
        Decimal.parse('9223372036854775808').toShortDecimalOrNull(),
        isNull,
      );
    });

    test('масштаб за миллионом переходит, а не бросает', () {
      // Мост обещает точность вверх и `null` вниз — ни то, ни другое не может
      // оказаться исключением. Проверка масштаба, поставленная было на сдвиг,
      // ровно этим и обернулась: масштаб больше миллиона получается обычным
      // умножением, а мост внутри сдвигает.
      final wide = Decimal.parse('1e-1000000');
      final wideSquared = wide * wide;
      expect(wideSquared.scale, 2000000);
      expect(wideSquared.toShortDecimalOrNull()?.scale, 2000000);

      final short = ShortDecimal.parse('1e-1000000');
      final shortSquared = short * short;
      expect(shortSquared.scale, 2000000);
      expect(shortSquared.toDecimal().scale, 2000000);
    });

    test('туда и обратно на случайных значениях', () {
      for (var i = -500; i <= 500; i++) {
        final source = '${i / 8}';
        final wide = Decimal.parse(source);
        final short = wide.toShortDecimalOrNull();

        expect(short, isNotNull, reason: source);
        expect(short!.toDecimal(), wide, reason: source);
      }
    });
  });
}
