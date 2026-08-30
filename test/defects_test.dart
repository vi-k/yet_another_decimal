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
  // docs/records/2026-08-28[9], решения владельца по политике — там же.
  // Хвост (Д34, Д37, Д35) разобран в docs/records/2026-08-29[2].

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

  // Спор здесь был не с кодом, а с политикой: перевёрнутый знак — не форма и
  // не переполнение значения, а выдуманное число. Владелец решил 2026-08-29 в
  // пользу того, что обещает dartdoc `divideOrNull`: «null, когда конечной
  // десятичной формы нет».
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

  group('Д34 деление дробей отвергает представимый результат', () {
    const twoTo62 = 4611686018427387904;

    test('знак делителя выносится до произведений', () {
      // 2 / (-1/2^62) = -2^63, и это ровно int.min. Числитель по дороге
      // заворачивался в int.min при знаменателе -1, а такой паре знака
      // положить некуда.
      expect(
        (ShortFraction(2, 1) / ShortFraction(-1, twoTo62)).toString(),
        '-9223372036854775808',
      );
    });

    test('и когда у ответа есть знаменатель', () {
      expect(
        (ShortFraction(2, 3) / ShortFraction(-1, twoTo62)).toString(),
        '-9223372036854775808/3',
      );
    });

    test('непредставимый ответ по-прежнему отвергается', () {
      const min = -9223372036854775808;

      // 1 / int.min: знаменателю 2^63 положительным не быть.
      expect(
        () => ShortFraction(1, 1) / ShortFraction(min, 1),
        throwsArgumentError,
      );
    });
  });

  group('Д37 отрицательная степень строится не на завёрнутой степени', () {
    const answer = '0.000000000000000000001073741824';

    test('представимая обратная степень считается', () {
      // 5^30 из int64 вышла, а 2^30 × 10^-30 в нём есть с запасом.
      expect(ShortDecimal(5).pow(-30).toString(), answer);
      expect(Decimal(5).pow(-30).toString(), answer);
    });

    test('то же значение другими основаниями', () {
      expect(ShortDecimal(25).pow(-15).toString(), answer);
      expect(ShortDecimal(125).pow(-10).toString(), answer);
    });

    test('минимальное целое не жалуется на деление на ноль', () {
      const min = -9223372036854775808;

      // Куб основания завернулся ровно в ноль, но основание не ноль, и
      // конечной обратной величины у него нет.
      expect(() => ShortDecimal(min).pow(-3), throwsUnsupportedError);
    });

    test('без конечной обратной величины — отказ, а не чужая пара', () {
      // Исключение деления несёт в себе пару, на которой его подняли, и
      // ответить от неё нельзя: делитель здесь — сама степень, а она в int64
      // не влезла. Разбор — Д38.
      expect(() => ShortDecimal(3).pow(-40), throwsUnsupportedError);
    });

    test('ответ вне int64 — отказ, а не выдуманное число', () {
      expect(() => ShortDecimal(2).pow(-63), throwsUnsupportedError);
      expect(() => ShortDecimal(2).pow(-70), throwsUnsupportedError);
    });

    test('ноль в отрицательной степени по-прежнему делит на ноль', () {
      expect(() => ShortDecimal.zero.pow(-1), throwsUnsupportedError);
      expect(() => Decimal.zero.pow(-1), throwsUnsupportedError);
    });
  });

  group('Д35 экспоненциальная запись не строит степень десятки', () {
    const max = 9223372036854775807;

    test('самое маленькое число, которое читается', () {
      expect(
        Decimal.parse('1e-1000000').toStringAsExponential(2),
        '1.00e-1000000',
      );
      expect(
        ShortDecimal.parse('1e-1000000').toStringAsExponential(2),
        '1.00e-1000000',
      );
    });

    test('и у самого края масштаба', () {
      expect(
        ShortDecimal(1, shiftRight: max).toStringAsExponential(2),
        '1.00e-9223372036854775807',
      );
      expect(
        Decimal(1, shiftRight: max).toStringAsExponential(2),
        '1.00e-9223372036854775807',
      );
      expect(
        (ShortDecimal.one << max).toStringAsExponential(2),
        '1.00e+9223372036854775807',
      );
      expect(
        (Decimal.one << max).toStringAsExponential(2),
        '1.00e+9223372036854775807',
      );
    });

    test('перенос при округлении остаётся верным', () {
      expect(Decimal.parse('9.99').toStringAsExponential(1), '1.0e+1');
      expect(ShortDecimal.parse('0.0999').toStringAsExponential(1), '1.0e-1');
    });

    test('у самого дна масштаба показателя нет', () {
      final short = ShortDecimal(10, shiftLeft: max);
      final long = (Decimal(10) << max) << 1;

      expect(short.scale, -9223372036854775808);
      expect(() => short.toStringAsExponential(2), throwsArgumentError);
      expect(() => long.toStringAsExponential(2), throwsArgumentError);
      expect(() => short.toStringAsPrecision(3), throwsArgumentError);
      expect(() => long.toStringAsPrecision(3), throwsArgumentError);
    });

    test('у потолка показателя переносу некуда идти', () {
      // Показатель уже на самом верху int64, а девятки округляются вверх:
      // ответу нужен порядок на единицу больше, и его нет.
      const nearMax = 9223372036854775806;
      final short = ShortDecimal(99) << nearMax;
      final long = Decimal(99) << nearMax;

      expect(short.toStringAsExponential, throwsArgumentError);
      expect(long.toStringAsExponential, throwsArgumentError);
      expect(() => short.toStringAsPrecision(1), throwsArgumentError);
      expect(() => long.toStringAsPrecision(1), throwsArgumentError);
    });

    test('слишком большому числу отказывают тем же именем', () {
      // Позиционная запись такого числа длиннее миллиона знаков.
      for (final call in <String Function()>[
        () => (ShortDecimal.one << 1000003).toStringAsPrecision(3),
        () => (Decimal.one << 1000003).toStringAsPrecision(3),
      ]) {
        expect(
          call,
          throwsA(
            isA<ArgumentError>().having((e) => e.name, 'name', 'precision'),
          ),
        );
      }
    });

    test('toStringAsPrecision называет аргумент, который ему передали', () {
      for (final call in <String Function()>[
        () => Decimal.parse('1e-1000000').toStringAsPrecision(3),
        () => ShortDecimal.parse('1e-1000000').toStringAsPrecision(3),
        () => ShortDecimal(1, shiftRight: max).toStringAsPrecision(3),
      ]) {
        expect(
          call,
          throwsA(
            isA<ArgumentError>()
                .having((e) => e.name, 'name', 'precision')
                .having((e) => e.invalidValue, 'invalidValue', 3),
          ),
        );
      }
    });
  });

  // Д38–Д42 нашло ревью сегодняшних правок (Fable-агент, 2026-08-29): разбор —
  // в docs/records/2026-08-29[9].

  group('Д38 отказ pow не выдумывает чужое деление', () {
    test('восстановление после отказа не даёт чисел другого деления', () {
      // Старшая семья на том же вопросе отвечает нулём: 3^-40 ≈ 8e-20.
      expect(
        () {
          try {
            return Decimal(3).pow(-40);
          } on DecimalDivideException catch (e) {
            return e.round(2);
          }
        }(),
        Decimal.zero,
      );

      // Короткой ответить нечем — и она не отвечает вместо этого числами
      // деления единицы на основание (было 0.33).
      expect(() => ShortDecimal(3).pow(-40), throwsUnsupportedError);
      expect(() => ShortDecimal(-3).pow(-40), throwsUnsupportedError);
      expect(
        () => ShortDecimal(-9223372036854775808).pow(-2),
        throwsUnsupportedError,
      );
    });
  });

  group('Д39 последняя влезающая степень не отвергается', () {
    test('(-2)^63 — это int.min, и он представим', () {
      const min = -9223372036854775808;

      expect(ShortDecimal.parse('-0.5').pow(-63).toString(), '$min');
      expect(Decimal.parse('-0.5').pow(-63).toString(), '$min');

      // Та же степень с другой стороны: положительная ветвь её и раньше
      // считала.
      expect(ShortDecimal(-2).pow(63).toString(), '$min');
    });

    test('и с масштабом тоже', () {
      expect(
        ShortDecimal(-5).pow(-63).toString(),
        Decimal(-5).pow(-63).toString(),
      );
    });

    test('а 2^63 по-прежнему не влезает', () {
      expect(() => ShortDecimal.parse('0.5').pow(-63), throwsUnsupportedError);
    });
  });

  group('Д40 степень основания без цикла длиной в показатель', () {
    test('единица и десятка отвечают сразу, а не за миллион шагов', () {
      final stopwatch = Stopwatch()..start();

      expect(ShortDecimal.one.pow(-1000000).toString(), '1');
      expect(ShortDecimal(-1).pow(-1000001).toString(), '-1');
      expect(ShortDecimal.zero.pow(1000000).toString(), '0');
      expect(ShortDecimal(10).pow(-1000000).scale, 1000000);

      // Порог с большим запасом: цикл длиной в миллион шагов занимал сотни
      // миллисекунд, а на показателе в int64 не кончался бы вовсе.
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });

  group('Д41 перенос в инженерной записи не всегда двигает показатель', () {
    const max = 9223372036854775807;

    test('99.9 округляется до 100 при том же показателе', () {
      expect(
        (ShortDecimal(999) << (max - 2)).toStringAsEngineering(),
        '100e+9223372036854775806',
      );
      expect(
        (Decimal(999) << (max - 2)).toStringAsEngineering(),
        '100e+9223372036854775806',
      );
    });

    test('а 999.9 округляется до 1000, и вот там показателю некуда', () {
      expect(
        (ShortDecimal(9999) << (max - 2)).toStringAsEngineering,
        throwsA(isA<ScaleOutOfRangeError>()),
      );
      expect(
        (Decimal(9999) << (max - 2)).toStringAsEngineering,
        throwsA(isA<ScaleOutOfRangeError>()),
      );
    });
  });

  group('Д43 разность масштаба и числа знаков не заворачивается', () {
    const max = 9223372036854775807;

    test('старшая семья отказывает по своей же границе', () {
      final value = Decimal(1, shiftRight: max);

      // Степень десятки, которая тут нужна, за миллионом — и за int64 тоже:
      // раньше отсюда вылетал RangeError по таблице степеней.
      for (final call in <Decimal Function()>[
        () => value.round(-1),
        () => value.floor(-1),
        () => value.ceil(-1),
        () => value.truncate(-1),
        () => value.roundToEven(-1),
        () => value.roundAwayFromZero(-1),
      ]) {
        expect(call, throwsA(isA<DecimalDigitsOutOfRangeError>()));
      }
    });

    test('короткая семья отвечает, у неё делителя и так нет', () {
      final value = ShortDecimal(1, shiftRight: max);

      // Всё число стоит правее запрошенной позиции — дальше решает правило.
      expect(value.round(-1).toString(), '0');
      expect(value.floor(-1).toString(), '0');
      expect(value.truncate(-1).toString(), '0');
      expect(value.roundToEven(-1).toString(), '0');
      expect(value.ceil(-1).toString(), '10');
      expect(value.roundAwayFromZero(-1).toString(), '10');
    });
  });

  group('Д44 исключение деления отвечает и без дроби', () {
    const min = -9223372036854775808;

    test('пара 1/int.min округляется всеми шестью правилами', () {
      try {
        final impossible = ShortDecimal.one / ShortDecimal(min);
        fail('ожидалось исключение, получено $impossible');
      } on ShortDecimalDivideException catch (e) {
        // Дроби у этой пары нет: знаменателю 2^63 негде быть положительным.
        expect(() => e.fraction, throwsArgumentError);

        // А округлённые ответы есть, и они обычные числа.
        expect(e.round().toString(), '0');
        expect(e.floor().toString(), '-1');
        expect(e.ceil().toString(), '0');
        expect(e.truncate().toString(), '0');
        expect(e.roundToEven().toString(), '0');
        expect(e.roundAwayFromZero().toString(), '-1');
        expect(e.round(18).toString(), '0');
        expect(e.roundAwayFromZero(18).toString(), '-0.000000000000000001');
      }
    });

    test('обычная пара отвечает как прежде', () {
      expect(
        () => ShortDecimal(1) / ShortDecimal(3),
        throwsA(
          isA<ShortDecimalDivideException>()
              .having((e) => e.round(4).toString(), 'round(4)', '0.3333')
              .having((e) => e.floor(4).toString(), 'floor(4)', '0.3333')
              .having((e) => e.fraction.toString(), 'fraction', '1/3'),
        ),
      );
    });

    test('число знаков за миллионом отвергается и здесь', () {
      try {
        final impossible = ShortDecimal(1) / ShortDecimal(3);
        fail('ожидалось исключение, получено $impossible');
      } on ShortDecimalDivideException catch (e) {
        expect(
          () => e.round(-1000000000),
          throwsA(isA<DecimalDigitsOutOfRangeError>()),
        );
      }
    });
  });

  group('Д45 граница toStringAsPrecision описана тем, что проверяет', () {
    test('целых цифр числа граница не касается', () {
      // Позиционная запись длиннее миллиона символов допустима — столько же
      // отдаёт и toString. Ограничены знаки после точки.
      expect(
        (Decimal.one << 1999999).toStringAsPrecision(1000000).length,
        2000000,
      );
      expect(
        (ShortDecimal.one << 1999999).toStringAsPrecision(1000000).length,
        2000000,
      );
    });

    test('а знаки после точки — касается, и отказ типизирован', () {
      for (final call in <String Function()>[
        () => Decimal.parse('1e-1000000').toStringAsPrecision(3),
        () => ShortDecimal.parse('1e-1000000').toStringAsPrecision(3),
      ]) {
        expect(
          call,
          throwsA(
            isA<DecimalDigitsOutOfRangeError>()
                .having((e) => e.name, 'name', 'precision')
                .having(
                  (e) => e.message,
                  'message',
                  'The number would need more than a million digits'
                      ' after the point',
                ),
          ),
        );
      }
    });
  });

  group('Д46 отказ pow не разворачивает получателя в строку', () {
    test('масштаб, на котором позиционная запись не помещается в память', () {
      // Отказ строится из base и scale. Раньше он интерполировал само число,
      // и его позиционная запись просила 2,2·10^17 байт: вызывающий, который
      // исключение ловит и не печатает, получал OutOfMemoryError вместо
      // обещанного UnsupportedError.
      expect(
        () => ShortDecimal(3, shiftRight: 224944935700986765).pow(-41),
        throwsUnsupportedError,
      );

      // Тот же приём в inverse — второе место, где отказ называл получателя.
      expect(
        () => ShortDecimal(3, shiftRight: 224944935700986765).inverse,
        throwsUnsupportedError,
      );
    });

    test('и сообщение остаётся коротким на любом масштабе', () {
      for (final call in <void Function()>[
        () => ShortDecimal(3, shiftRight: 2000000).pow(-41),
        () => ShortDecimal(3, shiftRight: 2000000).inverse,
      ]) {
        expect(
          call,
          throwsA(
            isA<UnsupportedError>().having(
              (e) => e.message?.length ?? 0,
              'message length',
              lessThan(100),
            ),
          ),
        );
      }
    });

    test('получатель в сообщении назван парой', () {
      expect(
        () => ShortDecimal(3, shiftRight: 100).pow(-41),
        throwsA(
          isA<UnsupportedError>().having(
            (e) => e.message,
            'message',
            'The result of 3 at scale 100 to the power of -41 has no'
                ' $ShortDecimal form',
          ),
        ),
      );
    });
  });

  group('Д47 обе стороны границы toStringAsPrecision названы своим', () {
    test('граница проходит по позиции округления, а не по числу', () {
      // Ограничена позиция, считаемая от точки: при precision 1 она равна
      // показателю ведущей цифры. Миллион — последняя допустимая.
      expect(
        (Decimal.one << 1000000).toStringAsPrecision(1).length,
        1000001,
      );
      expect(
        (ShortDecimal.one << 1000000).toStringAsPrecision(1).length,
        1000001,
      );
    });

    test('отказ слева от точки говорит про то, что проверяет', () {
      // Знаков после точки у этого числа нет вовсе, и прежний текст про них
      // был неправдой; ограничена позиция округления.
      for (final call in <String Function()>[
        () => (Decimal.one << 1000001).toStringAsPrecision(1),
        () => (ShortDecimal.one << 1000001).toStringAsPrecision(1),
      ]) {
        expect(
          call,
          throwsA(
            isA<DecimalDigitsOutOfRangeError>()
                .having((e) => e.name, 'name', 'precision')
                .having(
                  (e) => e.message,
                  'message',
                  'The number would be rounded more than a million digits'
                      ' before the point',
                ),
          ),
        );
      }
    });

    test('справа от точки текст прежний', () {
      for (final call in <String Function()>[
        () => Decimal.parse('1e-1000000').toStringAsPrecision(3),
        () => ShortDecimal.parse('1e-1000000').toStringAsPrecision(3),
      ]) {
        expect(
          call,
          throwsA(
            isA<DecimalDigitsOutOfRangeError>().having(
              (e) => e.message,
              'message',
              'The number would need more than a million digits'
                  ' after the point',
            ),
          ),
        );
      }
    });
  });
  group('Д48 округление к большому числу знаков не идёт по одной цифре', () {
    test('миллион знаков считается, а не крутит миллион делений', () {
      final stopwatch = Stopwatch()..start();

      // Ответ всегда умещается в девятнадцать цифр: масштаб спускается до
      // представимого. Спуск по одной цифре делал это миллион раз, каждый раз
      // заново деля число в миллион цифр.
      expect(ShortFraction(1, 3).round(1000000).toString().length, 21);
      expect(
        ShortDecimal.one
            .divide(ShortDecimal(3), scaleOnInfinitePrecision: 1000000)
            .toString()
            .length,
        21,
      );

      // Порог с запасом: на десяти тысячах знаков спуск занимал секунду, на
      // ста тысячах не кончался за двадцать.
      expect(stopwatch.elapsedMilliseconds, lessThan(20000));
    });

    test('и ответ тот же, что на числе знаков поменьше', () {
      for (final digits in [20, 100, 1000, 10000]) {
        expect(
          ShortFraction(1, 3).round(digits).toString(),
          ShortFraction(1, 3).round(20).toString(),
          reason: 'знаков: $digits',
        );
      }
    });
  });

  group('Д49 разрыв масштабов не строит степень десятки', () {
    // Десять миллионов: старая дорога строила число в десять миллионов цифр и
    // не возвращалась.
    final a = ShortDecimal(1, shiftRight: 10000000);
    final b = ShortDecimal(3);

    test('целое деление, остаток и модуль отвечают сразу', () {
      final stopwatch = Stopwatch()..start();

      expect(a ~/ b, 0);
      expect(a % b, a);
      expect(a.remainder(b), a);
      expect(a.divideWithRemainder(b).quotient, 0);
      expect(a.divideWithRemainder(b).remainder, a);
      expect(a.compareTo(b), -1);

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('за миллионом отказ, где короткого пути нет', () {
      // Дробь такой пары в int64 не существует, и знать это без степени
      // десятки нельзя: отказ приходит оттуда же, откуда у старшей семьи, —
      // степень за миллионной границей.
      expect(
        () => a.divideToFraction(b),
        throwsA(isA<DecimalDigitsOutOfRangeError>()),
      );

      // Модуль отрицательного: евклидов ответ — это делимое плюс делитель, а
      // делитель и есть число, которое не помещается.
      expect(
        () => (-a) % b,
        throwsA(isA<DecimalDigitsOutOfRangeError>()),
      );
    });

    test('разрыв в пределах миллиона считается прежней дорогой', () {
      // Оба масштаба за миллионом, а разрыв между ними нулевой: короткий путь
      // не берётся, и пара выравнивается как раньше.
      final wide = ShortDecimal(1, shiftRight: 1500000);
      final other = ShortDecimal(3, shiftRight: 1500000);

      expect(
        wide.divide(other, scaleOnInfinitePrecision: 4).toString(),
        '0.3333',
      );
      expect(wide ~/ other, 0);
    });

    test('деление с числом знаков округляется в ноль', () {
      final stopwatch = Stopwatch()..start();

      expect(
        a.divide(b, scaleOnInfinitePrecision: 0),
        ShortDecimal.zero,
      );
      expect(
        a.divide(b, scaleOnInfinitePrecision: 1000000),
        ShortDecimal.zero,
      );

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('исключение деления отвечает всеми шестью округлениями', () {
      final stopwatch = Stopwatch()..start();

      // Значение — крошечное положительное число, поэтому вниз ноль, а вверх
      // единица последнего разряда.
      expect(
        () => a / b,
        throwsA(
          isA<ShortDecimalDivideException>()
              .having((e) => e.round(), 'round', ShortDecimal.zero)
              .having((e) => e.floor(), 'floor', ShortDecimal.zero)
              .having((e) => e.truncate(), 'truncate', ShortDecimal.zero)
              .having((e) => e.roundToEven(), 'roundToEven', ShortDecimal.zero)
              .having((e) => e.ceil(), 'ceil', ShortDecimal.one)
              .having(
                (e) => e.roundAwayFromZero(),
                'roundAwayFromZero',
                ShortDecimal.one,
              ),
        ),
      );

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });

  group('Д50 pow(int.min) на основаниях, где ответ известен', () {
    const min = -9223372036854775808;

    test('единица и минус единица отвечают, ноль отказывает делением', () {
      // int.min чётен, поэтому обе единицы дают единицу.
      expect(Decimal.one.pow(min).toString(), '1');
      expect(Decimal(-1).pow(min).toString(), '1');
      expect(ShortDecimal.one.pow(min).toString(), '1');
      expect(ShortDecimal(-1).pow(min).toString(), '1');

      // У нуля обратного нет, и отказ об этом и говорит.
      expect(() => Decimal.zero.pow(min), throwsUnsupportedError);
      expect(() => ShortDecimal.zero.pow(min), throwsUnsupportedError);
    });

    test('на остальных основаниях отказ прежний', () {
      expect(() => Decimal(2).pow(min), throwsArgumentError);
      expect(() => ShortDecimal(2).pow(min), throwsArgumentError);
    });
  });

  group('Д51 обход через обратное основание при переполнении масштаба', () {
    // Масштаб положительной степени выходит из int64 — 2^62 умножить на два, —
    // а канонический ответ помещается: обратная величина основания несёт
    // масштаб в другую сторону.
    const scale = 4611686018427387904;
    const answerScale = -9223372036854775806;

    test('обе семьи отвечают одинаково', () {
      final big = Decimal(5, shiftRight: scale).pow(-2);
      final short = ShortDecimal(5, shiftRight: scale).pow(-2);

      expect(big.base, BigInt.from(4));
      expect(big.scale, answerScale);
      expect(short.base, 4);
      expect(short.scale, answerScale);
    });

    test('а без обратной величины отказ остаётся', () {
      // У тройки конечной обратной величины нет, и обходить нечем.
      expect(
        () => ShortDecimal(3, shiftRight: scale).pow(-2),
        throwsUnsupportedError,
      );

      // Положительная степень того же основания отказывает как прежде:
      // обходить там нечего, масштаб и есть ответ.
      expect(
        () => Decimal(5, shiftRight: scale).pow(2),
        throwsA(isA<ScaleOutOfRangeError>()),
      );
    });
  });

  group('Д52 разрыв масштабов не заворачивается', () {
    const max = 9223372036854775807;
    // Разрыв здесь `int.max + 1` — он из int64 выходит, и заворот уходил
    // отрицательным индексом в таблицу степеней.
    final a = ShortDecimal(1, shiftRight: max);
    const b = ShortDecimal.ten;

    test('сравнение отвечает, а не падает', () {
      expect(a.compareTo(b), -1);
      expect(a < b, isTrue);
      expect(a == b, isFalse);
      expect(b.compareTo(a), 1);
    });

    test('целое деление, модуль и остаток отвечают', () {
      expect(a ~/ b, 0);
      expect(a % b, a);
      expect(a.remainder(b), a);
      expect(a.divideWithRemainder(b).quotient, 0);
      expect(a.divideWithRemainder(b).remainder, a);
      expect((-a).remainder(b), -a);
    });

    test('сложение и вычитание отвечают по своему правилу', () {
      // Точный ответ непредставим, и молчаливое переполнение здесь — правило
      // семьи. Проверяется, что оно и происходит, а не падение.
      expect((a + b).scale, max);
      expect((a - b).scale, max);
    });
  });

  group('Д53 ноль округляется в ноль на любом масштабе', () {
    // Старшая семья держит ноль ненормализованным, короткая канонизирует его.
    final big = Decimal(0, shiftRight: 9000000000000000000);
    final short = ShortDecimal(0, shiftRight: 9000000000000000000);

    test('обе семьи отвечают нулём во всех шести режимах', () {
      expect(big.isZero, isTrue);
      expect(big.scale, 9000000000000000000);

      for (final digits in [-21, 0, 21]) {
        expect(big.round(digits).toString(), '0', reason: 'знаков: $digits');
        expect(big.floor(digits).toString(), '0', reason: 'знаков: $digits');
        expect(big.ceil(digits).toString(), '0', reason: 'знаков: $digits');
        expect(big.truncate(digits).toString(), '0', reason: 'знаков: $digits');
        expect(
          big.roundToEven(digits).toString(),
          '0',
          reason: 'знаков: $digits',
        );
        expect(
          big.roundAwayFromZero(digits).toString(),
          '0',
          reason: 'знаков: $digits',
        );

        expect(short.round(digits).toString(), '0', reason: 'знаков: $digits');
      }
    });
  });
}
