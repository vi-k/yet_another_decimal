/// Эталонная модель для property-тестов.
///
/// Точная рациональная арифметика на [BigInt]. Намеренно написана максимально
/// прямолинейно и **не использует код пакета** — иначе она повторяла бы его
/// ошибки вместо того, чтобы их ловить.
library;

import 'dart:math';

import 'package:denary/denary.dart';
import 'package:meta/meta.dart';

final BigInt _b10 = BigInt.from(10);

/// Точное рациональное число: [num] / [den], `den > 0`, дробь сокращена.
@immutable
final class Ref implements Comparable<Ref> {
  final BigInt num;
  final BigInt den;

  factory Ref(BigInt numerator, BigInt denominator) {
    if (denominator == BigInt.zero) {
      throw ArgumentError('denominator must not be zero');
    }

    var n = numerator;
    var d = denominator;
    if (d.isNegative) {
      n = -n;
      d = -d;
    }

    final g = n.gcd(d);

    return Ref._(n ~/ g, d ~/ g);
  }

  const Ref._(this.num, this.den);

  /// Значение `base * 10^-scale` как точная дробь.
  factory Ref.scaled(BigInt base, int scale) => scale >= 0
      ? Ref(base, _b10.pow(scale))
      : Ref(base * _b10.pow(-scale), BigInt.one);

  factory Ref.fromDecimal(Decimal value) => Ref.scaled(value.base, value.scale);

  factory Ref.fromShortDecimal(ShortDecimal value) =>
      Ref.scaled(BigInt.from(value.base), value.scale);

  factory Ref.fromInt(int value) => Ref(BigInt.from(value), BigInt.one);

  /// Разбор десятичной записи без потери точности.
  factory Ref.parse(String source) {
    final dot = source.indexOf('.');
    if (dot == -1) {
      return Ref(BigInt.parse(source), BigInt.one);
    }

    final digits = '${source.substring(0, dot)}${source.substring(dot + 1)}';

    return Ref.scaled(BigInt.parse(digits), source.length - dot - 1);
  }

  bool get isZero => num == BigInt.zero;

  int get sign => num.sign;

  bool get isNegative => num.isNegative;

  Ref operator -() => Ref._(-num, den);

  Ref operator +(Ref other) =>
      Ref(num * other.den + other.num * den, den * other.den);

  Ref operator -(Ref other) =>
      Ref(num * other.den - other.num * den, den * other.den);

  Ref operator *(Ref other) => Ref(num * other.num, den * other.den);

  Ref operator /(Ref other) {
    if (other.isZero) {
      throw ArgumentError('division by zero');
    }

    return Ref(num * other.den, den * other.num);
  }

  Ref abs() => num.isNegative ? Ref._(-num, den) : this;

  /// Представим ли конечной десятичной дробью, то есть содержит ли знаменатель
  /// только множители 2 и 5.
  bool get hasFiniteDecimal {
    var d = den;
    while (d % BigInt.two == BigInt.zero) {
      d = d ~/ BigInt.two;
    }
    final five = BigInt.from(5);
    while (d % five == BigInt.zero) {
      d = d ~/ five;
    }

    return d == BigInt.one;
  }

  /// Числитель и знаменатель значения, умноженного на `10^fractionDigits`.
  ///
  /// Отрицательное число знаков масштабирует **знаменатель**. Делить нацело
  /// числитель, как здесь делалось раньше, нельзя: остаток теряется до
  /// округления, и модель начинает врать ровно там, где её и спрашивают —
  /// при округлении к десяткам и сотням.
  (BigInt, BigInt) _scaled(int fractionDigits) => fractionDigits >= 0
      ? (num * _b10.pow(fractionDigits), den)
      : (num, den * _b10.pow(-fractionDigits));

  BigInt truncateToScaled(int fractionDigits) {
    final (n, d) = _scaled(fractionDigits);

    return n ~/ d;
  }

  BigInt floorToScaled(int fractionDigits) {
    final (n, d) = _scaled(fractionDigits);
    var q = n ~/ d;
    if (n.isNegative && n.remainder(d) != BigInt.zero) {
      q -= BigInt.one;
    }

    return q;
  }

  BigInt ceilToScaled(int fractionDigits) {
    final (n, d) = _scaled(fractionDigits);
    var q = n ~/ d;
    if (!n.isNegative && n.remainder(d) != BigInt.zero) {
      q += BigInt.one;
    }

    return q;
  }

