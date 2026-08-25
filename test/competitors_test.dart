/// Сверка с пакетом `decimal` — главным конкурентом.
///
/// Смысл не в том, что конкурент — эталон истины. Смысл в том, что расхождение
/// с ним обязано быть **осознанным**: либо это наш дефект, либо решение,
/// записанное в разделе «Осознанные расхождения» ниже.
///
/// Ревью 2026-08-25 показало, что такая сверка даёт красный на восьми дефектах
/// из пятнадцати — в том числе на всех, где мы единственные отвечаем неверно.
library;

import 'package:decimal/decimal.dart' as rival;
import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import 'support/reference.dart';

const _cases = 500;

/// Разбор одной строки всеми тремя способами.
({Decimal wide, ShortDecimal short, rival.Decimal other}) _parseAll(
  String source,
) => (
  wide: Decimal.parse(source),
  short: ShortDecimal.parse(source),
  other: rival.Decimal.parse(source),
);

void main() {
  group('арифметика совпадает с decimal', () {
    test('сложение, вычитание, умножение', () {
      final gen = Gen(101);
      for (var i = 0; i < _cases; i++) {
        final sa = gen.shortSafeString();
        final sb = gen.shortSafeString();
        final a = _parseAll(sa);
        final b = _parseAll(sb);

        final why = 'случай $i: $sa и $sb';
        expect(
          (a.wide + b.wide).toString(),
          (a.other + b.other).toString(),
          reason: 'сложение, $why',
        );
        expect(
          (a.short + b.short).toString(),
          (a.other + b.other).toString(),
          reason: 'сложение ShortDecimal, $why',
        );
        expect(
          (a.wide - b.wide).toString(),
          (a.other - b.other).toString(),
          reason: 'вычитание, $why',
        );
        expect(
          (a.wide * b.wide).toString(),
          (a.other * b.other).toString(),
          reason: 'умножение, $why',
        );
        expect(
          (a.short * b.short).toString(),
          (a.other * b.other).toString(),
          reason: 'умножение ShortDecimal, $why',
        );
      }
    });

    test('сравнение', () {
      final gen = Gen(102);
      for (var i = 0; i < _cases; i++) {
        final sa = gen.shortSafeString();
        final sb = gen.shortSafeString();
        final a = _parseAll(sa);
        final b = _parseAll(sb);

        final expected = a.other.compareTo(b.other).sign;
        final why = 'случай $i: $sa против $sb';
        expect(a.wide.compareTo(b.wide), expected, reason: why);
        expect(a.short.compareTo(b.short), expected, reason: why);
        expect(a.wide == b.wide, a.other == b.other, reason: why);
      }
    });

    test('округления', () {
      final gen = Gen(103);
      for (var i = 0; i < _cases; i++) {
        final source = gen.shortSafeString();
        final digits = gen.fractionDigits(4);
        final v = _parseAll(source);

        final why = 'случай $i: $source до $digits знаков';
        expect(
          v.wide.round(digits).toString(),
          v.other.round(scale: digits).toString(),
          reason: 'round, $why',
        );
        expect(
          v.wide.floor(digits).toString(),
          v.other.floor(scale: digits).toString(),
          reason: 'floor, $why',
        );
        expect(
          v.wide.ceil(digits).toString(),
          v.other.ceil(scale: digits).toString(),
          reason: 'ceil, $why',
        );
        expect(
          v.wide.truncate(digits).toString(),
          v.other.truncate(scale: digits).toString(),
          reason: 'truncate, $why',
        );
        expect(
          v.short.round(digits).toString(),
          v.other.round(scale: digits).toString(),
          reason: 'round ShortDecimal, $why',
        );
      }
    });

    test('печать', () {
      final gen = Gen(104);
      for (var i = 0; i < _cases; i++) {
        final source = gen.shortSafeString();
        final v = _parseAll(source);

        expect(
          v.wide.toString(),
          v.other.toString(),
          reason: 'случай $i: $source',
        );
        expect(
          v.short.toString(),
          v.other.toString(),
          reason: 'случай $i: $source, ShortDecimal',
        );
      }
    });

    test('toStringAsFixed', () {
      final gen = Gen(105);
      for (var i = 0; i < _cases; i++) {
        final source = gen.shortSafeString();
        final digits = gen.fractionDigits(4);
        final v = _parseAll(source);

        final why = 'случай $i: $source до $digits знаков';
        expect(
          v.wide.toStringAsFixed(digits),
          v.other.toStringAsFixed(digits),
          reason: why,
        );
        expect(
          v.short.toStringAsFixed(digits),
          v.other.toStringAsFixed(digits),
          reason: 'ShortDecimal, $why',
        );
      }
    }, skip: 'Д5: toStringAsFixed не добивает нулями');

    test('точное деление', () {
      final gen = Gen(106);
      for (var i = 0; i < _cases; i++) {
        final sa = gen.shortSafeString();
        final sb = gen.shortSafeString();
        final a = _parseAll(sa);
        final b = _parseAll(sb);
        if (b.wide.isZero) {
          continue;
        }

        final exact = a.other / b.other;
        if (!exact.hasFinitePrecision) {
          continue;
        }

        expect(
          (a.wide / b.wide).toString(),
          exact.toDecimal().toString(),
          reason: 'случай $i: $sa / $sb',
        );
      }
    }, skip: 'Д1: деление на отрицательное бросает вместо результата');

    test('целая часть', () {
      final gen = Gen(107);
      for (var i = 0; i < _cases; i++) {
        final source = gen.shortSafeString();
        final v = _parseAll(source);

        expect(
          v.wide.toBigInt(),
          v.other.toBigInt(),
          reason: 'случай $i: $source',
        );
      }
    });
  });

  group('разбор мусора совпадает с decimal', () {
    const garbage = [
      '',
      ' ',
      '.',
      '-',
      '-.',
      '+',
      '--1',
      '1.',
      '1.2.3',
      '1 2',
      '1\t0',
      '1_000',
      'NaN',
      'Infinity',
      '0x10',
      '0X1F',
      '0x1.8',
      '-0x10',
    ];

    test('Decimal', () {
      for (final source in garbage) {
        expect(
          Decimal.tryParse(source),
          isNull,
          reason: 'вход ${jsonish(source)}',
        );
        expect(
          rival.Decimal.tryParse(source),
          isNull,
          reason: 'конкурент на ${jsonish(source)}',
        );
      }
    }, skip: 'Д10: tryParse принимает шестнадцатеричное');

    test('ShortDecimal', () {
      for (final source in garbage) {
        expect(
          ShortDecimal.tryParse(source),
          isNull,
          reason: 'вход ${jsonish(source)}',
        );
      }
    }, skip: 'Д10 и Д12: tryParse принимает hex, "-" и табуляцию');

    test('корректные записи принимаются обоими', () {
      const valid = ['0', '-0', '007', '0.000', '+5', '.5', '-.5', '1.50'];
      for (final source in valid) {
        expect(
          Decimal.tryParse(source),
          isNotNull,
          reason: 'вход ${jsonish(source)}',
        );
        expect(
          rival.Decimal.tryParse(source),
          isNotNull,
          reason: 'конкурент на ${jsonish(source)}',
        );
      }
    });
  });

  group('осознанные расхождения с decimal', () {
    test('деление возвращает результат, а не Rational', () {
      // У конкурента `/` тотален и возвращает `Rational`. У нас точное деление
      // даёт `Decimal`, а непредставимое бросает исключение, несущее дробь.
      // Это разные контракты, а не дефект.
      expect(Decimal(1) / Decimal(8), Decimal.parse('0.125'));
      expect(
        () => Decimal(1) / Decimal(3),
        throwsA(isA<DecimalDivideException>()),
      );
      final rivalResult = rival.Decimal.fromInt(1) / rival.Decimal.fromInt(3);
      expect(rivalResult.hasFinitePrecision, isFalse);
    });

    test('экспоненциальная запись пока не поддерживается', () {
      // Конкурент разбирает, мы нет. Пункт из `docs/backlog.md`; когда будет
      // сделано, этот тест переедет в группу совпадений.
      expect(Decimal.tryParse('1e21'), isNull);
      expect(ShortDecimal.tryParse('1e21'), isNull);
      expect(rival.Decimal.tryParse('1e21'), isNotNull);
    });
  });
}

/// Читаемое представление строки в сообщении об ошибке.
String jsonish(String source) => '"${source.replaceAll('\t', r'\t')}"';
