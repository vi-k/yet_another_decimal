// ignore_for_file: avoid_js_rounded_ints

/// Примитивы 128-битной арифметики из `lib/src/short_decimal/wide.dart`.
///
/// Каждый сверяется с `BigInt` — единственным в Dart, кто считает шире
/// машинного слова, — на детерминированном генераторе из
/// `support/reference.dart` и отдельно на границах `int`. Ширина операндов
/// перебирается по всему диапазону, а не берётся случайной: деление Кнута
/// ошибается на одном делителе из миллиона, и попасть в него случайно нельзя.
library;

import 'package:denary/src/short_decimal/wide.dart';
import 'package:test/test.dart';

import '../support/reference.dart';

/// Сколько случайных случаев прогоняется на каждый примитив.
const _cases = 100000;

/// Значения, на которых ломается арифметика по модулю: границы `int`,
/// степени двойки рядом с ними и мелочь вокруг нуля.
const _edges = <int>[
  -9223372036854775808,
  -9223372036854775807,
  -9223372036854775798,
  9223372036854775807,
  9223372036854775806,
  9223372036854775800,
  -4611686018427387904,
  4611686018427387904,
  -5000000000000000000,
  5000000000000000000,
  -9000000000000000000,
  9000000000000000000,
  -10,
  -1,
  0,
  1,
  10,
];

/// 2^64 — им беззнаковое читается из знакового.
final _twoPow64 = BigInt.one << 64;

final _ten = BigInt.from(10);

/// Бит-в-бит значение [word], прочитанное как беззнаковое.
BigInt _unsigned(int word) =>
    word >= 0 ? BigInt.from(word) : BigInt.from(word) + _twoPow64;

/// Знаковое 128-битное из пары `(high, low)`.
BigInt _signed128(int high, int low) =>
    (BigInt.from(high) << 64) + _unsigned(low);

/// Беззнаковое 128-битное из пары `(high, low)`.
BigInt _unsigned128(int high, int low) =>
    (_unsigned(high) << 64) + _unsigned(low);

/// Случайное слово: две половины по 32 бита из [gen].
int _word(Gen gen) => (gen.seedlessInt << 32) | gen.seedlessInt;

/// Случайное слово, модуль которого занимает не больше [bits] бит.
///
/// Знак случайный. При `bits == 64` знак задан уже старшим битом, и значение
/// равномерно по всему диапазону `int` — вместе с `int.min`, у которого
/// модуля в int64 нет.
int _signedOfWidth(Gen gen, int bits) {
  if (bits >= 64) {
    return _word(gen);
  }
  final magnitude = _word(gen) >>> (64 - bits);

  return gen.nextBool ? magnitude : -magnitude;
}

/// Случайное ненулевое слово шириной не больше [bits] бит, читаемое как
/// беззнаковое.
int _unsignedOfWidth(Gen gen, int bits) {
  final word = bits >= 64 ? _word(gen) : _word(gen) >>> (64 - bits);

  return word == 0 ? 1 : word;
}