  /// Округление половины от нуля — та же семантика, что у пакета и у
  /// `num.round()`.
  BigInt roundToScaled(int fractionDigits) {
    final (n, d) = _scaled(fractionDigits);
    var q = n ~/ d;
    final rest = n.remainder(d).abs();
    if (rest * BigInt.two >= d) {
      q += BigInt.from(n.sign);
    }

    return q;
  }

  /// Десятичная запись с ровно [fractionDigits] знаками после точки, с
  /// округлением половины от нуля. Эталон для `toStringAsFixed`.
  String toStringAsFixed(int fractionDigits) {
    if (fractionDigits < 0) {
      throw ArgumentError.value(fractionDigits, 'fractionDigits');
    }

    final scaled = roundToScaled(fractionDigits);
    final sign = scaled.isNegative ? '-' : '';
    var digits = scaled.abs().toString();

    if (fractionDigits == 0) {
      return '$sign$digits';
    }

    if (digits.length <= fractionDigits) {
      digits = digits.padLeft(fractionDigits + 1, '0');
    }

    final cut = digits.length - fractionDigits;

    return '$sign${digits.substring(0, cut)}.${digits.substring(cut)}';
  }

  /// Каноническая десятичная запись без хвостовых нулей.
  ///
  /// Требует [hasFiniteDecimal]; для бесконечной дроби бросает.
  String toDecimalString() {
    if (!hasFiniteDecimal) {
      throw StateError('$this is not a finite decimal');
    }

    // Достаточно знаков, чтобы дробь легла точно.
    var digits = 0;
    var d = den;
    while (d != BigInt.one) {
      d = d % BigInt.two == BigInt.zero ? d ~/ BigInt.two : d ~/ BigInt.from(5);
      digits++;
    }

    final text = toStringAsFixed(digits);
    if (!text.contains('.')) {
      return text;
    }

    var end = text.length;
    while (text.codeUnitAt(end - 1) == 0x30) {
      end--;
    }
    if (text.codeUnitAt(end - 1) == 0x2e) {
      end--;
    }

    final trimmed = text.substring(0, end);

    return trimmed == '-0' ? '0' : trimmed;
  }

  @override
  int compareTo(Ref other) => (num * other.den).compareTo(other.num * den);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ref && num == other.num && den == other.den;

  @override
  int get hashCode => Object.hash(num, den);

  @override
  String toString() => den == BigInt.one ? '$num' : '$num/$den';
}

/// Генератор случайных значений для property-тестов.
///
/// Детерминирован: одно и то же зерно даёт одну и ту же последовательность,
/// поэтому упавший случай воспроизводится.
final class Gen {
  final Random _random;

  Gen([int seed = 20260825]) : _random = Random(seed);

  int get seedlessInt => _random.nextInt(1 << 32);

  /// Строка десятичного числа с [intDigits] цифрами до точки и [fracDigits]
  /// после, со случайным знаком.
  String decimalString({required int intDigits, required int fracDigits}) {
    final buffer = StringBuffer();
    if (_random.nextBool()) {
      buffer.write('-');
    }
    for (var i = 0; i < intDigits; i++) {
      buffer.write(_random.nextInt(10));
    }
    if (fracDigits > 0) {
      buffer.write('.');
      for (var i = 0; i < fracDigits; i++) {
        buffer.write(_random.nextInt(10));
      }
    }

    return buffer.toString();
  }

  /// Значение, у которого не только само оно, но и **произведение двух таких**
  /// укладывается в int64 — то есть пригодное для сверки двух семейств.
  ///
  /// Отсюда потолок в девять значащих цифр: `999999999^2` меньше `int.max`,
  /// а выравнивание масштабов при сложении даёт не больше восемнадцати цифр.
  String shortSafeString() {
    final total = 1 + _random.nextInt(9);
    final fracDigits = _random.nextInt(total);

    return decimalString(intDigits: total - fracDigits, fracDigits: fracDigits);
  }

  /// Значение произвольной величины — только для `Decimal`.
  String wideString() {
    final intDigits = 1 + _random.nextInt(40);
    final fracDigits = _random.nextInt(40);

    return decimalString(intDigits: intDigits, fracDigits: fracDigits);
  }

  int fractionDigits([int max = 6]) => _random.nextInt(max + 1);

  /// Число знаков округления, в том числе **отрицательное**.
  ///
  /// Округление к десяткам и сотням — рабочий режим пакета, и с починенной
  /// моделью законы можно гонять и на нём. Отдельно от [fractionDigits],
  /// потому что `toStringAsFixed` отрицательного не принимает по контракту.
  int signedFractionDigits([int max = 6]) => _random.nextInt(2 * max + 1) - max;

  bool get nextBool => _random.nextBool();
}
