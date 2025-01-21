import 'package:decimal2/decimal2.dart';
import 'package:test/test.dart';

void expectDecimal(
  Decimal d,
  Object str, {
  BigInt? value,
  int? shift,
  int? precision,
}) {
  expect(d.toString(), str);

  if (value != null) {
    expect(d.value, value);
  }

  if (shift != null) {
    expect(d.shift, shift);
  }

  if (precision != null) {
    expect(d.fractionDigits, precision);
  }
}

void expectShortDecimal(ShortDecimal d, String str) =>
    expect(d.toString(), str);

void main() {
  group('Decimal', () {
    group('parse', () {
      test('0', () {
        expectDecimal(
          Decimal.parse('0'),
          '0',
          value: BigInt.zero,
          shift: 0,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('0.0'),
          '0',
          value: BigInt.zero,
          shift: -1,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('.0'),
          '0',
          value: BigInt.zero,
          shift: -1,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('00000.00000'),
          '0',
          value: BigInt.zero,
          shift: -5,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse(' 0'),
          '0',
          value: BigInt.zero,
          shift: 0,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('0 '),
          '0',
          value: BigInt.zero,
          shift: 0,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse(' 0.0'),
          '0',
          value: BigInt.zero,
          shift: -1,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('0.0 '),
          '0',
          value: BigInt.zero,
          shift: -1,
          precision: 0,
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
          shift: 0,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('-0.0'),
          '0',
          value: BigInt.zero,
          shift: -1,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('-.0'),
          '0',
          value: BigInt.zero,
          shift: -1,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('-00000.00000'),
          '0',
          value: BigInt.zero,
          shift: -5,
          precision: 0,
        );
      });

      test('1', () {
        expectDecimal(
          Decimal.parse('1'),
          '1',
          value: BigInt.one,
          shift: 0,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('0.1'),
          '0.1',
          value: BigInt.one,
          shift: -1,
          precision: 1,
        );
        expectDecimal(
          Decimal.parse('.1'),
          '0.1',
          value: BigInt.one,
          shift: -1,
          precision: 1,
        );
        expectDecimal(
          Decimal.parse('0.01'),
          '0.01',
          value: BigInt.one,
          shift: -2,
          precision: 2,
        );
        expectDecimal(
          Decimal.parse('0.001'),
          '0.001',
          value: BigInt.one,
          shift: -3,
          precision: 3,
        );
        expectDecimal(
          Decimal.parse('1.0'),
          '1',
          value: BigInt.from(10),
          shift: -1,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('1.00'),
          '1',
          value: BigInt.from(100),
          shift: -2,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('1.000'),
          '1',
          value: BigInt.from(1000),
          shift: -3,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('10'),
          '10',
          value: BigInt.from(10),
          shift: 0,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('100'),
          '100',
          value: BigInt.from(100),
          shift: 0,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('1000'),
          '1000',
          value: BigInt.from(1000),
          shift: 0,
          precision: 0,
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
          shift: 0,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('-0.1'),
          '-0.1',
          value: -BigInt.one,
          shift: -1,
          precision: 1,
        );
        expectDecimal(
          Decimal.parse('-0.01'),
          '-0.01',
          value: -BigInt.one,
          shift: -2,
          precision: 2,
        );
        expectDecimal(
          Decimal.parse('-0.001'),
          '-0.001',
          value: -BigInt.one,
          shift: -3,
          precision: 3,
        );
        expectDecimal(
          Decimal.parse('-1.0'),
          '-1',
          value: BigInt.from(-10),
          shift: -1,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('-1.00'),
          '-1',
          value: BigInt.from(-100),
          shift: -2,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('-1.000'),
          '-1',
          value: BigInt.from(-1000),
          shift: -3,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('-10'),
          '-10',
          value: BigInt.from(-10),
          shift: 0,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('-100'),
          '-100',
          value: BigInt.from(-100),
          shift: 0,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('-1000'),
          '-1000',
          value: BigInt.from(-1000),
          shift: 0,
          precision: 0,
        );
      });

      test('int', () {
        expectDecimal(
          Decimal.parse('1234567890'),
          '1234567890',
          value: BigInt.from(1234567890),
          shift: 0,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('123456789.0'),
          '123456789',
          value: BigInt.from(1234567890),
          shift: -1,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('12345678.90'),
          '12345678.9',
          value: BigInt.from(1234567890),
          shift: -2,
          precision: 1,
        );
        expectDecimal(
          Decimal.parse('1234567.890'),
          '1234567.89',
          value: BigInt.from(1234567890),
          shift: -3,
          precision: 2,
        );
        expectDecimal(
          Decimal.parse('123456.7890'),
          '123456.789',
          value: BigInt.from(1234567890),
          shift: -4,
          precision: 3,
        );
        expectDecimal(
          Decimal.parse('12345.67890'),
          '12345.6789',
          value: BigInt.from(1234567890),
          shift: -5,
          precision: 4,
        );
        expectDecimal(
          Decimal.parse('1234.567890'),
          '1234.56789',
          value: BigInt.from(1234567890),
          shift: -6,
          precision: 5,
        );
        expectDecimal(
          Decimal.parse('123.4567890'),
          '123.456789',
          value: BigInt.from(1234567890),
          shift: -7,
          precision: 6,
        );
        expectDecimal(
          Decimal.parse('12.34567890'),
          '12.3456789',
          value: BigInt.from(1234567890),
          shift: -8,
          precision: 7,
        );
        expectDecimal(
          Decimal.parse('1.234567890'),
          '1.23456789',
          value: BigInt.from(1234567890),
          shift: -9,
          precision: 8,
        );
        expectDecimal(
          Decimal.parse('0.1234567890'),
          '0.123456789',
          value: BigInt.from(1234567890),
          shift: -10,
          precision: 9,
        );
        expectDecimal(
          Decimal.parse('0.01234567890'),
          '0.0123456789',
          value: BigInt.from(1234567890),
          shift: -11,
          precision: 10,
        );
        expectDecimal(
          Decimal.parse('0.001234567890'),
          '0.00123456789',
          value: BigInt.from(1234567890),
          shift: -12,
          precision: 11,
        );
        expectDecimal(
          Decimal.parse('0.0001234567890'),
          '0.000123456789',
          value: BigInt.from(1234567890),
          shift: -13,
          precision: 12,
        );

        expectDecimal(
          Decimal.parse('-1234567890'),
          '-1234567890',
          value: BigInt.from(-1234567890),
          shift: 0,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('-123456789.0'),
          '-123456789',
          value: BigInt.from(-1234567890),
          shift: -1,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('-12345678.90'),
          '-12345678.9',
          value: BigInt.from(-1234567890),
          shift: -2,
          precision: 1,
        );
        expectDecimal(
          Decimal.parse('-1234567.890'),
          '-1234567.89',
          value: BigInt.from(-1234567890),
          shift: -3,
          precision: 2,
        );
        expectDecimal(
          Decimal.parse('-123456.7890'),
          '-123456.789',
          value: BigInt.from(-1234567890),
          shift: -4,
          precision: 3,
        );
        expectDecimal(
          Decimal.parse('-12345.67890'),
          '-12345.6789',
          value: BigInt.from(-1234567890),
          shift: -5,
          precision: 4,
        );
        expectDecimal(
          Decimal.parse('-1234.567890'),
          '-1234.56789',
          value: BigInt.from(-1234567890),
          shift: -6,
          precision: 5,
        );
        expectDecimal(
          Decimal.parse('-123.4567890'),
          '-123.456789',
          value: BigInt.from(-1234567890),
          shift: -7,
          precision: 6,
        );
        expectDecimal(
          Decimal.parse('-12.34567890'),
          '-12.3456789',
          value: BigInt.from(-1234567890),
          shift: -8,
          precision: 7,
        );
        expectDecimal(
          Decimal.parse('-1.234567890'),
          '-1.23456789',
          value: BigInt.from(-1234567890),
          shift: -9,
          precision: 8,
        );
        expectDecimal(
          Decimal.parse('-0.1234567890'),
          '-0.123456789',
          value: BigInt.from(-1234567890),
          shift: -10,
          precision: 9,
        );
        expectDecimal(
          Decimal.parse('-0.01234567890'),
          '-0.0123456789',
          value: BigInt.from(-1234567890),
          shift: -11,
          precision: 10,
        );
        expectDecimal(
          Decimal.parse('-0.001234567890'),
          '-0.00123456789',
          value: BigInt.from(-1234567890),
          shift: -12,
          precision: 11,
        );
        expectDecimal(
          Decimal.parse('-0.0001234567890'),
          '-0.000123456789',
          value: BigInt.from(-1234567890),
          shift: -13,
          precision: 12,
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
          shift: 0,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse(
            '123456789012345678901234567890.1234567890',
          ),
          '123456789012345678901234567890.123456789',
          value: BigInt.parse('1234567890123456789012345678901234567890'),
          shift: -10,
          precision: 9,
        );
        expectDecimal(
          Decimal.parse(
            '12345678901234567890.12345678901234567890',
          ),
          '12345678901234567890.1234567890123456789',
          value: BigInt.parse('1234567890123456789012345678901234567890'),
          shift: -20,
          precision: 19,
        );
        expectDecimal(
          Decimal.parse(
            '1234567890.123456789012345678901234567890',
          ),
          '1234567890.12345678901234567890123456789',
          value: BigInt.parse('1234567890123456789012345678901234567890'),
          shift: -30,
          precision: 29,
        );
        expectDecimal(
          Decimal.parse(
            '0.1234567890123456789012345678901234567890',
          ),
          '0.123456789012345678901234567890123456789',
          value: BigInt.parse('1234567890123456789012345678901234567890'),
          shift: -40,
          precision: 39,
        );
        expectDecimal(
          Decimal.parse(
            '0.00000000001234567890123456789012345678901234567890',
          ),
          '0.0000000000123456789012345678901234567890123456789',
          value: BigInt.parse('1234567890123456789012345678901234567890'),
          shift: -50,
          precision: 49,
        );

        expectDecimal(
          Decimal.parse(
            '-1234567890123456789012345678901234567890',
          ),
          '-1234567890123456789012345678901234567890',
          value: BigInt.parse('-1234567890123456789012345678901234567890'),
          shift: 0,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse(
            '-123456789012345678901234567890.1234567890',
          ),
          '-123456789012345678901234567890.123456789',
          value: BigInt.parse('-1234567890123456789012345678901234567890'),
          shift: -10,
          precision: 9,
        );
        expectDecimal(
          Decimal.parse(
            '-12345678901234567890.12345678901234567890',
          ),
          '-12345678901234567890.1234567890123456789',
          value: BigInt.parse('-1234567890123456789012345678901234567890'),
          shift: -20,
          precision: 19,
        );
        expectDecimal(
          Decimal.parse(
            '-1234567890.123456789012345678901234567890',
          ),
          '-1234567890.12345678901234567890123456789',
          value: BigInt.parse('-1234567890123456789012345678901234567890'),
          shift: -30,
          precision: 29,
        );
        expectDecimal(
          Decimal.parse(
            '-0.1234567890123456789012345678901234567890',
          ),
          '-0.123456789012345678901234567890123456789',
          value: BigInt.parse('-1234567890123456789012345678901234567890'),
          shift: -40,
          precision: 39,
        );
        expectDecimal(
          Decimal.parse(
            '-0.00000000001234567890123456789012345678901234567890',
          ),
          '-0.0000000000123456789012345678901234567890123456789',
          value: BigInt.parse('-1234567890123456789012345678901234567890'),
          shift: -50,
          precision: 49,
        );

        expectDecimal(
          Decimal.parse('1000000000000000000000000000000'),
          '1000000000000000000000000000000',
          value: BigInt.parse('1000000000000000000000000000000'),
          shift: 0,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('100000000000000000000.0000000000'),
          '100000000000000000000',
          value: BigInt.parse('1000000000000000000000000000000'),
          shift: -10,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('10000000000.00000000000000000000'),
          '10000000000',
          value: BigInt.parse('1000000000000000000000000000000'),
          shift: -20,
          precision: 0,
        );
        expectDecimal(
          Decimal.parse('1.000000000000000000000000000000'),
          '1',
          value: BigInt.parse('1000000000000000000000000000000'),
          shift: -30,
          precision: 0,
        );
      });
    });

    test('add', () {
      var value = Decimal(1, shiftLeft: 4);
      expectDecimal(
        value += Decimal(1, shiftLeft: 3),
        '11000',
        value: BigInt.from(11),
        shift: 3,
        precision: 0,
      );
      expectDecimal(
        value += Decimal(1, shiftLeft: 2),
        '11100',
        value: BigInt.from(111),
        shift: 2,
        precision: 0,
      );
      expectDecimal(
        value += Decimal(1, shiftLeft: 1),
        '11110',
        value: BigInt.from(1111),
        shift: 1,
        precision: 0,
      );
      expectDecimal(
        value += Decimal(10000, shiftRight: 4), // 1
        '11111',
        value: BigInt.from(111110000),
        shift: -4,
        precision: 0,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 1),
        '11111.1',
        value: BigInt.from(111111000),
        shift: -4,
        precision: 1,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 2),
        '11111.11',
        value: BigInt.from(111111100),
        shift: -4,
        precision: 2,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 3),
        '11111.111',
        value: BigInt.from(111111110),
        shift: -4,
        precision: 3,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 4),
        '11111.1111',
        value: BigInt.from(111111111),
        shift: -4,
        precision: 4,
      );
      expectDecimal(
        value += Decimal(1, shiftRight: 5),
        '11111.11111',
        value: BigInt.from(1111111111),
        shift: -5,
        precision: 5,
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
        shift: -39,
        precision: 20,
      );
    });

    test('multiply', () {
      expectDecimal(
        Decimal(123, shiftRight: 2) * Decimal(456, shiftRight: 1),
        '56.088',
        value: BigInt.from(56088),
        shift: -3,
        precision: 3,
      );
      expectDecimal(
        Decimal(-123, shiftRight: 2) * Decimal(456, shiftRight: 1),
        '-56.088',
        value: BigInt.from(-56088),
        shift: -3,
        precision: 3,
      );
      expectDecimal(
        Decimal(123, shiftRight: 2) * Decimal(-456, shiftRight: 1),
        '-56.088',
        value: BigInt.from(-56088),
        shift: -3,
        precision: 3,
      );
      expectDecimal(
        Decimal(-123, shiftRight: 2) * Decimal(-456, shiftRight: 1),
        '56.088',
        value: BigInt.from(56088),
        shift: -3,
        precision: 3,
      );

      var value = Decimal.parse('123456.00');
      expectDecimal(
        value *= Decimal.parse('12345.6'),
        '1524138393.6',
        value: BigInt.from(1524138393600),
        shift: -3,
        precision: 1,
      );
      expectDecimal(
        value *= Decimal.parse('1234.56'),
        '1881640295202.816',
        value: BigInt.from(188164029520281600),
        shift: -5,
        precision: 3,
      );
      expectDecimal(
        value *= Decimal.parse('123.456'),
        '232299784284558.852096',
        value: BigInt.parse('23229978428455885209600'),
        shift: -8,
        precision: 6,
      );
      expectDecimal(
        value *= Decimal.parse('12.3456'),
        '2867880216863449.7644363776',
        value: BigInt.parse('2867880216863449764436377600'),
        shift: -12,
        precision: 10,
      );
      expectDecimal(
        value *= Decimal.parse('1.23456'),
        '3540570200530940.541182574329856',
        value: BigInt.parse('354057020053094054118257432985600'),
        shift: -17,
        precision: 15,
      );

      value = Decimal.parse('-123456');
      expectDecimal(
        value *= Decimal.parse('12345.6'),
        '-1524138393.6',
        value: BigInt.from(-15241383936),
        shift: -1,
        precision: 1,
      );
      expectDecimal(
        value *= Decimal.parse('-1234.56'),
        '1881640295202.816',
        value: BigInt.from(1881640295202816),
        shift: -3,
        precision: 3,
      );
      expectDecimal(
        value *= Decimal.parse('-123.456'),
        '-232299784284558.852096',
        value: BigInt.parse('-232299784284558852096'),
        shift: -6,
        precision: 6,
      );
      expectDecimal(
        value *= Decimal.parse('-12.3456'),
        '2867880216863449.7644363776',
        value: BigInt.parse('28678802168634497644363776'),
        shift: -10,
        precision: 10,
      );
      expectDecimal(
        value *= Decimal.parse('-1.23456'),
        '-3540570200530940.541182574329856',
        value: BigInt.parse('-3540570200530940541182574329856'),
        shift: -15,
        precision: 15,
      );
    });

    group('divide', () {
      test('success', () {
        expectDecimal(
          Decimal(24, shiftRight: 1) / Decimal(12, shiftRight: 1),
          '2',
          value: BigInt.two,
          shift: 0,
          precision: 0,
        );

        var value = Decimal.parse('3540570200530940.541182574329856');
        expectDecimal(
          value /= Decimal(123456),
          '28678802168.634497644363776',
          value: BigInt.parse('28678802168634497644363776'),
          shift: -15,
          precision: 15,
        );
        expectDecimal(
          value /= Decimal.parse('12345.6'),
          '2322997.84284558852096',
          value: BigInt.parse('232299784284558852096'),
          shift: -14,
          precision: 14,
        );
        expectDecimal(
          value /= Decimal.parse('1234.56'),
          '1881.640295202816',
          value: BigInt.from(1881640295202816),
          shift: -12,
          precision: 12,
        );
        expectDecimal(
          value /= Decimal.parse('123.456'),
          '15.241383936',
          value: BigInt.from(15241383936),
          shift: -9,
          precision: 9,
        );
        expectDecimal(
          value /= Decimal.parse('12.3456'),
          '1.23456',
          value: BigInt.from(123456),
          shift: -5,
          precision: 5,
        );
        expectDecimal(
          value /= Decimal.parse('1.23456'),
          '1',
          value: BigInt.one,
          shift: 0,
          precision: 0,
        );

        expect(
          () => Decimal(15129, shiftRight: 1) / Decimal(86100),
          throwsA(
            predicate(
              (error) =>
                  error is DecimalDivideException &&
                  error.numerator.toString() == '0.123' &&
                  error.denominator.toString() == '7',
            ),
          ),
        );
      });

      group('DecimalDivideException', () {
        test('0.5', () {
          // round
          expect(0.5.round(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), BigInt.two).round(),
            '1',
          );

          expect((-0.5).round(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), BigInt.two).round(),
            '-1',
          );

          expect((-1.5).round(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-3), BigInt.two).round(),
            '-2',
          );

          // floor
          expect(0.5.floor(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), BigInt.two).floor(),
            '0',
          );

          expect((-0.5).floor(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), BigInt.two).floor(),
            '-1',
          );

          expect((-1.5).floor(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-3), BigInt.two).floor(),
            '-2',
          );

          // ceil
          expect(0.5.ceil(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), BigInt.two).ceil(),
            '1',
          );

          expect((-0.5).ceil(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), BigInt.two).ceil(),
            '0',
          );

          expect((-1.5).ceil(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-3), BigInt.two).ceil(),
            '-1',
          );

          // truncate
          expect(0.5.truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), BigInt.two).truncate(),
            '0',
          );

          expect((-0.5).truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), BigInt.two).truncate(),
            '0',
          );

          expect((-1.5).truncate(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-3), BigInt.two).truncate(),
            '-1',
          );
        });

        test('0.1', () {
          // round
          expect(0.1.round(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), BigInt.from(10)).round(),
            '0',
          );

          expect((-0.1).round(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), BigInt.from(10))
                .round(),
            '0',
          );

          expect((-1.1).round(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-11), BigInt.from(10))
                .round(),
            '-1',
          );

          // floor
          expect(0.1.floor(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), BigInt.from(10)).floor(),
            '0',
          );

          expect((-0.1).floor(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), BigInt.from(10))
                .floor(),
            '-1',
          );

          expect((-1.1).floor(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-11), BigInt.from(10))
                .floor(),
            '-2',
          );

          // ceil
          expect(0.1.ceil(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), BigInt.from(10)).ceil(),
            '1',
          );

          expect((-0.1).ceil(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), BigInt.from(10)).ceil(),
            '0',
          );

          expect((-1.1).ceil(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-11), BigInt.from(10))
                .ceil(),
            '-1',
          );

          // truncate
          expect(0.1.truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), BigInt.from(10)).floor(),
            '0',
          );

          expect((-0.1).truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), BigInt.from(10))
                .truncate(),
            '0',
          );

          expect((-1.1).truncate(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-11), BigInt.from(10))
                .truncate(),
            '-1',
          );
        });

        test('0.9', () {
          // round
          expect(0.9.round(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(9), BigInt.from(10)).round(),
            '1',
          );

          expect((-0.9).round(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-9), BigInt.from(10))
                .round(),
            '-1',
          );

          expect((-1.9).round(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-19), BigInt.from(10))
                .round(),
            '-2',
          );

          // floor
          expect(0.9.floor(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(9), BigInt.from(10)).floor(),
            '0',
          );

          expect((-0.9).floor(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-9), BigInt.from(10))
                .floor(),
            '-1',
          );

          expect((-1.9).floor(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-19), BigInt.from(10))
                .floor(),
            '-2',
          );

          // ceil
          expect(0.9.ceil(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(9), BigInt.from(10)).ceil(),
            '1',
          );

          expect((-0.9).ceil(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-9), BigInt.from(10)).ceil(),
            '0',
          );

          expect((-1.9).ceil(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-19), BigInt.from(10))
                .ceil(),
            '-1',
          );

          // truncate
          expect(0.9.truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(9), BigInt.from(10)).floor(),
            '0',
          );

          expect((-0.9).truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-9), BigInt.from(10))
                .truncate(),
            '0',
          );

          expect((-1.1).truncate(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-19), BigInt.from(10))
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
            expectDecimal(
              e.floor(fractionDigits: 3),
              '0.017',
            );
            expect((1512.9 * 1000 / 86100).round(), 18);
            expectDecimal(
              e.round(fractionDigits: 3),
              '0.018',
            );
            expect((1512.9 * 1000 / 86100).ceil(), 18);
            expectDecimal(
              e.ceil(fractionDigits: 3),
              '0.018',
            );
            expect((1512.9 * 1000 / 86100).truncate(), 17);
            expectDecimal(
              e.truncate(fractionDigits: 5),
              '0.01757',
            );

            // 0.017571(4)
            expect((1512.9 * 1000000 / 86100).floor(), 17571);
            expectDecimal(
              e.floor(fractionDigits: 6),
              '0.017571',
            );
            expect((1512.9 * 1000000 / 86100).round(), 17571);
            expectDecimal(
              e.round(fractionDigits: 6),
              '0.017571',
            );
            expect((1512.9 * 1000000 / 86100).ceil(), 17572);
            expectDecimal(
              e.ceil(fractionDigits: 6),
              '0.017572',
            );
            expect((1512.9 * 1000000 / 86100).truncate(), 17571);
            expectDecimal(
              e.truncate(fractionDigits: 6),
              '0.017571',
            );

            // 0.017571428(5)
            expect((1512.9 * 1000000000 / 86100).floor(), 17571428);
            expectDecimal(
              e.floor(fractionDigits: 9),
              '0.017571428',
            );
            expect((1512.9 * 1000000000 / 86100).round(), 17571429);
            expectDecimal(
              e.round(fractionDigits: 9),
              '0.017571429',
            );
            expect((1512.9 * 1000000000 / 86100).ceil(), 17571429);
            expectDecimal(
              e.ceil(fractionDigits: 9),
              '0.017571429',
            );
            expect((1512.9 * 1000000000 / 86100).truncate(), 17571428);
            expectDecimal(
              e.truncate(fractionDigits: 9),
              '0.017571428',
            );
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
            expectDecimal(
              e.floor(fractionDigits: 3),
              '-0.018',
            );
            expect((1512.9 * 1000 / -86100).round(), -18);
            expectDecimal(
              e.round(fractionDigits: 3),
              '-0.018',
            );
            expect((1512.9 * 1000 / -86100).ceil(), -17);
            expectDecimal(
              e.ceil(fractionDigits: 3),
              '-0.017',
            );
            expect((1512.9 * 1000 / -86100).truncate(), -17);
            expectDecimal(
              e.truncate(fractionDigits: 3),
              '-0.017',
            );

            // -0.017571(4)
            expect((1512.9 * 1000000 / -86100).floor(), -17572);
            expectDecimal(
              e.floor(fractionDigits: 6),
              '-0.017572',
            );
            expect((1512.9 * 1000000 / -86100).round(), -17571);
            expectDecimal(
              e.round(fractionDigits: 6),
              '-0.017571',
            );
            expect((1512.9 * 1000000 / -86100).ceil(), -17571);
            expectDecimal(
              e.ceil(fractionDigits: 6),
              '-0.017571',
            );
            expect((1512.9 * 1000000 / -86100).truncate(), -17571);
            expectDecimal(
              e.truncate(fractionDigits: 6),
              '-0.017571',
            );

            // -0.017571428(5)
            expect((1512.9 * 1000000000 / -86100).floor(), -17571429);
            expectDecimal(
              e.floor(fractionDigits: 9),
              '-0.017571429',
            );
            expect((1512.9 * 1000000000 / -86100).round(), -17571429);
            expectDecimal(
              e.round(fractionDigits: 9),
              '-0.017571429',
            );
            expect((1512.9 * 1000000000 / -86100).ceil(), -17571428);
            expectDecimal(
              e.ceil(fractionDigits: 9),
              '-0.017571428',
            );
            expect((1512.9 * 1000000000 / -86100).truncate(), -17571428);
            expectDecimal(
              e.truncate(fractionDigits: 9),
              '-0.017571428',
            );
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
            expectDecimal(
              e.floor(fractionDigits: 3),
              '-0.018',
            );
            expect((-1512.9 * 1000 / 86100).round(), -18);
            expectDecimal(
              e.round(fractionDigits: 3),
              '-0.018',
            );
            expect((-1512.9 * 1000 / 86100).ceil(), -17);
            expectDecimal(
              e.ceil(fractionDigits: 3),
              '-0.017',
            );
            expect((-1512.9 * 1000 / 86100).truncate(), -17);
            expectDecimal(
              e.truncate(fractionDigits: 3),
              '-0.017',
            );

            // -0.017571(4)
            expect((-1512.9 * 1000000 / 86100).floor(), -17572);
            expectDecimal(
              e.floor(fractionDigits: 6),
              '-0.017572',
            );
            expect((-1512.9 * 1000000 / 86100).round(), -17571);
            expectDecimal(
              e.round(fractionDigits: 6),
              '-0.017571',
            );
            expect((-1512.9 * 1000000 / 86100).ceil(), -17571);
            expectDecimal(
              e.ceil(fractionDigits: 6),
              '-0.017571',
            );
            expect((-1512.9 * 1000000 / 86100).truncate(), -17571);
            expectDecimal(
              e.truncate(fractionDigits: 6),
              '-0.017571',
            );

            // -0.017571428(5)
            expect((-1512.9 * 1000000000 / 86100).floor(), -17571429);
            expectDecimal(
              e.floor(fractionDigits: 9),
              '-0.017571429',
            );
            expect((-1512.9 * 1000000000 / 86100).round(), -17571429);
            expectDecimal(
              e.round(fractionDigits: 9),
              '-0.017571429',
            );
            expect((-1512.9 * 1000000000 / 86100).ceil(), -17571428);
            expectDecimal(
              e.ceil(fractionDigits: 9),
              '-0.017571428',
            );
            expect((-1512.9 * 1000000000 / 86100).truncate(), -17571428);
            expectDecimal(
              e.truncate(fractionDigits: 9),
              '-0.017571428',
            );
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
            expectDecimal(
              e.floor(fractionDigits: 3),
              '0.017',
            );
            expect((-1512.9 * 1000 / -86100).round(), 18);
            expectDecimal(
              e.round(fractionDigits: 3),
              '0.018',
            );
            expect((-1512.9 * 1000 / -86100).ceil(), 18);
            expectDecimal(
              e.ceil(fractionDigits: 3),
              '0.018',
            );
            expect((-1512.9 * 1000 / -86100).truncate(), 17);
            expectDecimal(
              e.truncate(fractionDigits: 5),
              '0.01757',
            );

            // 0.017571(4)
            expect((-1512.9 * 1000000 / -86100).floor(), 17571);
            expectDecimal(
              e.floor(fractionDigits: 6),
              '0.017571',
            );
            expect((-1512.9 * 1000000 / -86100).round(), 17571);
            expectDecimal(
              e.round(fractionDigits: 6),
              '0.017571',
            );
            expect((-1512.9 * 1000000 / -86100).ceil(), 17572);
            expectDecimal(
              e.ceil(fractionDigits: 6),
              '0.017572',
            );
            expect((-1512.9 * 1000000 / -86100).truncate(), 17571);
            expectDecimal(
              e.truncate(fractionDigits: 6),
              '0.017571',
            );

            // 0.017571428(5)
            expect((-1512.9 * 1000000000 / -86100).floor(), 17571428);
            expectDecimal(
              e.floor(fractionDigits: 9),
              '0.017571428',
            );
            expect((-1512.9 * 1000000000 / -86100).round(), 17571429);
            expectDecimal(
              e.round(fractionDigits: 9),
              '0.017571429',
            );
            expect((-1512.9 * 1000000000 / -86100).ceil(), 17571429);
            expectDecimal(
              e.ceil(fractionDigits: 9),
              '0.017571429',
            );
            expect((-1512.9 * 1000000000 / -86100).truncate(), 17571428);
            expectDecimal(
              e.truncate(fractionDigits: 9),
              '0.017571428',
            );
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

            expectDecimal(
              e.numerator,
              '7100000',
              value: BigInt.from(7100),
              shift: 3,
              precision: 0,
            );
            expect(e.denominator, BigInt.from(7));
          }

          expectDecimal(
            v1 ~/ v2,
            '1014285',
            value: BigInt.from(1014285),
            shift: 0,
            precision: 0,
          );
          expectDecimal(
            v1 % v2,
            '0.00615',
            value: BigInt.from(61500),
            shift: -7,
            precision: 5,
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

            expectDecimal(
              e.numerator,
              '-7100000',
              value: BigInt.from(-7100),
              shift: 3,
            );
            expect(e.denominator, BigInt.from(7));
          }

          expectDecimal(
            v1 ~/ v2,
            '-1014285',
            value: BigInt.from(-1014285),
            shift: 0,
            precision: 0,
          );
          expectDecimal(
            v1 % v2,
            '0.00615',
            value: BigInt.from(61500),
            shift: -7,
            precision: 5,
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
            expectDecimal(e.floor(fractionDigits: 6), '1.101428');
            expectDecimal(e.round(fractionDigits: 6), '1.101429');
            expectDecimal(e.ceil(fractionDigits: 6), '1.101429');
            expectDecimal(e.truncate(fractionDigits: 6), '1.101428');
            expectDecimal(e.truncate(fractionDigits: 12), '1.101428571428');

            expectDecimal(
              e.numerator,
              '7.71',
              value: BigInt.from(7710000),
              shift: -6,
              precision: 2,
            );
            expect(e.denominator, BigInt.from(7));
          }

          expectDecimal(
            v1 ~/ v2,
            '1',
            value: BigInt.one,
            shift: 0,
            precision: 0,
          );
          expectDecimal(
            v1 % v2,
            '8733',
            value: BigInt.from(873300),
            shift: -2,
            precision: 0,
          );
        });
      });
    });

    test('pow', () {
      expectDecimal(
        Decimal(2).pow(4),
        '16',
        value: BigInt.from(16),
        shift: 0,
        precision: 0,
      );

      expectDecimal(
        Decimal(2, shiftRight: 1).pow(4),
        '0.0016',
        value: BigInt.from(16),
        shift: -4,
        precision: 4,
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
  });

  group('ShortDecimal', () {
    test('toString', () {
      expectShortDecimal(ShortDecimal(0), '0');
      expectShortDecimal(ShortDecimal(0, shift: 1), '0');
      expectShortDecimal(ShortDecimal(0, shift: 2), '0');
      expectShortDecimal(ShortDecimal(0, shift: 3), '0');

      expectShortDecimal(ShortDecimal(1, shift: 3), '0.001');
      expectShortDecimal(ShortDecimal(1, shift: 2), '0.01');
      expectShortDecimal(ShortDecimal(1, shift: 1), '0.1');
      expectShortDecimal(ShortDecimal(1), '1');
      expectShortDecimal(ShortDecimal(10), '10');
      expectShortDecimal(ShortDecimal(100), '100');
      expectShortDecimal(ShortDecimal(1000), '1000');
      expectShortDecimal(ShortDecimal(1000, shift: 1), '100');
      expectShortDecimal(ShortDecimal(1000, shift: 2), '10');
      expectShortDecimal(ShortDecimal(1000, shift: 3), '1');
      expectShortDecimal(ShortDecimal(1000, shift: 4), '0.1');
      expectShortDecimal(ShortDecimal(1000, shift: 5), '0.01');
      expectShortDecimal(ShortDecimal(1000, shift: 6), '0.001');

      expectShortDecimal(ShortDecimal(1234567890), '1234567890');
      expectShortDecimal(ShortDecimal(1234567890, shift: 1), '123456789');
      expectShortDecimal(ShortDecimal(1234567890, shift: 2), '12345678.9');
      expectShortDecimal(ShortDecimal(1234567890, shift: 3), '1234567.89');
      expectShortDecimal(ShortDecimal(1234567890, shift: 4), '123456.789');
      expectShortDecimal(ShortDecimal(1234567890, shift: 5), '12345.6789');
      expectShortDecimal(ShortDecimal(1234567890, shift: 6), '1234.56789');
      expectShortDecimal(ShortDecimal(1234567890, shift: 7), '123.456789');
      expectShortDecimal(ShortDecimal(1234567890, shift: 8), '12.3456789');
      expectShortDecimal(ShortDecimal(1234567890, shift: 9), '1.23456789');
      expectShortDecimal(ShortDecimal(1234567890, shift: 10), '0.123456789');
      expectShortDecimal(ShortDecimal(1234567890, shift: 11), '0.0123456789');
      expectShortDecimal(ShortDecimal(1234567890, shift: 12), '0.00123456789');
      expectShortDecimal(ShortDecimal(1234567890, shift: 13), '0.000123456789');
    });
  });
}
