/// Вывод `Decimal` строкой и `optimize`.
///
/// Здесь сверка `base` и `scale` уместна: `toString` обязан снимать хвостовые
/// нули, не трогая представление, а `optimize` — наоборот, менять только его.
library;

import 'package:test/test.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import '../support/expect.dart';

void main() {
  group('Decimal', () {
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
}
