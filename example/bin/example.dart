// A tour of the package: exact arithmetic, division that refuses to lie,
// money, and the fast family.
//
//   dart run example/bin/example.dart

import 'package:yet_another_decimal/yet_another_decimal.dart';

void main() {
  _exactness();
  _division();
  _money();
  _theFastFamily();
}

/// What a decimal type is for in the first place.
void _exactness() {
  print('--- exact arithmetic ---');

  // The classic. A double cannot hold a tenth, so it does not.
  print(0.1 + 0.2);
  print(Decimal.parse('0.1') + Decimal.parse('0.2'));
  print(Decimal.parse('0.1') + Decimal.parse('0.2') == Decimal.parse('0.3'));

  // Nothing is rounded away, however long the number gets.
  final big = Decimal.parse('123456789012345678901234567890.123456789');
  print(big * big);

  // Exponential notation is read as well.
  print(Decimal.parse('1.5e21'));

  print('');
}

/// The one operation that cannot always answer.
void _division() {
  print('--- division ---');

  final one = Decimal(1);
  final three = Decimal(3);

  // A third has no finite decimal form, and the package will not pretend
  // otherwise. Pick how you want to be told.
  print(one.isDivisibleBy(three));
  print(one.divideOrNull(three));
  print(one.divide(three, scaleOnInfinitePrecision: 4));

  try {
    print(one / three);
  } on DecimalDivideException catch (e) {
    // The exception carries everything you might have wanted instead.
    print('${e.fraction} = ${e.round(4)}');
  }

  // Where the division is exact, all four agree — and `/` is the fastest.
  print(Decimal.parse('7.5') / Decimal(2));

  print('');
}

/// A bill, a tax and three people to split it between.
void _money() {
  print('--- money ---');

  final price = Decimal.parse('19.99');
  final tax = price * Decimal.parse('0.2');
  final total = price + tax;

  print(total);
  print(total.toStringAsFixed(2));
  print(total.round(2));

  // Splitting a bill is the case where the remainder must not disappear:
  // whoever pays the odd cent, the sum still has to add up.
  final split = total.round(2).divideWithRemainder(Decimal(3));
  print('${split.quotient} each, ${split.remainder} left over');

  print('');
}

/// The same thing on `int`, several times faster.
void _theFastFamily() {
  print('--- ShortDecimal ---');

  final price = ShortDecimal.parse('19.99');
  print(price * ShortDecimal(3));

  // The whole difference: an int64 has a last digit, and going past it is
  // silent, exactly as it is for `int`.
  print(ShortDecimal.parse('9223372036854.775807') + ShortDecimal(1));

  // So when the magnitudes are not known in advance, cross over. Up is always
  // exact; down can fail — not on size, an int64 holds a scale of its own, but
  // on the count of significant digits — and says so with null.
  print(price.toDecimal() * Decimal.parse('1e30'));
  print(Decimal.parse('1e30').toShortDecimalOrNull());
  print(Decimal.parse('12345678901234567890.123456789').toShortDecimalOrNull());

  print('');
}
