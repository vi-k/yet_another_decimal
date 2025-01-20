import 'package:meta/meta.dart';

@immutable
final class ShortDecimal implements Comparable<ShortDecimal> {
  @visibleForTesting
  final int value;

  @visibleForTesting
  final int scale; // = fraction digits

  factory ShortDecimal(int value, {int shift = 0}) {
    assert(shift >= 0, 'The shift must be at least 0');

    while (shift > 0 && value % 10 == 0) {
      value ~/= 10;
      shift--;
    }

    return ShortDecimal._(value, shift);
  }

  const ShortDecimal._(this.value, this.scale);

  int get precision => scale;

  ShortDecimal operator +(ShortDecimal other) {
    final (a, b, scale) = _toCommonScale(this, other);

    return ShortDecimal(a + b, shift: scale);
  }

  ShortDecimal operator -(ShortDecimal other) {
    final (a, b, scale) = _toCommonScale(this, other);

    return ShortDecimal(a - b, shift: scale);
  }

  ShortDecimal operator *(ShortDecimal other) => ShortDecimal(
        value * other.value,
        shift: scale + other.scale,
      );

  ShortDecimal operator /(ShortDecimal other) {
    var value = this.value;
    var scale = this.scale;
    var denominator = other.value;

    final gcd = _gcd(value, denominator);
    value ~/= gcd;
    denominator ~/= gcd;
    scale -= other.scale;

    if (denominator != 1) {
      while (denominator % 5 == 0) {
        value *= 2;
        scale++;
        denominator = denominator ~/ 5;
      }

      // ignore: use_is_even_rather_than_modulo
      while (denominator % 2 == 0) {
        value *= 5;
        scale++;
        denominator = denominator ~/ 2;
      }

      if (denominator != 1) {
        throw ShortDecimalDivideException(
          ShortDecimal._(value, scale),
          denominator,
        );
      }
    }

    while (scale < 0) {
      value *= 10;
      scale++;
    }

    return ShortDecimal(value, shift: scale);
  }

  bool operator <(ShortDecimal other) {
    final (a, b, _) = _toCommonScale(this, other);

    return a < b;
  }

  bool operator <=(ShortDecimal other) {
    final (a, b, _) = _toCommonScale(this, other);

    return a <= b;
  }

  bool operator >(ShortDecimal other) {
    final (a, b, _) = _toCommonScale(this, other);

    return a > b;
  }

  bool operator >=(ShortDecimal other) {
    final (a, b, _) = _toCommonScale(this, other);

    return a >= b;
  }

  ShortDecimal operator <<(int shiftAmount) => throw UnimplementedError();
  ShortDecimal operator >>(int shiftAmount) => throw UnimplementedError();

  double toDouble() => double.parse(toString());

  @override
  int compareTo(ShortDecimal other) {
    throw UnimplementedError();
  }

  static int _mult10N(int value, int count) {
    var result = value;
    for (var i = count; i > 0; i--) {
      result *= 10;
    }

    return result;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShortDecimal && value == other.value && scale == other.scale;

  @override
  int get hashCode => Object.hash(value, scale);

  String debugToString() => '$ShortDecimal(value: $value, scale: $scale)';

  @override
  String toString() {
    var result = value.toString();
    final scale = this.scale;

    // When 0 or scale == 0, return immediately.
    if (scale == 0 || value == 0) {
      return result;
    }

    // Going between a sign and a number.
    final (sign, number) = _splitByIndex(result, value.isNegative ? 1 : 0);

    if (scale >= number.length) {
      result = '${sign}0.${number.padLeft(scale, '0')}';
    } else {
      final (integer, fractional) =
          _splitByIndex(number, number.length - scale);
      result = '$sign$integer.$fractional';
    }

    return result;
  }

  // https://github.com/dart-lang/sdk/issues/46180
  static int _gcd(int a, int b) {
    while (b != 0) {
      final tmp = b;
      b = a % b;
      a = tmp;
    }

    return a;
  }

  static (int, int, int) _toCommonScale(ShortDecimal a, ShortDecimal b) {
    final as = a.scale;
    final bs = b.scale;

    if (as == bs) {
      return (a.value, b.value, as);
    } else if (as > bs) {
      return (a.value, _mult10N(b.value, as - bs), as);
    } else {
      return (_mult10N(a.value, bs - as), b.value, bs);
    }
  }

  (String, String) _splitByIndex(String str, int index) =>
      (str.substring(0, index), str.substring(index));
}

final class ShortDecimalDivideException implements Exception {
  final ShortDecimal numerator;
  final int denominator;

  ShortDecimalDivideException(this.numerator, this.denominator);

  @override
  String toString() => '$ShortDecimalDivideException:'
      ' The result of division cannot be represented as $ShortDecimal'
      ' (numerator: $numerator, denominator: $denominator)';
}
