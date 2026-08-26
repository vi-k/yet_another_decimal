# Yet another decimal

It's yet another package for fixed point decimals.

## Table of contents

1. [Why?](#why)

    1.1. [What packages are already in place?](#what-packages-are-already-in-place)

    1.2. [What's it supposed to be?](#whats-it-supposed-to-be)

    1.3. [Package performance](#package-performance)

    1.4. [decimal vs yet_another_decimal](#decimalhttpspubdevpackagesdecimal-vs-yet_another_decimalhttpspubdevpackagesyet_another_decimal)

2. [`Decimal` vs `ShortDecimal`](#decimal-vs-shortdecimal)

    2.1. [`ShortDecimal` limitations](#shortdecimal-limitations)

    2.2. [Performance](#performance)

    2.3. [`Decimal` optimization](#decimal-optimization)

## Why?

As of February 2025, there are several packages on [pub.dev](https://pub.dev)
that work with decimals.

### What packages are already in place?

#### [decimal](https://pub.dev/packages/decimal)

A wonderful package that works correctly with decimals. It exists since 2014
and is constantly updated. In one of the latest updates (3.2.0), performance
has been significantly improved. Before that, speed was the weak point of this
package. This was one of the reasons why [yet_another_decimal](https://pub.dev/packages/yet_another_decimal)
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

Until this README was rewritten it went on to say that the division ran through
`double`, and showed `Fixed.parse('111111111111111111')` squared and divided
back as `111111111111111120`. That is no longer true, and the claim has been
taken out: `fixed` divides in `BigInt` today, rounding half away from zero.
Checked on 6.1.1 and 6.2.0 — the answer comes back exact:

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

This package also uses to divide `double`, but unlike
[fixed](https://pub.dev/packages/fixed) it doesn't know some corner case:

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


### What's it supposed to be?

Three packages out of four did not satisfy me because of bugs in calculations,
incomplete functionality (division) or use of `double` under the hood.

The [decimal](https://pub.dev/packages/decimal) and
[yet_another_decimal](https://pub.dev/packages/yet_another_decimal)
does not have the above division problems. No need to calculate `scale`
yourself, and no `double` under the hood.

Numbers are read from strings — exponential notation included — and written
back without losing anything on the way:

```dart
print(Decimal.parse('1.5e21')); // 1500000000000000000000
print(Decimal.parse('-0.000001')); // -0.000001
print(Decimal.parse('19.99').toStringAsFixed(4)); // 19.9900
```

[decimal](https://pub.dev/packages/decimal) returns the result as `Rational`
([rational](https://pub.dev/packages/rational)), since not every division
result can be represented by a decimal. But it can be easily converted
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

[yet_another_decimal](https://pub.dev/packages/yet_another_decimal) does the opposite and returns the
result immediately:

```dart
final a = Decimal.one;
final b = Decimal(256);
print('$a / $b = ${a / b}'); // 1 / 256 = 0.00390625
```

I wanted a package that works with decimals to return the result as a decimal
by default. But not every division has a decimal answer — one third has none —
so the package makes you say which answer you want. Four ways, and only the
last of them can fail:

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
final decimal = rational.toDecimal(); // 9
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

[yet_another_decimal](https://pub.dev/packages/yet_another_decimal) has its own
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

The numbers below come from the bench in [`example/`](example), rebuilt for
1.2.0 — what it does and why is in [`example/README.md`](example/README.md).
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
Deps:   decimal 3.2.6, decimal_type 0.0.3, fixed 6.2.0, big_decimal 0.7.0
```

The two rightmost columns are this package: `Decimal` on `BigInt` and
`ShortDecimal` on `int`. `ShortDecimal` stands outside the comparison — int64 is
not the same job as `BigInt`, and it is in the table to show what that
difference buys. The bench also runs
[big_double](https://pub.dev/packages/big_double), which is left out here: it is
a floating-point type, and on most of these rows its answer is not the exact
one.

|                               |            decimal |        decimal_type |              fixed |       big_decimal |     Decimal | ShortDecimal |
|:------------------------------|-------------------:|--------------------:|-------------------:|------------------:|------------:|-------------:|
| add-big-int                   |           1.882 µs |      (▼2x) 3.246 µs |           2.397 µs |          2.248 µs |  ★ 1.329 µs |            — |
| add-int                       |           0.695 µs |      (▼2x) 1.172 µs |           0.876 µs |          0.837 µs |  ★ 0.483 µs |  ★★ 0.150 µs |
| add-dirty-big-int             |           0.920 µs |      (▼2x) 1.546 µs |           1.162 µs |          1.107 µs |  ★ 0.648 µs |            — |
| add-dirty-int                 |           0.412 µs |      (▼2x) 0.676 µs |           0.523 µs |          0.495 µs |  ★ 0.294 µs |  ★★ 0.092 µs |
| multiply-large-big-int        |         ★ 0.145 µs |          ★ 0.136 µs |           0.178 µs |        ★ 0.142 µs |  ★ 0.144 µs |            — |
| multiply-large-int            |         ★ 0.124 µs |          ★ 0.118 µs |           0.157 µs |        ★ 0.119 µs |  ★ 0.123 µs |  ★★ 0.064 µs |
| multiply-small-big-int        |         ★ 0.144 µs |          ★ 0.137 µs |    (▼41x) 5.671 µs |        ★ 0.142 µs |  ★ 0.143 µs |            — |
| multiply-small-int            |         ★ 0.119 µs |          ★ 0.112 µs |    (▼31x) 3.540 µs |        ★ 0.117 µs |  ★ 0.119 µs |  ★★ 0.067 µs |
| multiply-dirty-big-int        |         ★ 0.112 µs |          ★ 0.108 µs |    (▼28x) 3.038 µs |        ★ 0.109 µs |  ★ 0.112 µs |            — |
| multiply-dirty-int            |         ★ 0.046 µs |          ★ 0.043 µs |    (▼24x) 1.063 µs |        ★ 0.045 µs |  ★ 0.045 µs |  ★★ 0.026 µs |
| divide-large-big-int          |     (▼5x) 9.562 µs |               ERROR |           2.255 µs |          2.124 µs |  ★ 1.759 µs |            — |
| divide-large-int              |     (▼5x) 8.257 µs |               ERROR |           1.905 µs |          1.822 µs |  ★ 1.514 µs |  ★★ 0.062 µs |
| divide-small-big-int          | (▼110x) 631.223 µs |               ERROR |              ERROR |             ERROR |  ★ 5.708 µs |            — |
| divide-small-int              |  (▼52x) 146.752 µs |               ERROR |              ERROR |             ERROR |  ★ 2.795 µs |  ★★ 0.121 µs |
| divide-dirty-big-int          | (▼352x) 485.928 µs |               ERROR |     (▼2x) 3.634 µs |          2.007 µs |  ★ 1.380 µs |            — |
| divide-dirty-int              |   (▼64x) 39.868 µs |               ERROR |     (▼2x) 1.349 µs |          0.880 µs |  ★ 0.620 µs |  ★★ 0.027 µs |
| divide-large-and-view-big-int |     (▼5x) 9.813 µs |               ERROR |           2.378 µs |          2.172 µs |  ★ 1.814 µs |            — |
| divide-large-and-view-int     |     (▼5x) 8.509 µs |               ERROR |           2.027 µs |          1.840 µs |  ★ 1.536 µs |  ★★ 0.065 µs |
| divide-small-and-view-big-int |  (▼90x) 634.875 µs |               ERROR |              ERROR |             ERROR |  ★ 6.978 µs |            — |
| divide-small-and-view-int     |  (▼43x) 147.019 µs |               ERROR |              ERROR |             ERROR |  ★ 3.367 µs |  ★★ 0.323 µs |
| raw-view-big-int              |          24.338 µs |     (▼2x) 51.374 µs |    (▼2x) 56.241 µs |       ★ 20.919 µs | ★ 19.450 µs |            — |
| raw-view-int                  |          11.048 µs |     (▼3x) 25.080 µs |    (▼3x) 25.192 µs |          8.745 µs |  ★ 7.480 µs |  ★★ 1.694 µs |
| raw-view-zeros-big-int        |   (▼6x) 122.556 µs |    (▼8x) 153.163 µs |    (▼3x) 65.215 µs |       ★ 19.936 µs | ★ 18.744 µs |            — |
| raw-view-zeros-int            |    (▼7x) 57.655 µs |     (▼7x) 54.440 µs |    (▼4x) 31.293 µs |          8.813 µs |  ★ 7.449 µs |  ★★ 1.023 µs |
| repeat-view-big-int           |  (▼767x) 19.184 µs |  (▼2033x) 50.833 µs | (▼2242x) 56.055 µs | (▼827x) 20.684 µs |  ★ 0.025 µs |            — |
| repeat-view-int               |   (▼299x) 6.898 µs |  (▼1067x) 24.544 µs | (▼1088x) 25.035 µs |  (▼364x) 8.379 µs |  ★ 0.023 µs |     1.637 µs |
| repeat-view-zeros-big-int     |    (▼51x) 1.291 µs | (▼5977x) 149.438 µs | (▼2615x) 65.397 µs | (▼789x) 19.748 µs |  ★ 0.025 µs |            — |
| repeat-view-zeros-int         |    (▼42x) 1.054 µs |  (▼2095x) 52.394 µs | (▼1249x) 31.227 µs |  (▼333x) 8.326 µs |  ★ 0.025 µs |     0.968 µs |
| parse                         |          14.795 µs |           15.055 µs |    (▼8x) 88.191 µs |       ★ 11.437 µs | ★ 10.702 µs |  ★★ 1.765 µs |
| compare                       |           0.764 µs |      (▼7x) 2.950 µs |              ERROR |    (▼3x) 1.405 µs |  ★ 0.394 µs |  ★★ 0.154 µs |
| round                         |           4.370 µs |                   — |           4.789 µs |          4.774 µs |  ★ 3.710 µs |  ★★ 0.354 µs |
| to-double                     |     (▼2x) 2.210 µs |    (▼28x) 20.927 µs |                  — |          0.823 µs |  ★ 0.740 µs |  ★★ 0.102 µs |
| to-double-wide                |              ERROR |    (▼14x) 36.432 µs |                  — |             ERROR |  ★ 2.451 µs |            — |
| to-string-as-fixed            |    (▼2x) 16.410 µs |                   — |                  — |                 — |  ★ 5.754 µs |  ★★ 2.118 µs |
| unrepresentable-divide        |  (▼25x) 133.016 µs |                   — |                  — |        ★ 5.171 µs |    8.718 µs |     7.913 µs |

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
values the two packages disagree on 33 815 of them, and on 300 sampled
disagreements checked against exact arithmetic, this package was right every
time and `decimal` never.

That row is also where the fastest answers are the wrong ones:
`big_decimal` finishes it in 0.8 µs and `decimal` in 2.6, against 2.5 here.

Where a division is exact, the gap is not about `BigInt` against `int` but about
what the algorithm can see. `divide-dirty` divides a product back by its own
factors — every step exact, nothing about the numbers saying so in advance —
and [decimal](https://pub.dev/packages/decimal) spends 352 times longer on it
than this package.

The row this package still loses is `unrepresentable-divide`:
[big_decimal](https://pub.dev/packages/big_decimal) rounds a non-terminating
quotient about 1.7 times faster. What is left of that gap is a feature rather
than an oversight. `divide` returns the exact answer whenever the division has
a finite decimal form, however many digits that takes, and finding out costs a
`gcd` — one this row always spends and never uses, because a third never comes
out even. `big_decimal.divide` rounds to the scale it is handed either way and
never asks the question, so it is answering a smaller one.

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
is what [decimal](https://pub.dev/packages/decimal) did until version 3.2.0).
Therefore, the divide-large and divide-small test, where only division is
performed, may be far from real life. This tests perform the same operation as
divide-large and divide-small, but additionally convert the result of the
operation (only the operation, not each step in this operation) into a readable
form. (And in this tests [decimal](https://pub.dev/packages/decimal) used to
lose a lot of performance before).

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

`Decimal` keeps the printed form; `ShortDecimal` does not — its constructors are
`const`, and there is nowhere to keep it. [decimal_type](https://pub.dev/packages/decimal_type),
[fixed](https://pub.dev/packages/fixed) and [big_decimal](https://pub.dev/packages/big_decimal)
keep nothing either.

Until version 1.2.0 this test was called prepared-view and measured nothing at
all: it printed one value a hundred times and the cache answered ninety-nine of
them.

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

##### compare

Comparing neighbours of the same magnitude but of different scales, so that the
comparison cannot be settled by the exponent and has to bring the two numbers to
a common scale first.

[fixed](https://pub.dev/packages/fixed) 6.2.0 shows `ERROR` here: its
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
The packages that cannot do it at all show `—`.

### [decimal](https://pub.dev/packages/decimal) vs [yet_another_decimal](https://pub.dev/packages/yet_another_decimal)

The last thing I want to do is compete with the author of
[decimal](https://pub.dev/packages/decimal), especially when I see how long
this package has been around and how well supported it is. I don't think I have
anything overtly new to offer in the usual approach to decimal. Even using
different approaches under the hood, the end result will be on the outside, not
the inside. And it's pretty much the same feature set with pretty much the same
performance.

But actually the decision to write my own
[yet_another_decimal](https://pub.dev/packages/yet_another_decimal) was not
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
import 'package:yet_another_decimal/yet_another_decimal.dart';

// only the BigInt family
import 'package:yet_another_decimal/decimal.dart';

// only the int64 family
import 'package:yet_another_decimal/short_decimal.dart';
```

Take `Decimal` when the magnitudes are not known in advance: it has no bound
and nothing overflows. Take `ShortDecimal` when they are known to be small and
the speed is the point — it is several times faster and smaller, and its
overflow is silent. The bridge between them lives only in the umbrella import,
because it is the only thing that needs both.

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
[decimal](https://pub.dev/packages/decimal), on the sets that fit into an `int`
so that both families can be shown at once:

|                           |             decimal |         Decimal |    ShortDecimal |
|:--------------------------|--------------------:|----------------:|----------------:|
| add-int                   |      (▼4x) 0.695 µs |  (▼3x) 0.483 µs |      ★ 0.150 µs |
| add-dirty-int             |      (▼4x) 0.412 µs |  (▼3x) 0.294 µs |      ★ 0.092 µs |
| multiply-large-int        |            0.124 µs |        0.123 µs |      ★ 0.064 µs |
| multiply-small-int        |            0.119 µs |        0.119 µs |      ★ 0.067 µs |
| multiply-dirty-int        |            0.046 µs |        0.045 µs |      ★ 0.026 µs |
| divide-large-int          |    (▼133x) 8.257 µs | (▼24x) 1.514 µs |      ★ 0.062 µs |
| divide-small-int          | (▼1212x) 146.752 µs | (▼23x) 2.795 µs |      ★ 0.121 µs |
| divide-dirty-int          |  (▼1476x) 39.868 µs | (▼22x) 0.620 µs |      ★ 0.027 µs |
| divide-large-and-view-int |    (▼130x) 8.509 µs | (▼23x) 1.536 µs |      ★ 0.065 µs |
| divide-small-and-view-int |  (▼455x) 147.019 µs | (▼10x) 3.367 µs |      ★ 0.323 µs |
| raw-view-int              |     (▼6x) 11.048 µs |  (▼4x) 7.480 µs |      ★ 1.694 µs |
| raw-view-zeros-int        |    (▼56x) 57.655 µs |  (▼7x) 7.449 µs |      ★ 1.023 µs |
| repeat-view-int           |    (▼299x) 6.898 µs |      ★ 0.023 µs | (▼71x) 1.637 µs |
| repeat-view-zeros-int     |     (▼42x) 1.054 µs |      ★ 0.025 µs | (▼38x) 0.968 µs |
| parse                     |     (▼8x) 14.795 µs | (▼6x) 10.702 µs |      ★ 1.765 µs |
| compare                   |      (▼4x) 0.764 µs |  (▼2x) 0.394 µs |      ★ 0.154 µs |
| round                     |     (▼12x) 4.370 µs | (▼10x) 3.710 µs |      ★ 0.354 µs |
| to-double                 |     (▼21x) 2.210 µs |  (▼7x) 0.740 µs |      ★ 0.102 µs |
| to-string-as-fixed        |     (▼7x) 16.410 µs |  (▼2x) 5.754 µs |      ★ 2.118 µs |
| unrepresentable-divide    |   (▼16x) 133.016 µs |        8.718 µs |      ★ 7.913 µs |

*For a description of the tests, see [Package performance](#package-performance).*

`Decimal` and `ShortDecimal` run the same algorithms, so the distance between
those two columns is the distance between `BigInt` and `int`: two to three
times on arithmetic, twenty-odd on division.

Two rows are about something else. In `repeat-view` `Decimal` is seventy times
ahead because it keeps the string it printed last time and `ShortDecimal` has
nowhere to keep it — its constructors are `const`. In `unrepresentable-divide`
the two are close: what the row measures is one long division, and at these
lengths `BigInt` is not much worse at it than `int`.

If your application does a handful of decimal operations, none of this matters
and `Decimal` from either package will do. If it does a great many of them, or
if memory is tight, `ShortDecimal` is several times cheaper — as long as you
keep its limitations in mind.

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
result costs nothing — the canonical form is its own.

Until 1.2.0 the same thing was done by `optimize()`, which returned nothing and
changed the receiver instead. That method still works and is deprecated: a
method that mutates what it is called on has no business in a value type.

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
