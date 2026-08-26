/// Воспроизводители дефектов, найденных ревью 2026-08-25.
///
/// Разбор каждого — в `docs/records/2026-08-25[3]-package-review.md`,
/// нумерация совпадает.
///
/// Каждый тест написан с **корректным** ожиданием и помечен `skip` с номером
/// дефекта. Правка дефекта заканчивается снятием `skip`: это и есть критерий
/// готовности. Красных тестов в `main` при этом не появляется.
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

void main() {
  group('Д1 деление на отрицательное', () {
    test('Decimal', () {
      expect((Decimal(1) / Decimal(-2)).toString(), '-0.5');
      expect((Decimal(6) / Decimal(-3)).toString(), '-2');
      expect((Decimal(-6) / Decimal(-4)).toString(), '1.5');
      expect((Decimal(5) / Decimal(-1)).toString(), '-5');
      expect((Decimal(0) / Decimal(-5)).toString(), '0');
    });

    test('ShortDecimal', () {
      expect((ShortDecimal(1) / ShortDecimal(-2)).toString(), '-0.5');
      expect((ShortDecimal(6) / ShortDecimal(-3)).toString(), '-2');
      expect((ShortDecimal(-6) / ShortDecimal(-4)).toString(), '1.5');
    });

    test('знак делителя не влияет на представимость', () {
      for (final divisor in [2, 4, 5, 8, 10, 16, 20, 25]) {
        final positive = Decimal(1) / Decimal(divisor);
        final negative = Decimal(1) / Decimal(-divisor);
        expect(negative.toString(), '-$positive');
      }
    });
  });

  group('Д2 _pow10 переполняется', () {
    test('сравнение при разрыве масштабов 19', () {
      final dust = ShortDecimal.parse('0.000000000000000001');
      final limit = ShortDecimal.parse('10');
      expect(dust < limit, isTrue);
      expect(dust.compareTo(limit), -1);
    });

    test('сортировка остаётся сортировкой', () {
      final list = [
        ShortDecimal(2),
        ShortDecimal(1, shiftRight: 20),
        ShortDecimal(1),
      ]..sort();
      expect(list.map((e) => e.toString()).toList(), [
        '0.00000000000000000001',
        '1',
        '2',
      ]);
    });

    test('округление почти-нуля даёт ноль', () {
      final tiny = ShortDecimal.parse('0.0000000000000000001');
      expect(tiny.round().toString(), '0');
      expect(tiny.toStringAsFixed(0), '0');
    });

    test('toInt для значения меньше единицы', () {
      final value = ShortDecimal(9223372036854775807) >> 40;
      expect(value.toInt(), 0);
      expect(value > ShortDecimal.one, isFalse);
    });
  });

  group('Д3 деление на ноль', () {
    test('Decimal бросает, а не зависает', () {
      expect(() => Decimal(1) / Decimal(0), throwsA(isA<Object>()));
    });

    test('ShortDecimal бросает, а не зависает', () {
      expect(() => ShortDecimal(1) / ShortDecimal(0), throwsA(isA<Object>()));
    });
  });

  group('Д4 toBigInt при отрицательном масштабе', () {
    test('сдвиг влево', () {
      expect((Decimal(1) << 3).toBigInt(), BigInt.from(1000));
    });

    test('результат деления на дробь', () {
      final value = Decimal.parse('1') / Decimal.parse('0.001');
      expect(value.toString(), '1000');
      expect(value.toBigInt(), BigInt.from(1000));
    });

    test('согласовано с ShortDecimal.toInt', () {
      expect(
        (Decimal(1) << 3).toBigInt().toInt(),
        (ShortDecimal(1) << 3).toInt(),
      );
    });
  });

  group('Д5 toStringAsFixed добивает нулями', () {
    test('Decimal', () {
      expect(Decimal.parse('0.5').toStringAsFixed(3), '0.500');
      expect(Decimal.parse('-0.5').toStringAsFixed(3), '-0.500');
      expect(Decimal.parse('0.05').toStringAsFixed(5), '0.05000');
    });

    test('ShortDecimal', () {
      expect(ShortDecimal.parse('0.5').toStringAsFixed(3), '0.500');
      expect(ShortDecimal.parse('0.1').toStringAsFixed(2), '0.10');
    });

    test('семейства согласованы на нуле', () {
      expect(
        Decimal.parse('0.0').toStringAsFixed(2),
        ShortDecimal.parse('0.0').toStringAsFixed(2),
      );
    });
  });

  group('Д6 divideWithRemainder при отрицательном масштабе', () {
    test('Decimal', () {
      final division = Division(Decimal(1) << 2, Decimal(3) << 1);
      expect(division.toString(), '3 remainder 10');
    });

    test('ShortDecimal через parse', () {
      final division = ShortDecimal.parse(
        '400',
      ).divideWithRemainder(ShortDecimal.parse('30'));
      expect(division.toString(), '13 remainder 10');
    });

    test('печать исключения не бросает и содержит остаток', () {
      try {
        final unused = ShortDecimal(100) / ShortDecimal(30);
        fail('ожидалось ShortDecimalDivideException, получено $unused');
      } on ShortDecimalDivideException catch (e) {
        expect(e.toString(), contains('remainder'));
      }
    });
  });

  group('Д7 ShortDecimal.ten нормализована', () {
    test('хеш согласован с равенством', () {
      expect(ShortDecimal.ten == ShortDecimal(10), isTrue);
      expect(ShortDecimal.ten.hashCode, ShortDecimal(10).hashCode);
    });

    test('множество не двоится', () {
      expect({ShortDecimal.ten, ShortDecimal(10)}, hasLength(1));
      expect(<ShortDecimal, int>{ShortDecimal(10): 1}[ShortDecimal.ten], 1);
    });

    test('производные значения тоже каноничны', () {
      expect((ShortDecimal.ten << 1).hashCode, ShortDecimal(100).hashCode);
      expect((-ShortDecimal.ten).hashCode, ShortDecimal(-10).hashCode);
    });
  });

  group('Д8 divideToDouble на высокой точности', () {
    test('не NaN и не ноль', () {
      final a = Decimal.parse('0.${'1234567890' * 32}');
      final b = Decimal.parse('0.${'2345678901' * 32}');
      final result = a.divideToDouble(b);
      expect(result.isNaN, isFalse);
      expect(result, greaterThan(0.0));
      expect(result, closeTo(0.526, 0.01));
    });
  });

  group('Д9 Fraction и отрицательный fractionDigits', () {
    test('ведёт себя как Decimal', () {
      expect(Decimal.parse('123.4').floor(-1).toString(), '120');
      final fraction = Fraction(BigInt.from(1234), BigInt.from(10));
      expect(fraction.floor(-1).toString(), '120');
    });
  });

  group('Д10 tryParse не принимает шестнадцатеричное', () {
    test('Decimal', () {
      expect(Decimal.tryParse('0x10'), isNull);
      expect(Decimal.tryParse('0X1F'), isNull);
      expect(Decimal.tryParse('0x1.8'), isNull);
      expect(Decimal.tryParse('-0x10'), isNull);
    });

    test('ShortDecimal', () {
      expect(ShortDecimal.tryParse('0x10'), isNull);
      expect(ShortDecimal.tryParse('0X1F'), isNull);
    });
  });

  group('Д11 ShortFraction и округление к 19+ знакам', () {
    test('результат совпадает с Fraction', () {
      final short = ShortFraction(4, 7);
      final wide = Fraction(BigInt.from(4), BigInt.from(7));
      expect(short.round(19).toString(), wide.round(19).toString());
    });

    test('положительная дробь не даёт отрицательный результат', () {
      expect(ShortFraction(4, 7).round(20).isNegative, isFalse);
    });
  });

  group('Д12 ShortDecimal.tryParse', () {
    test('"+0" разбирается как "+1"', () {
      expect(ShortDecimal.tryParse('+1').toString(), '1');
      expect(ShortDecimal.tryParse('+0').toString(), '0');
      expect(ShortDecimal.tryParse('+0.0').toString(), '0');
    });

    test('голый знак — не число', () {
      expect(ShortDecimal.tryParse('-'), isNull);
      expect(ShortDecimal.tryParse('  -  '), isNull);
    });

    test('пробельные символы внутри числа — не число', () {
      expect(ShortDecimal.tryParse('1\t0'), isNull);
      expect(ShortDecimal.tryParse('1.5\t0'), isNull);
    });
  });

  group('Д13 ShortDecimal * до нормализации', () {
    test('канонический результат помещается — значит считается', () {
      final result = ShortDecimal(4611686018427387904) * ShortDecimal(5);
      expect(result.toString(), '23058430092136939520');
    });
  });

  group('Д14 ShortFraction перемножает после сокращения', () {
    test('перекрёстные множители сокращаются', () {
      const max = 9223372036854775807;
      final result = ShortFraction(max, 2) * ShortFraction(2, max - 2);
      expect(result.toString(), '$max/${max - 2}');
    });

    test('округление почти-единицы даёт единицу', () {
      const max = 9223372036854775807;
      expect(ShortFraction(max, max - 2).round(1).toString(), '1');
    });
  });

  // Оба ожидания переписаны в волне 2. Первое было невыполнимо: точное
  // значение 1/-2^63 требует знаменателя 2^63, который в int64 не помещается,
  // а сокращать нечего. Второе противоречило Д9, который требует от дробей
  // поддержки отрицательного fractionDigits. Обоснование —
  // docs/records/2026-08-26[1]-wave-2-defects-plan.md.
  group('Д15 ShortFraction: знак и проверка аргумента', () {
    test('знаменатель всегда положителен', () {
      final fraction = ShortFraction(2, -9223372036854775808);
      expect(fraction.denominator, greaterThan(0));
      expect(fraction.toString(), '-1/4611686018427387904');
    });

    test('неприводимая дробь даёт ArgumentError', () {
      expect(
        () => ShortFraction(1, -9223372036854775808),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('отрицательный fractionDigits работает как у Fraction', () {
      expect(ShortFraction(1234, 10).floor(-1).toString(), '120');
      expect(
        ShortFraction(1234, 10).floor(-1).toString(),
        Fraction(BigInt.from(1234), BigInt.from(10)).floor(-1).toString(),
      );
    });
  });
}
