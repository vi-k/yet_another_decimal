// ignore_for_file: avoid_js_rounded_ints

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

void main() {
  group('Decimal', () {
    group('parse', () {
      test('0', () {
        for (final p in [
          (Decimal.parse('0'), '0', BigInt.zero, 0, 0),
          (Decimal.parse('0.0'), '0', BigInt.zero, 1, 0),
          (Decimal.parse('.0'), '0', BigInt.zero, 1, 0),
          (Decimal.parse('00000.00000'), '0', BigInt.zero, 5, 0),
          (Decimal.parse(' 0'), '0', BigInt.zero, 0, 0),
          (Decimal.parse('0 '), '0', BigInt.zero, 0, 0),
          (Decimal.parse(' 0 '), '0', BigInt.zero, 0, 0),
          (Decimal.parse(' 0.0'), '0', BigInt.zero, 1, 0),
          (Decimal.parse('0.0 '), '0', BigInt.zero, 1, 0),
          (Decimal.parse(' 0.0 '), '0', BigInt.zero, 1, 0),
          (Decimal(0) >> 10, '0', BigInt.zero, 10, 0),
          (Decimal(0) << 10, '0', BigInt.zero, -10, 0),
          (Decimal.parse('-0'), '0', BigInt.zero, 0, 0),
          (Decimal.parse('-0.0'), '0', BigInt.zero, 1, 0),
          (Decimal.parse('-.0'), '0', BigInt.zero, 1, 0),
          (Decimal.parse('-00000.00000'), '0', BigInt.zero, 5, 0),
        ]) {
          expectDecimal(
            p.$1,
            p.$2,
            base: p.$3,
            scale: p.$4,
            fractionDigits: p.$5,
          );
        }

        expect(
          () => Decimal.parse('0.'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $Decimal: 0.',
            ),
          ),
        );

        expect(
          () => Decimal.parse('0.0.'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $Decimal: 0.0.',
            ),
          ),
        );

        expect(
          () => Decimal.parse('0..0'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $Decimal: 0..0',
            ),
          ),
        );
      });

      test('1', () {
        expectDecimal(
          Decimal.parse('1'),
          '1',
          base: BigInt.one,
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('0.1'),
          '0.1',
          base: BigInt.one,
          scale: 1,
          fractionDigits: 1,
        );
        expectDecimal(
          Decimal.parse('.1'),
          '0.1',
          base: BigInt.one,
          scale: 1,
          fractionDigits: 1,
        );
        expectDecimal(
          Decimal.parse('0.01'),
          '0.01',
          base: BigInt.one,
          scale: 2,
          fractionDigits: 2,
        );
        expectDecimal(
          Decimal.parse('0.001'),
          '0.001',
          base: BigInt.one,
          scale: 3,
          fractionDigits: 3,
        );
        expectDecimal(
          Decimal.parse('1.0'),
          '1',
          base: BigInt.from(10),
          scale: 1,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('1.00'),
          '1',
          base: BigInt.from(100),
          scale: 2,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('1.000'),
          '1',
          base: BigInt.from(1000),
          scale: 3,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('10'),
          '10',
          base: BigInt.from(10),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('100'),
          '100',
          base: BigInt.from(100),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('1000'),
          '1000',
          base: BigInt.from(1000),
          scale: 0,
          fractionDigits: 0,
        );

        expect(
          () => Decimal.parse('0.1 0'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $Decimal: 0.1 0',
            ),
          ),
        );

        expect(
          () => Decimal.parse('1..0'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $Decimal: 1..0',
            ),
          ),
        );

        expect(
          () => Decimal.parse('1 000'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $Decimal: 1 000',
            ),
          ),
        );

        expect(
          () => Decimal.parse('1,000.0'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $Decimal: 1,000.0',
            ),
          ),
        );

        expect(
          () => Decimal.parse("1'000.0"),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == "Could not parse $Decimal: 1'000.0",
            ),
          ),
        );

        expectDecimal(
          Decimal.parse('-1'),
          '-1',
          base: -BigInt.one,
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-0.1'),
          '-0.1',
          base: -BigInt.one,
          scale: 1,
          fractionDigits: 1,
        );
        expectDecimal(
          Decimal.parse('-0.01'),
          '-0.01',
          base: -BigInt.one,
          scale: 2,
          fractionDigits: 2,
        );
        expectDecimal(
          Decimal.parse('-0.001'),
          '-0.001',
          base: -BigInt.one,
          scale: 3,
          fractionDigits: 3,
        );
        expectDecimal(
          Decimal.parse('-1.0'),
          '-1',
          base: BigInt.from(-10),
          scale: 1,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-1.00'),
          '-1',
          base: BigInt.from(-100),
          scale: 2,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-1.000'),
          '-1',
          base: BigInt.from(-1000),
          scale: 3,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-10'),
          '-10',
          base: BigInt.from(-10),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-100'),
          '-100',
          base: BigInt.from(-100),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-1000'),
          '-1000',
          base: BigInt.from(-1000),
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('int', () {
        expectDecimal(
          Decimal.parse('1234567890'),
          '1234567890',
          base: BigInt.from(1234567890),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('123456789.0'),
          '123456789',
          base: BigInt.from(1234567890),
          scale: 1,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('12345678.90'),
          '12345678.9',
          base: BigInt.from(1234567890),
          scale: 2,
          fractionDigits: 1,
        );
        expectDecimal(
          Decimal.parse('1234567.890'),
          '1234567.89',
          base: BigInt.from(1234567890),
          scale: 3,
          fractionDigits: 2,
        );
        expectDecimal(
          Decimal.parse('123456.7890'),
          '123456.789',
          base: BigInt.from(1234567890),
          scale: 4,
          fractionDigits: 3,
        );
        expectDecimal(
          Decimal.parse('12345.67890'),
          '12345.6789',
          base: BigInt.from(1234567890),
          scale: 5,
          fractionDigits: 4,
        );
        expectDecimal(
          Decimal.parse('1234.567890'),
          '1234.56789',
          base: BigInt.from(1234567890),
          scale: 6,
          fractionDigits: 5,
        );
        expectDecimal(
          Decimal.parse('123.4567890'),
          '123.456789',
          base: BigInt.from(1234567890),
          scale: 7,
          fractionDigits: 6,
        );
        expectDecimal(
          Decimal.parse('12.34567890'),
          '12.3456789',
          base: BigInt.from(1234567890),
          scale: 8,
          fractionDigits: 7,
        );
        expectDecimal(
          Decimal.parse('1.234567890'),
          '1.23456789',
          base: BigInt.from(1234567890),
          scale: 9,
          fractionDigits: 8,
        );
        expectDecimal(
          Decimal.parse('0.1234567890'),
          '0.123456789',
          base: BigInt.from(1234567890),
          scale: 10,
          fractionDigits: 9,
        );
        expectDecimal(
          Decimal.parse('0.01234567890'),
          '0.0123456789',
          base: BigInt.from(1234567890),
          scale: 11,
          fractionDigits: 10,
        );
        expectDecimal(
          Decimal.parse('0.001234567890'),
          '0.00123456789',
          base: BigInt.from(1234567890),
          scale: 12,
          fractionDigits: 11,
        );
        expectDecimal(
          Decimal.parse('0.0001234567890'),
          '0.000123456789',
          base: BigInt.from(1234567890),
          scale: 13,
          fractionDigits: 12,
        );

        expectDecimal(
          Decimal.parse('-1234567890'),
          '-1234567890',
          base: BigInt.from(-1234567890),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-123456789.0'),
          '-123456789',
          base: BigInt.from(-1234567890),
          scale: 1,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-12345678.90'),
          '-12345678.9',
          base: BigInt.from(-1234567890),
          scale: 2,
          fractionDigits: 1,
        );
        expectDecimal(
          Decimal.parse('-1234567.890'),
          '-1234567.89',
          base: BigInt.from(-1234567890),
          scale: 3,
          fractionDigits: 2,
        );
        expectDecimal(
          Decimal.parse('-123456.7890'),
          '-123456.789',
          base: BigInt.from(-1234567890),
          scale: 4,
          fractionDigits: 3,
        );
        expectDecimal(
          Decimal.parse('-12345.67890'),
          '-12345.6789',
          base: BigInt.from(-1234567890),
          scale: 5,
          fractionDigits: 4,
        );
        expectDecimal(
          Decimal.parse('-1234.567890'),
          '-1234.56789',
          base: BigInt.from(-1234567890),
          scale: 6,
          fractionDigits: 5,
        );
        expectDecimal(
          Decimal.parse('-123.4567890'),
          '-123.456789',
          base: BigInt.from(-1234567890),
          scale: 7,
          fractionDigits: 6,
        );
        expectDecimal(
          Decimal.parse('-12.34567890'),
          '-12.3456789',
          base: BigInt.from(-1234567890),
          scale: 8,
          fractionDigits: 7,
        );
        expectDecimal(
          Decimal.parse('-1.234567890'),
          '-1.23456789',
          base: BigInt.from(-1234567890),
          scale: 9,
          fractionDigits: 8,
        );
        expectDecimal(
          Decimal.parse('-0.1234567890'),
          '-0.123456789',
          base: BigInt.from(-1234567890),
          scale: 10,
          fractionDigits: 9,
        );
        expectDecimal(
          Decimal.parse('-0.01234567890'),
          '-0.0123456789',
          base: BigInt.from(-1234567890),
          scale: 11,
          fractionDigits: 10,
        );
        expectDecimal(
          Decimal.parse('-0.001234567890'),
          '-0.00123456789',
          base: BigInt.from(-1234567890),
          scale: 12,
          fractionDigits: 11,
        );
        expectDecimal(
          Decimal.parse('-0.0001234567890'),
          '-0.000123456789',
          base: BigInt.from(-1234567890),
          scale: 13,
          fractionDigits: 12,
        );
      });

      test('BigInt', () {
        // BigInt
        expectDecimal(
          Decimal.parse('1234567890123456789012345678901234567890'),
          '1234567890123456789012345678901234567890',
          base: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('123456789012345678901234567890.1234567890'),
          '123456789012345678901234567890.123456789',
          base: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 10,
          fractionDigits: 9,
        );
        expectDecimal(
          Decimal.parse('12345678901234567890.12345678901234567890'),
          '12345678901234567890.1234567890123456789',
          base: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 20,
          fractionDigits: 19,
        );
        expectDecimal(
          Decimal.parse('1234567890.123456789012345678901234567890'),
          '1234567890.12345678901234567890123456789',
          base: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 30,
          fractionDigits: 29,
        );
        expectDecimal(
          Decimal.parse('0.1234567890123456789012345678901234567890'),
          '0.123456789012345678901234567890123456789',
          base: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 40,
          fractionDigits: 39,
        );
        expectDecimal(
          Decimal.parse('0.00000000001234567890123456789012345678901234567890'),
          '0.0000000000123456789012345678901234567890123456789',
          base: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 50,
          fractionDigits: 49,
        );

        expectDecimal(
          Decimal.parse('-1234567890123456789012345678901234567890'),
          '-1234567890123456789012345678901234567890',
          base: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-123456789012345678901234567890.1234567890'),
          '-123456789012345678901234567890.123456789',
          base: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 10,
          fractionDigits: 9,
        );
        expectDecimal(
          Decimal.parse('-12345678901234567890.12345678901234567890'),
          '-12345678901234567890.1234567890123456789',
          base: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 20,
          fractionDigits: 19,
        );
        expectDecimal(
          Decimal.parse('-1234567890.123456789012345678901234567890'),
          '-1234567890.12345678901234567890123456789',
          base: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 30,
          fractionDigits: 29,
        );
        expectDecimal(
          Decimal.parse('-0.1234567890123456789012345678901234567890'),
          '-0.123456789012345678901234567890123456789',
          base: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 40,
          fractionDigits: 39,
        );
        expectDecimal(
          Decimal.parse(
            '-0.00000000001234567890123456789012345678901234567890',
          ),
          '-0.0000000000123456789012345678901234567890123456789',
          base: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 50,
          fractionDigits: 49,
        );

        expectDecimal(
          Decimal.parse('1000000000000000000000000000000'),
          '1000000000000000000000000000000',
          base: BigInt.parse('1000000000000000000000000000000'),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('100000000000000000000.0000000000'),
          '100000000000000000000',
          base: BigInt.parse('1000000000000000000000000000000'),
          scale: 10,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('10000000000.00000000000000000000'),
          '10000000000',
          base: BigInt.parse('1000000000000000000000000000000'),
          scale: 20,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('1.000000000000000000000000000000'),
          '1',
          base: BigInt.parse('1000000000000000000000000000000'),
          scale: 30,
          fractionDigits: 0,
        );
      });
    });

    test('add', () {
      var value = Decimal(10000);
      expectDecimal(
        value += Decimal(1000),
        '11000',
        base: BigInt.from(11000),
        scale: 0,
        fractionDigits: 0,
      );
      expectDecimal(
        value += Decimal(100),
        '11100',
        base: BigInt.from(11100),
        scale: 0,
        fractionDigits: 0,
      );
      expectDecimal(
        value += Decimal(10),
        '11110',
        base: BigInt.from(11110),
        scale: 0,
        fractionDigits: 0,
      );
      expectDecimal(
        value += Decimal(10000, shiftRight: 4), // 1
        '11111',
        base: BigInt.from(111110000),
        scale: 4,
        fractionDigits: 0,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 1),
        '11111.1',
        base: BigInt.from(111111000),
        scale: 4,
        fractionDigits: 1,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 2),
        '11111.11',
        base: BigInt.from(111111100),
        scale: 4,
        fractionDigits: 2,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 3),
        '11111.111',
        base: BigInt.from(111111110),
        scale: 4,
        fractionDigits: 3,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 4),
        '11111.1111',
        base: BigInt.from(111111111),
        scale: 4,
        fractionDigits: 4,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 5),
        '11111.11111',
        base: BigInt.from(1111111111),
        scale: 5,
        fractionDigits: 5,
      );

      final values = List<Decimal>.generate(
        40,
        (index) => Decimal.fromBigInt(
          BigInt.parse('10000000000000000000'),
          shiftRight: index,
        ),
        growable: false,
      );
      value = values[0];
      for (final v in values.skip(1)) {
        value += v;
      }
      expectDecimal(
        value,
        '11111111111111111111.11111111111111111111',
        base: BigInt.parse(
          '11111111111111111111111111111111111111110000000000000000000',
        ),
        scale: 39,
        fractionDigits: 20,
      );
    });

    test('multiply', () {
      expectDecimal(
        Decimal(123, shiftRight: 2) * Decimal(456, shiftRight: 1),
        '56.088',
        base: BigInt.from(56088),
        scale: 3,
        fractionDigits: 3,
      );
      expectDecimal(
        Decimal(-123, shiftRight: 2) * Decimal(456, shiftRight: 1),
        '-56.088',
        base: BigInt.from(-56088),
        scale: 3,
        fractionDigits: 3,
      );
      expectDecimal(
        Decimal(123, shiftRight: 2) * Decimal(-456, shiftRight: 1),
        '-56.088',
        base: BigInt.from(-56088),
        scale: 3,
        fractionDigits: 3,
      );
      expectDecimal(
        Decimal(-123, shiftRight: 2) * Decimal(-456, shiftRight: 1),
        '56.088',
        base: BigInt.from(56088),
        scale: 3,
        fractionDigits: 3,
      );

      var value = Decimal.parse('123456.00');
      expectDecimal(
        value *= Decimal.parse('12345.6'),
        '1524138393.6',
        base: BigInt.from(1524138393600),
        scale: 3,
        fractionDigits: 1,
      );
      expectDecimal(
        value *= Decimal.parse('1234.56'),
        '1881640295202.816',
        base: BigInt.from(188164029520281600),
        scale: 5,
        fractionDigits: 3,
      );
      expectDecimal(
        value *= Decimal.parse('123.456'),
        '232299784284558.852096',
        base: BigInt.parse('23229978428455885209600'),
        scale: 8,
        fractionDigits: 6,
      );
      expectDecimal(
        value *= Decimal.parse('12.3456'),
        '2867880216863449.7644363776',
        base: BigInt.parse('2867880216863449764436377600'),
        scale: 12,
        fractionDigits: 10,
      );
      expectDecimal(
        value *= Decimal.parse('1.23456'),
        '3540570200530940.541182574329856',
        base: BigInt.parse('354057020053094054118257432985600'),
        scale: 17,
        fractionDigits: 15,
      );

      value = Decimal.parse('-123456');
      expectDecimal(
        value *= Decimal.parse('12345.6'),
        '-1524138393.6',
        base: BigInt.from(-15241383936),
        scale: 1,
        fractionDigits: 1,
      );
      expectDecimal(
        value *= Decimal.parse('-1234.56'),
        '1881640295202.816',
        base: BigInt.from(1881640295202816),
        scale: 3,
        fractionDigits: 3,
      );
      expectDecimal(
        value *= Decimal.parse('-123.456'),
        '-232299784284558.852096',
        base: BigInt.parse('-232299784284558852096'),
        scale: 6,
        fractionDigits: 6,
      );
      expectDecimal(
        value *= Decimal.parse('-12.3456'),
        '2867880216863449.7644363776',
        base: BigInt.parse('28678802168634497644363776'),
        scale: 10,
        fractionDigits: 10,
      );
      expectDecimal(
        value *= Decimal.parse('-1.23456'),
        '-3540570200530940.541182574329856',
        base: BigInt.parse('-3540570200530940541182574329856'),
        scale: 15,
        fractionDigits: 15,
      );
    });

    group('divide', () {
      test('success', () {
        expectDecimal(
          Decimal(24, shiftRight: 1) / Decimal(12, shiftRight: 1),
          '2',
          base: BigInt.two,
          scale: 0,
          fractionDigits: 0,
        );

        var value = Decimal.parse('3540570200530940.541182574329856');
        expectDecimal(
          value /= Decimal(123456),
          '28678802168.634497644363776',
          base: BigInt.parse('28678802168634497644363776'),
          scale: 15,
          fractionDigits: 15,
        );
        expectDecimal(
          value /= Decimal.parse('12345.6'),
          '2322997.84284558852096',
          base: BigInt.parse('232299784284558852096'),
          scale: 14,
          fractionDigits: 14,
        );
        expectDecimal(
          value /= Decimal.parse('1234.56'),
          '1881.640295202816',
          base: BigInt.from(1881640295202816),
          scale: 12,
          fractionDigits: 12,
        );
        expectDecimal(
          value /= Decimal.parse('123.456'),
          '15.241383936',
          base: BigInt.from(15241383936),
          scale: 9,
          fractionDigits: 9,
        );
        expectDecimal(
          value /= Decimal.parse('12.3456'),
          '1.23456',
          base: BigInt.from(123456),
          scale: 5,
          fractionDigits: 5,
        );
        expectDecimal(
          value /= Decimal.parse('1.23456'),
          '1',
          base: BigInt.one,
          scale: 0,
          fractionDigits: 0,
        );

        value = Decimal.one;
        for (var i = 0; i < 60; i++) {
          value /= Decimal(10);
        }
        expectDecimal(
          value,
          '0.000000000000000000000000000000000000000000000000000000000001',
          base: BigInt.from(1),
          scale: 60,
          fractionDigits: 60,
        );

        expectDecimal(
          Decimal(1) / Decimal(100),
          '0.01',
          base: BigInt.from(100),
          scale: 4,
          fractionDigits: 2,
        );
        expectDecimal(
          Decimal(1) / Decimal(1000, shiftRight: 1),
          '0.01',
          base: BigInt.from(1000),
          scale: 5,
          fractionDigits: 2,
        );
        expectDecimal(
          Decimal(1) / Decimal(10000, shiftRight: 2),
          '0.01',
          base: BigInt.from(10000),
          scale: 6,
          fractionDigits: 2,
        );

        expect(
          () => Decimal(15129, shiftRight: 1) / Decimal(86100),
          throwsA(
            predicate(
              (error) =>
                  error is DecimalDivideException &&
                  error.fraction.toString() == '123/7000',
            ),
          ),
        );
      });

      group('DecimalDivideException', () {
        test('0.5', () {
          // round
          expect(0.5.round(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), Decimal(2)).round(),
            '1',
          );

          expect((-0.5).round(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), Decimal(2)).round(),
            '-1',
          );

          expect((-1.5).round(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-3), Decimal(2)).round(),
            '-2',
          );

          // floor
          expect(0.5.floor(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), Decimal(2)).floor(),
            '0',
          );

          expect((-0.5).floor(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), Decimal(2)).floor(),
            '-1',
          );

          expect((-1.5).floor(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-3), Decimal(2)).floor(),
            '-2',
          );

          // ceil
          expect(0.5.ceil(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), Decimal(2)).ceil(),
            '1',
          );

          expect((-0.5).ceil(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), Decimal(2)).ceil(),
            '0',
          );

          expect((-1.5).ceil(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-3), Decimal(2)).ceil(),
            '-1',
          );

          // truncate
          expect(0.5.truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), Decimal(2)).truncate(),
            '0',
          );

          expect((-0.5).truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), Decimal(2)).truncate(),
            '0',
          );

          expect((-1.5).truncate(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-3), Decimal(2)).truncate(),
            '-1',
          );
        });

        test('0.1', () {
          // round
          expect(0.1.round(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), Decimal(10)).round(),
            '0',
          );

          expect((-0.1).round(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), Decimal(10)).round(),
            '0',
          );

          expect((-1.1).round(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-11), Decimal(10)).round(),
            '-1',
          );

          // floor
          expect(0.1.floor(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), Decimal(10)).floor(),
            '0',
          );

          expect((-0.1).floor(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), Decimal(10)).floor(),
            '-1',
          );

          expect((-1.1).floor(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-11), Decimal(10)).floor(),
            '-2',
          );

          // ceil
          expect(0.1.ceil(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), Decimal(10)).ceil(),
            '1',
          );

          expect((-0.1).ceil(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), Decimal(10)).ceil(),
            '0',
          );

          expect((-1.1).ceil(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-11), Decimal(10)).ceil(),
            '-1',
          );

          // truncate
          expect(0.1.truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), Decimal(10)).floor(),
            '0',
          );

          expect((-0.1).truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), Decimal(10)).truncate(),
            '0',
          );

          expect((-1.1).truncate(), -1);
          expectDecimal(
            DecimalDivideException.forTest(
              Decimal(-11),
              Decimal(10),
            ).truncate(),
            '-1',
          );
        });

        test('0.9', () {
          // round
          expect(0.9.round(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(9), Decimal(10)).round(),
            '1',
          );

          expect((-0.9).round(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-9), Decimal(10)).round(),
            '-1',
          );

          expect((-1.9).round(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-19), Decimal(10)).round(),
            '-2',
          );

          // floor
          expect(0.9.floor(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(9), Decimal(10)).floor(),
            '0',
          );

          expect((-0.9).floor(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-9), Decimal(10)).floor(),
            '-1',
          );

          expect((-1.9).floor(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-19), Decimal(10)).floor(),
            '-2',
          );

          // ceil
          expect(0.9.ceil(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(9), Decimal(10)).ceil(),
            '1',
          );

          expect((-0.9).ceil(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-9), Decimal(10)).ceil(),
            '0',
          );

          expect((-1.9).ceil(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-19), Decimal(10)).ceil(),
            '-1',
          );

          // truncate
          expect(0.9.truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(9), Decimal(10)).floor(),
            '0',
          );

          expect((-0.9).truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-9), Decimal(10)).truncate(),
            '0',
          );

          expect((-1.1).truncate(), -1);
          expectDecimal(
            DecimalDivideException.forTest(
              Decimal(-19),
              Decimal(10),
            ).truncate(),
            '-1',
          );
        });

        test('+n / +n', () {
          final v1 = Decimal(15129, shiftRight: 1);
          final v2 = Decimal(86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expect(v1 ~/ v2, BigInt.zero);
            expectDecimal(v1 % v2, '1512.9');

            // 0.017(5)
            expect((1512.9 * 1000 / 86100).floor(), 17);
            expectDecimal(e.floor(3), '0.017');

            expect((1512.9 * 1000 / 86100).round(), 18);
            expectDecimal(e.round(3), '0.018');

            expect((1512.9 * 1000 / 86100).ceil(), 18);
            expectDecimal(e.ceil(3), '0.018');

            expect((1512.9 * 1000 / 86100).truncate(), 17);
            expectDecimal(e.truncate(5), '0.01757');

            // 0.017571(4)
            expect((1512.9 * 1000000 / 86100).floor(), 17571);
            expectDecimal(e.floor(6), '0.017571');
            expect((1512.9 * 1000000 / 86100).round(), 17571);
            expectDecimal(e.round(6), '0.017571');
            expect((1512.9 * 1000000 / 86100).ceil(), 17572);
            expectDecimal(e.ceil(6), '0.017572');
            expect((1512.9 * 1000000 / 86100).truncate(), 17571);
            expectDecimal(e.truncate(6), '0.017571');

            // 0.017571428(5)
            expect((1512.9 * 1000000000 / 86100).floor(), 17571428);
            expectDecimal(e.floor(9), '0.017571428');
            expect((1512.9 * 1000000000 / 86100).round(), 17571429);
            expectDecimal(e.round(9), '0.017571429');
            expect((1512.9 * 1000000000 / 86100).ceil(), 17571429);
            expectDecimal(e.ceil(9), '0.017571429');
            expect((1512.9 * 1000000000 / 86100).truncate(), 17571428);
            expectDecimal(e.truncate(9), '0.017571428');
          }
        });

        test('+n / -n', () {
          final v1 = Decimal(15129, shiftRight: 1);
          final v2 = Decimal(-86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expect(v1 ~/ v2, BigInt.zero);
            expectDecimal(v1 % v2, '1512.9');

            // -0.017(5)
            expect((1512.9 * 1000 / -86100).floor(), -18);
            expectDecimal(e.floor(3), '-0.018');
            expect((1512.9 * 1000 / -86100).round(), -18);
            expectDecimal(e.round(3), '-0.018');
            expect((1512.9 * 1000 / -86100).ceil(), -17);
            expectDecimal(e.ceil(3), '-0.017');
            expect((1512.9 * 1000 / -86100).truncate(), -17);
            expectDecimal(e.truncate(3), '-0.017');

            // -0.017571(4)
            expect((1512.9 * 1000000 / -86100).floor(), -17572);
            expectDecimal(e.floor(6), '-0.017572');
            expect((1512.9 * 1000000 / -86100).round(), -17571);
            expectDecimal(e.round(6), '-0.017571');
            expect((1512.9 * 1000000 / -86100).ceil(), -17571);
            expectDecimal(e.ceil(6), '-0.017571');
            expect((1512.9 * 1000000 / -86100).truncate(), -17571);
            expectDecimal(e.truncate(6), '-0.017571');

            // -0.017571428(5)
            expect((1512.9 * 1000000000 / -86100).floor(), -17571429);
            expectDecimal(e.floor(9), '-0.017571429');
            expect((1512.9 * 1000000000 / -86100).round(), -17571429);
            expectDecimal(e.round(9), '-0.017571429');
            expect((1512.9 * 1000000000 / -86100).ceil(), -17571428);
            expectDecimal(e.ceil(9), '-0.017571428');
            expect((1512.9 * 1000000000 / -86100).truncate(), -17571428);
            expectDecimal(e.truncate(9), '-0.017571428');
          }
        });

        test('-n / +n', () {
          final v1 = Decimal(-15129, shiftRight: 1);
          final v2 = Decimal(86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expect(v1 ~/ v2, BigInt.zero);
            expectDecimal(v1 % v2, '84587.1');

            // -0.017(5)
            expect((-1512.9 * 1000 / 86100).floor(), -18);
            expectDecimal(e.floor(3), '-0.018');
            expect((-1512.9 * 1000 / 86100).round(), -18);
            expectDecimal(e.round(3), '-0.018');
            expect((-1512.9 * 1000 / 86100).ceil(), -17);
            expectDecimal(e.ceil(3), '-0.017');
            expect((-1512.9 * 1000 / 86100).truncate(), -17);
            expectDecimal(e.truncate(3), '-0.017');

            // -0.017571(4)
            expect((-1512.9 * 1000000 / 86100).floor(), -17572);
            expectDecimal(e.floor(6), '-0.017572');
            expect((-1512.9 * 1000000 / 86100).round(), -17571);
            expectDecimal(e.round(6), '-0.017571');
            expect((-1512.9 * 1000000 / 86100).ceil(), -17571);
            expectDecimal(e.ceil(6), '-0.017571');
            expect((-1512.9 * 1000000 / 86100).truncate(), -17571);
            expectDecimal(e.truncate(6), '-0.017571');

            // -0.017571428(5)
            expect((-1512.9 * 1000000000 / 86100).floor(), -17571429);
            expectDecimal(e.floor(9), '-0.017571429');
            expect((-1512.9 * 1000000000 / 86100).round(), -17571429);
            expectDecimal(e.round(9), '-0.017571429');
            expect((-1512.9 * 1000000000 / 86100).ceil(), -17571428);
            expectDecimal(e.ceil(9), '-0.017571428');
            expect((-1512.9 * 1000000000 / 86100).truncate(), -17571428);
            expectDecimal(e.truncate(9), '-0.017571428');
          }
        });

        test('-n / -n', () {
          final v1 = Decimal(-15129, shiftRight: 1);
          final v2 = Decimal(-86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expect(v1 ~/ v2, BigInt.zero);
            expectDecimal(v1 % v2, '84587.1');

            // 0.017(5)
            expect((-1512.9 * 1000 / -86100).floor(), 17);
            expectDecimal(e.floor(3), '0.017');
            expect((-1512.9 * 1000 / -86100).round(), 18);
            expectDecimal(e.round(3), '0.018');
            expect((-1512.9 * 1000 / -86100).ceil(), 18);
            expectDecimal(e.ceil(3), '0.018');
            expect((-1512.9 * 1000 / -86100).truncate(), 17);
            expectDecimal(e.truncate(5), '0.01757');

            // 0.017571(4)
            expect((-1512.9 * 1000000 / -86100).floor(), 17571);
            expectDecimal(e.floor(6), '0.017571');
            expect((-1512.9 * 1000000 / -86100).round(), 17571);
            expectDecimal(e.round(6), '0.017571');
            expect((-1512.9 * 1000000 / -86100).ceil(), 17572);
            expectDecimal(e.ceil(6), '0.017572');
            expect((-1512.9 * 1000000 / -86100).truncate(), 17571);
            expectDecimal(e.truncate(6), '0.017571');

            // 0.017571428(5)
            expect((-1512.9 * 1000000000 / -86100).floor(), 17571428);
            expectDecimal(e.floor(9), '0.017571428');
            expect((-1512.9 * 1000000000 / -86100).round(), 17571429);
            expectDecimal(e.round(9), '0.017571429');
            expect((-1512.9 * 1000000000 / -86100).ceil(), 17571429);
            expectDecimal(e.ceil(9), '0.017571429');
            expect((-1512.9 * 1000000000 / -86100).truncate(), 17571428);
            expectDecimal(e.truncate(9), '0.017571428');
          }
        });

        test('big / small', () {
          // 8733 / 0.0086100 = 1014285.(714285)…
          // modulo: 0.00615
          // 1014285 * 0.00861 = 8732.99385
          // 8732.99385 + 0.00615 = 8733
          var v1 = Decimal(8733);
          var v2 = Decimal.parse('0.0086100');
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expectDecimal(e.floor(), '1014285');
            expectDecimal(e.round(), '1014286');
            expectDecimal(e.ceil(), '1014286');
            expectDecimal(e.truncate(), '1014285');

            expectFraction(e.fraction, '7100000/7');
            expectDivision(
              e.quotientWithRemainder,
              '1014285 remainder 0.00615',
            );
          }

          expect(v1 ~/ v2, BigInt.from(1014285));
          expectDecimal(
            v1 % v2,
            '0.00615',
            base: BigInt.from(61500),
            scale: 7,
            fractionDigits: 5,
          );

          // +n / -n
          v1 = Decimal(8733);
          v2 = Decimal.parse('-0.0086100');
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expectDecimal(e.floor(), '-1014286');
            expectDecimal(e.round(), '-1014286');
            expectDecimal(e.ceil(), '-1014285');
            expectDecimal(e.truncate(), '-1014285');

            expectFraction(e.fraction, '-7100000/7');
            expectDivision(
              e.quotientWithRemainder,
              '-1014285 remainder 0.00615',
            );
          }

          expect(v1 ~/ v2, BigInt.from(-1014285));
          expectDecimal(
            v1 % v2,
            '0.00615',
            base: BigInt.from(61500),
            scale: 7,
            fractionDigits: 5,
          );
        });

        test('small / big', () {
          // 94833 / 86100.00 = 1.1014285(714285)…
          // modulo: 8733
          // 1 * 86100 = 86100
          // 86100 + 8733 = 94833
          final v1 = Decimal(94833);
          final v2 = Decimal.parse('86100.00');
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expectDecimal(e.floor(6), '1.101428');
            expectDecimal(e.round(6), '1.101429');
            expectDecimal(e.ceil(6), '1.101429');
            expectDecimal(e.truncate(6), '1.101428');
            expectDecimal(e.truncate(12), '1.101428571428');

            expectFraction(e.fraction, '771/700');
            expectDivision(e.quotientWithRemainder, '1 remainder 8733');
          }

          expect(v1 ~/ v2, BigInt.one);
          expectDecimal(
            v1 % v2,
            '8733',
            base: BigInt.from(873300),
            scale: 2,
            fractionDigits: 0,
          );
        });
      });
    });

    test('abs', () {
      expectDecimal(
        Decimal(2).abs(),
        '2',
        base: BigInt.from(2),
        scale: 0,
        fractionDigits: 0,
      );

      expectDecimal(
        Decimal(-2).abs(),
        '2',
        base: BigInt.from(2),
        scale: 0,
        fractionDigits: 0,
      );

      expectDecimal(
        Decimal.parse('-12345678901234567890.12345678901234567890').abs(),
        '12345678901234567890.1234567890123456789',
        base: BigInt.parse('1234567890123456789012345678901234567890'),
        scale: 20,
        fractionDigits: 19,
      );
    });

    test('pow', () {
      expectDecimal(
        Decimal(2).pow(4),
        '16',
        base: BigInt.from(16),
        scale: 0,
        fractionDigits: 0,
      );

      expectDecimal(
        Decimal(2, shiftRight: 1).pow(4),
        '0.0016',
        base: BigInt.from(16),
        scale: 4,
        fractionDigits: 4,
      );
    });

    test('toBigInt', () {
      expect(Decimal.parse('3.75').toBigInt(), BigInt.from(3));
      expect(Decimal.parse('-3.75').toBigInt(), BigInt.from(-3));

      expect(
        Decimal.parse('12345678901234567890.12345678901234567890').toBigInt(),
        BigInt.parse('12345678901234567890'),
      );
      expect(
        Decimal.parse('12345678901234567890.9').toBigInt(),
        BigInt.parse('12345678901234567890'),
      );
    });

    test('toDouble', () {
      expectDouble(Decimal.parse('0').toDouble(), 0, '0.0');
      expectDouble(Decimal.parse('0.1').toDouble(), 0.1, '0.1');
      expectDouble(Decimal.parse('0.01').toDouble(), 0.01, '0.01');
      expectDouble(Decimal.parse('0.001').toDouble(), 0.001, '0.001');
      expectDouble(Decimal.parse('0.0001').toDouble(), 0.0001, '0.0001');
      expectDouble(Decimal.parse('0.00001').toDouble(), 0.00001, '0.00001');
      expectDouble(Decimal.parse('0.000001').toDouble(), 0.000001, '0.000001');
      expectDouble(Decimal.parse('0.0000001').toDouble(), 0.0000001, '1e-7');
      expectDouble(Decimal.parse('0.00000001').toDouble(), 0.00000001, '1e-8');
      expectDouble(
        Decimal.parse('0.000000001').toDouble(),
        0.000000001,
        '1e-9',
      );
      expectDouble(
        Decimal.parse('0.0000000001').toDouble(),
        0.0000000001,
        '1e-10',
      );

      expectDouble(Decimal.parse('0.12').toDouble(), 0.12, '0.12');
      expectDouble(Decimal.parse('0.123').toDouble(), 0.123, '0.123');
      expectDouble(Decimal.parse('0.1234').toDouble(), 0.1234, '0.1234');
      expectDouble(Decimal.parse('0.12345').toDouble(), 0.12345, '0.12345');
      expectDouble(Decimal.parse('0.123456').toDouble(), 0.123456, '0.123456');
      expectDouble(
        Decimal.parse('0.1234567').toDouble(),
        0.1234567,
        '0.1234567',
      );
      expectDouble(
        Decimal.parse('0.12345678').toDouble(),
        0.12345678,
        '0.12345678',
      );
      expectDouble(
        Decimal.parse('0.123456789').toDouble(),
        0.123456789,
        '0.123456789',
      );
      expectDouble(
        Decimal.parse('0.1234567890').toDouble(),
        0.123456789,
        '0.123456789',
      );
      expectDouble(
        Decimal.parse('0.12345678901').toDouble(),
        0.12345678901,
        '0.12345678901',
      );
      expectDouble(
        Decimal.parse('0.123456789012').toDouble(),
        0.123456789012,
        '0.123456789012',
      );
      expectDouble(
        Decimal.parse('0.1234567890123').toDouble(),
        0.1234567890123,
        '0.1234567890123',
      );
      expectDouble(
        Decimal.parse('0.12345678901234').toDouble(),
        0.12345678901234,
        '0.12345678901234',
      );
      expectDouble(
        Decimal.parse('0.123456789012345').toDouble(),
        0.123456789012345,
        '0.123456789012345',
      );
      expectDouble(
        Decimal.parse('0.1234567890123456').toDouble(),
        0.1234567890123456,
        '0.1234567890123456',
      );
      // Loss of precision.
      expectDouble(
        Decimal.parse('0.12345678901234567').toDouble(),
        0.12345678901234566,
        '0.12345678901234566',
      );
      expectDouble(
        Decimal.parse('0.123456789012345678').toDouble(),
        0.12345678901234568,
        '0.12345678901234568',
      );

      // Loss of precision.

      var d = 12345678901234567890.0;
      var str = '12345678901234567000.0';
      expectDouble(
        Decimal.parse('12345678901234566144').toDouble(),
        d,
        str,
        isValid: false,
      );
      expectDouble(Decimal.parse('12345678901234566145').toDouble(), d, str);
      expectDouble(Decimal.parse('12345678901234568191').toDouble(), d, str);
      expectDouble(
        Decimal.parse('12345678901234568192').toDouble(),
        d,
        str,
        isValid: false,
      );

      d = 123456789012345678901234567890.0;
      str = '1.2345678901234568e+29';
      expectDouble(
        Decimal.parse('123456789012345669081626574847').toDouble(),
        d,
        str,
        isValid: false,
      );
      expectDouble(
        Decimal.parse('123456789012345669081626574848').toDouble(),
        d,
        str,
      );
      expectDouble(
        Decimal.parse('123456789012345686673812619264').toDouble(),
        d,
        str,
      );
      expectDouble(
        Decimal.parse('123456789012345686673812619265').toDouble(),
        d,
        str,
        isValid: false,
      );
    });

    group('compare', () {
      test('hashCode for different scales', () {
        final hashCode = Decimal(1).hashCode;
        for (var i = 1; i <= 60; i++) {
          expect(hashCode == Decimal.parse('1.${'0' * i}').hashCode, isTrue);
        }
      });

      test('operator ==', () {
        final v = Decimal(1);
        for (var i = 1; i <= 60; i++) {
          expect(v == Decimal.parse('1.${'0' * i}'), isTrue);
        }
      });

      test('compareTo', () {
        expect(
          Decimal.parse(
            '2.000000000000000000004',
          ).compareTo(Decimal.parse('2.000000000000000000009')),
          -1,
        );
        expect(
          Decimal.parse(
            '2.000000000000000000004',
          ).compareTo(Decimal.parse('2.000000000000000000001')),
          1,
        );
        expect(
          Decimal.parse(
            '2.000000000000000000004',
          ).compareTo(Decimal.parse('2.000000000000000000004')),
          0,
        );

        expect(
          Decimal.parse(
            '-2.000000000000000000004',
          ).compareTo(Decimal.parse('-2.000000000000000000009')),
          1,
        );
        expect(
          Decimal.parse(
            '-2.000000000000000000004',
          ).compareTo(Decimal.parse('-2.000000000000000000001')),
          -1,
        );
        expect(
          Decimal.parse(
            '-2.000000000000000000004',
          ).compareTo(Decimal.parse('-2.000000000000000000004')),
          0,
        );

        expect(
          Decimal(1000000000000, shiftRight: 9).compareTo(Decimal(1000)),
          0,
        );
        expect(
          Decimal(100000000000, shiftRight: 8).compareTo(Decimal(1000)),
          0,
        );
        expect(Decimal(10000000000, shiftRight: 7).compareTo(Decimal(1000)), 0);
        expect(Decimal(1000000000, shiftRight: 6).compareTo(Decimal(1000)), 0);
        expect(Decimal(100000000, shiftRight: 5).compareTo(Decimal(1000)), 0);
        expect(Decimal(10000000, shiftRight: 4).compareTo(Decimal(1000)), 0);
        expect(Decimal(1000000, shiftRight: 3).compareTo(Decimal(1000)), 0);
        expect(Decimal(100000, shiftRight: 2).compareTo(Decimal(1000)), 0);
        expect(Decimal(10000, shiftRight: 1).compareTo(Decimal(1000)), 0);
        expect(Decimal(1000).compareTo(Decimal(1000)), 0);
      });

      test('operators', () {
        expect(
          Decimal.parse('2.000000000000000000004') <
              Decimal.parse('2.000000000000000000004'),
          isFalse,
        );
        expect(
          Decimal.parse('2.000000000000000000004') <=
              Decimal.parse('2.000000000000000000004'),
          isTrue,
        );
        expect(
          Decimal.parse('2.000000000000000000004') >
              Decimal.parse('2.000000000000000000004'),
          isFalse,
        );
        expect(
          Decimal.parse('2.000000000000000000004') >=
              Decimal.parse('2.000000000000000000004'),
          isTrue,
        );

        expect(
          Decimal.parse('2.000000000000000000004') <
              Decimal.parse('2.000000000000000000001'),
          isFalse,
        );
        expect(
          Decimal.parse('2.000000000000000000004') <=
              Decimal.parse('2.000000000000000000001'),
          isFalse,
        );
        expect(
          Decimal.parse('2.000000000000000000004') >
              Decimal.parse('2.000000000000000000001'),
          isTrue,
        );
        expect(
          Decimal.parse('2.000000000000000000004') >=
              Decimal.parse('2.000000000000000000001'),
          isTrue,
        );

        expect(
          Decimal.parse('2.000000000000000000004') <
              Decimal.parse('2.000000000000000000009'),
          isTrue,
        );
        expect(
          Decimal.parse('2.000000000000000000004') <=
              Decimal.parse('2.000000000000000000009'),
          isTrue,
        );
        expect(
          Decimal.parse('2.000000000000000000004') >
              Decimal.parse('2.000000000000000000009'),
          isFalse,
        );
        expect(
          Decimal.parse('2.000000000000000000004') >=
              Decimal.parse('2.000000000000000000009'),
          isFalse,
        );
      });
    });

    test('clamp', () {
      for (final p in [
        (Decimal(5), Decimal(3), Decimal(7), '5'),
        (Decimal(3), Decimal(3), Decimal(7), '3'),
        (Decimal(1), Decimal(3), Decimal(7), '3'),
        (Decimal(7), Decimal(3), Decimal(7), '7'),
        (Decimal(9), Decimal(3), Decimal(7), '7'),
        (Decimal(-5), Decimal(-7), Decimal(-3), '-5'),
        (Decimal(-3), Decimal(-7), Decimal(-3), '-3'),
        (Decimal(-1), Decimal(-7), Decimal(-3), '-3'),
        (Decimal(-7), Decimal(-7), Decimal(-3), '-7'),
        (Decimal(-9), Decimal(-7), Decimal(-3), '-7'),
        (Decimal(500), Decimal(4) << 2, Decimal(6) << 2, '500'),
        (
          Decimal(5) >> 2,
          Decimal.parse('0.0400'),
          Decimal.parse('0.060000'),
          '0.05',
        ),
      ]) {
        expectDecimal(p.$1.clamp(p.$2, p.$3), p.$4);
      }

      expect(
        () => Decimal(0).clamp(Decimal(2), Decimal(1)),
        throwsA(
          predicate(
            (error) =>
                error is ArgumentError &&
                error.message ==
                    'The lowerLimit must be no greater than upperLimit',
          ),
        ),
      );
    });

    test('isInteger', () {
      for (final p in [
        (Decimal(0), isTrue),
        (Decimal(0) >> 10, isTrue),
        (Decimal(2), isTrue),
        (Decimal(2) >> 1, isFalse),
        (Decimal(-2), isTrue),
        (Decimal(-2) >> 1, isFalse),
        (Decimal.parse('12345678901234567890'), isTrue),
        (Decimal.parse('12345678901234567890') >> 1, isTrue),
        (Decimal.parse('12345678901234567890') >> 2, isFalse),
        (Decimal.parse('-12345678901234567890'), isTrue),
        (Decimal.parse('-12345678901234567890') >> 1, isTrue),
        (Decimal.parse('-12345678901234567890') >> 2, isFalse),
      ]) {
        expect(p.$1.isInteger, p.$2);
      }
    });

    test('toString', () {
      for (final p in [
        (Decimal(0), '0', BigInt.from(0), 0, 0),
        (Decimal(0) >> 1, '0', BigInt.from(0), 1, 0),
        (Decimal(0) >> 2, '0', BigInt.from(0), 2, 0),
        (Decimal(0) >> 3, '0', BigInt.from(0), 3, 0),
        (Decimal(1), '1', BigInt.from(1), 0, 0),
        (Decimal(1) >> 1, '0.1', BigInt.from(1), 1, 1),
        (Decimal(1) >> 2, '0.01', BigInt.from(1), 2, 2),
        (Decimal(1) >> 3, '0.001', BigInt.from(1), 3, 3),
        (Decimal(10), '10', BigInt.from(10), 0, 0),
        (Decimal(1) << 1, '10', BigInt.from(1), -1, 0),
        (Decimal(100), '100', BigInt.from(100), 0, 0),
        (Decimal(1) << 2, '100', BigInt.from(1), -2, 0),
        (Decimal(1000), '1000', BigInt.from(1000), 0, 0),
        (Decimal(1) << 3, '1000', BigInt.from(1), -3, 0),
        (Decimal(1000) >> 1, '100', BigInt.from(1000), 1, 0),
        (Decimal(1000) >> 2, '10', BigInt.from(1000), 2, 0),
        (Decimal(1000) >> 3, '1', BigInt.from(1000), 3, 0),
        (Decimal(1000) >> 4, '0.1', BigInt.from(1000), 4, 1),
        (Decimal(1000) >> 5, '0.01', BigInt.from(1000), 5, 2),
        (Decimal(1000) >> 6, '0.001', BigInt.from(1000), 6, 3),
        (Decimal(1234567890), '1234567890', BigInt.from(1234567890), 0, 0),
        (Decimal(1234567890) >> 1, '123456789', BigInt.from(1234567890), 1, 0),
        (Decimal(1234567890) >> 2, '12345678.9', BigInt.from(1234567890), 2, 1),
        (Decimal(1234567890) >> 3, '1234567.89', BigInt.from(1234567890), 3, 2),
        (Decimal(1234567890) >> 4, '123456.789', BigInt.from(1234567890), 4, 3),
        (Decimal(1234567890) >> 5, '12345.6789', BigInt.from(1234567890), 5, 4),
        (Decimal(1234567890) >> 6, '1234.56789', BigInt.from(1234567890), 6, 5),
        (Decimal(1234567890) >> 7, '123.456789', BigInt.from(1234567890), 7, 6),
        (Decimal(1234567890) >> 8, '12.3456789', BigInt.from(1234567890), 8, 7),
        (Decimal(1234567890) >> 9, '1.23456789', BigInt.from(1234567890), 9, 8),
        (
          Decimal(1234567890) >> 10,
          '0.123456789',
          BigInt.from(1234567890),
          10,
          9,
        ),
        (
          Decimal(1234567890) >> 11,
          '0.0123456789',
          BigInt.from(1234567890),
          11,
          10,
        ),
        (
          Decimal(1234567890) >> 12,
          '0.00123456789',
          BigInt.from(1234567890),
          12,
          11,
        ),
        (
          Decimal(1234567890) >> 13,
          '0.000123456789',
          BigInt.from(1234567890),
          13,
          12,
        ),
      ]) {
        expectDecimal(
          p.$1,
          p.$2,
          base: p.$3,
          scale: p.$4,
          fractionDigits: p.$5,
        );
      }
    });

    group('toStringAsFixed', () {
      test('0', () {
        expect(0.0.toStringAsFixed(0), '0');
        expect(Decimal(0).toStringAsFixed(0), '0');

        expect(0.0.toStringAsFixed(1), '0.0');
        expect(Decimal(0).toStringAsFixed(1), '0.0');

        expect(0.0.toStringAsFixed(2), '0.00');
        expect(Decimal(0).toStringAsFixed(2), '0.00');

        final v = Decimal(0, shiftRight: 2);
        expectDecimal(v, '0', base: BigInt.zero, scale: 2, fractionDigits: 0);
        expect(v.toStringAsFixed(0), '0');
        expect(v.toStringAsFixed(1), '0.0');
        expect(v.toStringAsFixed(2), '0.00');
      });

      test('small', () {
        // +n
        var v1 = 3.75;
        var v2 = Decimal.parse('3.75');
        var v3 = Decimal(37500, shiftRight: 4);
        expectDecimal(
          v3,
          '3.75',
          base: BigInt.from(37500),
          scale: 4,
          fractionDigits: 2,
        );

        expect(v1.toStringAsFixed(0), '4');
        expect(v2.toStringAsFixed(0), '4');
        expect(v3.toStringAsFixed(0), '4');

        expect(v1.toStringAsFixed(1), '3.8');
        expect(v2.toStringAsFixed(1), '3.8');
        expect(v3.toStringAsFixed(1), '3.8');

        expect(v1.toStringAsFixed(2), '3.75');
        expect(v2.toStringAsFixed(2), '3.75');
        expect(v3.toStringAsFixed(2), '3.75');

        expect(v1.toStringAsFixed(3), '3.750');
        expect(v2.toStringAsFixed(3), '3.750');
        expect(v3.toStringAsFixed(3), '3.750');

        // -n
        v1 = -3.75;
        v2 = Decimal.parse('-3.75');
        v3 = Decimal(-37500, shiftRight: 4);
        expectDecimal(
          v3,
          '-3.75',
          base: BigInt.from(-37500),
          scale: 4,
          fractionDigits: 2,
        );

        expect(v1.toStringAsFixed(0), '-4');
        expect(v2.toStringAsFixed(0), '-4');
        expect(v3.toStringAsFixed(0), '-4');

        expect(v1.toStringAsFixed(1), '-3.8');
        expect(v2.toStringAsFixed(1), '-3.8');
        expect(v3.toStringAsFixed(1), '-3.8');

        expect(v1.toStringAsFixed(2), '-3.75');
        expect(v2.toStringAsFixed(2), '-3.75');
        expect(v3.toStringAsFixed(2), '-3.75');

        expect(v1.toStringAsFixed(3), '-3.750');
        expect(v2.toStringAsFixed(3), '-3.750');
        expect(v3.toStringAsFixed(3), '-3.750');
      });

      test('big', () {
        // +n
        var v1 = Decimal.parse('12345678901234567890.12345678901234567890');
        var v2 = Decimal.fromBigInt(
          BigInt.parse('12345678901234567890123456789012345678900000000000'),
          shiftRight: 30,
        );
        expectDecimal(
          v2,
          '12345678901234567890.1234567890123456789',
          base: BigInt.parse(
            '12345678901234567890123456789012345678900000000000',
          ),
          scale: 30,
          fractionDigits: 19,
        );

        expect(v1.toStringAsFixed(0), '12345678901234567890');
        expect(v2.toStringAsFixed(0), '12345678901234567890');

        expect(v1.toStringAsFixed(10), '12345678901234567890.1234567890');
        expect(v2.toStringAsFixed(10), '12345678901234567890.1234567890');

        expect(
          v1.toStringAsFixed(20),
          '12345678901234567890.12345678901234567890',
        );
        expect(
          v2.toStringAsFixed(20),
          '12345678901234567890.12345678901234567890',
        );

        expect(
          v1.toStringAsFixed(30),
          '12345678901234567890.123456789012345678900000000000',
        );
        expect(
          v2.toStringAsFixed(30),
          '12345678901234567890.123456789012345678900000000000',
        );

        // -n
        v1 = Decimal.parse('-12345678901234567890.12345678901234567890');
        v2 = Decimal.fromBigInt(
          BigInt.parse('-12345678901234567890123456789012345678900000000000'),
          shiftRight: 30,
        );
        expectDecimal(
          v2,
          '-12345678901234567890.1234567890123456789',
          base: BigInt.parse(
            '-12345678901234567890123456789012345678900000000000',
          ),
          scale: 30,
          fractionDigits: 19,
        );

        expect(v1.toStringAsFixed(0), '-12345678901234567890');
        expect(v2.toStringAsFixed(0), '-12345678901234567890');

        expect(v1.toStringAsFixed(10), '-12345678901234567890.1234567890');
        expect(v2.toStringAsFixed(10), '-12345678901234567890.1234567890');

        expect(
          v1.toStringAsFixed(20),
          '-12345678901234567890.12345678901234567890',
        );
        expect(
          v2.toStringAsFixed(20),
          '-12345678901234567890.12345678901234567890',
        );

        expect(
          v1.toStringAsFixed(30),
          '-12345678901234567890.123456789012345678900000000000',
        );
        expect(
          v2.toStringAsFixed(30),
          '-12345678901234567890.123456789012345678900000000000',
        );
      });
    });
  });

  group('Fraction', () {
    test('create', () {
      expect(
        () => Fraction(BigInt.zero, BigInt.zero),
        throwsA(
          predicate(
            (error) =>
                error is UnsupportedError &&
                error.message == 'division by zero',
          ),
        ),
      );

      expectFraction(Fraction(BigInt.from(123), BigInt.from(123)), '1');
      expectFraction(Fraction(BigInt.from(-123), BigInt.from(123)), '-1');
      expectFraction(Fraction(BigInt.from(123), BigInt.from(-123)), '-1');
      expectFraction(Fraction(BigInt.from(-123), BigInt.from(-123)), '1');

      expectFraction(Fraction(BigInt.from(123), BigInt.from(7)), '123/7');
      expectFraction(Fraction(BigInt.from(-123), BigInt.from(7)), '-123/7');
      expectFraction(Fraction(BigInt.from(123), BigInt.from(-7)), '-123/7');
      expectFraction(Fraction(BigInt.from(-123), BigInt.from(-7)), '123/7');

      expectFraction(Fraction(BigInt.from(123), BigInt.from(1230)), '1/10');
      expectFraction(Fraction(BigInt.from(1230), BigInt.from(123)), '10');
    });

    test('parse', () {
      expect(
        () => Fraction.parse('0/0'),
        throwsA(
          predicate(
            (error) =>
                error is UnsupportedError &&
                error.message == 'division by zero',
          ),
        ),
      );

      expectFraction(Fraction.parse('123/123'), '1');
      expectFraction(Fraction.parse('-123/123'), '-1');
      expectFraction(Fraction.parse('123/-123'), '-1');
      expectFraction(Fraction.parse('-123/-123'), '1');

      expectFraction(Fraction.parse('123/7'), '123/7');
      expectFraction(Fraction.parse('-123/7'), '-123/7');
      expectFraction(Fraction.parse('123/-7'), '-123/7');
      expectFraction(Fraction.parse('-123/-7'), '123/7');

      expectFraction(Fraction.parse('123/1230'), '1/10');
      expectFraction(Fraction.parse('1230/123'), '10');
    });

    test('to Decimal', () {
      var f = Decimal.parse('1.2').divideToFraction(Decimal.parse('2.1'));
      expectFraction(f, '4/7');

      expectDecimal(f.floor(), '0');
      expectDecimal(f.floor(1), '0.5');
      expectDecimal(f.floor(2), '0.57');

      expectDecimal(f.round(), '1');
      expectDecimal(f.round(1), '0.6');
      expectDecimal(f.round(2), '0.57');

      expectDecimal(f.ceil(), '1');
      expectDecimal(f.ceil(1), '0.6');
      expectDecimal(f.ceil(2), '0.58');

      expectDecimal(f.truncate(), '0');
      expectDecimal(f.truncate(1), '0.5');
      expectDecimal(f.truncate(2), '0.57');

      f = Decimal.parse('-1.2').divideToFraction(Decimal.parse('2.1'));
      expectFraction(f, '-4/7');

      expectDecimal(f.floor(), '-1');
      expectDecimal(f.floor(1), '-0.6');
      expectDecimal(f.floor(2), '-0.58');

      expectDecimal(f.round(), '-1');
      expectDecimal(f.round(1), '-0.6');
      expectDecimal(f.round(2), '-0.57');

      expectDecimal(f.ceil(), '0');
      expectDecimal(f.ceil(1), '-0.5');
      expectDecimal(f.ceil(2), '-0.57');

      expectDecimal(f.truncate(), '0');
      expectDecimal(f.truncate(1), '-0.5');
      expectDecimal(f.truncate(2), '-0.57');
    });
  });

  group('Division', () {
    test('create', () {
      expect(
        () => Division(Decimal.zero, Decimal.zero),
        throwsA(
          predicate(
            (error) =>
                error is UnsupportedError &&
                error.message == 'division by zero',
          ),
        ),
      );

      expectDivide(Decimal(0), Decimal(7), '0');
      expectDivide(Decimal(1), Decimal(7), '0 remainder 1');
      expectDivide(Decimal(-1), Decimal(7), '0 remainder -1');
      expectDivide(Decimal(1), Decimal(-7), '0 remainder 1');
      expectDivide(Decimal(-1), Decimal(-7), '0 remainder -1');

      expectDivide(
        Decimal.parse('123.456'),
        Decimal.parse('7.7'),
        '16 remainder 0.256',
      );

      expectDivide(
        Decimal.parse('-1111111111.1111111111'),
        Decimal.parse('1234567.1234567'),
        '-900 remainder -700.0000811111',
      );

      expectDivide(
        Decimal.parse('12345678901234567890.1234567890'),
        Decimal.parse('-333333333333333333.1'),
        '-37 remainder 12345567901234565.423456789',
      );

      expectDivide(
        Decimal.parse('12345678901234567890.1234567890') -
            Decimal.parse('12345567901234565.423456789'),
        Decimal.parse('-333333333333333333.1'),
        '-37',
      );

      expectDivide(
        Decimal.parse('-12345678901234567890.1234567890'),
        Decimal.parse('333333333333333333.1'),
        '-37 remainder -12345567901234565.423456789',
      );

      expectDivide(
        Decimal.parse('-12345678901234567890.1234567890') -
            Decimal.parse('-12345567901234565.423456789'),
        Decimal.parse('333333333333333333.1'),
        '-37',
      );
    });
  });

  group('ShortDecimal', () {
    group('parse', () {
      test('0', () {
        for (final p in [
          (ShortDecimal.parse('0'), '0', 0, 0, 0),
          (ShortDecimal.parse('0.0'), '0', 0, 0, 0),
          (ShortDecimal.parse('.0'), '0', 0, 0, 0),
          (ShortDecimal.parse('00000.00000'), '0', 0, 0, 0),
          (ShortDecimal.parse(' 0'), '0', 0, 0, 0),
          (ShortDecimal.parse('0 '), '0', 0, 0, 0),
          (ShortDecimal.parse(' 0 '), '0', 0, 0, 0),
          (ShortDecimal.parse(' 0.0'), '0', 0, 0, 0),
          (ShortDecimal.parse('0.0 '), '0', 0, 0, 0),
          (ShortDecimal.parse(' 0.0 '), '0', 0, 0, 0),
          (ShortDecimal(0) >> 10, '0', 0, 0, 0),
          (ShortDecimal(0) << 10, '0', 0, 0, 0),
          (ShortDecimal.parse('-0'), '0', 0, 0, 0),
          (ShortDecimal.parse('-0.0'), '0', 0, 0, 0),
          (ShortDecimal.parse('-.0'), '0', 0, 0, 0),
          (ShortDecimal.parse('-00000.00000'), '0', 0, 0, 0),
        ]) {
          expectShortDecimal(
            p.$1,
            p.$2,
            base: p.$3,
            scale: p.$4,
            fractionDigits: p.$5,
          );
        }

        expect(
          () => ShortDecimal.parse('0.'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $ShortDecimal: 0.',
            ),
          ),
        );

        expect(
          () => ShortDecimal.parse('0.0.'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $ShortDecimal: 0.0.',
            ),
          ),
        );

        expect(
          () => ShortDecimal.parse('0..0'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $ShortDecimal: 0..0',
            ),
          ),
        );
      });

      test('1', () {
        expectShortDecimal(
          ShortDecimal.parse('1'),
          '1',
          base: 1,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('0.1'),
          '0.1',
          base: 1,
          scale: 1,
          fractionDigits: 1,
        );
        expectShortDecimal(
          ShortDecimal.parse('.1'),
          '0.1',
          base: 1,
          scale: 1,
          fractionDigits: 1,
        );
        expectShortDecimal(
          ShortDecimal.parse('0.01'),
          '0.01',
          base: 1,
          scale: 2,
          fractionDigits: 2,
        );
        expectShortDecimal(
          ShortDecimal.parse('0.001'),
          '0.001',
          base: 1,
          scale: 3,
          fractionDigits: 3,
        );
        expectShortDecimal(
          ShortDecimal.parse('1.0'),
          '1',
          base: 1,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('1.00'),
          '1',
          base: 1,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('1.000'),
          '1',
          base: 1,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('10'),
          '10',
          base: 1,
          scale: -1,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('100'),
          '100',
          base: 1,
          scale: -2,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('1000'),
          '1000',
          base: 1,
          scale: -3,
          fractionDigits: 0,
        );

        expect(
          () => ShortDecimal.parse('0.1 0'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $ShortDecimal: 0.1 0',
            ),
          ),
        );

        expect(
          () => ShortDecimal.parse('1..0'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $ShortDecimal: 1..0',
            ),
          ),
        );

        expect(
          () => ShortDecimal.parse('1 000'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $ShortDecimal: 1 000',
            ),
          ),
        );

        expect(
          () => ShortDecimal.parse('1,000.0'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse $ShortDecimal: 1,000.0',
            ),
          ),
        );

        expect(
          () => ShortDecimal.parse("1'000.0"),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == "Could not parse $ShortDecimal: 1'000.0",
            ),
          ),
        );

        expectShortDecimal(
          ShortDecimal.parse('-1'),
          '-1',
          base: -1,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('-0.1'),
          '-0.1',
          base: -1,
          scale: 1,
          fractionDigits: 1,
        );
        expectShortDecimal(
          ShortDecimal.parse('-0.01'),
          '-0.01',
          base: -1,
          scale: 2,
          fractionDigits: 2,
        );
        expectShortDecimal(
          ShortDecimal.parse('-0.001'),
          '-0.001',
          base: -1,
          scale: 3,
          fractionDigits: 3,
        );
        expectShortDecimal(
          ShortDecimal.parse('-1.0'),
          '-1',
          base: -1,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('-1.00'),
          '-1',
          base: -1,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('-1.000'),
          '-1',
          base: -1,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('-10'),
          '-10',
          base: -1,
          scale: -1,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('-100'),
          '-100',
          base: -1,
          scale: -2,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('-1000'),
          '-1000',
          base: -1,
          scale: -3,
          fractionDigits: 0,
        );
      });

      test('int', () {
        expectShortDecimal(
          ShortDecimal.parse('1234567890'),
          '1234567890',
          base: 123456789,
          scale: -1,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('123456789.0'),
          '123456789',
          base: 123456789,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('12345678.90'),
          '12345678.9',
          base: 123456789,
          scale: 1,
          fractionDigits: 1,
        );
        expectShortDecimal(
          ShortDecimal.parse('1234567.890'),
          '1234567.89',
          base: 123456789,
          scale: 2,
          fractionDigits: 2,
        );
        expectShortDecimal(
          ShortDecimal.parse('123456.7890'),
          '123456.789',
          base: 123456789,
          scale: 3,
          fractionDigits: 3,
        );
        expectShortDecimal(
          ShortDecimal.parse('12345.67890'),
          '12345.6789',
          base: 123456789,
          scale: 4,
          fractionDigits: 4,
        );
        expectShortDecimal(
          ShortDecimal.parse('1234.567890'),
          '1234.56789',
          base: 123456789,
          scale: 5,
          fractionDigits: 5,
        );
        expectShortDecimal(
          ShortDecimal.parse('123.4567890'),
          '123.456789',
          base: 123456789,
          scale: 6,
          fractionDigits: 6,
        );
        expectShortDecimal(
          ShortDecimal.parse('12.34567890'),
          '12.3456789',
          base: 123456789,
          scale: 7,
          fractionDigits: 7,
        );
        expectShortDecimal(
          ShortDecimal.parse('1.234567890'),
          '1.23456789',
          base: 123456789,
          scale: 8,
          fractionDigits: 8,
        );
        expectShortDecimal(
          ShortDecimal.parse('0.1234567890'),
          '0.123456789',
          base: 123456789,
          scale: 9,
          fractionDigits: 9,
        );
        expectShortDecimal(
          ShortDecimal.parse('0.01234567890'),
          '0.0123456789',
          base: 123456789,
          scale: 10,
          fractionDigits: 10,
        );
        expectShortDecimal(
          ShortDecimal.parse('0.001234567890'),
          '0.00123456789',
          base: 123456789,
          scale: 11,
          fractionDigits: 11,
        );
        expectShortDecimal(
          ShortDecimal.parse('0.0001234567890'),
          '0.000123456789',
          base: 123456789,
          scale: 12,
          fractionDigits: 12,
        );

        expectShortDecimal(
          ShortDecimal.parse('-1234567890'),
          '-1234567890',
          base: -123456789,
          scale: -1,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('-123456789.0'),
          '-123456789',
          base: -123456789,
          scale: 0,
          fractionDigits: 0,
        );
        expectShortDecimal(
          ShortDecimal.parse('-12345678.90'),
          '-12345678.9',
          base: -123456789,
          scale: 1,
          fractionDigits: 1,
        );
        expectShortDecimal(
          ShortDecimal.parse('-1234567.890'),
          '-1234567.89',
          base: -123456789,
          scale: 2,
          fractionDigits: 2,
        );
        expectShortDecimal(
          ShortDecimal.parse('-123456.7890'),
          '-123456.789',
          base: -123456789,
          scale: 3,
          fractionDigits: 3,
        );
        expectShortDecimal(
          ShortDecimal.parse('-12345.67890'),
          '-12345.6789',
          base: -123456789,
          scale: 4,
          fractionDigits: 4,
        );
        expectShortDecimal(
          ShortDecimal.parse('-1234.567890'),
          '-1234.56789',
          base: -123456789,
          scale: 5,
          fractionDigits: 5,
        );
        expectShortDecimal(
          ShortDecimal.parse('-123.4567890'),
          '-123.456789',
          base: -123456789,
          scale: 6,
          fractionDigits: 6,
        );
        expectShortDecimal(
          ShortDecimal.parse('-12.34567890'),
          '-12.3456789',
          base: -123456789,
          scale: 7,
          fractionDigits: 7,
        );
        expectShortDecimal(
          ShortDecimal.parse('-1.234567890'),
          '-1.23456789',
          base: -123456789,
          scale: 8,
          fractionDigits: 8,
        );
        expectShortDecimal(
          ShortDecimal.parse('-0.1234567890'),
          '-0.123456789',
          base: -123456789,
          scale: 9,
          fractionDigits: 9,
        );
        expectShortDecimal(
          ShortDecimal.parse('-0.01234567890'),
          '-0.0123456789',
          base: -123456789,
          scale: 10,
          fractionDigits: 10,
        );
        expectShortDecimal(
          ShortDecimal.parse('-0.001234567890'),
          '-0.00123456789',
          base: -123456789,
          scale: 11,
          fractionDigits: 11,
        );
        expectShortDecimal(
          ShortDecimal.parse('-0.0001234567890'),
          '-0.000123456789',
          base: -123456789,
          scale: 12,
          fractionDigits: 12,
        );

        expectShortDecimal(
          ShortDecimal.parse('-9223372036854775808'),
          '-9223372036854775808',
          base: -9223372036854775808,
          scale: 0,
          fractionDigits: 0,
        );

        expectShortDecimal(
          ShortDecimal.parse('-922337203685477580.8'),
          '-922337203685477580.8',
          base: -9223372036854775808,
          scale: 1,
          fractionDigits: 1,
        );
      });
    });

    test('add', () {
      var value = ShortDecimal.zero;
      expectShortDecimal(
        value += ShortDecimal(10000000),
        '10000000',
        base: 1,
        scale: -7,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(1000000),
        '11000000',
        base: 11,
        scale: -6,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(100000),
        '11100000',
        base: 111,
        scale: -5,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(10000),
        '11110000',
        base: 1111,
        scale: -4,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(1000),
        '11111000',
        base: 11111,
        scale: -3,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(100),
        '11111100',
        base: 111111,
        scale: -2,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(10),
        '11111110',
        base: 1111111,
        scale: -1,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(1),
        '11111111',
        base: 11111111,
        scale: 0,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 1),
        '11111111.1',
        base: 111111111,
        scale: 1,
        fractionDigits: 1,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 2),
        '11111111.11',
        base: 1111111111,
        scale: 2,
        fractionDigits: 2,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 3),
        '11111111.111',
        base: 11111111111,
        scale: 3,
        fractionDigits: 3,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 4),
        '11111111.1111',
        base: 111111111111,
        scale: 4,
        fractionDigits: 4,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 5),
        '11111111.11111',
        base: 1111111111111,
        scale: 5,
        fractionDigits: 5,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 6),
        '11111111.111111',
        base: 11111111111111,
        scale: 6,
        fractionDigits: 6,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 7),
        '11111111.1111111',
        base: 111111111111111,
        scale: 7,
        fractionDigits: 7,
      );
      expectShortDecimal(
        value += ShortDecimal(1, shiftRight: 8),
        '11111111.11111111',
        base: 1111111111111111,
        scale: 8,
        fractionDigits: 8,
      );

      final values = List<ShortDecimal>.generate(
        16,
        (index) => ShortDecimal(10000000, shiftRight: index),
        growable: false,
      );
      value = values[0];
      for (final v in values.skip(1)) {
        value += v;
      }
      expectShortDecimal(
        value,
        '11111111.11111111',
        base: 1111111111111111,
        scale: 8,
        fractionDigits: 8,
      );
    });

    test('multiply', () {
      expectShortDecimal(
        ShortDecimal(123, shiftRight: 2) * ShortDecimal(456, shiftRight: 1),
        '56.088',
        base: 56088,
        scale: 3,
        fractionDigits: 3,
      );
      expectShortDecimal(
        ShortDecimal(-123, shiftRight: 2) * ShortDecimal(456, shiftRight: 1),
        '-56.088',
        base: -56088,
        scale: 3,
        fractionDigits: 3,
      );
      expectShortDecimal(
        ShortDecimal(123, shiftRight: 2) * ShortDecimal(-456, shiftRight: 1),
        '-56.088',
        base: -56088,
        scale: 3,
        fractionDigits: 3,
      );
      expectShortDecimal(
        ShortDecimal(-123, shiftRight: 2) * ShortDecimal(-456, shiftRight: 1),
        '56.088',
        base: 56088,
        scale: 3,
        fractionDigits: 3,
      );

      // big positive values
      var m = ShortDecimal(123000);
      var value = ShortDecimal.one;
      expectShortDecimal(
        value *= m,
        '123000',
        base: 123,
        scale: -3,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '15129000000',
        base: 15129,
        scale: -6,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '1860867000000000',
        base: 1860867,
        scale: -9,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '228886641000000000000',
        base: 228886641,
        scale: -12,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '28153056843000000000000000',
        base: 28153056843,
        scale: -15,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '3462825991689000000000000000000',
        base: 3462825991689,
        scale: -18,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '425927596977747000000000000000000000',
        base: 425927596977747,
        scale: -21,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '52389094428262881000000000000000000000000',
        base: 52389094428262881,
        scale: -24,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '6443858614676334363000000000000000000000000000',
        base: 6443858614676334363,
        scale: -27,
        fractionDigits: 0,
      );

      // big negative values
      m = ShortDecimal(-123000);
      value = ShortDecimal.one;
      expectShortDecimal(
        value *= m,
        '-123000',
        base: -123,
        scale: -3,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '15129000000',
        base: 15129,
        scale: -6,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '-1860867000000000',
        base: -1860867,
        scale: -9,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '228886641000000000000',
        base: 228886641,
        scale: -12,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '-28153056843000000000000000',
        base: -28153056843,
        scale: -15,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '3462825991689000000000000000000',
        base: 3462825991689,
        scale: -18,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '-425927596977747000000000000000000000',
        base: -425927596977747,
        scale: -21,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '52389094428262881000000000000000000000000',
        base: 52389094428262881,
        scale: -24,
        fractionDigits: 0,
      );
      expectShortDecimal(
        value *= m,
        '-6443858614676334363000000000000000000000000000',
        base: -6443858614676334363,
        scale: -27,
        fractionDigits: 0,
      );

      // small positive values
      m = ShortDecimal(123, shiftRight: 4);
      value = ShortDecimal.one;
      expectShortDecimal(
        value *= m,
        '0.0123',
        base: 123,
        scale: 4,
        fractionDigits: 4,
      );
      expectShortDecimal(
        value *= m,
        '0.00015129',
        base: 15129,
        scale: 8,
        fractionDigits: 8,
      );
      expectShortDecimal(
        value *= m,
        '0.000001860867',
        base: 1860867,
        scale: 12,
        fractionDigits: 12,
      );
      expectShortDecimal(
        value *= m,
        '0.0000000228886641',
        base: 228886641,
        scale: 16,
        fractionDigits: 16,
      );
      expectShortDecimal(
        value *= m,
        '0.00000000028153056843',
        base: 28153056843,
        scale: 20,
        fractionDigits: 20,
      );
      expectShortDecimal(
        value *= m,
        '0.000000000003462825991689',
        base: 3462825991689,
        scale: 24,
        fractionDigits: 24,
      );
      expectShortDecimal(
        value *= m,
        '0.0000000000000425927596977747',
        base: 425927596977747,
        scale: 28,
        fractionDigits: 28,
      );
      expectShortDecimal(
        value *= m,
        '0.00000000000000052389094428262881',
        base: 52389094428262881,
        scale: 32,
        fractionDigits: 32,
      );
      expectShortDecimal(
        value *= m,
        '0.000000000000000006443858614676334363',
        base: 6443858614676334363,
        scale: 36,
        fractionDigits: 36,
      );

      // small negative values
      m = ShortDecimal(-123, shiftRight: 4);
      value = ShortDecimal.one;
      expectShortDecimal(
        value *= m,
        '-0.0123',
        base: -123,
        scale: 4,
        fractionDigits: 4,
      );
      expectShortDecimal(
        value *= m,
        '0.00015129',
        base: 15129,
        scale: 8,
        fractionDigits: 8,
      );
      expectShortDecimal(
        value *= m,
        '-0.000001860867',
        base: -1860867,
        scale: 12,
        fractionDigits: 12,
      );
      expectShortDecimal(
        value *= m,
        '0.0000000228886641',
        base: 228886641,
        scale: 16,
        fractionDigits: 16,
      );
      expectShortDecimal(
        value *= m,
        '-0.00000000028153056843',
        base: -28153056843,
        scale: 20,
        fractionDigits: 20,
      );
      expectShortDecimal(
        value *= m,
        '0.000000000003462825991689',
        base: 3462825991689,
        scale: 24,
        fractionDigits: 24,
      );
      expectShortDecimal(
        value *= m,
        '-0.0000000000000425927596977747',
        base: -425927596977747,
        scale: 28,
        fractionDigits: 28,
      );
      expectShortDecimal(
        value *= m,
        '0.00000000000000052389094428262881',
        base: 52389094428262881,
        scale: 32,
        fractionDigits: 32,
      );
      expectShortDecimal(
        value *= m,
        '-0.000000000000000006443858614676334363',
        base: -6443858614676334363,
        scale: 36,
        fractionDigits: 36,
      );
    });

    group('divide', () {
      test('success', () {
        expectShortDecimal(
          ShortDecimal(24, shiftRight: 1) / ShortDecimal(12, shiftRight: 1),
          '2',
          base: 2,
          scale: 0,
          fractionDigits: 0,
        );

        var value = ShortDecimal(6443858614676334363, shiftLeft: 27);
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '52389094428262881000000000000000000000000',
          base: 52389094428262881,
          scale: -24,
          fractionDigits: 0,
        );
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '425927596977747000000000000000000000',
          base: 425927596977747,
          scale: -21,
          fractionDigits: 0,
        );
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '3462825991689000000000000000000',
          base: 3462825991689,
          scale: -18,
          fractionDigits: 0,
        );
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '28153056843000000000000000',
          base: 28153056843,
          scale: -15,
          fractionDigits: 0,
        );
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '228886641000000000000',
          base: 228886641,
          scale: -12,
          fractionDigits: 0,
        );
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '1860867000000000',
          base: 1860867,
          scale: -9,
          fractionDigits: 0,
        );
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '15129000000',
          base: 15129,
          scale: -6,
          fractionDigits: 0,
        );
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '123000',
          base: 123,
          scale: -3,
          fractionDigits: 0,
        );
        expectShortDecimal(
          value /= ShortDecimal(123000),
          '1',
          base: 1,
          scale: 0,
          fractionDigits: 0,
        );

        value = ShortDecimal.one;
        for (var i = 0; i < 60; i++) {
          value /= ShortDecimal(10);
        }
        expectShortDecimal(
          value,
          '0.000000000000000000000000000000000000000000000000000000000001',
          base: 1,
          scale: 60,
          fractionDigits: 60,
        );

        expect(
          () => ShortDecimal(15129, shiftRight: 1) / ShortDecimal(86100),
          throwsA(
            predicate(
              (error) =>
                  error is ShortDecimalDivideException &&
                  error.fraction.toString() == '123/7000',
            ),
          ),
        );
      });

      group('ShortDecimalDivideException', () {
        test('0.5', () {
          // round
          expect(0.5.round(), 1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(1),
              ShortDecimal(2),
            ).round(),
            '1',
          );

          expect((-0.5).round(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-1),
              ShortDecimal(2),
            ).round(),
            '-1',
          );

          expect((-1.5).round(), -2);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-3),
              ShortDecimal(2),
            ).round(),
            '-2',
          );

          // floor
          expect(0.5.floor(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(1),
              ShortDecimal(2),
            ).floor(),
            '0',
          );

          expect((-0.5).floor(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-1),
              ShortDecimal(2),
            ).floor(),
            '-1',
          );

          expect((-1.5).floor(), -2);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-3),
              ShortDecimal(2),
            ).floor(),
            '-2',
          );

          // ceil
          expect(0.5.ceil(), 1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(1),
              ShortDecimal(2),
            ).ceil(),
            '1',
          );

          expect((-0.5).ceil(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-1),
              ShortDecimal(2),
            ).ceil(),
            '0',
          );

          expect((-1.5).ceil(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-3),
              ShortDecimal(2),
            ).ceil(),
            '-1',
          );

          // truncate
          expect(0.5.truncate(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(1),
              ShortDecimal(2),
            ).truncate(),
            '0',
          );

          expect((-0.5).truncate(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-1),
              ShortDecimal(2),
            ).truncate(),
            '0',
          );

          expect((-1.5).truncate(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-3),
              ShortDecimal(2),
            ).truncate(),
            '-1',
          );
        });

        test('0.1', () {
          // round
          expect(0.1.round(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(1),
              ShortDecimal(10),
            ).round(),
            '0',
          );

          expect((-0.1).round(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-1),
              ShortDecimal(10),
            ).round(),
            '0',
          );

          expect((-1.1).round(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-11),
              ShortDecimal(10),
            ).round(),
            '-1',
          );

          // floor
          expect(0.1.floor(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(1),
              ShortDecimal(10),
            ).floor(),
            '0',
          );

          expect((-0.1).floor(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-1),
              ShortDecimal(10),
            ).floor(),
            '-1',
          );

          expect((-1.1).floor(), -2);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-11),
              ShortDecimal(10),
            ).floor(),
            '-2',
          );

          // ceil
          expect(0.1.ceil(), 1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(1),
              ShortDecimal(10),
            ).ceil(),
            '1',
          );

          expect((-0.1).ceil(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-1),
              ShortDecimal(10),
            ).ceil(),
            '0',
          );

          expect((-1.1).ceil(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-11),
              ShortDecimal(10),
            ).ceil(),
            '-1',
          );

          // truncate
          expect(0.1.truncate(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(1),
              ShortDecimal(10),
            ).floor(),
            '0',
          );

          expect((-0.1).truncate(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-1),
              ShortDecimal(10),
            ).truncate(),
            '0',
          );

          expect((-1.1).truncate(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-11),
              ShortDecimal(10),
            ).truncate(),
            '-1',
          );
        });

        test('0.9', () {
          // round
          expect(0.9.round(), 1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(9),
              ShortDecimal(10),
            ).round(),
            '1',
          );

          expect((-0.9).round(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-9),
              ShortDecimal(10),
            ).round(),
            '-1',
          );

          expect((-1.9).round(), -2);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-19),
              ShortDecimal(10),
            ).round(),
            '-2',
          );

          // floor
          expect(0.9.floor(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(9),
              ShortDecimal(10),
            ).floor(),
            '0',
          );

          expect((-0.9).floor(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-9),
              ShortDecimal(10),
            ).floor(),
            '-1',
          );

          expect((-1.9).floor(), -2);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-19),
              ShortDecimal(10),
            ).floor(),
            '-2',
          );

          // ceil
          expect(0.9.ceil(), 1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(9),
              ShortDecimal(10),
            ).ceil(),
            '1',
          );

          expect((-0.9).ceil(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-9),
              ShortDecimal(10),
            ).ceil(),
            '0',
          );

          expect((-1.9).ceil(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-19),
              ShortDecimal(10),
            ).ceil(),
            '-1',
          );

          // truncate
          expect(0.9.truncate(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(9),
              ShortDecimal(10),
            ).floor(),
            '0',
          );

          expect((-0.9).truncate(), 0);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-9),
              ShortDecimal(10),
            ).truncate(),
            '0',
          );

          expect((-1.1).truncate(), -1);
          expectShortDecimal(
            ShortDecimalDivideException.forTest(
              ShortDecimal(-19),
              ShortDecimal(10),
            ).truncate(),
            '-1',
          );
        });

        test('+n / +n', () {
          final v1 = ShortDecimal(15129, shiftRight: 1);
          final v2 = ShortDecimal(86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on ShortDecimalDivideException catch (e) {
            expect(v1 ~/ v2, 0);
            expectShortDecimal(v1 % v2, '1512.9');

            // 0.017(5)
            expect((1512.9 * 1000 / 86100).floor(), 17);
            expectShortDecimal(e.floor(3), '0.017');

            expect((1512.9 * 1000 / 86100).round(), 18);
            expectShortDecimal(e.round(3), '0.018');

            expect((1512.9 * 1000 / 86100).ceil(), 18);
            expectShortDecimal(e.ceil(3), '0.018');

            expect((1512.9 * 1000 / 86100).truncate(), 17);
            expectShortDecimal(e.truncate(5), '0.01757');

            // 0.017571(4)
            expect((1512.9 * 1000000 / 86100).floor(), 17571);
            expectShortDecimal(e.floor(6), '0.017571');
            expect((1512.9 * 1000000 / 86100).round(), 17571);
            expectShortDecimal(e.round(6), '0.017571');
            expect((1512.9 * 1000000 / 86100).ceil(), 17572);
            expectShortDecimal(e.ceil(6), '0.017572');
            expect((1512.9 * 1000000 / 86100).truncate(), 17571);
            expectShortDecimal(e.truncate(6), '0.017571');

            // 0.017571428(5)
            expect((1512.9 * 1000000000 / 86100).floor(), 17571428);
            expectShortDecimal(e.floor(9), '0.017571428');
            expect((1512.9 * 1000000000 / 86100).round(), 17571429);
            expectShortDecimal(e.round(9), '0.017571429');
            expect((1512.9 * 1000000000 / 86100).ceil(), 17571429);
            expectShortDecimal(e.ceil(9), '0.017571429');
            expect((1512.9 * 1000000000 / 86100).truncate(), 17571428);
            expectShortDecimal(e.truncate(9), '0.017571428');
          }
        });

        test('+n / -n', () {
          final v1 = ShortDecimal(15129, shiftRight: 1);
          final v2 = ShortDecimal(-86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on ShortDecimalDivideException catch (e) {
            expect(v1 ~/ v2, 0);
            expectShortDecimal(v1 % v2, '1512.9');

            // -0.017(5)
            expect((1512.9 * 1000 / -86100).floor(), -18);
            expectShortDecimal(e.floor(3), '-0.018');
            expect((1512.9 * 1000 / -86100).round(), -18);
            expectShortDecimal(e.round(3), '-0.018');
            expect((1512.9 * 1000 / -86100).ceil(), -17);
            expectShortDecimal(e.ceil(3), '-0.017');
            expect((1512.9 * 1000 / -86100).truncate(), -17);
            expectShortDecimal(e.truncate(3), '-0.017');

            // -0.017571(4)
            expect((1512.9 * 1000000 / -86100).floor(), -17572);
            expectShortDecimal(e.floor(6), '-0.017572');
            expect((1512.9 * 1000000 / -86100).round(), -17571);
            expectShortDecimal(e.round(6), '-0.017571');
            expect((1512.9 * 1000000 / -86100).ceil(), -17571);
            expectShortDecimal(e.ceil(6), '-0.017571');
            expect((1512.9 * 1000000 / -86100).truncate(), -17571);
            expectShortDecimal(e.truncate(6), '-0.017571');

            // -0.017571428(5)
            expect((1512.9 * 1000000000 / -86100).floor(), -17571429);
            expectShortDecimal(e.floor(9), '-0.017571429');
            expect((1512.9 * 1000000000 / -86100).round(), -17571429);
            expectShortDecimal(e.round(9), '-0.017571429');
            expect((1512.9 * 1000000000 / -86100).ceil(), -17571428);
            expectShortDecimal(e.ceil(9), '-0.017571428');
            expect((1512.9 * 1000000000 / -86100).truncate(), -17571428);
            expectShortDecimal(e.truncate(9), '-0.017571428');
          }
        });

        test('-n / +n', () {
          final v1 = ShortDecimal(-15129, shiftRight: 1);
          final v2 = ShortDecimal(86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on ShortDecimalDivideException catch (e) {
            expect(v1 ~/ v2, 0);
            expectShortDecimal(v1 % v2, '84587.1');

            // -0.017(5)
            expect((-1512.9 * 1000 / 86100).floor(), -18);
            expectShortDecimal(e.floor(3), '-0.018');
            expect((-1512.9 * 1000 / 86100).round(), -18);
            expectShortDecimal(e.round(3), '-0.018');
            expect((-1512.9 * 1000 / 86100).ceil(), -17);
            expectShortDecimal(e.ceil(3), '-0.017');
            expect((-1512.9 * 1000 / 86100).truncate(), -17);
            expectShortDecimal(e.truncate(3), '-0.017');

            // -0.017571(4)
            expect((-1512.9 * 1000000 / 86100).floor(), -17572);
            expectShortDecimal(e.floor(6), '-0.017572');
            expect((-1512.9 * 1000000 / 86100).round(), -17571);
            expectShortDecimal(e.round(6), '-0.017571');
            expect((-1512.9 * 1000000 / 86100).ceil(), -17571);
            expectShortDecimal(e.ceil(6), '-0.017571');
            expect((-1512.9 * 1000000 / 86100).truncate(), -17571);
            expectShortDecimal(e.truncate(6), '-0.017571');

            // -0.017571428(5)
            expect((-1512.9 * 1000000000 / 86100).floor(), -17571429);
            expectShortDecimal(e.floor(9), '-0.017571429');
            expect((-1512.9 * 1000000000 / 86100).round(), -17571429);
            expectShortDecimal(e.round(9), '-0.017571429');
            expect((-1512.9 * 1000000000 / 86100).ceil(), -17571428);
            expectShortDecimal(e.ceil(9), '-0.017571428');
            expect((-1512.9 * 1000000000 / 86100).truncate(), -17571428);
            expectShortDecimal(e.truncate(9), '-0.017571428');
          }
        });

        test('-n / -n', () {
          final v1 = ShortDecimal(-15129, shiftRight: 1);
          final v2 = ShortDecimal(-86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on ShortDecimalDivideException catch (e) {
            expect(v1 ~/ v2, 0);
            expectShortDecimal(v1 % v2, '84587.1');

            // 0.017(5)
            expect((-1512.9 * 1000 / -86100).floor(), 17);
            expectShortDecimal(e.floor(3), '0.017');
            expect((-1512.9 * 1000 / -86100).round(), 18);
            expectShortDecimal(e.round(3), '0.018');
            expect((-1512.9 * 1000 / -86100).ceil(), 18);
            expectShortDecimal(e.ceil(3), '0.018');
            expect((-1512.9 * 1000 / -86100).truncate(), 17);
            expectShortDecimal(e.truncate(5), '0.01757');

            // 0.017571(4)
            expect((-1512.9 * 1000000 / -86100).floor(), 17571);
            expectShortDecimal(e.floor(6), '0.017571');
            expect((-1512.9 * 1000000 / -86100).round(), 17571);
            expectShortDecimal(e.round(6), '0.017571');
            expect((-1512.9 * 1000000 / -86100).ceil(), 17572);
            expectShortDecimal(e.ceil(6), '0.017572');
            expect((-1512.9 * 1000000 / -86100).truncate(), 17571);
            expectShortDecimal(e.truncate(6), '0.017571');

            // 0.017571428(5)
            expect((-1512.9 * 1000000000 / -86100).floor(), 17571428);
            expectShortDecimal(e.floor(9), '0.017571428');
            expect((-1512.9 * 1000000000 / -86100).round(), 17571429);
            expectShortDecimal(e.round(9), '0.017571429');
            expect((-1512.9 * 1000000000 / -86100).ceil(), 17571429);
            expectShortDecimal(e.ceil(9), '0.017571429');
            expect((-1512.9 * 1000000000 / -86100).truncate(), 17571428);
            expectShortDecimal(e.truncate(9), '0.017571428');
          }
        });

        test('big / small', () {
          // 8733 / 0.0086100 = 1014285.(714285)…
          // modulo: 0.00615
          // 1014285 * 0.00861 = 8732.99385
          // 8732.99385 + 0.00615 = 8733
          var v1 = ShortDecimal(8733);
          var v2 = ShortDecimal.parse('0.0086100');
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on ShortDecimalDivideException catch (e) {
            expectShortDecimal(e.floor(), '1014285');
            expectShortDecimal(e.round(), '1014286');
            expectShortDecimal(e.ceil(), '1014286');
            expectShortDecimal(e.truncate(), '1014285');

            expectShortFraction(e.fraction, '7100000/7');
            expectShortDivision(
              e.quotientWithRemainder,
              '1014285 remainder 0.00615',
            );
          }

          expect(v1 ~/ v2, 1014285);
          expectShortDecimal(
            v1 % v2,
            '0.00615',
            base: 615,
            scale: 5,
            fractionDigits: 5,
          );

          // +n / -n
          v1 = ShortDecimal(8733);
          v2 = ShortDecimal.parse('-0.0086100');
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on ShortDecimalDivideException catch (e) {
            expectShortDecimal(e.floor(), '-1014286');
            expectShortDecimal(e.round(), '-1014286');
            expectShortDecimal(e.ceil(), '-1014285');
            expectShortDecimal(e.truncate(), '-1014285');

            expectShortFraction(e.fraction, '-7100000/7');
            expectShortDivision(
              e.quotientWithRemainder,
              '-1014285 remainder 0.00615',
            );
          }

          expect(v1 ~/ v2, -1014285);
          expectShortDecimal(
            v1 % v2,
            '0.00615',
            base: 615,
            scale: 5,
            fractionDigits: 5,
          );
        });

        test('small / big', () {
          // 94833 / 86100.00 = 1.1014285(714285)…
          // modulo: 8733
          // 1 * 86100 = 86100
          // 86100 + 8733 = 94833
          final v1 = ShortDecimal(94833);
          final v2 = ShortDecimal.parse('86100.00');
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on ShortDecimalDivideException catch (e) {
            expectShortDecimal(e.floor(6), '1.101428');
            expectShortDecimal(e.round(6), '1.101429');
            expectShortDecimal(e.ceil(6), '1.101429');
            expectShortDecimal(e.truncate(6), '1.101428');
            expectShortDecimal(e.truncate(12), '1.101428571428');

            expectShortFraction(e.fraction, '771/700');
            expectShortDivision(e.quotientWithRemainder, '1 remainder 8733');
          }

          expect(v1 ~/ v2, 1);
          expectShortDecimal(
            v1 % v2,
            '8733',
            base: 8733,
            scale: 0,
            fractionDigits: 0,
          );
        });
      });
    });

    test('abs', () {
      expectShortDecimal(
        ShortDecimal(2).abs(),
        '2',
        base: 2,
        scale: 0,
        fractionDigits: 0,
      );

      expectShortDecimal(
        ShortDecimal(-2).abs(),
        '2',
        base: 2,
        scale: 0,
        fractionDigits: 0,
      );

      expectShortDecimal(
        ShortDecimal.parse('-1234567890.123456789').abs(),
        '1234567890.123456789',
        base: 1234567890123456789,
        scale: 9,
        fractionDigits: 9,
      );
    });

    test('pow', () {
      expectShortDecimal(
        ShortDecimal(2).pow(4),
        '16',
        base: 16,
        scale: 0,
        fractionDigits: 0,
      );

      expectShortDecimal(
        ShortDecimal(2, shiftRight: 1).pow(4),
        '0.0016',
        base: 16,
        scale: 4,
        fractionDigits: 4,
      );
    });

    test('toInt', () {
      expect(ShortDecimal.parse('3.75').toInt(), 3);
      expect(ShortDecimal.parse('-3.75').toInt(), -3);

      expectShortDecimal(
        ShortDecimal.parse('1234567890.123456789'),
        '1234567890.123456789',
        base: 1234567890123456789,
        scale: 9,
        fractionDigits: 9,
      );
      expect(ShortDecimal.parse('1234567890.123456789').toInt(), 1234567890);
      expect(ShortDecimal.parse('1234567890.9').toInt(), 1234567890);
    });

    test('toDouble', () {
      expectDouble(ShortDecimal.parse('0').toDouble(), 0, '0.0');
      expectDouble(ShortDecimal.parse('0.1').toDouble(), 0.1, '0.1');
      expectDouble(ShortDecimal.parse('0.01').toDouble(), 0.01, '0.01');
      expectDouble(ShortDecimal.parse('0.001').toDouble(), 0.001, '0.001');
      expectDouble(ShortDecimal.parse('0.0001').toDouble(), 0.0001, '0.0001');
      expectDouble(
        ShortDecimal.parse('0.00001').toDouble(),
        0.00001,
        '0.00001',
      );
      expectDouble(
        ShortDecimal.parse('0.000001').toDouble(),
        0.000001,
        '0.000001',
      );
      expectDouble(
        ShortDecimal.parse('0.0000001').toDouble(),
        0.0000001,
        '1e-7',
      );
      expectDouble(
        ShortDecimal.parse('0.00000001').toDouble(),
        0.00000001,
        '1e-8',
      );
      expectDouble(
        ShortDecimal.parse('0.000000001').toDouble(),
        0.000000001,
        '1e-9',
      );
      expectDouble(
        ShortDecimal.parse('0.0000000001').toDouble(),
        0.0000000001,
        '1e-10',
      );

      expectDouble(ShortDecimal.parse('0.12').toDouble(), 0.12, '0.12');
      expectDouble(ShortDecimal.parse('0.123').toDouble(), 0.123, '0.123');
      expectDouble(ShortDecimal.parse('0.1234').toDouble(), 0.1234, '0.1234');
      expectDouble(
        ShortDecimal.parse('0.12345').toDouble(),
        0.12345,
        '0.12345',
      );
      expectDouble(
        ShortDecimal.parse('0.123456').toDouble(),
        0.123456,
        '0.123456',
      );
      expectDouble(
        ShortDecimal.parse('0.1234567').toDouble(),
        0.1234567,
        '0.1234567',
      );
      expectDouble(
        ShortDecimal.parse('0.12345678').toDouble(),
        0.12345678,
        '0.12345678',
      );
      expectDouble(
        ShortDecimal.parse('0.123456789').toDouble(),
        0.123456789,
        '0.123456789',
      );
      expectDouble(
        ShortDecimal.parse('0.1234567890').toDouble(),
        0.123456789,
        '0.123456789',
      );
      expectDouble(
        ShortDecimal.parse('0.12345678901').toDouble(),
        0.12345678901,
        '0.12345678901',
      );
      expectDouble(
        ShortDecimal.parse('0.123456789012').toDouble(),
        0.123456789012,
        '0.123456789012',
      );
      expectDouble(
        ShortDecimal.parse('0.1234567890123').toDouble(),
        0.1234567890123,
        '0.1234567890123',
      );
      expectDouble(
        ShortDecimal.parse('0.12345678901234').toDouble(),
        0.12345678901234,
        '0.12345678901234',
      );
      expectDouble(
        ShortDecimal.parse('0.123456789012345').toDouble(),
        0.123456789012345,
        '0.123456789012345',
      );
      expectDouble(
        ShortDecimal.parse('0.1234567890123456').toDouble(),
        0.1234567890123456,
        '0.1234567890123456',
      );
      // Loss of precision.
      expectDouble(
        ShortDecimal.parse('0.12345678901234567').toDouble(),
        0.12345678901234566,
        '0.12345678901234566',
      );
      expectDouble(
        ShortDecimal.parse('0.123456789012345678').toDouble(),
        0.12345678901234568,
        '0.12345678901234568',
      );

      // Loss of precision.

      const d = 1234567890123456789.0;
      const str = '1234567890123456800.0';
      expectDouble(
        ShortDecimal(1234567890123456640).toDouble(),
        d,
        str,
        isValid: false,
      );
      expectDouble(ShortDecimal(1234567890123456641).toDouble(), d, str);
      expectDouble(ShortDecimal(1234567890123456895).toDouble(), d, str);
      expectDouble(
        ShortDecimal(1234567890123456896).toDouble(),
        d,
        str,
        isValid: false,
      );
    });

    test('clamp', () {
      for (final p in [
        (ShortDecimal(5), ShortDecimal(3), ShortDecimal(7), '5'),
        (ShortDecimal(3), ShortDecimal(3), ShortDecimal(7), '3'),
        (ShortDecimal(1), ShortDecimal(3), ShortDecimal(7), '3'),
        (ShortDecimal(7), ShortDecimal(3), ShortDecimal(7), '7'),
        (ShortDecimal(9), ShortDecimal(3), ShortDecimal(7), '7'),
        (ShortDecimal(-5), ShortDecimal(-7), ShortDecimal(-3), '-5'),
        (ShortDecimal(-3), ShortDecimal(-7), ShortDecimal(-3), '-3'),
        (ShortDecimal(-1), ShortDecimal(-7), ShortDecimal(-3), '-3'),
        (ShortDecimal(-7), ShortDecimal(-7), ShortDecimal(-3), '-7'),
        (ShortDecimal(-9), ShortDecimal(-7), ShortDecimal(-3), '-7'),
        (ShortDecimal(500), ShortDecimal(4) << 2, ShortDecimal(6) << 2, '500'),
        (
          ShortDecimal(5) >> 2,
          ShortDecimal.parse('0.0400'),
          ShortDecimal.parse('0.060000'),
          '0.05',
        ),
      ]) {
        expectShortDecimal(p.$1.clamp(p.$2, p.$3), p.$4);
      }

      expect(
        () => ShortDecimal(0).clamp(ShortDecimal(2), ShortDecimal(1)),
        throwsA(
          predicate(
            (error) =>
                error is ArgumentError &&
                error.message ==
                    'The lowerLimit must be no greater than upperLimit',
          ),
        ),
      );
    });

    test('isInteger', () {
      for (final p in [
        (ShortDecimal(0), isTrue),
        (ShortDecimal(0) >> 10, isTrue),
        (ShortDecimal(2), isTrue),
        (ShortDecimal(2) >> 1, isFalse),
        (ShortDecimal(-2), isTrue),
        (ShortDecimal(-2) >> 1, isFalse),
        (ShortDecimal(1111111111111111110), isTrue),
        (ShortDecimal(1111111111111111110) >> 1, isTrue),
        (ShortDecimal(1111111111111111110) >> 2, isFalse),
        (ShortDecimal(-1111111111111111110), isTrue),
        (ShortDecimal(-1111111111111111110) >> 1, isTrue),
        (ShortDecimal(-1111111111111111110) >> 2, isFalse),
      ]) {
        expect(p.$1.isInteger, p.$2);
      }
    });

    test('toString', () {
      for (final p in [
        (ShortDecimal(0), '0', 0, 0, 0),
        (ShortDecimal(0) >> 1, '0', 0, 0, 0),
        (ShortDecimal(0) >> 2, '0', 0, 0, 0),
        (ShortDecimal(0) >> 3, '0', 0, 0, 0),
        (ShortDecimal(1), '1', 1, 0, 0),
        (ShortDecimal(1) >> 1, '0.1', 1, 1, 1),
        (ShortDecimal(1) >> 2, '0.01', 1, 2, 2),
        (ShortDecimal(1) >> 3, '0.001', 1, 3, 3),
        (ShortDecimal(10), '10', 1, -1, 0),
        (ShortDecimal(1) << 1, '10', 1, -1, 0),
        (ShortDecimal(100), '100', 1, -2, 0),
        (ShortDecimal(1) << 2, '100', 1, -2, 0),
        (ShortDecimal(1000), '1000', 1, -3, 0),
        (ShortDecimal(1) << 3, '1000', 1, -3, 0),
        (ShortDecimal(1000) >> 1, '100', 1, -2, 0),
        (ShortDecimal(1000) >> 2, '10', 1, -1, 0),
        (ShortDecimal(1000) >> 3, '1', 1, 0, 0),
        (ShortDecimal(1000) >> 4, '0.1', 1, 1, 1),
        (ShortDecimal(1000) >> 5, '0.01', 1, 2, 2),
        (ShortDecimal(1000) >> 6, '0.001', 1, 3, 3),
        (ShortDecimal(1234567890), '1234567890', 123456789, -1, 0),
        (ShortDecimal(1234567890) >> 1, '123456789', 123456789, 0, 0),
        (ShortDecimal(1234567890) >> 2, '12345678.9', 123456789, 1, 1),
        (ShortDecimal(1234567890) >> 3, '1234567.89', 123456789, 2, 2),
        (ShortDecimal(1234567890) >> 4, '123456.789', 123456789, 3, 3),
        (ShortDecimal(1234567890) >> 5, '12345.6789', 123456789, 4, 4),
        (ShortDecimal(1234567890) >> 6, '1234.56789', 123456789, 5, 5),
        (ShortDecimal(1234567890) >> 7, '123.456789', 123456789, 6, 6),
        (ShortDecimal(1234567890) >> 8, '12.3456789', 123456789, 7, 7),
        (ShortDecimal(1234567890) >> 9, '1.23456789', 123456789, 8, 8),
        (ShortDecimal(1234567890) >> 10, '0.123456789', 123456789, 9, 9),
        (ShortDecimal(1234567890) >> 11, '0.0123456789', 123456789, 10, 10),
        (ShortDecimal(1234567890) >> 12, '0.00123456789', 123456789, 11, 11),
        (ShortDecimal(1234567890) >> 13, '0.000123456789', 123456789, 12, 12),
        (
          ShortDecimal(9223372036854775807),
          '9223372036854775807',
          9223372036854775807,
          0,
          0,
        ),
        (
          ShortDecimal(-9223372036854775808),
          '-9223372036854775808',
          -9223372036854775808,
          0,
          0,
        ),
      ]) {
        expectShortDecimal(
          p.$1,
          p.$2,
          base: p.$3,
          scale: p.$4,
          fractionDigits: p.$5,
        );
      }
    });
  });

  group('ShortFraction', () {
    test('create', () {
      expect(
        () => ShortFraction(0, 0),
        throwsA(
          predicate(
            (error) =>
                error is UnsupportedError &&
                error.message == 'division by zero',
          ),
        ),
      );

      expectShortFraction(ShortFraction(123, 123), '1');
      expectShortFraction(ShortFraction(-123, 123), '-1');
      expectShortFraction(ShortFraction(123, -123), '-1');
      expectShortFraction(ShortFraction(-123, -123), '1');

      expectShortFraction(ShortFraction(123, 7), '123/7');
      expectShortFraction(ShortFraction(-123, 7), '-123/7');
      expectShortFraction(ShortFraction(123, -7), '-123/7');
      expectShortFraction(ShortFraction(-123, -7), '123/7');

      expectShortFraction(ShortFraction(123, 1230), '1/10');
      expectShortFraction(ShortFraction(1230, 123), '10');
    });

    test('parse', () {
      expect(
        () => ShortFraction.parse('0/0'),
        throwsA(
          predicate(
            (error) =>
                error is UnsupportedError &&
                error.message == 'division by zero',
          ),
        ),
      );

      expectShortFraction(ShortFraction.parse('123/123'), '1');
      expectShortFraction(ShortFraction.parse('-123/123'), '-1');
      expectShortFraction(ShortFraction.parse('123/-123'), '-1');
      expectShortFraction(ShortFraction.parse('-123/-123'), '1');

      expectShortFraction(ShortFraction.parse('123/7'), '123/7');
      expectShortFraction(ShortFraction.parse('-123/7'), '-123/7');
      expectShortFraction(ShortFraction.parse('123/-7'), '-123/7');
      expectShortFraction(ShortFraction.parse('-123/-7'), '123/7');

      expectShortFraction(ShortFraction.parse('123/1230'), '1/10');
      expectShortFraction(ShortFraction.parse('1230/123'), '10');
    });

    test('to Decimal', () {
      var f = ShortDecimal.parse(
        '1.2',
      ).divideToFraction(ShortDecimal.parse('2.1'));
      expectShortFraction(f, '4/7');

      expectShortDecimal(f.floor(), '0');
      expectShortDecimal(f.floor(1), '0.5');
      expectShortDecimal(f.floor(2), '0.57');

      expectShortDecimal(f.round(), '1');
      expectShortDecimal(f.round(1), '0.6');
      expectShortDecimal(f.round(2), '0.57');

      expectShortDecimal(f.ceil(), '1');
      expectShortDecimal(f.ceil(1), '0.6');
      expectShortDecimal(f.ceil(2), '0.58');

      expectShortDecimal(f.truncate(), '0');
      expectShortDecimal(f.truncate(1), '0.5');
      expectShortDecimal(f.truncate(2), '0.57');

      f = ShortDecimal.parse(
        '-1.2',
      ).divideToFraction(ShortDecimal.parse('2.1'));
      expectShortFraction(f, '-4/7');

      expectShortDecimal(f.floor(), '-1');
      expectShortDecimal(f.floor(1), '-0.6');
      expectShortDecimal(f.floor(2), '-0.58');

      expectShortDecimal(f.round(), '-1');
      expectShortDecimal(f.round(1), '-0.6');
      expectShortDecimal(f.round(2), '-0.57');

      expectShortDecimal(f.ceil(), '0');
      expectShortDecimal(f.ceil(1), '-0.5');
      expectShortDecimal(f.ceil(2), '-0.57');

      expectShortDecimal(f.truncate(), '0');
      expectShortDecimal(f.truncate(1), '-0.5');
      expectShortDecimal(f.truncate(2), '-0.57');
    });
  });

  group('ShortDivision', () {
    test('create', () {
      expect(
        () => ShortDivision(ShortDecimal.zero, ShortDecimal.zero),
        throwsA(
          predicate(
            (error) =>
                error is UnsupportedError &&
                error.message == 'division by zero',
          ),
        ),
      );

      expectShortDivide(ShortDecimal(0), ShortDecimal(7), '0');
      expectShortDivide(ShortDecimal(1), ShortDecimal(7), '0 remainder 1');
      expectShortDivide(ShortDecimal(-1), ShortDecimal(7), '0 remainder -1');
      expectShortDivide(ShortDecimal(1), ShortDecimal(-7), '0 remainder 1');
      expectShortDivide(ShortDecimal(-1), ShortDecimal(-7), '0 remainder -1');

      expectShortDivide(
        ShortDecimal.parse('123.456'),
        ShortDecimal.parse('7.7'),
        '16 remainder 0.256',
      );

      expectShortDivide(
        ShortDecimal.parse('-111111111.111111111'),
        ShortDecimal.parse('1234567.1234567'),
        '-90 remainder -70.000008111',
      );

      expectShortDivide(
        ShortDecimal.parse('1234567890.123456789'),
        ShortDecimal.parse('-333333333.1'),
        '-3 remainder 234567890.823456789',
      );

      expectShortDivide(
        ShortDecimal.parse('12333333324.7'),
        ShortDecimal.parse('-333333333.1'),
        '-37',
      );
    });
  });
}
