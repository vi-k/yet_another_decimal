import 'package:decimal2/decimal2.dart';
import 'package:test/test.dart';

void expectDecimal(
  Decimal d,
  Object str, {
  BigInt? value,
  int? scale,
  int? fractionDigits,
}) {
  expect(d.toString(), str);

  if (value != null) {
    expect(d.value, value);
  }

  if (scale != null) {
    expect(d.scale, scale);
  }

  if (fractionDigits != null) {
    expect(d.fractionDigits, fractionDigits);
  }
}

void expectShortDecimal(ShortDecimal d, String str) =>
    expect(d.toString(), str);

void expectFraction(Fraction f, String str) {
  expect(f.toString(), str);
}

void expectDivision(Division division, String str) {
  expect(division.toString(), str);
}

void expectDivide(
  Decimal dividend,
  Decimal divisor,
  String str,
) {
  final d = Division(dividend, divisor);

  expect(d.toString(), str);

  expect(
    Decimal.fromBigInt(d.quotient) * divisor + d.remainder == dividend,
    isTrue,
  );
}

void expectDouble(
  double a,
  double b,
  String str, {
  bool isValid = true,
}) {
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
        expectDecimal(
          Decimal.parse('0'),
          '0',
          value: BigInt.zero,
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('0.0'),
          '0',
          value: BigInt.zero,
          scale: 1,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('.0'),
          '0',
          value: BigInt.zero,
          scale: 1,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('00000.00000'),
          '0',
          value: BigInt.zero,
          scale: 5,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse(' 0'),
          '0',
          value: BigInt.zero,
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('0 '),
          '0',
          value: BigInt.zero,
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse(' 0.0'),
          '0',
          value: BigInt.zero,
          scale: 1,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('0.0 '),
          '0',
          value: BigInt.zero,
          scale: 1,
          fractionDigits: 0,
        );

        expect(
          () => Decimal.parse('0.'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse Decimal: 0.',
            ),
          ),
        );

        expect(
          () => Decimal.parse('0.0.'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse Decimal: 0.0.',
            ),
          ),
        );

        expectDecimal(
          Decimal.parse('-0'),
          '0',
          value: BigInt.zero,
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-0.0'),
          '0',
          value: BigInt.zero,
          scale: 1,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-.0'),
          '0',
          value: BigInt.zero,
          scale: 1,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-00000.00000'),
          '0',
          value: BigInt.zero,
          scale: 5,
          fractionDigits: 0,
        );
      });

      test('1', () {
        expectDecimal(
          Decimal.parse('1'),
          '1',
          value: BigInt.one,
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('0.1'),
          '0.1',
          value: BigInt.one,
          scale: 1,
          fractionDigits: 1,
        );
        expectDecimal(
          Decimal.parse('.1'),
          '0.1',
          value: BigInt.one,
          scale: 1,
          fractionDigits: 1,
        );
        expectDecimal(
          Decimal.parse('0.01'),
          '0.01',
          value: BigInt.one,
          scale: 2,
          fractionDigits: 2,
        );
        expectDecimal(
          Decimal.parse('0.001'),
          '0.001',
          value: BigInt.one,
          scale: 3,
          fractionDigits: 3,
        );
        expectDecimal(
          Decimal.parse('1.0'),
          '1',
          value: BigInt.from(10),
          scale: 1,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('1.00'),
          '1',
          value: BigInt.from(100),
          scale: 2,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('1.000'),
          '1',
          value: BigInt.from(1000),
          scale: 3,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('10'),
          '10',
          value: BigInt.from(10),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('100'),
          '100',
          value: BigInt.from(100),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('1000'),
          '1000',
          value: BigInt.from(1000),
          scale: 0,
          fractionDigits: 0,
        );

        expect(
          () => Decimal.parse('1 000'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse Decimal: 1 000',
            ),
          ),
        );

        expect(
          () => Decimal.parse('1,000.0'),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == 'Could not parse Decimal: 1,000.0',
            ),
          ),
        );

        expect(
          () => Decimal.parse("1'000.0"),
          throwsA(
            predicate(
              (error) =>
                  error is FormatException &&
                  error.message == "Could not parse Decimal: 1'000.0",
            ),
          ),
        );

        expectDecimal(
          Decimal.parse('-1'),
          '-1',
          value: -BigInt.one,
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-0.1'),
          '-0.1',
          value: -BigInt.one,
          scale: 1,
          fractionDigits: 1,
        );
        expectDecimal(
          Decimal.parse('-0.01'),
          '-0.01',
          value: -BigInt.one,
          scale: 2,
          fractionDigits: 2,
        );
        expectDecimal(
          Decimal.parse('-0.001'),
          '-0.001',
          value: -BigInt.one,
          scale: 3,
          fractionDigits: 3,
        );
        expectDecimal(
          Decimal.parse('-1.0'),
          '-1',
          value: BigInt.from(-10),
          scale: 1,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-1.00'),
          '-1',
          value: BigInt.from(-100),
          scale: 2,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-1.000'),
          '-1',
          value: BigInt.from(-1000),
          scale: 3,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-10'),
          '-10',
          value: BigInt.from(-10),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-100'),
          '-100',
          value: BigInt.from(-100),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-1000'),
          '-1000',
          value: BigInt.from(-1000),
          scale: 0,
          fractionDigits: 0,
        );
      });

      test('int', () {
        expectDecimal(
          Decimal.parse('1234567890'),
          '1234567890',
          value: BigInt.from(1234567890),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('123456789.0'),
          '123456789',
          value: BigInt.from(1234567890),
          scale: 1,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('12345678.90'),
          '12345678.9',
          value: BigInt.from(1234567890),
          scale: 2,
          fractionDigits: 1,
        );
        expectDecimal(
          Decimal.parse('1234567.890'),
          '1234567.89',
          value: BigInt.from(1234567890),
          scale: 3,
          fractionDigits: 2,
        );
        expectDecimal(
          Decimal.parse('123456.7890'),
          '123456.789',
          value: BigInt.from(1234567890),
          scale: 4,
          fractionDigits: 3,
        );
        expectDecimal(
          Decimal.parse('12345.67890'),
          '12345.6789',
          value: BigInt.from(1234567890),
          scale: 5,
          fractionDigits: 4,
        );
        expectDecimal(
          Decimal.parse('1234.567890'),
          '1234.56789',
          value: BigInt.from(1234567890),
          scale: 6,
          fractionDigits: 5,
        );
        expectDecimal(
          Decimal.parse('123.4567890'),
          '123.456789',
          value: BigInt.from(1234567890),
          scale: 7,
          fractionDigits: 6,
        );
        expectDecimal(
          Decimal.parse('12.34567890'),
          '12.3456789',
          value: BigInt.from(1234567890),
          scale: 8,
          fractionDigits: 7,
        );
        expectDecimal(
          Decimal.parse('1.234567890'),
          '1.23456789',
          value: BigInt.from(1234567890),
          scale: 9,
          fractionDigits: 8,
        );
        expectDecimal(
          Decimal.parse('0.1234567890'),
          '0.123456789',
          value: BigInt.from(1234567890),
          scale: 10,
          fractionDigits: 9,
        );
        expectDecimal(
          Decimal.parse('0.01234567890'),
          '0.0123456789',
          value: BigInt.from(1234567890),
          scale: 11,
          fractionDigits: 10,
        );
        expectDecimal(
          Decimal.parse('0.001234567890'),
          '0.00123456789',
          value: BigInt.from(1234567890),
          scale: 12,
          fractionDigits: 11,
        );
        expectDecimal(
          Decimal.parse('0.0001234567890'),
          '0.000123456789',
          value: BigInt.from(1234567890),
          scale: 13,
          fractionDigits: 12,
        );

        expectDecimal(
          Decimal.parse('-1234567890'),
          '-1234567890',
          value: BigInt.from(-1234567890),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-123456789.0'),
          '-123456789',
          value: BigInt.from(-1234567890),
          scale: 1,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('-12345678.90'),
          '-12345678.9',
          value: BigInt.from(-1234567890),
          scale: 2,
          fractionDigits: 1,
        );
        expectDecimal(
          Decimal.parse('-1234567.890'),
          '-1234567.89',
          value: BigInt.from(-1234567890),
          scale: 3,
          fractionDigits: 2,
        );
        expectDecimal(
          Decimal.parse('-123456.7890'),
          '-123456.789',
          value: BigInt.from(-1234567890),
          scale: 4,
          fractionDigits: 3,
        );
        expectDecimal(
          Decimal.parse('-12345.67890'),
          '-12345.6789',
          value: BigInt.from(-1234567890),
          scale: 5,
          fractionDigits: 4,
        );
        expectDecimal(
          Decimal.parse('-1234.567890'),
          '-1234.56789',
          value: BigInt.from(-1234567890),
          scale: 6,
          fractionDigits: 5,
        );
        expectDecimal(
          Decimal.parse('-123.4567890'),
          '-123.456789',
          value: BigInt.from(-1234567890),
          scale: 7,
          fractionDigits: 6,
        );
        expectDecimal(
          Decimal.parse('-12.34567890'),
          '-12.3456789',
          value: BigInt.from(-1234567890),
          scale: 8,
          fractionDigits: 7,
        );
        expectDecimal(
          Decimal.parse('-1.234567890'),
          '-1.23456789',
          value: BigInt.from(-1234567890),
          scale: 9,
          fractionDigits: 8,
        );
        expectDecimal(
          Decimal.parse('-0.1234567890'),
          '-0.123456789',
          value: BigInt.from(-1234567890),
          scale: 10,
          fractionDigits: 9,
        );
        expectDecimal(
          Decimal.parse('-0.01234567890'),
          '-0.0123456789',
          value: BigInt.from(-1234567890),
          scale: 11,
          fractionDigits: 10,
        );
        expectDecimal(
          Decimal.parse('-0.001234567890'),
          '-0.00123456789',
          value: BigInt.from(-1234567890),
          scale: 12,
          fractionDigits: 11,
        );
        expectDecimal(
          Decimal.parse('-0.0001234567890'),
          '-0.000123456789',
          value: BigInt.from(-1234567890),
          scale: 13,
          fractionDigits: 12,
        );
      });

      test('BigInt', () {
        // BigInt
        expectDecimal(
          Decimal.parse(
            '1234567890123456789012345678901234567890',
          ),
          '1234567890123456789012345678901234567890',
          value: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse(
            '123456789012345678901234567890.1234567890',
          ),
          '123456789012345678901234567890.123456789',
          value: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 10,
          fractionDigits: 9,
        );
        expectDecimal(
          Decimal.parse(
            '12345678901234567890.12345678901234567890',
          ),
          '12345678901234567890.1234567890123456789',
          value: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 20,
          fractionDigits: 19,
        );
        expectDecimal(
          Decimal.parse(
            '1234567890.123456789012345678901234567890',
          ),
          '1234567890.12345678901234567890123456789',
          value: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 30,
          fractionDigits: 29,
        );
        expectDecimal(
          Decimal.parse(
            '0.1234567890123456789012345678901234567890',
          ),
          '0.123456789012345678901234567890123456789',
          value: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 40,
          fractionDigits: 39,
        );
        expectDecimal(
          Decimal.parse(
            '0.00000000001234567890123456789012345678901234567890',
          ),
          '0.0000000000123456789012345678901234567890123456789',
          value: BigInt.parse('1234567890123456789012345678901234567890'),
          scale: 50,
          fractionDigits: 49,
        );

        expectDecimal(
          Decimal.parse(
            '-1234567890123456789012345678901234567890',
          ),
          '-1234567890123456789012345678901234567890',
          value: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse(
            '-123456789012345678901234567890.1234567890',
          ),
          '-123456789012345678901234567890.123456789',
          value: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 10,
          fractionDigits: 9,
        );
        expectDecimal(
          Decimal.parse(
            '-12345678901234567890.12345678901234567890',
          ),
          '-12345678901234567890.1234567890123456789',
          value: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 20,
          fractionDigits: 19,
        );
        expectDecimal(
          Decimal.parse(
            '-1234567890.123456789012345678901234567890',
          ),
          '-1234567890.12345678901234567890123456789',
          value: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 30,
          fractionDigits: 29,
        );
        expectDecimal(
          Decimal.parse(
            '-0.1234567890123456789012345678901234567890',
          ),
          '-0.123456789012345678901234567890123456789',
          value: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 40,
          fractionDigits: 39,
        );
        expectDecimal(
          Decimal.parse(
            '-0.00000000001234567890123456789012345678901234567890',
          ),
          '-0.0000000000123456789012345678901234567890123456789',
          value: BigInt.parse('-1234567890123456789012345678901234567890'),
          scale: 50,
          fractionDigits: 49,
        );

        expectDecimal(
          Decimal.parse('1000000000000000000000000000000'),
          '1000000000000000000000000000000',
          value: BigInt.parse('1000000000000000000000000000000'),
          scale: 0,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('100000000000000000000.0000000000'),
          '100000000000000000000',
          value: BigInt.parse('1000000000000000000000000000000'),
          scale: 10,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('10000000000.00000000000000000000'),
          '10000000000',
          value: BigInt.parse('1000000000000000000000000000000'),
          scale: 20,
          fractionDigits: 0,
        );
        expectDecimal(
          Decimal.parse('1.000000000000000000000000000000'),
          '1',
          value: BigInt.parse('1000000000000000000000000000000'),
          scale: 30,
          fractionDigits: 0,
        );
      });
    });

    test('add', () {
      var value = Decimal(1, shiftLeft: 4);
      expectDecimal(
        value += Decimal(1, shiftLeft: 3),
        '11000',
        value: BigInt.from(11),
        scale: -3,
        fractionDigits: 0,
      );
      expectDecimal(
        value += Decimal(1, shiftLeft: 2),
        '11100',
        value: BigInt.from(111),
        scale: -2,
        fractionDigits: 0,
      );
      expectDecimal(
        value += Decimal(1, shiftLeft: 1),
        '11110',
        value: BigInt.from(1111),
        scale: -1,
        fractionDigits: 0,
      );
      expectDecimal(
        value += Decimal(10000, shiftRight: 4), // 1
        '11111',
        value: BigInt.from(111110000),
        scale: 4,
        fractionDigits: 0,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 1),
        '11111.1',
        value: BigInt.from(111111000),
        scale: 4,
        fractionDigits: 1,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 2),
        '11111.11',
        value: BigInt.from(111111100),
        scale: 4,
        fractionDigits: 2,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 3),
        '11111.111',
        value: BigInt.from(111111110),
        scale: 4,
        fractionDigits: 3,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 4),
        '11111.1111',
        value: BigInt.from(111111111),
        scale: 4,
        fractionDigits: 4,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 5),
        '11111.11111',
        value: BigInt.from(1111111111),
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
        value: BigInt.parse(
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
        value: BigInt.from(56088),
        scale: 3,
        fractionDigits: 3,
      );
      expectDecimal(
        Decimal(-123, shiftRight: 2) * Decimal(456, shiftRight: 1),
        '-56.088',
        value: BigInt.from(-56088),
        scale: 3,
        fractionDigits: 3,
      );
      expectDecimal(
        Decimal(123, shiftRight: 2) * Decimal(-456, shiftRight: 1),
        '-56.088',
        value: BigInt.from(-56088),
        scale: 3,
        fractionDigits: 3,
      );
      expectDecimal(
        Decimal(-123, shiftRight: 2) * Decimal(-456, shiftRight: 1),
        '56.088',
        value: BigInt.from(56088),
        scale: 3,
        fractionDigits: 3,
      );

      var value = Decimal.parse('123456.00');
      expectDecimal(
        value *= Decimal.parse('12345.6'),
        '1524138393.6',
        value: BigInt.from(1524138393600),
        scale: 3,
        fractionDigits: 1,
      );
      expectDecimal(
        value *= Decimal.parse('1234.56'),
        '1881640295202.816',
        value: BigInt.from(188164029520281600),
        scale: 5,
        fractionDigits: 3,
      );
      expectDecimal(
        value *= Decimal.parse('123.456'),
        '232299784284558.852096',
        value: BigInt.parse('23229978428455885209600'),
        scale: 8,
        fractionDigits: 6,
      );
      expectDecimal(
        value *= Decimal.parse('12.3456'),
        '2867880216863449.7644363776',
        value: BigInt.parse('2867880216863449764436377600'),
        scale: 12,
        fractionDigits: 10,
      );
      expectDecimal(
        value *= Decimal.parse('1.23456'),
        '3540570200530940.541182574329856',
        value: BigInt.parse('354057020053094054118257432985600'),
        scale: 17,
        fractionDigits: 15,
      );

      value = Decimal.parse('-123456');
      expectDecimal(
        value *= Decimal.parse('12345.6'),
        '-1524138393.6',
        value: BigInt.from(-15241383936),
        scale: 1,
        fractionDigits: 1,
      );
      expectDecimal(
        value *= Decimal.parse('-1234.56'),
        '1881640295202.816',
        value: BigInt.from(1881640295202816),
        scale: 3,
        fractionDigits: 3,
      );
      expectDecimal(
        value *= Decimal.parse('-123.456'),
        '-232299784284558.852096',
        value: BigInt.parse('-232299784284558852096'),
        scale: 6,
        fractionDigits: 6,
      );
      expectDecimal(
        value *= Decimal.parse('-12.3456'),
        '2867880216863449.7644363776',
        value: BigInt.parse('28678802168634497644363776'),
        scale: 10,
        fractionDigits: 10,
      );
      expectDecimal(
        value *= Decimal.parse('-1.23456'),
        '-3540570200530940.541182574329856',
        value: BigInt.parse('-3540570200530940541182574329856'),
        scale: 15,
        fractionDigits: 15,
      );
    });

    group('divide', () {
      test('success', () {
        expectDecimal(
          Decimal(24, shiftRight: 1) / Decimal(12, shiftRight: 1),
          '2',
          value: BigInt.two,
          scale: 0,
          fractionDigits: 0,
        );

        var value = Decimal.parse('3540570200530940.541182574329856');
        expectDecimal(
          value /= Decimal(123456),
          '28678802168.634497644363776',
          value: BigInt.parse('28678802168634497644363776'),
          scale: 15,
          fractionDigits: 15,
        );
        expectDecimal(
          value /= Decimal.parse('12345.6'),
          '2322997.84284558852096',
          value: BigInt.parse('232299784284558852096'),
          scale: 14,
          fractionDigits: 14,
        );
        expectDecimal(
          value /= Decimal.parse('1234.56'),
          '1881.640295202816',
          value: BigInt.from(1881640295202816),
          scale: 12,
          fractionDigits: 12,
        );
        expectDecimal(
          value /= Decimal.parse('123.456'),
          '15.241383936',
          value: BigInt.from(15241383936),
          scale: 9,
          fractionDigits: 9,
        );
        expectDecimal(
          value /= Decimal.parse('12.3456'),
          '1.23456',
          value: BigInt.from(123456),
          scale: 5,
          fractionDigits: 5,
        );
        expectDecimal(
          value /= Decimal.parse('1.23456'),
          '1',
          value: BigInt.one,
          scale: 0,
          fractionDigits: 0,
        );

        // expect(
        //   () => Decimal(15129, shiftRight: 1) / Decimal(86100),
        //   throwsA(
        //     predicate(
        //       (error) =>
        //           error is DecimalDivideException &&
        //           error.numerator.toString() == '0.123' &&
        //           error.denominator.toString() == '7',
        //     ),
        //   ),
        // );
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
            DecimalDivideException.forTest(Decimal(-11), Decimal(10))
                .truncate(),
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
            DecimalDivideException.forTest(Decimal(-19), Decimal(10))
                .truncate(),
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
            expectDecimal(v1 ~/ v2, '0');
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
            expectDecimal(v1 ~/ v2, '0');
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
            expectDecimal(v1 ~/ v2, '0');
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
            expectDecimal(v1 ~/ v2, '0');
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
          // 8733 / 0.0086100 = 1014285.(714285)...
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
            expectDivision(e.division, '1014285 remainder 0.00615');
          }

          expectDecimal(
            v1 ~/ v2,
            '1014285',
            value: BigInt.from(1014285),
            scale: 0,
            fractionDigits: 0,
          );
          expectDecimal(
            v1 % v2,
            '0.00615',
            value: BigInt.from(61500),
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
            expectDivision(e.division, '-1014285 remainder 0.00615');
          }

          expectDecimal(
            v1 ~/ v2,
            '-1014285',
            value: BigInt.from(-1014285),
            scale: 0,
            fractionDigits: 0,
          );
          expectDecimal(
            v1 % v2,
            '0.00615',
            value: BigInt.from(61500),
            scale: 7,
            fractionDigits: 5,
          );
        });

        test('small / big', () {
          // 94833 / 86100.00 = 1.1014285(714285)...
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
            expectDivision(e.division, '1 remainder 8733');
          }

          expectDecimal(
            v1 ~/ v2,
            '1',
            value: BigInt.one,
            scale: 0,
            fractionDigits: 0,
          );
          expectDecimal(
            v1 % v2,
            '8733',
            value: BigInt.from(873300),
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
        value: BigInt.from(2),
        scale: 0,
        fractionDigits: 0,
      );

      expectDecimal(
        Decimal(-2).abs(),
        '2',
        value: BigInt.from(2),
        scale: 0,
        fractionDigits: 0,
      );

      expectDecimal(
        Decimal.parse('-12345678901234567890.12345678901234567890').abs(),
        '12345678901234567890.1234567890123456789',
        value: BigInt.parse('1234567890123456789012345678901234567890'),
        scale: 20,
        fractionDigits: 19,
      );
    });

    test('pow', () {
      expectDecimal(
        Decimal(2).pow(4),
        '16',
        value: BigInt.from(16),
        scale: 0,
        fractionDigits: 0,
      );

      expectDecimal(
        Decimal(2, shiftRight: 1).pow(4),
        '0.0016',
        value: BigInt.from(16),
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
      test('compareTo', () {
        expect(
          Decimal.parse('2.000000000000000000004')
              .compareTo(Decimal.parse('2.000000000000000000009')),
          -1,
        );
        expect(
          Decimal.parse('2.000000000000000000004')
              .compareTo(Decimal.parse('2.000000000000000000001')),
          1,
        );
        expect(
          Decimal.parse('2.000000000000000000004')
              .compareTo(Decimal.parse('2.000000000000000000004')),
          0,
        );

        expect(
          Decimal.parse('-2.000000000000000000004')
              .compareTo(Decimal.parse('-2.000000000000000000009')),
          1,
        );
        expect(
          Decimal.parse('-2.000000000000000000004')
              .compareTo(Decimal.parse('-2.000000000000000000001')),
          -1,
        );
        expect(
          Decimal.parse('-2.000000000000000000004')
              .compareTo(Decimal.parse('-2.000000000000000000004')),
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
        expect(Decimal(100, shiftLeft: 1).compareTo(Decimal(1000)), 0);
        expect(Decimal(10, shiftLeft: 2).compareTo(Decimal(1000)), 0);
        expect(Decimal(1, shiftLeft: 3).compareTo(Decimal(1000)), 0);
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
      expectDecimal(Decimal(5).clamp(Decimal(3), Decimal(7)), '5');
      expectDecimal(Decimal(3).clamp(Decimal(3), Decimal(7)), '3');
      expectDecimal(Decimal(1).clamp(Decimal(3), Decimal(7)), '3');
      expectDecimal(Decimal(7).clamp(Decimal(3), Decimal(7)), '7');
      expectDecimal(Decimal(9).clamp(Decimal(3), Decimal(7)), '7');

      expectDecimal(Decimal(-5).clamp(Decimal(-7), Decimal(-3)), '-5');
      expectDecimal(Decimal(-3).clamp(Decimal(-7), Decimal(-3)), '-3');
      expectDecimal(Decimal(-1).clamp(Decimal(-7), Decimal(-3)), '-3');
      expectDecimal(Decimal(-7).clamp(Decimal(-7), Decimal(-3)), '-7');
      expectDecimal(Decimal(-9).clamp(Decimal(-7), Decimal(-3)), '-7');

      expectDecimal(
        Decimal(500).clamp(Decimal(4) << 2, Decimal(6) << 2),
        '500',
      );
      expectDecimal(
        Decimal(5, shiftRight: 2).clamp(
          Decimal.parse('0.0400'),
          Decimal.parse('0.060000'),
        ),
        '0.05',
      );

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
      expect(Decimal(0).isInteger, isTrue);
      expect(Decimal(0, shiftRight: 10).isInteger, isTrue);
      expect(Decimal(0, shiftLeft: 10).isInteger, isTrue);

      expect(Decimal(2).isInteger, isTrue);
      expect(Decimal(2, shiftRight: 1).isInteger, isFalse);
      expect(Decimal(2, shiftLeft: 1).isInteger, isTrue);

      expect(Decimal(-2).isInteger, isTrue);
      expect(Decimal(-2, shiftRight: 1).isInteger, isFalse);
      expect(Decimal(-2, shiftLeft: 1).isInteger, isTrue);

      expect(Decimal.parse('12345678901234567890').isInteger, isTrue);
      expect(
        Decimal.fromBigInt(BigInt.parse('12345678901234567890'), shiftRight: 1)
            .isInteger,
        isTrue,
      );
      expect(
        Decimal.fromBigInt(BigInt.parse('12345678901234567890'), shiftRight: 2)
            .isInteger,
        isFalse,
      );
      expect(
        Decimal.fromBigInt(BigInt.parse('12345678901234567890'), shiftLeft: 1)
            .isInteger,
        isTrue,
      );
      expect(
        Decimal.fromBigInt(BigInt.parse('12345678901234567890'), shiftLeft: 2)
            .isInteger,
        isTrue,
      );

      expect(Decimal.parse('12345678901234567890').isInteger, isTrue);
      expect(Decimal.parse('-12345678901234567890').isInteger, isTrue);
    });

    group('toStringAsFixed', () {
      test('0', () {
        expect(0.0.toStringAsFixed(0), '0');
        expect(Decimal(0).toStringAsFixed(0), '0');

        expect(0.0.toStringAsFixed(1), '0.0');
        expect(Decimal(0).toStringAsFixed(1), '0.0');

        expect(0.0.toStringAsFixed(2), '0.00');
        expect(Decimal(0).toStringAsFixed(2), '0.00');

        final v1 = Decimal(0, shiftLeft: 2);
        expectDecimal(
          v1,
          '0',
          value: BigInt.zero,
          scale: -2,
          fractionDigits: 0,
        );
        expect(v1.toStringAsFixed(0), '0');
        expect(v1.toStringAsFixed(1), '0.0');
        expect(v1.toStringAsFixed(2), '0.00');

        final v2 = Decimal(0, shiftRight: 2);
        expectDecimal(
          v2,
          '0',
          value: BigInt.zero,
          scale: 2,
          fractionDigits: 0,
        );
        expect(v2.toStringAsFixed(0), '0');
        expect(v2.toStringAsFixed(1), '0.0');
        expect(v2.toStringAsFixed(2), '0.00');
      });

      test('small', () {
        // +n
        var v1 = 3.75;
        var v2 = Decimal.parse('3.75');
        var v3 = Decimal(37500, shiftRight: 4);
        expectDecimal(
          v3,
          '3.75',
          value: BigInt.from(37500),
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
          value: BigInt.from(-37500),
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
          value: BigInt.parse(
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
          value: BigInt.parse(
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

      test('negative scale', () {
        // +n
        var v1 = Decimal(375, shiftLeft: 3);
        expectDecimal(
          v1,
          '375000',
          value: BigInt.from(375),
          scale: -3,
          fractionDigits: 0,
        );

        expect(v1.toStringAsFixed(0), '375000');
        expect(v1.toStringAsFixed(1), '375000.0');
        expect(v1.toStringAsFixed(2), '375000.00');

        // -n
        v1 = Decimal(-375, shiftLeft: 3);
        expectDecimal(
          v1,
          '-375000',
          value: BigInt.from(-375),
          scale: -3,
          fractionDigits: 0,
        );

        expect(v1.toStringAsFixed(0), '-375000');
        expect(v1.toStringAsFixed(1), '-375000.0');
        expect(v1.toStringAsFixed(2), '-375000.00');
      });
    });
  });

  group('ShortDecimal', () {
    test('toString', () {
      expectShortDecimal(ShortDecimal(0), '0');
      expectShortDecimal(ShortDecimal(0, scale: 1), '0');
      expectShortDecimal(ShortDecimal(0, scale: 2), '0');
      expectShortDecimal(ShortDecimal(0, scale: 3), '0');

      expectShortDecimal(ShortDecimal(1, scale: 3), '0.001');
      expectShortDecimal(ShortDecimal(1, scale: 2), '0.01');
      expectShortDecimal(ShortDecimal(1, scale: 1), '0.1');
      expectShortDecimal(ShortDecimal(1), '1');
      expectShortDecimal(ShortDecimal(10), '10');
      expectShortDecimal(ShortDecimal(100), '100');
      expectShortDecimal(ShortDecimal(1000), '1000');
      expectShortDecimal(ShortDecimal(1000, scale: 1), '100');
      expectShortDecimal(ShortDecimal(1000, scale: 2), '10');
      expectShortDecimal(ShortDecimal(1000, scale: 3), '1');
      expectShortDecimal(ShortDecimal(1000, scale: 4), '0.1');
      expectShortDecimal(ShortDecimal(1000, scale: 5), '0.01');
      expectShortDecimal(ShortDecimal(1000, scale: 6), '0.001');

      expectShortDecimal(ShortDecimal(1234567890), '1234567890');
      expectShortDecimal(ShortDecimal(1234567890, scale: 1), '123456789');
      expectShortDecimal(ShortDecimal(1234567890, scale: 2), '12345678.9');
      expectShortDecimal(ShortDecimal(1234567890, scale: 3), '1234567.89');
      expectShortDecimal(ShortDecimal(1234567890, scale: 4), '123456.789');
      expectShortDecimal(ShortDecimal(1234567890, scale: 5), '12345.6789');
      expectShortDecimal(ShortDecimal(1234567890, scale: 6), '1234.56789');
      expectShortDecimal(ShortDecimal(1234567890, scale: 7), '123.456789');
      expectShortDecimal(ShortDecimal(1234567890, scale: 8), '12.3456789');
      expectShortDecimal(ShortDecimal(1234567890, scale: 9), '1.23456789');
      expectShortDecimal(ShortDecimal(1234567890, scale: 10), '0.123456789');
      expectShortDecimal(ShortDecimal(1234567890, scale: 11), '0.0123456789');
      expectShortDecimal(ShortDecimal(1234567890, scale: 12), '0.00123456789');
      expectShortDecimal(ShortDecimal(1234567890, scale: 13), '0.000123456789');
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
      var f = Decimal.parse('1.2').fraction(Decimal.parse('2.1'));
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

      f = Decimal.parse('-1.2').fraction(Decimal.parse('2.1'));
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
}
