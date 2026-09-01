# Denary

[![CI](https://github.com/vi-k/denary/actions/workflows/ci.yml/badge.svg)](https://github.com/vi-k/denary/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/denary.svg)](https://pub.dev/packages/denary)

A package for decimal numbers with a fixed point and no loss of precision.

## Table of contents

1. [Getting started](#getting-started)

2. [Money](#money)

3. [Why?](#why)

    3.1. [What packages are already in place?](#what-packages-are-already-in-place)

    3.2. [What's it supposed to be?](#whats-it-supposed-to-be)

    3.3. [Package performance](#package-performance)

    3.4. [decimal vs denary](#decimalhttpspubdevpackagesdecimal-vs-denaryhttpspubdevpackagesdenary)

4. [`Decimal` vs `ShortDecimal`](#decimal-vs-shortdecimal)

    4.1. [`ShortDecimal` limitations](#shortdecimal-limitations)

    4.2. [Performance](#performance)

    4.3. [`Decimal` optimization](#decimal-optimization)

## Getting started

```bash
dart pub add denary
```

```dart
import 'package:denary/denary.dart';

final price = Decimal.parse('19.99');
final total = price * Decimal(3);

print(total); // 59.97
print(Decimal.parse('0.1') + Decimal.parse('0.2') == Decimal.parse('0.3')); // true

// Not every division has a decimal answer, so the package makes you say which
// answer you want. Only the last of these throws over that — though all four
// throw on a zero divisor, which is a question rather than an answer.
print(total.divideOrNull(Decimal(7))); // null
print(total.divide(Decimal(7), scaleOnInfinitePrecision: 2)); // 8.57
print(total.divideWithRemainder(Decimal(2))); // 29 remainder 1.97
print(total / Decimal(3)); // 19.99

// A value is kept, the way it was written is not: trailing zeros say nothing
// about a number, so printing gives them back only when asked.
print(Decimal.parse('4.50')); // 4.5
print(Decimal.parse('4.50').toStringAsFixed(2)); // 4.50
```

There are two number types, and they never mix on their own:

- `Decimal` keeps the value in a `BigInt`. Nothing overflows, ever.
- `ShortDecimal` keeps it in an `int`. Several times faster and smaller, and
  past the edge of int64 it wraps around silently, exactly as `int` does.

Either one can be imported without the other:

```dart
import 'package:denary/decimal.dart';       // the BigInt family
import 'package:denary/short_decimal.dart'; // the int64 family
```

Which to take, and what the second one costs, is in
[`Decimal` vs `ShortDecimal`](#decimal-vs-shortdecimal). The rest of this
README is why the package exists and what it is measured to cost.

## Money

**Print the digits you mean.** A value is kept, the way it was written is not:

```dart
print(Decimal.parse('4.50'));                    // 4.5
print(Decimal.parse('4.50').toStringAsFixed(2)); // 4.50
```

**Round the way your rules round.** `round` sends a half away from zero,
`roundToEven` sends it to the even neighbour — the rule accounting asks for, so
that a column of halves does not lean one way. `roundAwayFromZero` moves the
last digit out on any remainder at all. `floor`, `ceil` and `truncate` take a
number of digits as well.

```dart
print(Decimal.parse('2.5').round());               // 3
print(Decimal.parse('2.5').roundToEven());         // 2
print(Decimal.parse('2.01').roundAwayFromZero(1)); // 2.1
```

**Divide in the direction you need.** `divide` rounds to the closest; where the
direction matters, take the exact ratio of the division and round that:

```dart
final bill = Decimal.parse('23.99');

print(bill.divide(Decimal(3), scaleOnInfinitePrecision: 2)); // 8
print(bill.divideToFraction(Decimal(3)).floor(2));           // 7.99
```

**Split a sum without losing a cent.** Work in the smallest unit, divide as
integers, and keep the remainder where you can see it:

```dart
final cents = (bill << 2) ~/ Decimal(3);
final share = Decimal.fromBigInt(cents, shiftRight: 2);

print(share);                       // 7.99
print(bill - share * Decimal(3));   // 0.02
```

`~/` answers with a `BigInt` — integer division answers with an integer
everywhere in Dart — while `%` answers with a `Decimal`. `divideWithRemainder`
hands over both at once.

**Coming from JSON with numeric prices.** A `double` has lost what it lost
before this package sees it, so there is no constructor taking one. What you
almost always want is the shortest decimal that produces the same `double`,
and that is what its `toString` already is:

```dart
const fromApi = 19.99;

print(Decimal.parse(fromApi.toString())); // 19.99
```

Where the exact binary value is what you are after instead, ask for the digits:
`Decimal.parse(fromApi.toStringAsFixed(20))` is `19.98999999999999843681`.

## Why?

As of February 2025, there are several packages on [pub.dev](https://pub.dev)
that work with decimals.

### What packages are already in place?

#### [decimal](https://pub.dev/packages/decimal)

A wonderful package that works correctly with decimals. It exists since 2014
and is constantly updated. In one of the latest updates (3.2.0), performance
has been significantly improved. Before that, speed was the weak point of this
package. This was one of the reasons why [denary](https://pub.dev/packages/denary)
appeared, since I started writing it before 3.2.0. However, I would have
written it anyway. More about it below.

#### [fixed](https://pub.dev/packages/fixed)

The package has difficulty dividing. You can't just do a 1 / 8 operation and
get the expected 0.125:

```dart
final a = Fixed.fromInt(1, decimalDigits: 0); // 1
final b = Fixed.fromInt(8, decimalDigits: 0); // 8
print('$a / $b = ${a / b}'); // 1 / 8 = 0

final c = Fixed.fromInt(10, decimalDigits: 1); // 1.0
final d = Fixed.fromInt(80, decimalDigits: 1); // 8.0
print('$c / $d = ${c / d}'); // 1.0 / 8.0 = 0.1

final e = Fixed.fromInt(100, decimalDigits: 2); // 1.00
final f = Fixed.fromInt(800, decimalDigits: 2); // 8.00
print('$e / $f = ${e / f}'); // 1.00 / 8.00 = 0.13
```

The result depends on the scale of the numerator and denominator: the division
keeps the larger of the two and rounds the answer to it. An eighth has an exact
decimal form, and it is rounded away all the same, without a word. You have to
know the answer's scale in advance and ask for it:

```dart
final a = Fixed.fromInt(1, decimalDigits: 0).copyWith(decimalDigits: 3); // 1.000
final b = Fixed.fromInt(8, decimalDigits: 0); // 8
print('$a / $b = ${a / b}'); // 1.000 / 8 = 0.125
```

The division itself is exact: `fixed` divides in `BigInt`, rounding half away
from zero. Checked on 6.1.1 and 6.2.0 — a number squared and divided back comes
out to the digit:

```dart
final a = Fixed.parse('111111111111111111');
final b = a * a;
print(b); // 12345679012345678987654320987654321
print(b / a); // 111111111111111111
```

What remains is the first point, and it is the reason this package exists: the
division rounds to a scale nobody asked for. Here `Decimal(1) / Decimal(8)` is
`0.125` whatever the two sides were built from, and a division that has no
finite decimal form says so instead of quietly rounding.

#### [decimal_type](https://pub.dev/packages/decimal_type)

This package divides through `double`, and it does not know about one corner
case:

```dart
var a = Decimal(BigInt.parse('644385861467633436300000'), decimalPrecision: 0);
var b = Decimal.fromInt(123);
print('$a / $b = ${a / b}'); // FormatException: Could not parse BigInt 238909442826288e+21
```

First the result of division is calculated as `double`, then it is converted to
a string using `double.toStringAsFixed`, and the string is then converted to
`BigInt`. But `double.toStringAsFixed` does not always return an "asFixed"
result. When the error limit is reached, the method switches to
`double.toStringAsExponential`. The author did not notice this feature. But we
found out faster what is hiding under the hood.

#### [big_decimal](https://pub.dev/packages/big_decimal)

This one seems to have been ported over from Java:

> A bugless implementation of BigDecimal in Dart based on Java's BigDecimal.

But it doesn't just divide 1 by 8 in it:

```dart
final a = BigDecimal.one;
final b = BigDecimal.parse('8');
print('$a / $b = ${a.divide(b)}'); //  Exception: Rounding necessary
```

Numbers can be divided by specifying the rounding mode. But that's not what we
wanted to do.

```dart
final a = BigDecimal.one;
final b = BigDecimal.parse('8');
print('$a / $b = ${a.divide(b, roundingMode: RoundingMode.FLOOR)}'); // 1 / 8 = 0
```

Or by changing the scale of the numerator:

```dart
final a = BigDecimal.parse('1.000');
final b = BigDecimal.parse('8');
print('$a / $b = ${a.divide(b)}'); // 1.000 / 8 = 0.125
```

If we don't guess the scale, we get an error.

That's how "a bugless implementation of BigDecimal" works.

#### [precise_decimal](https://pub.dev/packages/precise_decimal)

This one is younger than the rest — it came out in April 2026, when this
package was already written — and it is the one with nothing to report. It
divides 1 by 8 and gets 0.125 without being told a scale. It answers `null`
from `tryDivideExact` when the quotient does not terminate, and throws from
`divideExact` with a message that says why. It puts 0.5 above 0.49 in
`compareTo`. It carries `1 / 256 / 256 / …` to the last digit. Every trap the
four above fall into, it walks past.

In the bench it is the only competitor that supports all 35 tests and answers
none of them wrongly — `to-double-wide` included, the row where
[decimal](https://pub.dev/packages/decimal) and
[big_decimal](https://pub.dev/packages/big_decimal) each miss the nearest
`double` on seven values out of twenty. On `add-dirty-int` it is faster than
this package, and that is the only row where anyone is: its coefficient stays
an `int` for as long as one fits, so small values never leave int64 arithmetic.

The visible difference between us is a matter of taste rather than of
correctness. It keeps the scale a number was parsed with, so `parse('1.500')`
prints as `1.500`, while here the value is brought to its canonical form and
prints as `1.5`; both packages call those two numbers equal in `==`,
`compareTo` and `hashCode`. What it has and this package does not is the rest
of General Decimal Arithmetic — `DecimalContext` with `decimal32/64/128`,
conditions and traps. What this package has and it does not is a second family,
on `int`.


### What's it supposed to be?

Three packages out of five did not satisfy me because of bugs in calculations,
incomplete functionality (division) or use of `double` under the hood.

[decimal](https://pub.dev/packages/decimal),
[precise_decimal](https://pub.dev/packages/precise_decimal) and
[denary](https://pub.dev/packages/denary)
do not have the above division problems. No need to calculate `scale`
yourself, and no `double` under the hood.

Numbers are read from strings — exponential notation included — and written
back without losing anything on the way:

```dart
print(Decimal.parse('1.5e21')); // 1500000000000000000000
print(Decimal.parse('-0.000001')); // -0.000001
print(Decimal.parse('19.99').toStringAsFixed(4)); // 19.9900
```

[decimal](https://pub.dev/packages/decimal) returns the result of a division as
`Rational` ([rational](https://pub.dev/packages/rational)), since not every
quotient can be represented by a decimal. But it can be easily converted
to `Decimal`:

```dart
final a = Decimal.one;
final b = Decimal.fromInt(256);
print('$a / $b = ${a / b}'); // 1 / 256 = 1/256
print('$a / $b = ${(a / b).toDecimal()}'); // 1 / 256 = 0.00390625
```

If the result cannot be represented as a decimal, i.e. the number has an
infinite number of decimal places (has infinite precision), an exception will
be thrown. But if you pass `scaleOnInfinitePrecision` to `toDecimal` to limit
the precision, the number will be converted to decimal with loss of precision
and no exception will be thrown.

```dart
final a = Decimal.one;
final b = Decimal.fromInt(3);
print('$a / $b = ${a / b}'); // 1 / 3 = 1/3
print('$a / $b = ${(a / b).toDecimal(scaleOnInfinitePrecision: 6)}'); // 1 / 3 = 0.333333
```

[denary](https://pub.dev/packages/denary) does the opposite and returns the
result immediately:

```dart
final a = Decimal.one;
final b = Decimal(256);
print('$a / $b = ${a / b}'); // 1 / 256 = 0.00390625
```

I wanted a package that works with decimals to return the result as a decimal
by default. But not every division has a decimal answer — one third has none —
so the package makes you say which answer you want. Four ways, and only the
last of them fails over a quotient nobody can write down:

```dart
final a = Decimal.one;
final b = Decimal(3);

print(a.isDivisibleBy(b)); // false — ask before dividing
print(a.divideOrNull(b)); // null — divide, and be told
print(a.divide(b, scaleOnInfinitePrecision: 6)); // 0.333333 — round on the spot
print(a / b); // throws DecimalDivideException
```

`divideOrNull` is the one to reach for by default: it asks the same question as
catching the exception and is several times faster at it — about five times in
`Decimal`, and more than a hundred in `ShortDecimal`, where the division costs
nanoseconds while a throw still costs about a microsecond. `operator /` is the
fast form for the case where the division is known to be exact in advance: a
value scaled by a power of ten, or a divisor that is a factor of the dividend.
Splitting money by a number of parts is not such a case: a third of 23.99 has
no finite decimal form, and `Decimal.parse('23.99') / Decimal(3)` throws. A
money split goes to the smallest unit first, and then nothing is lost:
`Decimal.parse('23.99') << 2` is 2399 cents, `~/ Decimal(3)` gives each part
799 of them, and `%` says which two are left over.

When it does throw, the exception is not a dead end: it carries every other
answer the division had.

```dart
final a = Decimal.one;
final b = Decimal(3);
try {
  print('$a / $b = ${a / b}');
} on DecimalDivideException catch (e) {
  print('${e.dividend} / ${e.divisor} = ${e.fraction}'); // 1 / 3 = 1/3
  print('${e.dividend} / ${e.divisor} = ${e.quotientWithRemainder}'); // 1 / 3 = 0 remainder 1
  print('${e.dividend} / ${e.divisor} = ${e.round(6)}'); // 1 / 3 = 0.333333
}
```

It is possible to avoid exceptions by using one of the methods:
`divideToDouble`, `divideToFraction`, `divideWithRemainder`.

This way I tried to avoid different interpretations. If you need the result as
`double`, say so explicitly:

```dart
print('$a / $b = ${a.divideToDouble(b)}'); // 0.3333333333333333
print('$a / $b = ${a.divideToFraction(b)}'); // 1/3
print('$a / $b = ${a.divideWithRemainder(b)}'); // 0 remainder 1
```

The approach implemented in [decimal](https://pub.dev/packages/decimal) is
convenient because it allows to perform a number of actions, the intermediate
results of which cannot be represented as a decimal, but the final result is
still expected to be a decimal. For example: 1 / 3 * 9:

```dart
final rational = Decimal.fromInt(1) / Decimal.fromInt(3) * Decimal.fromInt(9).toRational();
final decimal = rational.toDecimal(); // 3
```

A package that works only with decimals will not be able to solve such
an example so elegantly. Or you will have to resort to rounding and lose
precision:

```
1 / 3 = 0.333
0.333 * 9 = 2.997
```

But you can use additional solutions for working with fractions, such as the
[fraction](https://pub.dev/packages/fraction), or the already mentioned
[rational](https://pub.dev/packages/rational).

[denary](https://pub.dev/packages/denary) has its own
`Fraction` class, which provides basic functions for working with fraction.

```dart
final a = Fraction(BigInt.from(1), BigInt.from(2));
final b = Fraction(BigInt.from(1), BigInt.from(3));
final f1 = a * b;
final f2 = a / b;
final f3 = a + b;
final f4 = a - b;
print('($a) * ($b) = $f1 -> ${f1.round(6)}'); // (1/2) * (1/3) = 1/6 -> 0.166667
print('($a) / ($b) = $f2 -> ${f2.toDecimal()}'); // (1/2) / (1/3) = 3/2 -> 1.5
print('($a) + ($b) = $f3 -> ${f3.round(6)}'); // (1/2) + (1/3) = 5/6 -> 0.833333
print('($a) - ($b) = $f4 -> ${f4.round(6)}'); // (1/2) - (1/3) = 1/6 -> 0.166667
```

### Package performance

The numbers below come from the bench in [`example/`](example) — what it does
and why is in [`example/README.md`](example/README.md).
The short of it:

- every answer is checked before it is timed, so a wrong answer is never
  reported as a fast one;
- every benchmark is measured five times, and the whole sweep is run twice
  (`--passes=2`); the table shows the best of the two medians, because
  unrelated load on the machine can only ever make a benchmark look slower;
- the result of every measured cycle goes into a sink the optimizer is not
  allowed to drop;
- a package that has no such operation shows `—`, not an error.

One row is one pass over a list of values, and the number is what that pass
cost in microseconds. `★` marks the winner and everyone within 10 % of it,
`▼Nx` says how many times slower than the winner. `ShortDecimal` stands outside
that reckoning and carries a mark of its own: `★★` where it is faster than
every package in the comparison — so the rows where that mark is missing are
exactly the rows where int64 buys nothing. The absolute values mean nothing on
their own; another machine will give different ones. The ratios are the point.

*Running the tests:*

```bash
dart compile exe example/bin/benchmark.dart
example/bin/benchmark.exe all --passes=2
```

```
Dart:   3.13.0 (stable) on "macos_arm64"
OS:     Version 26.5.2 (Build 25F84)
CPUs:   14
Mode:   AOT (dart compile exe)
Runs:   5 (median of the series)
Deps:   decimal 3.2.6, decimal_type 0.0.3, fixed 6.1.1, big_decimal 0.7.0,
        precise_decimal 0.0.1
```

The two rightmost columns are this package: `Decimal` on `BigInt` and
`ShortDecimal` on `int`. `ShortDecimal` stands outside the comparison — int64 is
not the same job as `BigInt`, and it is in the table to show what that
difference buys. The bench also runs
[big_double](https://pub.dev/packages/big_double), which is left out here: it is
a floating-point type, and on most of these rows its answer is not the exact
one.

|                               |            decimal |        decimal_type |              fixed |       big_decimal |  precise_decimal |     Decimal | ShortDecimal |
|:------------------------------|-------------------:|--------------------:|-------------------:|------------------:|-----------------:|------------:|-------------:|
| add-big-int                   |           1.578 µs |      (▼2x) 2.686 µs |           1.963 µs |          1.860 µs |         1.429 µs |  ★ 0.996 µs |            — |
| add-int                       |           0.589 µs |      (▼2x) 0.989 µs |     (▼2x) 0.738 µs |          0.701 µs |         0.556 µs |  ★ 0.355 µs |  ★★ 0.150 µs |
| add-dirty-big-int             |           0.778 µs |      (▼2x) 1.283 µs |           0.970 µs |          0.917 µs |         0.700 µs |  ★ 0.490 µs |            — |
| add-dirty-int                 |     (▼2x) 0.353 µs |      (▼3x) 0.568 µs |     (▼2x) 0.440 µs |    (▼2x) 0.415 µs |       ★ 0.164 µs |    0.223 µs |  ★★ 0.092 µs |
| multiply-large-big-int        |           0.118 µs |          ★ 0.107 µs |           0.151 µs |        ★ 0.110 µs |   (▼2x) 0.294 µs |  ★ 0.115 µs |            — |
| multiply-large-int            |         ★ 0.101 µs |          ★ 0.093 µs |           0.135 µs |        ★ 0.094 µs |   (▼2x) 0.241 µs |  ★ 0.098 µs |  ★★ 0.045 µs |
| multiply-small-big-int        |           0.119 µs |          ★ 0.107 µs |    (▼46x) 5.048 µs |        ★ 0.110 µs |   (▼2x) 0.294 µs |  ★ 0.116 µs |            — |
| multiply-small-int            |           0.100 µs |          ★ 0.088 µs |    (▼36x) 3.208 µs |        ★ 0.091 µs |         0.107 µs |  ★ 0.096 µs |  ★★ 0.045 µs |
| multiply-dirty-big-int        |         ★ 0.093 µs |          ★ 0.085 µs |    (▼31x) 2.720 µs |        ★ 0.088 µs |   (▼2x) 0.254 µs |  ★ 0.090 µs |            — |
| multiply-dirty-int            |           0.038 µs |          ★ 0.034 µs |    (▼28x) 0.968 µs |        ★ 0.035 µs |         0.046 µs |  ★ 0.037 µs |  ★★ 0.017 µs |
| divide-large-big-int          |     (▼5x) 8.830 µs |               ERROR |           2.056 µs |          1.926 µs |         2.001 µs |  ★ 1.653 µs |            — |
| divide-large-int              |     (▼5x) 7.589 µs |               ERROR |           1.731 µs |          1.648 µs |         1.708 µs |  ★ 1.414 µs |  ★★ 0.057 µs |
| divide-small-big-int          | (▼108x) 579.441 µs |               ERROR |              ERROR |             ERROR |  (▼2x) 11.322 µs |  ★ 5.322 µs |            — |
| divide-small-int              |  (▼51x) 134.427 µs |               ERROR |              ERROR |             ERROR |   (▼2x) 6.957 µs |  ★ 2.633 µs |  ★★ 0.123 µs |
| divide-dirty-big-int          | (▼341x) 443.722 µs |               ERROR |     (▼2x) 3.288 µs |          1.811 µs | (▼32x) 42.037 µs |  ★ 1.300 µs |            — |
| divide-dirty-int              |   (▼64x) 36.411 µs |               ERROR |     (▼2x) 1.234 µs |          0.789 µs |  (▼10x) 5.788 µs |  ★ 0.567 µs |  ★★ 0.025 µs |
| divide-large-and-view-big-int |     (▼5x) 8.977 µs |               ERROR |           2.161 µs |          1.928 µs |         2.090 µs |  ★ 1.648 µs |            — |
| divide-large-and-view-int     |     (▼5x) 7.746 µs |               ERROR |           1.848 µs |          1.656 µs |         1.809 µs |  ★ 1.421 µs |  ★★ 0.060 µs |
| divide-small-and-view-big-int |  (▼90x) 581.455 µs |               ERROR |              ERROR |             ERROR |        11.309 µs |  ★ 6.459 µs |            — |
| divide-small-and-view-int     |  (▼43x) 134.752 µs |               ERROR |              ERROR |             ERROR |   (▼2x) 7.038 µs |  ★ 3.133 µs |  ★★ 0.321 µs |
| raw-view-big-int              |          22.341 µs |     (▼2x) 48.948 µs |    (▼2x) 52.652 µs |       ★ 19.366 µs |        30.749 µs | ★ 18.071 µs |            — |
| raw-view-int                  |          10.192 µs |     (▼3x) 23.962 µs |    (▼3x) 23.825 µs |          7.984 µs |  (▼2x) 19.160 µs |  ★ 6.800 µs |  ★★ 1.578 µs |
| raw-view-zeros-big-int        |   (▼6x) 109.526 µs |    (▼8x) 142.183 µs |    (▼3x) 61.879 µs |       ★ 18.675 µs |        30.721 µs | ★ 17.723 µs |            — |
| raw-view-zeros-int            |    (▼6x) 47.844 µs |     (▼7x) 48.987 µs |    (▼4x) 29.784 µs |          8.033 µs |  (▼2x) 20.093 µs |  ★ 6.943 µs |  ★★ 1.114 µs |
| repeat-view-big-int           |  (▼592x) 17.592 µs |  (▼1614x) 47.914 µs | (▼1763x) 52.323 µs | (▼639x) 18.987 µs |  (▼68x) 2.046 µs |  ★ 0.030 µs |            — |
| repeat-view-int               |   (▼221x) 6.257 µs |   (▼829x) 23.446 µs |  (▼829x) 23.422 µs |  (▼269x) 7.627 µs |  (▼60x) 1.703 µs |  ★ 0.028 µs |     1.545 µs |
| repeat-view-zeros-big-int     |    (▼41x) 1.240 µs | (▼4771x) 142.148 µs | (▼2068x) 61.638 µs | (▼607x) 18.091 µs |  (▼65x) 1.961 µs |  ★ 0.030 µs |            — |
| repeat-view-zeros-int         |    (▼34x) 1.024 µs |  (▼1692x) 50.379 µs |  (▼983x) 29.284 µs |  (▼256x) 7.647 µs |  (▼58x) 1.729 µs |  ★ 0.030 µs |     0.930 µs |
| parse                         |   (▼12x) 14.030 µs |    (▼12x) 14.252 µs |   (▼76x) 85.171 µs |   (▼9x) 10.785 µs | (▼10x) 11.604 µs |  ★ 1.113 µs |  ★★ 0.819 µs |
| compare                       |           0.636 µs |      (▼7x) 2.556 µs |              ERROR |    (▼3x) 1.174 µs |         0.616 µs |  ★ 0.329 µs |  ★★ 0.159 µs |
| round                         |           3.873 µs |                   — |           4.278 µs |          4.218 µs |         5.250 µs |  ★ 3.425 µs |  ★★ 0.215 µs |
| to-double                     |     (▼2x) 1.842 µs |    (▼30x) 19.662 µs |                  — |          0.740 µs | (▼19x) 13.009 µs |  ★ 0.652 µs |  ★★ 0.094 µs |
| to-double-wide                |              ERROR |    (▼14x) 33.923 µs |                  — |             ERROR |  (▼8x) 19.973 µs |  ★ 2.348 µs |            — |
| to-string-as-fixed            |    (▼2x) 15.102 µs |                   — |                  — |                 — |         7.302 µs |  ★ 5.504 µs |  ★★ 1.835 µs |
| unrepresentable-divide        |  (▼32x) 122.338 µs |                   — |           6.683 µs |          4.758 µs |         4.184 µs |  ★ 3.708 µs |  ★★ 0.397 µs |
| unrepresentable-divide-wide   |  (▼71x) 283.447 µs |                   — |           6.627 µs |          5.289 µs |         4.456 µs |  ★ 3.966 µs |  ★★ 3.123 µs |

`ERROR` is not a crash. It means the package answered and the answer was wrong.
[fixed](https://pub.dev/packages/fixed) and
[decimal_type](https://pub.dev/packages/decimal_type) return 0 for
`1 / 256 / 256 / …`, which is what a fixed scale does to a small number, and
`fixed` puts 0.5 below 0.49 in `compare`, because its `compareTo` looks at the
stored integers without first bringing the scales together.
[big_decimal](https://pub.dev/packages/big_decimal) is the honest one in that
column: it refuses with `Rounding necessary` instead of answering wrongly — but
a refusal is not a result either, and it shows as `ERROR` all the same.

`to-double-wide` is the one row where [decimal](https://pub.dev/packages/decimal)
shows `ERROR`, and it deserves to be spelled out. Its values carry more
significant digits than a `double` holds, so every one of them has to be
rounded and the only question is whether it lands on the nearest one. The set
was generated blind — not by hunting for values where somebody fails — and the
expected answers were computed outside Dart by exact conversion. Of the twenty,
`decimal` misses the nearest double on seven and `big_decimal` on seven as well;
both divide one `double` by another, which rounds twice. Over 100 000 random
values `decimal` and this package disagree on 33 815 of them, and on 300 of
those disagreements checked against exact arithmetic, this package was right
every time and `decimal` never.

That row is also where the fastest answers are the wrong ones:
`big_decimal` finishes it in 0.8 µs and `decimal` in 2.4, against 2.3 here.

Where a division is exact, the gap is not about `BigInt` against `int` but about
what the algorithm can see. `divide-dirty` divides a product back by its own
factors — every step exact, nothing about the numbers saying so in advance —
and [decimal](https://pub.dev/packages/decimal) spends 341 times longer on it
than this package.

`unrepresentable-divide` rounds a quotient that has no finite decimal form, and
this package takes the row ahead of everyone in the comparison, with
`ShortDecimal` nine times ahead of `Decimal` on top of that. `divide` returns the
exact answer whenever the division does have a finite form, however many digits
that takes, and it pays nothing to find out: when the divisor shares no prime
factor with ten, a non-zero remainder from the rounding is itself the proof that
no finite form exists, so the question is never asked separately.

#### Description of benchmarks

##### add

Adding numbers:

10000000000000000000 + 1000000000000000000 + 100000000000000000 + 10000000000000000 + 1000000000000000 + 100000000000000 + 10000000000000 + 1000000000000 + 100000000000 + 10000000000 + 1000000000 + 100000000 + 10000000 + 1000000 + 100000 + 10000 + 1000 + 100 + 10 + 1 + 0.1 + 0.01 + 0.001 + 0.0001 + 0.00001 + 0.000001 + 0.0000001 + 0.00000001 + 0.000000001 + 0.0000000001 + 0.00000000001 + 0.000000000001 + 0.0000000000001 + 0.00000000000001 + 0.000000000000001 + 0.0000000000000001 + 0.00000000000000001 + 0.000000000000000001 + 0.0000000000000000001 + 0.00000000000000000001 = 11111111111111111111.11111111111111111111

A very simple operation. But note that in the case of decimal, it is much more
complicated than multiplication.

##### multiply-large

Multiplication of large numbers:

123456789 * 123456789 * 123456789 * 123456789 * 123456789 * 123456789 * 123456789 * 123456789 * 123456789 * 123456789 = 822526259147102579504761143661535547764137892295514168093701699676416207799736601

A simple operation for decimal. It is impossible to make a mistake in it. There
is no simpler operation.

##### multiply-small

Multiplication of small numbers:

0.0123456789 * 0.0123456789 * 0.0123456789 * 0.0123456789 * 0.0123456789 * 0.0123456789 * 0.0123456789 * 0.0123456789 * 0.0123456789 * 0.0123456789 = 0.0000000000000000000822526259147102579504761143661535547764137892295514168093701699676416207799736601

A simple operation, but not all packages are ready to handle numbers that have
more than 20 decimal places.

##### divide-large

Division of large numbers:

822526259147102579504761143661535547764137892295514168093701699676416207799736601 / 123456789 / 123456789 / 123456789 / 123456789 / 123456789 / 123456789 / 123456789 / 123456789 / 123456789 / 123456789 = 1

Division is not the strongest point of most packages. Even integers! Even the
result of which is also an integer!

##### divide-small

Division of small numbers:

1 / 256 / 256 / 256 / 256 / 256 / 256 / 256 / 256 / 256 = 0.000000000000000000000211758236813575084767080625169910490512847900390625

It's a difficult task. It's easy to stumble over. [decimal](https://pub.dev/packages/decimal)
solves it, but at what cost! Some packages use the `double` trick and stumble
over it. And some don't even try.

##### divide-large-and-view and divide-small-and-view

Division of numbers and converting the result in a readable format.

Packages can use intermediate results in their work, which speed up the speed
of operations, but do not have a decimal form understandable to the user. (This
is what [decimal](https://pub.dev/packages/decimal) did until version 3.2.0;
none of the packages compared here does it today — all of them keep a
significand and a scale). Therefore, the divide-large and divide-small test,
where only division is performed, may be far from real life. This tests perform
the same operation as divide-large and divide-small, but additionally convert
the result of the operation (only the operation, not each step in this
operation) into a readable form.

I'll be honest, it took me a long time to find a solution that satisfied me in
terms of performance.

##### raw-view

Convert newly created numbers into a readable format:

- 123456789012345678901234567890123456789
- 1234567890123456789012345678901234567.89
- 12345678901234567890123456789012345.6789
- 123456789012345678901234567890123.456789
- 1234567890123456789012345678901.23456789
- 12345678901234567890123456789.0123456789
- 123456789012345678901234567.890123456789
- 1234567890123456789012345.67890123456789
- 12345678901234567890123.4567890123456789
- 123456789012345678901.234567890123456789
- 1234567890123456789.01234567890123456789
- 12345678901234567.8901234567890123456789
- 123456789012345.678901234567890123456789
- 1234567890123.45678901234567890123456789
- 12345678901.2345678901234567890123456789
- 123456789.012345678901234567890123456789
- 1234567.89012345678901234567890123456789
- 12345.6789012345678901234567890123456789
- 123.456789012345678901234567890123456789
- 1.23456789012345678901234567890123456789

This is usually a resource-intensive task, as the package does not have time to
do any optimizations with the number.

The values above are one cycle of it. The set is a pool a hundred cycles deep,
walked in order, so every cycle converts values no cycle before it converted.
A package is free to remember what it printed — that is what repeat-view
measures — but this row may not be answered from that memory, and a fresh
object is not enough to prevent it: a table keyed by the value rather than by
the object answers a new object just the same. A pool larger than any cache in
the comparison is what keeps the row a first conversion for every package
alike.

##### raw-view-zeros

Convert newly created numbers with lots of leading and trailing zeros into
a readable format:

- 100000000000000000000000000000000000000
- 10000000000000000000000000000000000
- 1000000000000000000000000000000
- 100000000000000000000000000
- 10000000000000000000000
- 1000000000000000000
- 100000000000000
- 10000000000
- 1000000
- 100
- 0.01
- 0.000001
- 0.0000000001
- 0.00000000000001
- 0.000000000000000001
- 0.0000000000000000000001
- 0.00000000000000000000000001
- 0.000000000000000000000000000001
- 0.0000000000000000000000000000000001
- 0.00000000000000000000000000000000000001

Converting such numbers is technically quite different from converting numbers
without zeros in raw-view. Each of the tests (raw-view and raw-vew-zeros)
separately can give a wrong idea of performance, so they should be considered
only together.

##### repeat-view

Converting the same numbers to a readable format a second time, and every time
after that.

Printing one and the same value over and over is what a screen does, and a
package is free to remember what it printed last time. raw-view measures the
first conversion, this one measures all the later ones, and the two are only
meaningful together: a package that is quick here and slow there has a cache,
not a faster algorithm.

`Decimal` keeps the printed form; `ShortDecimal` does not, and cannot:
`vm:deeply-immutable` admits only final non-late fields, so a cache filled on
first use has nowhere to live. [decimal_type](https://pub.dev/packages/decimal_type),
[fixed](https://pub.dev/packages/fixed) and [big_decimal](https://pub.dev/packages/big_decimal)
keep nothing either.

##### repeat-view-zeros

The same, on numbers with a large number of leading or trailing zeros.

##### add-dirty, multiply-dirty, divide-dirty

The same three operations on values with nothing round about them: no trailing
zeros to strip, no common factors to cancel, no digit repeated. Every other set
here is built out of powers of ten or out of one factor repeated, which is the
best case for stripping zeros, for `gcd` and for the fast path of division.
Money does not look like that.

divide-dirty divides a product back by its own factors. Every division in it is
exact, but nothing about the numbers says so in advance — only `gcd` can see it.

##### parse

Reading twenty money-like numbers out of strings. Every package is given the
same strings.

The row is not quite like for like, and the difference is a design decision on
this side: our `parse` stops at the digits and the scale, and leaves the
canonical form to whoever asks for it, while the other packages normalise the
value on the spot. Read the row together with raw-view and repeat-view, which
is where the work our `parse` did not do comes back.

##### compare

Comparing neighbours of the same magnitude but of different scales, so that the
comparison cannot be settled by the exponent and has to bring the two numbers to
a common scale first.

[fixed](https://pub.dev/packages/fixed) 6.1.1 shows `ERROR` here: its
`compareTo` compares the stored integers without aligning the scales, so it puts
0.5 below 0.49. The bench checks every answer before timing it, and a wrong
answer is never reported as a fast one.

##### round

Rounding to two digits, halves away from zero.

##### to-double

Converting to the nearest `double`.

##### to-double-wide

The same conversion on numbers that carry more significant digits than a
`double` has room for — which is the only case where rounding to the nearest
double is a question at all. `to-double` above uses money-sized values, where
every package agrees.

The twenty values were generated with a fixed seed and no filtering, and their
expected answers come from exact decimal-to-binary conversion done outside
Dart. Magnitudes stay between `1e-4` and `1e16`, where Dart prints a `double`
the same way the generator does, so the comparison is byte-for-byte.

##### to-string-as-fixed

Writing a number out with exactly two digits after the point — the operation
that formats money for a screen.

##### unrepresentable-divide

Dividing by three: not one of the results has a finite decimal form, so every
one of them has to be rounded to ten digits. This is the price of the total
forms of division — `divide(other, scaleOnInfinitePrecision: 10)` here,
`toDecimal(scaleOnInfinitePrecision: 10)` in [decimal](https://pub.dev/packages/decimal),
`divide(..., scale: 10)` in [big_decimal](https://pub.dev/packages/big_decimal).
[fixed](https://pub.dev/packages/fixed) has no argument for it at all: its
`operator /` gives the quotient the wider of the two scales, so it is the
divisor that carries the ten digits. The packages that cannot do it at all show
`—`.

##### unrepresentable-divide-wide

The same rounding to ten digits, with money divided by money instead of by
three. Dividing by three keeps the exact dividend and the answer the same width,
so a dividend that outgrows a machine word gives an answer that outgrows it too
and the case cannot be put on a bench at all. A money-sized divisor pulls the
answer back under four thousand while the exact dividend, carrying ten more
digits, runs up to `8.9e22` — past what a machine word holds, while the values
and the answers both stay inside one. Carrying that middle somewhere is what the
row measures.

### [decimal](https://pub.dev/packages/decimal) vs [denary](https://pub.dev/packages/denary)

The last thing I want to do is compete with the author of
[decimal](https://pub.dev/packages/decimal), especially when I see how long
this package has been around and how well supported it is. I don't think I have
anything overtly new to offer in the usual approach to decimal. Even using
different approaches under the hood, the end result will be on the outside, not
the inside. And it's pretty much the same feature set. I thought the same about
performance — the table above says otherwise.

But actually the decision to write my own
[denary](https://pub.dev/packages/denary) was not
only influenced by the poor (at the time) performance of
[decimal](https://pub.dev/packages/decimal). There was another reason. For my
task I needed a lightweight decimal, which needed a regular `int` instead of
`BigInt` to store values under the hood. My values fit even in int32. These are
the results of training: geoposition, distance, altitude gain, pace, heart
rate, cadence, power. As an old generation programmer, it's morally hard for me
to waste resources in places where it's not necessary. Especially I expect
a large amount of data and calculations with them. And I was surprised to find
no ready-made solution on [pub.dev](https://pub.dev).

So, `Decimal` was not originally the main purpose of the package. The main goal
was `ShortDecimal`. `Decimal` was just a natural evolution of the package.

## `Decimal` vs `ShortDecimal`

Two families, three ways to import them:

```dart
// both, and the bridge between them
import 'package:denary/denary.dart';

// only the BigInt family
import 'package:denary/decimal.dart';

// only the int64 family
import 'package:denary/short_decimal.dart';
```

Take `Decimal` when the magnitudes are not known in advance: it has no bound
and nothing overflows. Take `ShortDecimal` when they are known to be small and
the speed is the point — it is several times faster and smaller, and its
overflow is silent. The bridge between them lives only in the umbrella import,
because it is the only thing that needs both.

`ShortDecimal` carries `@pragma('vm:deeply-immutable')`, and `Decimal` never
will — that annotation rejects a `BigInt` field outright. What it grants is
that the VM may hand another isolate the very same instance instead of a copy:
send one across a port and it comes back `identical`, where an ordinary class
of two `int` fields comes back copied. What it costs is every lazily filled
field, because a deeply immutable class may hold only final non-late ones —
which is why the printed form is remembered in `Decimal` and not here.

Both families answer to the same names. Two of those names are operators, and
operators are easy to read the wrong way round, so each has a word for it:

| Operator | The same thing, spelled out |
|:--|:--|
| `value >> n` | `value.movePointLeft(n)` — divides by `10^n` |
| `value << n` | `value.movePointRight(n)` — multiplies by `10^n` |

`>>` moves the point **left**, and that is exactly what trips readers up.

## `ShortDecimal` limitations

`ShortDecimal` has the same functions as `Decimal`, but the values are stored
in `int` with all the consequences. On the one hand, it is high performance,
but on the other hand it is a possibility of uncontrolled overflow of a value,
which will not happen in case of using `BigInt`. You can write code that will
control overflow, but it will make the algorithms much more complicated and
slow. The additing is too simple to be burdened with additional checks. Each
such check will increase the operation's execution time by times.

Therefore, `ShortDecimal` should only be used with the possibility of overflow
in mind:

```dart
print(ShortDecimal(9223372036854775807) + ShortDecimal.one); // -9223372036854775808
```

The `ShortDecimal` capability bounds are `int` bounds. In native platforms and
wasm it is int64, in js environment accuracy is promised only up to int53.

For int64, significant digits (base in package terms), i.e. the value without
leading and trailing zeros, must not be out of the range
[-9223372036854775808..9223372036854775807].

```dart
final a = ShortDecimal(9223372036854775807) >> 40; // ok
final b = ShortDecimal(9223372036854775807) << 23; // ok
print(a); // 0.0000000000000000000009223372036854775807
print(b); // 922337203685477580700000000000000000000000
```

The number itself 922337203685477580700000000000000000000000 goes well beyond
`int`. But its base (without trailing zeros) fits into int64.

But you also have to work with that number in the same scale:

```dart
//   922337203685477580700000000000000000000000
//                   - 100000000000000000000000
// = 922337203685477580600000000000000000000000
print(b - (ShortDecimal(1) << 23)); // 922337203685477580600000000000000000000000 <- ok

//   922337203685477580700000000000000000000000
//                                          - 1
// = 922337203685477580699999999999999999999999
print(b - ShortDecimal(1)); // -200376420520689665 <- overflow
```

Such constraints impose on `ShortDecimal` the need to constantly optimize the
value resulting from operations on it, in order to keep the ability to stay
within the `int` boundaries longer. `Decimal` does not need such optimization.

For example, multiplying two numbers: 1.2 * 5. Under the hood, everything is
stored in an integer variable (`base`) and a parameter indicating where the
decimal point is located (usually called `scale`). 1.2 would be stored as
(base: 12, scale: 1) and 5 as (base: 5, scale: 0).

```dart
final a = Decimal.parse('1.2'); // kept as base 12, scale 1
final b = Decimal.parse('5'); // kept as base 5, scale 0

final c = ShortDecimal.parse('1.2'); // kept as base 12, scale 1
final d = ShortDecimal.parse('5'); // kept as base 5, scale 0
```

Multiplication of such numbers is quite a simple operation: the bases are
multiplied and the scales are added. The result will be: (base: 60, scale: 1).
This is 6. And `Decimal` doesn't need to reduce it to (base: 6, scale: 0). But
for `ShortDecimal` it is vital.

```dart
final r1 = a * b;
print(r1); // 6, kept as base 60, scale 1

final r2 = c * d;
print(r2); // 6, kept as base 6, scale 0
```

`Decimal`, of course, could after each operation bring the value to normal,
i.e. to (base: 6, scale: 0), but this is additional time, which in most cases
is unnecessary. And where `BigInt` is used, there is no practical need for
this: there is not too much difference between (base: 6, scale: 0) and
(base: 60000000000, scale: 10). But in the case of `int` we can reach overflow
very quickly. For example, it is enough to multiply 1.0 by 1.0, i.e.
(base: 10, scale: 1) by (base: 10, scale: 1), only 18 times to go beyond the
`int` boundary. Even though it's only 1!

```dart
var a = Decimal.parse('1.0');
for (var i = 0; i < 18; i++) {
  a *= Decimal.parse('1.0');
}
print(a); // 1, kept as base 10000000000000000000, scale 19

final i = 10000000000000000000; // The integer literal 10000000000000000000 can't be represented in 64 bits.
```

That's why you should pack the value after each operation to stay within `int`
boundaries longer. But you should not worry about performance. In the case of
`int` it will be much faster than `BigInt` without packing.

```dart
var a = ShortDecimal.parse('1.0');
for (var i = 0; i < 18; i++) {
  a *= ShortDecimal.parse('1.0');
}
print(a); // 1, kept as base 1, scale 0
```

### Performance

The same bench, this package against
[decimal](https://pub.dev/packages/decimal) and
[precise_decimal](https://pub.dev/packages/precise_decimal), on the sets that
fit into an `int` so that both families can be shown at once. The first column
is the package most projects already have; the second is the quickest of the
competitors on most rows — thirteen of the twenty-one — though not on
multiplication, `round`, `to-double`, `raw-view` or `repeat-view-zeros`, where
it is the slower of the two, nor on `compare`, where the two come out level:

|                             |             decimal |   precise_decimal |         Decimal |    ShortDecimal |
|:----------------------------|--------------------:|------------------:|----------------:|----------------:|
| add-int                     |      (▼3x) 0.589 µs |    (▼3x) 0.556 µs |  (▼2x) 0.355 µs |      ★ 0.150 µs |
| add-dirty-int               |      (▼3x) 0.353 µs |          0.164 µs |  (▼2x) 0.223 µs |      ★ 0.092 µs |
| multiply-large-int          |      (▼2x) 0.101 µs |    (▼5x) 0.241 µs |  (▼2x) 0.098 µs |      ★ 0.045 µs |
| multiply-small-int          |      (▼2x) 0.100 µs |    (▼2x) 0.107 µs |  (▼2x) 0.096 µs |      ★ 0.045 µs |
| multiply-dirty-int          |      (▼2x) 0.038 µs |    (▼2x) 0.046 µs |  (▼2x) 0.037 µs |      ★ 0.017 µs |
| divide-large-int            |    (▼133x) 7.589 µs |   (▼29x) 1.708 µs | (▼24x) 1.414 µs |      ★ 0.057 µs |
| divide-small-int            | (▼1092x) 134.427 µs |   (▼56x) 6.957 µs | (▼21x) 2.633 µs |      ★ 0.123 µs |
| divide-dirty-int            |  (▼1456x) 36.411 µs |  (▼231x) 5.788 µs | (▼22x) 0.567 µs |      ★ 0.025 µs |
| divide-large-and-view-int   |    (▼129x) 7.746 µs |   (▼30x) 1.809 µs | (▼23x) 1.421 µs |      ★ 0.060 µs |
| divide-small-and-view-int   |  (▼419x) 134.752 µs |   (▼21x) 7.038 µs |  (▼9x) 3.133 µs |      ★ 0.321 µs |
| raw-view-int                |     (▼6x) 10.192 µs |  (▼12x) 19.160 µs |  (▼4x) 6.800 µs |      ★ 1.578 µs |
| raw-view-zeros-int          |    (▼42x) 47.844 µs |  (▼18x) 20.093 µs |  (▼6x) 6.943 µs |      ★ 1.114 µs |
| repeat-view-int             |    (▼223x) 6.257 µs |   (▼60x) 1.703 µs |      ★ 0.028 µs | (▼55x) 1.545 µs |
| repeat-view-zeros-int       |     (▼34x) 1.024 µs |   (▼57x) 1.729 µs |      ★ 0.030 µs | (▼31x) 0.930 µs |
| parse                       |    (▼17x) 14.030 µs |  (▼14x) 11.604 µs |        1.113 µs |      ★ 0.819 µs |
| compare                     |      (▼4x) 0.636 µs |    (▼3x) 0.616 µs |  (▼2x) 0.329 µs |      ★ 0.159 µs |
| round                       |     (▼18x) 3.873 µs |   (▼24x) 5.250 µs | (▼15x) 3.425 µs |      ★ 0.215 µs |
| to-double                   |     (▼19x) 1.842 µs | (▼138x) 13.009 µs |  (▼6x) 0.652 µs |      ★ 0.094 µs |
| to-string-as-fixed          |     (▼8x) 15.102 µs |    (▼3x) 7.302 µs |  (▼2x) 5.504 µs |      ★ 1.835 µs |
| unrepresentable-divide      |  (▼308x) 122.338 µs |   (▼10x) 4.184 µs |  (▼9x) 3.708 µs |      ★ 0.397 µs |
| unrepresentable-divide-wide |   (▼90x) 283.447 µs |          4.456 µs |        3.966 µs |      ★ 3.123 µs |

*For a description of the tests, see [Package performance](#package-performance).*

`Decimal` and `ShortDecimal` run the same algorithms, so the distance between
the two right-hand columns is the distance between `BigInt` and `int`: about
twice on arithmetic, twenty-odd on division.

One row is about something else. In `repeat-view` `Decimal` is fifty-odd times
ahead because it keeps the string it printed last time, and `ShortDecimal` may
not keep one at all — that is what `vm:deeply-immutable` costs, and instances
the VM can share between isolates are what it buys.

`unrepresentable-divide-wide` is the other one. The exact dividend outgrows a
machine word there, so `ShortDecimal` carries it on a pair of them instead of
handing the work to `BigInt` — still ahead, but by a quarter rather than by an
order.

If your application does a handful of decimal operations, none of this matters
and `Decimal` from any of these packages will do. If it does a great many of
them, or if memory is tight, `ShortDecimal` is several times cheaper — as long
as you keep its limitations in mind.

### `Decimal` optimization

Some of what a decimal can be asked — how many digits it has after the point,
what its unscaled value is, whether it equals another decimal — has an answer
only in the canonical form: the base with its trailing zeros taken off and the
scale moved to match. `Decimal` does not hold every value that way, because
getting there costs `BigInt` arithmetic and most values are never asked those
questions. It packs a value the first time something needs the canonical form,
and keeps the result on hand.

There has to be a way to ask for it by hand, for when the algorithm does not do
it itself, and that is `normalized()`:

```dart
final packed = value.normalized();
```

It answers with the value in its canonical form, and calling it again on the
result costs nothing — the canonical form is its own. It answers rather than
changes: a method that mutates what it is called on has no business in a value
type.

The user does not need to know about packing and scaling, nor about `base` and
`scale`. What the user may legitimately want is the number taken apart, and
that is what `unscaledValue` and `exponent` are for — both read the canonical
form, so equal decimals answer equally whatever produced them.

#### What packing does to printing

Nothing, most of the time. This is a correction: earlier versions of this
section showed packing making `toString` fifty times faster, and those numbers
were measured before `toString` began keeping the string it had produced.

Printing one and the same value over and over is free either way now — the
first call prints, the rest read the kept string. Ten million `toString()`
calls on a single number, AOT, on the machine the tables above were measured
on, with the result going into a sink the optimizer may not drop:

| ten million prints of one value | |
|:--|--:|
| as it comes | 0.02 s |
| after `normalized()` | 0.02 s |

Where the difference shows is values that are each printed once, and it points
the other way:

```dart
var v = Decimal(1000000000000000000) >> 18; // = 1, and not in canonical form

for (var i = 0; i < 10000000; i++) {
  final next = i.isEven ? -v : v; // a new number every time round
  sink += next.toString().length; // and 'normalized()' before it, in the second run
}
```

| ten million values, each printed once | |
|:--|--:|
| as it comes | 1.36 s |
| `normalized()` before each print | 5.38 s |

Packing a number costs several times more than printing it. `toString` takes
the trailing zeros off the string it is building anyway, and that is cheaper
than taking them off a `BigInt` and allocating a decimal to hold the result.
This is why normalization is not built into `toString`: everyone who prints a
number once and drops it would be paying for a canonical form nobody asked for.

And where the value is already canonical, there is nothing to pay and nothing
to gain — 1.58 s against 1.61 s on the same ten million.

So: `normalized()` is for the canonical form itself — for `unscaledValue`, for
`exponent`, for a decimal that will be compared or used as a map key many times
over. It is not a way to print faster; the kept string is that.

`ShortDecimal` needs none of this: it normalises the value in every operation,
and its `normalized()` answers with the receiver itself.