void main() {
  group('mul128', () {
    test('совпадает с произведением в BigInt', () {
      final gen = Gen(101);
      var checked = 0;
      for (var i = 0; i < _cases; i++) {
        final a = _signedOfWidth(gen, 1 + i % 64);
        final b = _signedOfWidth(gen, 1 + (i * 7) % 64);
        final (high, low) = mul128(a, b);
        if (_signed128(high, low) != BigInt.from(a) * BigInt.from(b)) {
          fail('случай $i: $a * $b дало ($high, $low)');
        }
        checked++;
      }
      expect(checked, _cases);
    });

    test('на границах int', () {
      for (final a in _edges) {
        for (final b in _edges) {
          final (high, low) = mul128(a, b);
          expect(
            _signed128(high, low),
            BigInt.from(a) * BigInt.from(b),
            reason: '$a * $b',
          );
        }
      }
    });
  });

  group('productFits', () {
    test('совпадает с проверкой через BigInt', () {
      final gen = Gen(102);
      var checked = 0;
      for (var i = 0; i < _cases; i++) {
        final a = _signedOfWidth(gen, 1 + i % 64);
        final b = _signedOfWidth(gen, 1 + (i * 7) % 64);
        final expected = (BigInt.from(a) * BigInt.from(b)).isValidInt;
        if (productFits(a, b) != expected) {
          fail('случай $i: $a * $b, ждали $expected');
        }
        checked++;
      }
      expect(checked, _cases);
    });

    test('на границах int', () {
      for (final a in _edges) {
        for (final b in _edges) {
          expect(
            productFits(a, b),
            (BigInt.from(a) * BigInt.from(b)).isValidInt,
            reason: '$a * $b',
          );
        }
      }
    });

    test('int.min на -1 не помещается', () {
      expect(productFits(-9223372036854775808, -1), isFalse);
      expect(productFits(-9223372036854775807, -1), isTrue);
    });
  });

  group('udivmod10', () {
    test('совпадает с беззнаковым делением в BigInt', () {
      final gen = Gen(103);
      var checked = 0;
      for (var i = 0; i < _cases; i++) {
        final x = _signedOfWidth(gen, 1 + i % 64);
        final (quotient, remainder) = udivmod10(x);
        final value = _unsigned(x);
        if (_unsigned(quotient) != value ~/ _ten ||
            BigInt.from(remainder) != value % _ten) {
          fail('случай $i: $x дало ($quotient, $remainder)');
        }
        checked++;
      }
      expect(checked, _cases);
    });

    test('на границах int', () {
      for (final x in _edges) {
        final (quotient, remainder) = udivmod10(x);
        final value = _unsigned(x);
        expect(_unsigned(quotient), value ~/ _ten, reason: '$x');
        expect(BigInt.from(remainder), value % _ten, reason: '$x');
      }
    });
  });

  group('udivmod128by64', () {
    test('совпадает с делением в BigInt', () {
      final gen = Gen(104);
      var checked = 0;
      for (var i = 0; i < _cases; i++) {
        final width = 1 + i % 128;
        final high = width > 64 ? _unsignedOfWidth(gen, width - 64) : 0;
        final low = width > 64 ? _word(gen) : _unsignedOfWidth(gen, width);
        final divisor = _unsignedOfWidth(gen, 1 + (i * 5) % 64);
        final (quotientHigh, quotientLow, remainder) = udivmod128by64(
          high,
          low,
          divisor,
        );
        final value = _unsigned128(high, low);
        final by = _unsigned(divisor);
        if (_unsigned128(quotientHigh, quotientLow) != value ~/ by ||
            _unsigned(remainder) != value % by) {
          fail(
            'случай $i: ($high, $low) / $divisor дало '
            '($quotientHigh, $quotientLow, $remainder)',
          );
        }
        checked++;
      }
      expect(checked, _cases);
    });

    test('на границах int', () {
      for (final high in _edges) {
        for (final low in _edges) {
          for (final divisor in _edges) {
            if (divisor == 0) {
              continue;
            }
            final (quotientHigh, quotientLow, remainder) = udivmod128by64(
              high,
              low,
              divisor,
            );
            final value = _unsigned128(high, low);
            final by = _unsigned(divisor);
            final why = '($high, $low) / $divisor';
            expect(
              _unsigned128(quotientHigh, quotientLow),
              value ~/ by,
              reason: why,
            );
            expect(_unsigned(remainder), value % by, reason: why);
          }
        }
      }
    });

    test('шаг «вернуть назад» считает верно', () {
      // Оценка очередной цифры частного выходит завышенной на единицу, и
      // делитель приходится прибавлять обратно. Случай редкий — на случайных
      // входах примерно один на четыреста тысяч делений, — поэтому в
      // property-тест выше он почти не попадает, и образцы найдены отдельным
      // перебором со счётчиком внутри самой функции.
      const triggers = <(int, int, int)>[
        (3346029922, -6466054713806110661, 2360441713946),
        (-8084384793251963889, 244409797365118889, 2400243101008335),
        (10466462714275464, -1219597883059603273, 18316102902),
        (542314902160848, 6348028748605380180, 79718905883),
        (6, 7661581100321527644, 35698171562),
        (17926241389052, -6638066377127633102, 198326602357),
      ];
      for (final (high, low, divisor) in triggers) {
        final (quotientHigh, quotientLow, remainder) = udivmod128by64(
          high,
          low,
          divisor,
        );
        final value = _unsigned128(high, low);
        final by = _unsigned(divisor);
        final why = '($high, $low) / $divisor';
        expect(
          _unsigned128(quotientHigh, quotientLow),
          value ~/ by,
          reason: why,
        );
        expect(_unsigned(remainder), value % by, reason: why);
      }
    });

    test('делитель 2^63 — это int.min, прочитанный беззнаково', () {
      // Ровно тот образец, которым `divide` отвечает на `-int.min`.
      final (quotientHigh, quotientLow, remainder) = udivmod128by64(
        1,
        0,
        -9223372036854775808,
      );
      expect(_unsigned128(quotientHigh, quotientLow), BigInt.two);
      expect(remainder, 0);
    });
  });

  group('compare128', () {
    test('совпадает со сравнением перекрёстных произведений в BigInt', () {
      final gen = Gen(105);
      var checked = 0;
      for (var i = 0; i < _cases; i++) {
        final a = _signedOfWidth(gen, 1 + i % 64);
        final b = _signedOfWidth(gen, 1 + (i * 7) % 64);
        final c = _signedOfWidth(gen, 1 + (i * 11) % 64);
        final d = _signedOfWidth(gen, 1 + (i * 13) % 64);
        final (highLeft, lowLeft) = mul128(a, d);
        final (highRight, lowRight) = mul128(c, b);
        final expected = (BigInt.from(a) * BigInt.from(d))
            .compareTo(BigInt.from(c) * BigInt.from(b))
            .sign;
        if (compare128(highLeft, lowLeft, highRight, lowRight) != expected ||
            compare128(highLeft, lowLeft, highLeft, lowLeft) != 0) {
          fail('случай $i: $a/$b против $c/$d');
        }
        checked++;
      }
      expect(checked, _cases);
    });

    test('на границах int', () {
      for (final a in _edges) {
        for (final b in _edges) {
          final (high, low) = mul128(a, b);
          final (otherHigh, otherLow) = mul128(b, a == 0 ? 1 : a - 1);
          expect(
            compare128(high, low, otherHigh, otherLow),
            _signed128(high, low)
                .compareTo(_signed128(otherHigh, otherLow))
                .sign,
            reason: '$a и $b',
          );
        }
      }
    });
  });
}
