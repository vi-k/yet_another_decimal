/// Property-тесты против точной рациональной модели из `support/reference.dart`.
///
/// Проверяют не отдельные значения, а законы, которые обязаны выполняться на
/// любых входах. Генератор детерминирован, поэтому упавший случай
/// воспроизводится: номер итерации и сами значения печатаются в `reason`.
library;

import 'package:denary/denary.dart';
import 'package:test/test.dart';

import 'support/reference.dart';

/// Сколько случайных случаев прогоняется на каждый закон.
const _cases = 2000;

void main() {
  group('Decimal против точной модели', () {
    test('сложение, вычитание, умножение', () {
      final gen = Gen(1);
      for (var i = 0; i < _cases; i++) {
        final sa = gen.wideString();
        final sb = gen.wideString();
        final a = Decimal.parse(sa);
        final b = Decimal.parse(sb);
        final ra = Ref.parse(sa);
        final rb = Ref.parse(sb);

        final why = 'случай $i: $sa и $sb';
        expect((a + b).toString(), (ra + rb).toDecimalString(), reason: why);
        expect((a - b).toString(), (ra - rb).toDecimalString(), reason: why);
        expect((a * b).toString(), (ra * rb).toDecimalString(), reason: why);
      }
    });

    test('сравнение согласовано с моделью и само с собой', () {
      final gen = Gen(2);
      for (var i = 0; i < _cases; i++) {
        final sa = gen.wideString();
        final sb = gen.wideString();
        final a = Decimal.parse(sa);
        final b = Decimal.parse(sb);
        final expected = Ref.parse(sa).compareTo(Ref.parse(sb));

        final why = 'случай $i: $sa против $sb';
        expect(a.compareTo(b), expected.sign, reason: why);
        expect(a < b, expected < 0, reason: why);
        expect(a <= b, expected <= 0, reason: why);
        expect(a > b, expected > 0, reason: why);
        expect(a >= b, expected >= 0, reason: why);
        expect(a == b, expected == 0, reason: why);
      }
    });

    test('равные значения дают равный хеш', () {
      final gen = Gen(3);
      for (var i = 0; i < _cases; i++) {
        final source = gen.wideString();
        final a = Decimal.parse(source);
        // То же значение в другом представлении: сдвиг туда-обратно и
        // хвостовые нули после точки.
        final b = Decimal.parse(source) >> 5 << 5;
        final c = Decimal.parse(
          source.contains('.') ? '${source}000' : '$source.000',
        );

        final why = 'случай $i: $source';
        expect(a, b, reason: why);
        expect(a, c, reason: why);
        expect(a.hashCode, b.hashCode, reason: why);
        expect(a.hashCode, c.hashCode, reason: why);
        expect({a, b, c}, hasLength(1), reason: why);
      }
    });

    test('округления совпадают с моделью', () {
      final gen = Gen(4);
      for (var i = 0; i < _cases; i++) {
        final source = gen.wideString();
        final digits = gen.signedFractionDigits();
        final value = Decimal.parse(source);
        final model = Ref.parse(source);

        final why = 'случай $i: $source до $digits знаков';
        expect(
          value.floor(digits).toString(),
          Ref.scaled(model.floorToScaled(digits), digits).toDecimalString(),
          reason: 'floor, $why',
        );
        expect(
          value.ceil(digits).toString(),
          Ref.scaled(model.ceilToScaled(digits), digits).toDecimalString(),
          reason: 'ceil, $why',
        );
        expect(
          value.round(digits).toString(),
          Ref.scaled(model.roundToScaled(digits), digits).toDecimalString(),
          reason: 'round, $why',
        );
        expect(
          value.truncate(digits).toString(),
          Ref.scaled(model.truncateToScaled(digits), digits).toDecimalString(),
          reason: 'truncate, $why',
        );
      }
    });

    test('floor <= truncate|round <= ceil', () {
      final gen = Gen(5);
      for (var i = 0; i < _cases; i++) {
        final source = gen.wideString();
        final digits = gen.signedFractionDigits();
        final value = Decimal.parse(source);

        final why = 'случай $i: $source до $digits знаков';
        expect(value.floor(digits) <= value.ceil(digits), isTrue, reason: why);
        expect(value.floor(digits) <= value.round(digits), isTrue, reason: why);
        expect(value.round(digits) <= value.ceil(digits), isTrue, reason: why);
        expect(
          value.floor(digits) <= value.truncate(digits),
          isTrue,
          reason: why,
        );
        expect(
          value.truncate(digits) <= value.ceil(digits),
          isTrue,
          reason: why,
        );
      }
    });

    test('parse(toString()) возвращает то же значение', () {
      final gen = Gen(6);
      for (var i = 0; i < _cases; i++) {
        final source = gen.wideString();
        final value = Decimal.parse(source);

        expect(
          Decimal.parse(value.toString()),
          value,
          reason: 'случай $i: $source',
        );
      }
    });

    test('% неотрицателен, remainder имеет знак делимого', () {
      final gen = Gen(7);
      for (var i = 0; i < _cases; i++) {
        final sa = gen.wideString();
        final sb = gen.wideString();
        final a = Decimal.parse(sa);
        final b = Decimal.parse(sb);
        if (b.isZero) {
          continue;
        }

        final why = 'случай $i: $sa и $sb';
        expect((a % b).isNegative, isFalse, reason: why);
        final rem = a.remainder(b);
        if (!rem.isZero) {
          expect(rem.isNegative, a.isNegative, reason: why);
        }
        // Контракт усекающего деления.
        expect(Decimal.fromBigInt(a ~/ b) * b + rem, a, reason: why);
      }
    });

    test('divideWithRemainder: quotient * divisor + remainder == dividend', () {
      final gen = Gen(8);
      for (var i = 0; i < _cases; i++) {
        final sa = gen.wideString();
        final sb = gen.wideString();
        final a = Decimal.parse(sa);
        final b = Decimal.parse(sb);
        if (b.isZero) {
          continue;
        }

        final division = a.divideWithRemainder(b);
        expect(
          Decimal.fromBigInt(division.quotient) * b + division.remainder,
          a,
          reason: 'случай $i: $sa и $sb',
        );
      }
    });

    test('деление точно тогда и только тогда, когда результат представим', () {
      final gen = Gen(9);
      for (var i = 0; i < _cases; i++) {
        final sa = gen.shortSafeString();
        final sb = gen.shortSafeString();
        final a = Decimal.parse(sa);
        final b = Decimal.parse(sb);
        if (b.isZero) {
          continue;
        }

        final model = Ref.parse(sa) / Ref.parse(sb);
        final why = 'случай $i: $sa / $sb';

        if (model.hasFiniteDecimal) {
          final result = a / b;
          expect(result.toString(), model.toDecimalString(), reason: why);
          expect(result * b, a, reason: why);
        } else {
          expect(
            () => a / b,
            throwsA(isA<DecimalDivideException>()),
            reason: why,
          );
        }
      }
    });

    test('divide округляет непредставимое так же, как модель', () {
      final gen = Gen(14);
      for (var i = 0; i < _cases; i++) {
        // Половина случаев — на коротких значениях: у пары произвольной
        // величины деление представимо примерно никогда, и ветка точного
        // ответа не исполнялась ни разу на двух тысячах случаев.
        final narrow = gen.nextBool;
        final sa = narrow ? gen.shortSafeString() : gen.wideString();
        final sb = narrow ? gen.shortSafeString() : gen.wideString();
        final a = Decimal.parse(sa);
        final b = Decimal.parse(sb);
        if (b.isZero) {
          continue;
        }

        final digits = gen.signedFractionDigits(12);
        final model = Ref.parse(sa) / Ref.parse(sb);
        final result = a.divide(b, scaleOnInfinitePrecision: digits);
        final why = 'случай $i: $sa / $sb до $digits знаков';

        if (model.hasFiniteDecimal) {
          // Представимое возвращается точным, а не урезанным до digits.
          // Сверять с `a / b` здесь нельзя: это тот же самый вызов.
          expect(result.toString(), model.toDecimalString(), reason: why);
        } else {
          expect(
            result,
            Decimal.fromBigInt(model.roundToScaled(digits)) >> digits,
            reason: why,
          );
        }
      }
    });

    test('toStringAsFixed даёт ровно n знаков и разбирается обратно', () {
      final gen = Gen(10);
      for (var i = 0; i < _cases; i++) {
        final source = gen.wideString();
        final digits = gen.fractionDigits();
        final value = Decimal.parse(source);
        final text = value.toStringAsFixed(digits);

        final why = 'случай $i: $source до $digits знаков, получено "$text"';
        if (digits == 0) {
          expect(text.contains('.'), isFalse, reason: why);
        } else {
          final dot = text.indexOf('.');
          expect(dot, isNot(-1), reason: why);
          expect(text.length - dot - 1, digits, reason: why);
        }
        expect(Decimal.parse(text), value.round(digits), reason: why);
        expect(text, Ref.parse(source).toStringAsFixed(digits), reason: why);
      }
    });
  });

  group('ShortDecimal против Decimal на безопасных значениях', () {
    test('арифметика совпадает', () {
      final gen = Gen(11);
      for (var i = 0; i < _cases; i++) {
        final sa = gen.shortSafeString();
        final sb = gen.shortSafeString();
        final wa = Decimal.parse(sa);
        final wb = Decimal.parse(sb);
        final na = ShortDecimal.parse(sa);
        final nb = ShortDecimal.parse(sb);

        final why = 'случай $i: $sa и $sb';
        expect((na + nb).toString(), (wa + wb).toString(), reason: why);
        expect((na - nb).toString(), (wa - wb).toString(), reason: why);
        expect((na * nb).toString(), (wa * wb).toString(), reason: why);
        expect(na.compareTo(nb), wa.compareTo(wb), reason: why);
        expect(na == nb, wa == wb, reason: why);
      }
    });

    test('округления совпадают', () {
      final gen = Gen(12);
      for (var i = 0; i < _cases; i++) {
        final source = gen.shortSafeString();
        // В том числе к десяткам и сотням: у короткого семейства этот режим
        // не проверялся вовсе, и четыре мутации в нём выживали.
        final digits = gen.signedFractionDigits();
        final wide = Decimal.parse(source);
        final short = ShortDecimal.parse(source);

        final why = 'случай $i: $source до $digits знаков';
        expect(
          short.floor(digits).toString(),
          wide.floor(digits).toString(),
          reason: why,
        );
        expect(
          short.ceil(digits).toString(),
          wide.ceil(digits).toString(),
          reason: why,
        );
        expect(
          short.round(digits).toString(),
          wide.round(digits).toString(),
          reason: why,
        );
        expect(
          short.truncate(digits).toString(),
          wide.truncate(digits).toString(),
          reason: why,
        );
      }
    });

    test('деление во всех формах совпадает', () {
      final gen = Gen(15);
      for (var i = 0; i < _cases; i++) {
        final sa = gen.shortSafeString();
        final sb = gen.shortSafeString();
        final wa = Decimal.parse(sa);
        final wb = Decimal.parse(sb);
        final na = ShortDecimal.parse(sa);
        final nb = ShortDecimal.parse(sb);
        if (wb.isZero) {
          continue;
        }

        final why = 'случай $i: $sa / $sb';

        expect(
          na.divideOrNull(nb)?.toString(),
          wa.divideOrNull(wb)?.toString(),
          reason: why,
        );
        expect(na.isDivisibleBy(nb), wa.isDivisibleBy(wb), reason: why);
        expect((na ~/ nb).toString(), (wa ~/ wb).toString(), reason: why);
        expect((na % nb).toString(), (wa % wb).toString(), reason: why);
        expect(
          na.remainder(nb).toString(),
          wa.remainder(wb).toString(),
          reason: why,
        );
        expect(
          na.divideWithRemainder(nb).toString(),
          wa.divideWithRemainder(wb).toString(),
          reason: why,
        );
        expect(na.divideToDouble(nb), wa.divideToDouble(wb), reason: why);
        expect(
          na.divideToFraction(nb).toString(),
          wa.divideToFraction(wb).toString(),
          reason: why,
        );

        // В том числе отрицательное: округление частного к десяткам и сотням
        // у короткого семейства не проверялось, и зажатие такого числа знаков
        // к нулю прошло бы незамеченным.
        final digits = gen.signedFractionDigits();
        expect(
          na.divide(nb, scaleOnInfinitePrecision: digits).toString(),
          wa.divide(wb, scaleOnInfinitePrecision: digits).toString(),
          reason: '$why до $digits знаков',
        );
      }
    });

    test('свойства и переводы совпадают', () {
      final gen = Gen(16);
      for (var i = 0; i < _cases; i++) {
        final source = gen.shortSafeString();
        final wide = Decimal.parse(source);
        final short = ShortDecimal.parse(source);
        final why = 'случай $i: $source';

        expect(short.precision, wide.precision, reason: why);
        expect(short.fractionDigits, wide.fractionDigits, reason: why);
        expect(short.exponent, wide.exponent, reason: why);
        expect(
          BigInt.from(short.unscaledValue),
          wide.unscaledValue,
          reason: why,
        );
        expect(short.sign, wide.sign, reason: why);
        expect(short.isInteger, wide.isInteger, reason: why);
        expect(short.isPositive, wide.isPositive, reason: why);
        expect(short.toDouble(), wide.toDouble(), reason: why);
        expect(short.toInt(), wide.toInt(), reason: why);
        expect(short.toBigInt(), wide.toBigInt(), reason: why);
        expect(short.toJson(), wide.toJson(), reason: why);
        expect(short.abs().toString(), wide.abs().toString(), reason: why);
        expect((-short).toString(), (-wide).toString(), reason: why);
        expect(
          short.normalized().toString(),
          wide.normalized().toString(),
          reason: why,
        );

        final digits = gen.fractionDigits();
        expect(
          short.toStringAsFixed(digits),
          wide.toStringAsFixed(digits),
          reason: '$why с $digits знаками',
        );
        expect(
          short.toStringAsExponential(digits),
          wide.toStringAsExponential(digits),
          reason: '$why в экспоненте с $digits знаками',
        );
        expect(
          short.toStringAsPrecision(1 + digits),
          wide.toStringAsPrecision(1 + digits),
          reason: '$why с точностью ${1 + digits}',
        );

        final places = gen.signedFractionDigits(4);
        expect(
          short.movePointLeft(places).toString(),
          wide.movePointLeft(places).toString(),
          reason: '$why, точка влево на $places',
        );
      }
    });

    test('разбор и печать совпадают', () {
      final gen = Gen(13);
      for (var i = 0; i < _cases; i++) {
        final source = gen.shortSafeString();
        expect(
          ShortDecimal.parse(source).toString(),
          Decimal.parse(source).toString(),
          reason: 'случай $i: $source',
        );
      }
    });
  });
}
