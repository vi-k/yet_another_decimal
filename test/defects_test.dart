// ignore_for_file: avoid_js_rounded_ints

/// Воспроизводители дефектов, найденных ревью 2026-08-25.
///
/// Разбор каждого — в `docs/records/2026-08-25[3]-package-review.md`,
/// нумерация совпадает.
///
/// Каждый тест написан с **корректным** ожиданием и помечен `skip` с номером
/// дефекта. Правка дефекта заканчивается снятием `skip`: это и есть критерий
/// готовности. Красных тестов в `main` при этом не появляется.
library;

import 'package:denary/denary.dart';
import 'package:test/test.dart';

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
  // Д16–Д19 найдены 2026-08-28 обзором «глазами пользователя»: разбор — в
  // docs/records/2026-08-28[8]. Все четыре — расхождение кода с собственным
  // dartdoc, а не с чьим-то ожиданием.

  group('Д16 divideToFraction усекает вместо броска', () {
    test(
      'непредставимая в int64 дробь даёт ArgumentError',
      () {
        const max = 9223372036854775807;
        final value = ShortDecimal(max, shiftLeft: 1);

        expect(
          () => value.divideToFraction(ShortDecimal.one),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });

  group('Д17 ShortFraction.floor и ceil теряют направление', () {
    // 4/7 = 0.571428…, двадцать знаков в int64 не помещаются.
    test(
      'floor не поднимается выше самой дроби',
      () {
        final result = ShortFraction(4, 7).floor(20);

        expect(result.toDecimal() * Decimal(7), lessThan(Decimal(4)));
      },
    );

    test(
      'ceil не опускается ниже самой дроби',
      () {
        final result = ShortFraction(4, 7).ceil(20);

        expect(result.toDecimal() * Decimal(7), greaterThan(Decimal(4)));
      },
    );

    test(
      'floor и ceil одной дроби не совпадают',
      () {
        final fraction = ShortFraction(4, 7);

        expect(fraction.floor(20), isNot(fraction.ceil(20)));
      },
    );
  });

  group('Д18 ShortFraction.toDouble округляет дважды', () {
    test(
      'ответ тот же, что у точного пути Fraction',
      () {
        const n = 9007199254740993;

        expect(
          ShortFraction(n, 7).toDouble(),
          Fraction(BigInt.from(n), BigInt.from(7)).toDouble(),
        );
      },
    );
  });

  group('Д19 масштаб переполняется в делении', () {
    // `(Decimal.one >> max) >> 1` бросает ArgumentError с тем же сообщением:
    // деление обязано отвечать так же, а не отдавать масштаб, ушедший в минус.
    // Значение уже каноническое: снимать нечего, и разрыв масштабов настоящий.
    // Сотня с тем же сдвигом сюда не годится — у неё два нуля снимаются, и
    // деление у канонической формы получается (это Д24).
    test(
      'деление отвечает так же, как сдвиг: броском',
      () {
        const max = 9223372036854775807;
        final value = Decimal(1, shiftRight: max);

        expect(
          () => value.divideOrNull(Decimal.one << 1),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    // У `ShortDecimal` представление каноническое сразу, поэтому за край
    // масштаб уводит единица, а не сотня: у сотни два нуля уже сняты.
    test('второе семейство отвечает так же', () {
      const max = 9223372036854775807;
      final value = ShortDecimal(1, shiftRight: max);

      expect(
        () => value.divideOrNull(ShortDecimal.one << 1),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

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

  // Д20–Д37 найдены 2026-08-28 двумя независимыми ревью кода: разбор — в
  // docs/records/2026-08-28[9]. Часть из них ждёт решений владельца и потому
  // остаётся под `skip` — это помечено в тексте каждого.

  group('Д23 быстрый путь divide мимо проверки масштаба', () {
    test(
      'divide с числом знаков отвечает так же, как соседние формы',
      () {
        const max = 9223372036854775807;
        final a = (Decimal(7) << max) << 1;
        final b = Decimal(3) >> max;

        // `a / b`, `divideOrNull` и `divide` без числа знаков уже бросают.
        expect(
          () => a.divide(b, scaleOnInfinitePrecision: 2),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });

  group('Д24 проверка масштаба смотрит на сырую форму', () {
    test(
      'равные значения делятся одинаково',
      () {
        const max = 9223372036854775807;
        final raw = Decimal(100, shiftRight: max);
        final canonical = raw.normalized();
        final ten = Decimal.one << 1;

        expect(raw == canonical, isTrue);

        // Печатать такое нельзя — строка вышла бы длиной в масштаб, — поэтому
        // сверяется хранимая пара.
        expect(
          raw.divideOrNull(ten)!.debugToString(),
          canonical.divideOrNull(ten)!.debugToString(),
        );
      },
    );
  });

  group('Д26 сложение теряет представимый канонический результат', () {
    test(
      'сумма считается, когда каноническая форма помещается',
      () {
        const max = 9223372036854775807;

        // 9223372036854775810 = 922337203685477581 × 10, и это в int64
        // влезает — тот же довод, по которому чинили умножение (Д13).
        expect(
          (ShortDecimal(max) + ShortDecimal(3)).toString(),
          '9223372036854775810',
        );
      },
    );

    test(
      'и вычитание тоже',
      () {
        const max = 9223372036854775807;

        expect(
          (ShortDecimal(max) - ShortDecimal(-3)).toString(),
          '9223372036854775810',
        );
      },
    );
  });

  // Д27 ждёт решения владельца, поэтому остаётся под `skip`. Спор здесь не с
  // кодом, а с политикой: `test/short_decimal/divide_test.dart` прямо
  // закрепляет, что на непредставимом частном переполнение остаётся
  // молчаливым. Ниже записано, чего ждёт от `divideOrNull` его собственный
  // dartdoc — «null, когда конечной десятичной формы нет»; перевёрнутый знак
  // не форма и не переполнение значения, а выдуманное число.
  group('Д27 непредставимое частное возвращается с чужим знаком', () {
    test(
      'divideOrNull не выдумывает значение',
      () {
        const twoTo62 = 4611686018427387904;
        final result = ShortDecimal(1).divideOrNull(ShortDecimal(twoTo62));

        // Точное частное положительно и в int64 не помещается: ответа нет.
        expect(result, isNull);
      },
    );

    test(
      'isDivisibleBy не обещает того, чего нет',
      () {
        const twoTo62 = 4611686018427387904;

        expect(ShortDecimal(1).isDivisibleBy(ShortDecimal(twoTo62)), isFalse);
      },
    );
  });

  group('Д29 сброс цифр округляет дважды', () {
    test(
      'round отдаёт ближайшее представимое, а не округлённое дважды',
      () {
        final short = ShortFraction(9000000013530038636, 41);
        final wide =
            Fraction(BigInt.from(9000000013530038636), BigInt.from(41));

        // Точное значение — …161.85365…, и на одном знаке ближайшее к нему
        // …161.9, а не …161.8, которое получается из …161.85.
        expect(short.round(2).toString(), wide.round(1).toString());
      },
    );

    test(
      'roundToEven тоже',
      () {
        final short = ShortFraction(52, 55);
        final wide = Fraction(BigInt.from(52), BigInt.from(55));

        expect(
          short.roundToEven(19).toString(),
          wide.roundToEven(18).toString(),
        );
      },
    );

    test(
      'и деление с числом знаков',
      () {
        final short = ShortDecimal(9000000174082531245)
            .divide(ShortDecimal(173), scaleOnInfinitePrecision: 4);
        final wide = Decimal(9000000174082531245)
            .divide(Decimal(173), scaleOnInfinitePrecision: 2);

        expect(short.toString(), wide.toString());
      },
    );
  });

  group('Д32 исключение деления нельзя напечатать', () {
    test(
      'toString исключения не бросает',
      () {
        const min = -9223372036854775808;

        try {
          final _ = ShortDecimal(1) / ShortDecimal(min);
          fail('деление обязано бросить');
        } on ShortDecimalDivideException catch (e) {
          expect(e.toString(), isNotEmpty);
        }
      },
    );

    // У старшего семейства ломается не дробь, а степень десятки: разрыв
    // масштабов здесь больше миллиона, и построить её нельзя.
    test('то же у старшего семейства', () {
      final tiny = Decimal.one >> 999999;
      final huge = Decimal(3) << 999999;

      try {
        final _ = tiny / huge;
        fail('деление обязано бросить');
      } on DecimalDivideException catch (e) {
        expect(e.toString(), contains('cannot be represented'));
      }
    });
  });

  group('Д25 равные значения возводятся одинаково', () {
    test('десятка в отрицательной степени не зависит от формы хранения', () {
      // Одно и то же значение: 10 × 10^0 и 1 × 10^-1.
      final raw = Decimal.ten;
      final packed = Decimal.parse('1e1');

      expect(raw == packed, isTrue);
      expect(
        raw.pow(-1000001).debugToString(),
        packed.pow(-1000001).debugToString(),
      );
    });
  });

  group('Д33 inverse бросает то, что обещает', () {
    test('минимальное целое даёт UnsupportedError', () {
      const min = -9223372036854775808;

      expect(
        () => ShortDecimal(min).inverse,
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('Д36 знак нуля в divideToDouble', () {
    test('ноль на отрицательное даёт минус ноль в обеих семьях', () {
      final short = ShortDecimal(0).divideToDouble(ShortDecimal(-5));

      expect(short.isNegative, isTrue);
      expect(Decimal(0).divideToDouble(Decimal(-5)).isNegative, isTrue);

      // Как обычное деление в Dart, и как было у быстрого пути короткой семьи.
      expect(Decimal(0).divideToDouble(Decimal(-5)), 0 / -5);
    });

    test('ноль на положительное остаётся плюс нулём', () {
      final short = ShortDecimal(0).divideToDouble(ShortDecimal(5));

      expect(short.isNegative, isFalse);
      expect(Decimal(0).divideToDouble(Decimal(5)).isNegative, isFalse);
    });
  });

  group('Д20 канонизация не меняет значение', () {
    test('снятие нулей не уводит масштаб за край', () {
      const max = 9223372036854775807;
      final value = (Decimal(10) << max) << 1;

      // Значение построено законно, но канонической формы у него нет: масштаб
      // и так на самом дне, а снятие нуля просит ещё один шаг вниз.
      expect(value.normalized, throwsArgumentError);
    });

    test('то же в короткой семье, прямо в конструкторе', () {
      const max = 9223372036854775807;

      expect(
        () => ShortDecimal(100, shiftLeft: max),
        throwsArgumentError,
      );
    });
  });

  group('Д21 у самого дна масштаба нет показателя', () {
    test('exponent отказывается, а не переполняется', () {
      const max = 9223372036854775807;
      final value = ShortDecimal(10, shiftLeft: max);

      expect(value.scale, -9223372036854775808);
      expect(() => value.exponent, throwsArgumentError);
    });
  });

  group('Д22 факторизация делителя не заворачивает масштаб', () {
    test('обе семьи отвечают null', () {
      const max = 9223372036854775807;

      expect((Decimal.one >> max).divideOrNull(Decimal.two), isNull);
      expect((ShortDecimal.one >> max).divideOrNull(ShortDecimal.two), isNull);
    });

    test('делитель из пятёрок тоже', () {
      const max = 9223372036854775807;

      expect((Decimal.one >> max).divideOrNull(Decimal(5)), isNull);
      expect((ShortDecimal.one >> max).divideOrNull(ShortDecimal(5)), isNull);
    });

    test('делитель, кратный десяти, тоже', () {
      const max = 9223372036854775807;

      expect((Decimal.one >> max).divideOrNull(Decimal(10)), isNull);
    });
  });

  group('Д28 toInt клампит, как весь Dart', () {
    test('за границей int64 отвечает краем диапазона', () {
      expect(ShortDecimal.parse('1e19').toInt(), 9223372036854775807);
      expect(ShortDecimal.parse('-1e19').toInt(), -9223372036854775808);

      // Старшее семейство и целочисленное деление отвечали так и раньше.
      expect(Decimal.parse('1e19').toInt(), 9223372036854775807);
      expect(
        ShortDecimal.parse('1e19') ~/ ShortDecimal.one,
        9223372036854775807,
      );
    });

    test('ноль и обычные значения не задеты', () {
      expect(ShortDecimal.zero.toInt(), 0);
      expect(ShortDecimal.parse('-19.99').toInt(), -19);
      expect(ShortDecimal.parse('1e18').toInt(), 1000000000000000000);
    });
  });

  group('Д30 parse держит один предел на оба написания', () {
    test('дробных знаков не больше, чем позволяет показатель', () {
      expect(Decimal.tryParse('0.${'0' * 1000000}1'), isNull);
      expect(ShortDecimal.tryParse('0.${'0' * 1000000}1'), isNull);
    });

    test('на самой границе читается', () {
      expect(Decimal.parse('1e-1000000').scale, 1000000);
      expect(Decimal.parse('0.${'0' * 999999}1').scale, 1000000);
    });
  });
}
