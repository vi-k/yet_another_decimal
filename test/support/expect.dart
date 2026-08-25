/// Хелперы для проверки значений обоих семейств.
///
/// Проверять принято через них, а не голым `expect`: помимо значения они
/// сверяют форму его хранения — но только там, где её передали. В
/// арифметических проверках `base` и `scale` не передаются: форма результата
/// там артефакт алгоритма, и быстрый путь деления законно даёт другую форму
/// при том же значении.
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

void expectDecimal(
  Decimal d,
  String str, {
  BigInt? base,
  int? scale,
  int? fractionDigits,
}) {
  expect(d.toString(), str);

  if (base != null) {
    expect(d.base, base);
  }

  if (scale != null) {
    expect(d.scale, scale);
  }

  if (fractionDigits != null) {
    expect(d.fractionDigits, fractionDigits);
  }
}

void expectShortDecimal(
  ShortDecimal d,
  String str, {
  int? base,
  int? scale,
  int? fractionDigits,
}) {
  expect(d.toString(), str);

  if (base != null) {
    expect(d.base, base);
  }

  if (scale != null) {
    expect(d.scale, scale);
  }

  if (fractionDigits != null) {
    expect(d.fractionDigits, fractionDigits);
  }
}

void expectFraction(Fraction f, String str) {
  expect(f.toString(), str);
}

void expectShortFraction(ShortFraction f, String str) {
  expect(f.toString(), str);
}

void expectDivision(Division division, String str) {
  expect(division.toString(), str);
}

void expectShortDivision(ShortDivision division, String str) {
  expect(division.toString(), str);
}

void expectDivide(Decimal dividend, Decimal divisor, String str) {
  final d = Division(dividend, divisor);

  expect(d.toString(), str);

  expect(
    Decimal.fromBigInt(d.quotient) * divisor + d.remainder == dividend,
    isTrue,
  );
}

void expectShortDivide(
  ShortDecimal dividend,
  ShortDecimal divisor,
  String str,
) {
  final d = ShortDivision(dividend, divisor);

  expect(d.toString(), str);

  expect(ShortDecimal(d.quotient) * divisor + d.remainder == dividend, isTrue);
}

void expectDouble(double a, double b, String str, {bool isValid = true}) {
  if (isValid) {
    expect(a, b);
    expect(a.toString(), str);
    expect(b.toString(), str);
  } else {
    expect(a != b, isTrue);
    expect(a.toString() != str, isTrue);
  }
}
