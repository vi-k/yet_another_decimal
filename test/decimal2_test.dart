import 'package:decimal2/decimal2.dart';
import 'package:test/test.dart';

void expectDecimal(
  Decimal d,
  Object str, {
  int? s,
  int? p,
}) {
  expect(d.toString(), str);
  if (s != null) {
    expect(d.scale, s);
  }
  if (p != null) {
    expect(d.precision, p);
  }
}

void expectShortDecimal(ShortDecimal d, String str) =>
    expect(d.toString(), str);

void main() {
  group('Decimal', () {
    test('parse', () {
      expectDecimal(Decimal.parse('0'), '0', s: 0, p: 0);
      expectDecimal(Decimal.parse('0.0'), '0', s: 1, p: 0);
      expectDecimal(Decimal.parse('.0'), '0', s: 1, p: 0);
      expectDecimal(Decimal.parse('00000.00000'), '0', s: 5, p: 0);
      expectDecimal(Decimal.parse(' 0'), '0', s: 0, p: 0);
      expectDecimal(Decimal.parse('0 '), '0', s: 0, p: 0);
      expectDecimal(Decimal.parse(' 0.0'), '0', s: 1, p: 0);
      expectDecimal(Decimal.parse('0.0 '), '0', s: 1, p: 0);

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

      expectDecimal(Decimal.parse('-0'), '0', s: 0, p: 0);
      expectDecimal(Decimal.parse('-0.0'), '0', s: 1, p: 0);
      expectDecimal(Decimal.parse('-.0'), '0', s: 1, p: 0);
      expectDecimal(Decimal.parse('-00000.00000'), '0', s: 5, p: 0);

      expectDecimal(Decimal.parse('1'), '1', s: 0, p: 0);
      expectDecimal(Decimal.parse('0.1'), '0.1', s: 1, p: 1);
      expectDecimal(Decimal.parse('.1'), '0.1', s: 1, p: 1);
      expectDecimal(Decimal.parse('0.01'), '0.01', s: 2, p: 2);
      expectDecimal(Decimal.parse('0.001'), '0.001', s: 3, p: 3);
      expectDecimal(Decimal.parse('1.0'), '1', s: 1, p: 0);
      expectDecimal(Decimal.parse('1.00'), '1', s: 2, p: 0);
      expectDecimal(Decimal.parse('1.000'), '1', s: 3, p: 0);
      expectDecimal(Decimal.parse('10'), '10', s: 0, p: 0);
      expectDecimal(Decimal.parse('100'), '100', s: 0, p: 0);
      expectDecimal(Decimal.parse('1000'), '1000', s: 0, p: 0);

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

      expectDecimal(Decimal.parse('-1'), '-1', s: 0, p: 0);
      expectDecimal(Decimal.parse('-0.1'), '-0.1', s: 1, p: 1);
      expectDecimal(Decimal.parse('-0.01'), '-0.01', s: 2, p: 2);
      expectDecimal(Decimal.parse('-0.001'), '-0.001', s: 3, p: 3);
      expectDecimal(Decimal.parse('-1.0'), '-1', s: 1, p: 0);
      expectDecimal(Decimal.parse('-1.00'), '-1', s: 2, p: 0);
      expectDecimal(Decimal.parse('-1.000'), '-1', s: 3, p: 0);
      expectDecimal(Decimal.parse('-10'), '-10', s: 0, p: 0);
      expectDecimal(Decimal.parse('-100'), '-100', s: 0, p: 0);
      expectDecimal(Decimal.parse('-1000'), '-1000', s: 0, p: 0);

      expectDecimal(Decimal.parse('1234567890'), '1234567890', s: 0, p: 0);
      expectDecimal(Decimal.parse('123456789.0'), '123456789', s: 1, p: 0);
      expectDecimal(Decimal.parse('12345678.90'), '12345678.9', s: 2, p: 1);
      expectDecimal(Decimal.parse('1234567.890'), '1234567.89', s: 3, p: 2);
      expectDecimal(Decimal.parse('123456.7890'), '123456.789', s: 4, p: 3);
      expectDecimal(Decimal.parse('12345.67890'), '12345.6789', s: 5, p: 4);
      expectDecimal(Decimal.parse('1234.567890'), '1234.56789', s: 6, p: 5);
      expectDecimal(Decimal.parse('123.4567890'), '123.456789', s: 7, p: 6);
      expectDecimal(Decimal.parse('12.34567890'), '12.3456789', s: 8, p: 7);
      expectDecimal(Decimal.parse('1.234567890'), '1.23456789', s: 9, p: 8);
      expectDecimal(Decimal.parse('0.1234567890'), '0.123456789', s: 10, p: 9);
      expectDecimal(
        Decimal.parse('0.01234567890'),
        '0.0123456789',
        s: 11,
        p: 10,
      );
      expectDecimal(
        Decimal.parse('0.001234567890'),
        '0.00123456789',
        s: 12,
        p: 11,
      );
      expectDecimal(
        Decimal.parse('0.0001234567890'),
        '0.000123456789',
        s: 13,
        p: 12,
      );

      expectDecimal(Decimal.parse('-1234567890'), '-1234567890', s: 0, p: 0);
      expectDecimal(Decimal.parse('-123456789.0'), '-123456789', s: 1, p: 0);
      expectDecimal(Decimal.parse('-12345678.90'), '-12345678.9', s: 2, p: 1);
      expectDecimal(Decimal.parse('-1234567.890'), '-1234567.89', s: 3, p: 2);
      expectDecimal(Decimal.parse('-123456.7890'), '-123456.789', s: 4, p: 3);
      expectDecimal(Decimal.parse('-12345.67890'), '-12345.6789', s: 5, p: 4);
      expectDecimal(Decimal.parse('-1234.567890'), '-1234.56789', s: 6, p: 5);
      expectDecimal(Decimal.parse('-123.4567890'), '-123.456789', s: 7, p: 6);
      expectDecimal(Decimal.parse('-12.34567890'), '-12.3456789', s: 8, p: 7);
      expectDecimal(Decimal.parse('-1.234567890'), '-1.23456789', s: 9, p: 8);
      expectDecimal(
        Decimal.parse('-0.1234567890'),
        '-0.123456789',
        s: 10,
        p: 9,
      );
      expectDecimal(
        Decimal.parse('-0.01234567890'),
        '-0.0123456789',
        s: 11,
        p: 10,
      );
      expectDecimal(
        Decimal.parse('-0.001234567890'),
        '-0.00123456789',
        s: 12,
        p: 11,
      );
      expectDecimal(
        Decimal.parse('-0.0001234567890'),
        '-0.000123456789',
        s: 13,
        p: 12,
      );

      // BigInt
      expectDecimal(
        Decimal.parse('1234567890123456789012345678901234567890'),
        '1234567890123456789012345678901234567890',
        s: 0,
        p: 0,
      );
      expectDecimal(
        Decimal.parse('123456789012345678901234567890.1234567890'),
        '123456789012345678901234567890.123456789',
        s: 10,
        p: 9,
      );
      expectDecimal(
        Decimal.parse('12345678901234567890.12345678901234567890'),
        '12345678901234567890.1234567890123456789',
        s: 20,
        p: 19,
      );
      expectDecimal(
        Decimal.parse('1234567890.123456789012345678901234567890'),
        '1234567890.12345678901234567890123456789',
        s: 30,
        p: 29,
      );
      expectDecimal(
        Decimal.parse('0.1234567890123456789012345678901234567890'),
        '0.123456789012345678901234567890123456789',
        s: 40,
        p: 39,
      );
      expectDecimal(
        Decimal.parse('0.00000000001234567890123456789012345678901234567890'),
        '0.0000000000123456789012345678901234567890123456789',
        s: 50,
        p: 49,
      );

      expectDecimal(
        Decimal.parse('-1234567890123456789012345678901234567890'),
        '-1234567890123456789012345678901234567890',
        s: 0,
        p: 0,
      );
      expectDecimal(
        Decimal.parse('-123456789012345678901234567890.1234567890'),
        '-123456789012345678901234567890.123456789',
        s: 10,
        p: 9,
      );
      expectDecimal(
        Decimal.parse('-12345678901234567890.12345678901234567890'),
        '-12345678901234567890.1234567890123456789',
        s: 20,
        p: 19,
      );
      expectDecimal(
        Decimal.parse('-1234567890.123456789012345678901234567890'),
        '-1234567890.12345678901234567890123456789',
        s: 30,
        p: 29,
      );
      expectDecimal(
        Decimal.parse('-0.1234567890123456789012345678901234567890'),
        '-0.123456789012345678901234567890123456789',
        s: 40,
        p: 39,
      );
      expectDecimal(
        Decimal.parse('-0.00000000001234567890123456789012345678901234567890'),
        '-0.0000000000123456789012345678901234567890123456789',
        s: 50,
        p: 49,
      );

      expectDecimal(
        Decimal.parse('1000000000000000000000000000000'),
        '1000000000000000000000000000000',
        s: 0,
        p: 0,
      );
      expectDecimal(
        Decimal.parse('100000000000000000000.0000000000'),
        '100000000000000000000',
        s: 10,
        p: 0,
      );
      expectDecimal(
        Decimal.parse('10000000000.00000000000000000000'),
        '10000000000',
        s: 20,
        p: 0,
      );
      expectDecimal(
        Decimal.parse('1.000000000000000000000000000000'),
        '1',
        s: 30,
        p: 0,
      );
    });

    test('add', () {
      var value = Decimal.parse('10000');
      expectDecimal(
        value += Decimal.parse('1000.0'),
        '11000',
        s: 1,
        p: 0,
      );
      expectDecimal(
        value += Decimal.parse('100.00'),
        '11100',
        s: 2,
        p: 0,
      );
      expectDecimal(
        value += Decimal.parse('10.000'),
        '11110',
        s: 3,
        p: 0,
      );
      expectDecimal(
        value += Decimal.parse('1.0000'),
        '11111',
        s: 4,
        p: 0,
      );
      expectDecimal(
        value += Decimal.parse('0.1'),
        '11111.1',
        s: 4,
        p: 1,
      );
      expectDecimal(
        value += Decimal.parse('0.01'),
        '11111.11',
        s: 4,
        p: 2,
      );
      expectDecimal(
        value += Decimal.parse('0.001'),
        '11111.111',
        s: 4,
        p: 3,
      );
      expectDecimal(
        value += Decimal.parse('0.0001'),
        '11111.1111',
        s: 4,
        p: 4,
      );
      expectDecimal(
        value += Decimal.parse('0.00001'),
        '11111.11111',
        s: 5,
        p: 5,
      );

      final values = List<Decimal>.generate(
        40,
        (index) => Decimal.fromBigInt(
          BigInt.parse('10000000000000000000'),
          shiftLeft: index,
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
        s: 39,
        p: 20,
      );
    });

    test('multiply', () {
      expectDecimal(
        Decimal(123, shiftLeft: 2) * Decimal(456, shiftLeft: 1),
        '56.088',
        s: 3,
        p: 3,
      );
      expectDecimal(
        Decimal(-123, shiftLeft: 2) * Decimal(456, shiftLeft: 1),
        '-56.088',
        s: 3,
        p: 3,
      );
      expectDecimal(
        Decimal(123, shiftLeft: 2) * Decimal(-456, shiftLeft: 1),
        '-56.088',
        s: 3,
        p: 3,
      );
      expectDecimal(
        Decimal(-123, shiftLeft: 2) * Decimal(-456, shiftLeft: 1),
        '56.088',
        s: 3,
        p: 3,
      );

      var value = Decimal.parse('123456.00');
      expectDecimal(
        value *= Decimal.parse('12345.6'),
        '1524138393.6',
        s: 3,
        p: 1,
      );
      expectDecimal(
        value *= Decimal.parse('1234.56'),
        '1881640295202.816',
        s: 5,
        p: 3,
      );
      expectDecimal(
        value *= Decimal.parse('123.456'),
        '232299784284558.852096',
        s: 8,
        p: 6,
      );
      expectDecimal(
        value *= Decimal.parse('12.3456'),
        '2867880216863449.7644363776',
        s: 12,
        p: 10,
      );
      expectDecimal(
        value *= Decimal.parse('1.23456'),
        '3540570200530940.541182574329856',
        s: 17,
        p: 15,
      );

      value = Decimal.parse('-123456');
      expectDecimal(
        value *= Decimal.parse('12345.6'),
        '-1524138393.6',
        s: 1,
        p: 1,
      );
      expectDecimal(
        value *= Decimal.parse('-1234.56'),
        '1881640295202.816',
        s: 3,
        p: 3,
      );
      expectDecimal(
        value *= Decimal.parse('-123.456'),
        '-232299784284558.852096',
        s: 6,
        p: 6,
      );
      expectDecimal(
        value *= Decimal.parse('-12.3456'),
        '2867880216863449.7644363776',
        s: 10,
        p: 10,
      );
      expectDecimal(
        value *= Decimal.parse('-1.23456'),
        '-3540570200530940.541182574329856',
        s: 15,
        p: 15,
      );
    });

    group('divide', () {
      test('success', () {
        expectDecimal(
          Decimal(24, shiftLeft: 1) / Decimal(12, shiftLeft: 1),
          '2',
          s: 0,
          p: 0,
        );

        var value = Decimal.parse('3540570200530940.541182574329856');
        expectDecimal(
          value /= Decimal(123456),
          '28678802168.634497644363776',
          s: 15,
          p: 15,
        );
        expectDecimal(
          value /= Decimal.parse('12345.6'),
          '2322997.84284558852096',
          s: 14,
          p: 14,
        );
        expectDecimal(
          value /= Decimal.parse('1234.56'),
          '1881.640295202816',
          s: 12,
          p: 12,
        );
        expectDecimal(
          value /= Decimal.parse('123.456'),
          '15.241383936',
          s: 9,
          p: 9,
        );
        expectDecimal(
          value /= Decimal.parse('12.3456'),
          '1.23456',
          s: 5,
          p: 5,
        );
        expectDecimal(
          value /= Decimal.parse('1.23456'),
          '1',
          s: 0,
          p: 0,
        );

        expect(
          () => Decimal(15129, shiftLeft: 1) / Decimal(86100),
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
            DecimalDivideException.forTest(Decimal(1), BigInt.two).round(0),
            '1',
          );

          expect((-0.5).round(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), BigInt.two).round(0),
            '-1',
          );

          expect((-1.5).round(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-3), BigInt.two).round(0),
            '-2',
          );

          // floor
          expect(0.5.floor(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), BigInt.two).floor(0),
            '0',
          );

          expect((-0.5).floor(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), BigInt.two).floor(0),
            '-1',
          );

          expect((-1.5).floor(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-3), BigInt.two).floor(0),
            '-2',
          );

          // ceil
          expect(0.5.ceil(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), BigInt.two).ceil(0),
            '1',
          );

          expect((-0.5).ceil(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), BigInt.two).ceil(0),
            '0',
          );

          expect((-1.5).ceil(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-3), BigInt.two).ceil(0),
            '-1',
          );

          // truncate
          expect(0.5.truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), BigInt.two).truncate(0),
            '0',
          );

          expect((-0.5).truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), BigInt.two).truncate(0),
            '0',
          );

          expect((-1.5).truncate(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-3), BigInt.two).truncate(0),
            '-1',
          );
        });

        test('0.1', () {
          // round
          expect(0.1.round(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), BigInt.from(10))
                .round(0),
            '0',
          );

          expect((-0.1).round(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), BigInt.from(10))
                .round(0),
            '0',
          );

          expect((-1.1).round(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-11), BigInt.from(10))
                .round(0),
            '-1',
          );

          // floor
          expect(0.1.floor(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), BigInt.from(10))
                .floor(0),
            '0',
          );

          expect((-0.1).floor(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), BigInt.from(10))
                .floor(0),
            '-1',
          );

          expect((-1.1).floor(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-11), BigInt.from(10))
                .floor(0),
            '-2',
          );

          // ceil
          expect(0.1.ceil(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), BigInt.from(10)).ceil(0),
            '1',
          );

          expect((-0.1).ceil(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), BigInt.from(10))
                .ceil(0),
            '0',
          );

          expect((-1.1).ceil(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-11), BigInt.from(10))
                .ceil(0),
            '-1',
          );

          // truncate
          expect(0.1.truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(1), BigInt.from(10))
                .floor(0),
            '0',
          );

          expect((-0.1).truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-1), BigInt.from(10))
                .truncate(0),
            '0',
          );

          expect((-1.1).truncate(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-11), BigInt.from(10))
                .truncate(0),
            '-1',
          );
        });

        test('0.9', () {
          // round
          expect(0.9.round(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(9), BigInt.from(10))
                .round(0),
            '1',
          );

          expect((-0.9).round(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-9), BigInt.from(10))
                .round(0),
            '-1',
          );

          expect((-1.9).round(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-19), BigInt.from(10))
                .round(0),
            '-2',
          );

          // floor
          expect(0.9.floor(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(9), BigInt.from(10))
                .floor(0),
            '0',
          );

          expect((-0.9).floor(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-9), BigInt.from(10))
                .floor(0),
            '-1',
          );

          expect((-1.9).floor(), -2);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-19), BigInt.from(10))
                .floor(0),
            '-2',
          );

          // ceil
          expect(0.9.ceil(), 1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(9), BigInt.from(10)).ceil(0),
            '1',
          );

          expect((-0.9).ceil(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-9), BigInt.from(10))
                .ceil(0),
            '0',
          );

          expect((-1.9).ceil(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-19), BigInt.from(10))
                .ceil(0),
            '-1',
          );

          // truncate
          expect(0.9.truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(9), BigInt.from(10))
                .floor(0),
            '0',
          );

          expect((-0.9).truncate(), 0);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-9), BigInt.from(10))
                .truncate(0),
            '0',
          );

          expect((-1.1).truncate(), -1);
          expectDecimal(
            DecimalDivideException.forTest(Decimal(-19), BigInt.from(10))
                .truncate(0),
            '-1',
          );
        });

        test('+n / +n', () {
          final v1 = Decimal(15129, shiftLeft: 1);
          final v2 = Decimal(86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expectDecimal(v1 ~/ v2, '0');
            expectDecimal(v1 % v2, '1512.9');

            // 0.01757(1)
            expect((1512.9 * 100000 / 86100).floor(), 1757);
            expectDecimal(
              e.floor(0),
              '0.01757',
            );
            expect((1512.9 * 100000 / 86100).round(), 1757);
            expectDecimal(
              e.round(0),
              '0.01757',
            );
            expect((1512.9 * 100000 / 86100).ceil(), 1758);
            expectDecimal(
              e.ceil(0),
              '0.01758',
            );
            expect((1512.9 * 100000 / 86100).truncate(), 1757);
            expectDecimal(
              e.truncate(0),
              '0.01757',
            );

            // 0.01757142(8)
            expect((1512.9 * 100000000 / 86100).floor(), 1757142);
            expectDecimal(
              e.floor(3),
              '0.01757142',
            );
            expect((1512.9 * 100000000 / 86100).round(), 1757143);
            expectDecimal(
              e.round(3),
              '0.01757143',
            );
            expect((1512.9 * 100000000 / 86100).ceil(), 1757143);
            expectDecimal(
              e.ceil(3),
              '0.01757143',
            );
            expect((1512.9 * 100000000 / 86100).truncate(), 1757142);
            expectDecimal(
              e.truncate(3),
              '0.01757142',
            );

            // 0.01757142857(1)
            expect((1512.9 * 100000000000 / 86100).floor(), 1757142857);
            expectDecimal(
              e.floor(6),
              '0.01757142857',
            );
            expect((1512.9 * 100000000000 / 86100).round(), 1757142857);
            expectDecimal(
              e.round(6),
              '0.01757142857',
            );
            expect((1512.9 * 100000000000 / 86100).ceil(), 1757142858);
            expectDecimal(
              e.ceil(6),
              '0.01757142858',
            );
            expect((1512.9 * 100000000000 / 86100).truncate(), 1757142857);
            expectDecimal(
              e.truncate(6),
              '0.01757142857',
            );
          }
        });

        test('+n / -n', () {
          final v1 = Decimal(15129, shiftLeft: 1);
          final v2 = Decimal(-86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expectDecimal(v1 ~/ v2, '0');
            expectDecimal(v1 % v2, '1512.9');

            // -0.01757(1)
            expect((1512.9 * 100000 / -86100).floor(), -1758);
            expectDecimal(
              e.floor(0),
              '-0.01758',
            );
            expect((1512.9 / -86100 * 100000).round(), -1757);
            expectDecimal(
              e.round(0),
              '-0.01757',
            );
            expect((1512.9 / -86100 * 100000).ceil(), -1757);
            expectDecimal(
              e.ceil(0),
              '-0.01757',
            );
            expect((1512.9 / -86100 * 100000).truncate(), -1757);
            expectDecimal(
              e.truncate(0),
              '-0.01757',
            );

            // -0.01757142(8)
            expect((1512.9 * 100000000 / -86100).floor(), -1757143);
            expectDecimal(
              e.floor(3),
              '-0.01757143',
            );
            expect((1512.9 * 100000000 / -86100).round(), -1757143);
            expectDecimal(
              e.round(3),
              '-0.01757143',
            );
            expect((1512.9 * 100000000 / -86100).ceil(), -1757142);
            expectDecimal(
              e.ceil(3),
              '-0.01757142',
            );
            expect((1512.9 * 100000000 / -86100).truncate(), -1757142);
            expectDecimal(
              e.truncate(3),
              '-0.01757142',
            );

            // -0.01757142857(1)
            expect((1512.9 * 100000000000 / -86100).floor(), -1757142858);
            expectDecimal(
              e.floor(6),
              '-0.01757142858',
            );
            expect((1512.9 * 100000000000 / -86100).round(), -1757142857);
            expectDecimal(
              e.round(6),
              '-0.01757142857',
            );
            expect((1512.9 * 100000000000 / -86100).ceil(), -1757142857);
            expectDecimal(
              e.ceil(6),
              '-0.01757142857',
            );
            expect((1512.9 * 100000000000 / -86100).truncate(), -1757142857);
            expectDecimal(
              e.truncate(6),
              '-0.01757142857',
            );
          }
        });

        test('-n / +n', () {
          final v1 = Decimal(-15129, shiftLeft: 1);
          final v2 = Decimal(86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expectDecimal(v1 ~/ v2, '0');
            expectDecimal(v1 % v2, '84587.1');

            // -0.01757(1)
            expect((1512.9 * 100000 / -86100).floor(), -1758);
            expectDecimal(
              e.floor(0),
              '-0.01758',
            );
            expect((1512.9 / -86100 * 100000).round(), -1757);
            expectDecimal(
              e.round(0),
              '-0.01757',
            );
            expect((1512.9 / -86100 * 100000).ceil(), -1757);
            expectDecimal(
              e.ceil(0),
              '-0.01757',
            );
            expect((1512.9 / -86100 * 100000).truncate(), -1757);
            expectDecimal(
              e.truncate(0),
              '-0.01757',
            );

            // -0.01757142(8)
            expect((1512.9 * 100000000 / -86100).floor(), -1757143);
            expectDecimal(
              e.floor(3),
              '-0.01757143',
            );
            expect((1512.9 * 100000000 / -86100).round(), -1757143);
            expectDecimal(
              e.round(3),
              '-0.01757143',
            );
            expect((1512.9 * 100000000 / -86100).ceil(), -1757142);
            expectDecimal(
              e.ceil(3),
              '-0.01757142',
            );
            expect((1512.9 * 100000000 / -86100).truncate(), -1757142);
            expectDecimal(
              e.truncate(3),
              '-0.01757142',
            );

            // -0.01757142857(1)
            expect((1512.9 * 100000000000 / -86100).floor(), -1757142858);
            expectDecimal(
              e.floor(6),
              '-0.01757142858',
            );
            expect((1512.9 * 100000000000 / -86100).round(), -1757142857);
            expectDecimal(
              e.round(6),
              '-0.01757142857',
            );
            expect((1512.9 * 100000000000 / -86100).ceil(), -1757142857);
            expectDecimal(
              e.ceil(6),
              '-0.01757142857',
            );
            expect((1512.9 * 100000000000 / -86100).truncate(), -1757142857);
            expectDecimal(
              e.truncate(6),
              '-0.01757142857',
            );
          }
        });

        test('-n / -n', () {
          final v1 = Decimal(-15129, shiftLeft: 1);
          final v2 = Decimal(-86100);
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expectDecimal(v1 ~/ v2, '0');
            expectDecimal(v1 % v2, '84587.1');

            // 0.01757(1)
            expect((1512.9 * 100000 / 86100).floor(), 1757);
            expectDecimal(
              e.floor(0),
              '0.01757',
            );
            expect((1512.9 * 100000 / 86100).round(), 1757);
            expectDecimal(
              e.round(0),
              '0.01757',
            );
            expect((1512.9 * 100000 / 86100).ceil(), 1758);
            expectDecimal(
              e.ceil(0),
              '0.01758',
            );
            expect((1512.9 * 100000 / 86100).truncate(), 1757);
            expectDecimal(
              e.truncate(0),
              '0.01757',
            );

            // 0.01757142(8)
            expect((1512.9 * 100000000 / 86100).floor(), 1757142);
            expectDecimal(
              e.floor(3),
              '0.01757142',
            );
            expect((1512.9 * 100000000 / 86100).round(), 1757143);
            expectDecimal(
              e.round(3),
              '0.01757143',
            );
            expect((1512.9 * 100000000 / 86100).ceil(), 1757143);
            expectDecimal(
              e.ceil(3),
              '0.01757143',
            );
            expect((1512.9 * 100000000 / 86100).truncate(), 1757142);
            expectDecimal(
              e.truncate(3),
              '0.01757142',
            );

            // 0.01757142857(1)
            expect((1512.9 * 100000000000 / 86100).floor(), 1757142857);
            expectDecimal(
              e.floor(6),
              '0.01757142857',
            );
            expect((1512.9 * 100000000000 / 86100).round(), 1757142857);
            expectDecimal(
              e.round(6),
              '0.01757142857',
            );
            expect((1512.9 * 100000000000 / 86100).ceil(), 1757142858);
            expectDecimal(
              e.ceil(6),
              '0.01757142858',
            );
            expect((1512.9 * 100000000000 / 86100).truncate(), 1757142857);
            expectDecimal(
              e.truncate(6),
              '0.01757142857',
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
            expectDecimal(e.floor(0), '1014285');
            expectDecimal(e.round(0), '1014286');
            expectDecimal(e.ceil(0), '1014286');
            expectDecimal(e.truncate(0), '1014285');

            expectDecimal(e.numerator, '7100000', s: 0);
            expect(e.denominator, BigInt.from(7));
          }

          expectDecimal(v1 ~/ v2, '1014285', s: 0, p: 0);
          expectDecimal(v1 % v2, '0.00615', s: 7);

          // +n / -n
          v1 = Decimal(8733);
          v2 = Decimal.parse('-0.0086100');
          try {
            // ignore: unnecessary_statements
            v1 / v2;
          } on DecimalDivideException catch (e) {
            expectDecimal(e.floor(0), '-1014286');
            expectDecimal(e.round(0), '-1014286');
            expectDecimal(e.ceil(0), '-1014285');
            expectDecimal(e.truncate(0), '-1014285');

            expectDecimal(e.numerator, '-7100000', s: 0);
            expect(e.denominator, BigInt.from(7));
          }

          expectDecimal(v1 ~/ v2, '-1014285', s: 0, p: 0);
          expectDecimal(v1 % v2, '0.00615', s: 7, p: 5);
        });

        test('positive scale', () {
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
            expectDecimal(e.numerator, '7.71', s: 6);
            expect(e.denominator, BigInt.from(7));
          }

          expectDecimal(v1 ~/ v2, '1', s: 0, p: 0);
          expectDecimal(v1 % v2, '8733', s: 2, p: 0);
        });
      });
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
