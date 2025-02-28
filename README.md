# Decimals

It's yet another package for fixed point decimals.

## Table of contents

1. [Why?](#why)

    1.1. [What packages are already in place?](#packages)

    1.2. [What's it supposed to be?](#expectations)

    1.3. [Package performance](#package-performance)

    1.4. [decimal vs decimal2](#decimal-vs-decimal2)

2. [`Decimal` vs `ShortDecimal`](#decimal-vs-short-decimal)

    2.1. [`ShortDecimal` limitations](#short-decimal-limitations)

    2.2. [Performance](#short-decimal-performance)

    2.3. [`Decimal` optimization](#decimal-optimization)

<a id="why"></a>
## Why?

As of February 2025, there are several packages on [pub.dev](https://pub.dev)
that work with decimals.

<a id="packages"></a>
### What packages are already in place?

#### [decimal](https://pub.dev/packages/decimal)

A wonderful package that works correctly with decimals. It exists since 2014
and is constantly updated. In one of the latest updates (3.2.0), performance
has been significantly improved. Before that, speed was the weak point of this
package. This was one of the reasons why decimal2 appeared, since I started
writing it before 3.2.0. However, I would have written it anyway. More about it
below.

#### [fixed](https://pub.dev/packages/fixed)

The package has difficulty dividing. You can't just do a 1 / 8 operation and
get the expected 0.125:

```dart
final a = Fixed.fromInt(1, scale: 0); // 1
final b = Fixed.fromInt(8, scale: 0); // 8
print('$a / $b = ${a / b}'); // 1 / 8 = 0

final c = Fixed.fromInt(10, scale: 1); // 1.0
final d = Fixed.fromInt(80, scale: 1); // 8.0
print('$c / $d = ${c / d}'); // 1.0 / 8.0 = 0.1

final e = Fixed.fromInt(100, scale: 2); // 1.00
final f = Fixed.fromInt(800, scale: 2); // 8.00
print('$e / $f = ${e / f}'); // 1.00 / 8.00 = 0.13
```

The result depends on the scale of the numerator and denominator. That is, the
division method does not calculate the scale of the result. You have to do it
yourself.

```dart
final a = Fixed.fromInt(1, scale: 0).copyWith(scale: 3); // 1.000
final b = Fixed.fromInt(8, scale: 0); // 8
print('$a / $b = ${a / b}'); // 1.000 / 8 = 0.125
```

But the main drawback of the package is not even that, but the fact that
`double` is used for the division operation under the hood:

```dart
final a = Fixed.parse('111111111111111111');
final b = a * a;
print(b); // 12345679012345678987654320987654321
print(b / a); // 111111111111111120 (!)
```

The reason for the error is that double has limited precision, and in this
example we have gone beyond the limits of that precision. But fixed point
decimals are used to avoid errors in floating-point operations, not the other
way around. In my opinion, this is a very bad solution.

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


<a id="expectations"></a>
### What's it supposed to be?

Three packages out of four did not satisfy me because of bugs in calculations,
incomplete functionality (division) or use of `double` under the hood.

The [decimal](https://pub.dev/packages/decimal) and decimal2 does not have
the above division problems. No need to calculate `scale` yourself, and no
`double` under the hood.

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

decimal2 does the opposite and returns the result immediately:

```dart
final a = Decimal.one;
final b = Decimal(256);
print('$a / $b = ${a / b}'); // 1 / 256 = 0.00390625
```

I wanted a package that works with decimal to return the result as decimal by
default. I'm counting on the fact that whoever is using the division operation
knows what they are doing, and understands in which cases they can get decimal
when dividing, and in which cases they will go beyond the capabilities of
decimal.

If the result cannot be obtained as a decimal, an exception will be thrown. It
can be caught and handled to get the desired result:

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

decimal2 has its own `Fraction` class, which provides basic functions for
working with fraction.

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

<a id="package-performance"></a>
### Package performance

I care about performance, so I wrote tests to check packages. When I did this,
I was not yet aware of the bugs I wrote above. So the result might seem
strange. It's as if there were only two packages to compare: this and
[decimal](https://pub.dev/packages/decimal).

The tests were performed on Apple M2 Pro 32 Gb. The code of the tests was
written with the help of [benchmark_harness](https://pub.dev/packages/benchmark_harness).
Each test was run for at least 2 sec, during which time the test exercise was
executed until the end time was reached. Each exercise has 100 cycles of
performing an operation. A single operation performs a series of identical
actions on multiple values. In the table you see the average time to complete
one operation in microseconds. Asterisks indicate the best results and close to
them (up to 10% difference).

Absolute values are not important because they will differ from computer to
computer, from startup to startup. All that matters is comparing the tests with
each other.

Running Tests:

```
dart compile exe example/bin/benchmark.dart && example/bin/benchmark.exe
```

|                       |           decimal |     decimal_type |            fixed |      big_decimal | decimal2-decimal |
|:----------------------|------------------:|-----------------:|-----------------:|-----------------:|-----------------:|
| add                   |          1.863 µs |         3.340 µs |         2.386 µs |         2.276 µs |       ★ 1.694 µs |
| multiply-large        |        ★ 0.135 µs |       ★ 0.131 µs |         0.175 µs |       ★ 0.132 µs |       ★ 0.129 µs |
| multiply-small        |        ★ 0.138 µs |       ★ 0.129 µs |            ERROR |       ★ 0.132 µs |       ★ 0.129 µs |
| divide-large          |    (▼4x) 7.916 µs |            ERROR |            ERROR |       ★ 1.650 µs |         2.025 µs |
| divide-small          | (▼38x) 496.494 µs |            ERROR |            ERROR |            ERROR |      ★ 12.969 µs |
| divide-large-and-view |    (▼4x) 8.479 µs |            ERROR |            ERROR |       ★ 1.840 µs |         2.128 µs |
| divide-small-and-view | (▼35x) 511.241 µs |            ERROR |            ERROR |            ERROR |      ★ 14.372 µs |
| raw-view              |         21.045 µs |        26.058 µs |  (▼3x) 61.210 µs |      ★ 18.167 µs |      ★ 17.337 µs |
| raw-view-zeros        |   (▼5x) 83.212 µs |  (▼4x) 73.963 µs |  (▼4x) 70.724 µs |      ★ 16.521 µs |      ★ 15.681 µs |
| prepared-view         |       ★ 16.845 µs |        25.988 µs |  (▼3x) 59.159 µs |      ★ 17.779 µs |      ★ 16.689 µs |
| prepared-view-zeros   |        ★ 1.567 µs | (▼46x) 72.737 µs | (▼44x) 69.415 µs | (▼10x) 16.105 µs |       ★ 1.635 µs |

With this test I did not intend to advertise my package at all. It was only
important for me to check myself whether I was doing everything right. I saw my
mistakes, and I corrected them. That's why this test is not very fair: I didn't
adapt the test to my package, but I “adapted” (i.e. optimized) my package to
this test. And I did it with the code of the packages I've given here. Even if
some of them didn't work for me or contain bugs, there are some very good
solutions in them that I was inspired by.

#### Description of benchmarks

- add. Adding numbers:

  10000000000000000000 + 1000000000000000000 + 100000000000000000 + 10000000000000000 + 1000000000000000 + 100000000000000 + 10000000000000 + 1000000000000 + 100000000000 + 10000000000 + 1000000000 + 100000000 + 10000000 + 1000000 + 100000 + 10000 + 1000 + 100 + 10 + 1 + 0.1 + 0.01 + 0.001 + 0.0001 + 0.00001 + 0.000001 + 0.0000001 + 0.00000001 + 0.000000001 + 0.0000000001 + 0.00000000001 + 0.000000000001 + 0.0000000000001 + 0.00000000000001 + 0.000000000000001 + 0.0000000000000001 + 0.00000000000000001 + 0.000000000000000001 + 0.0000000000000000001 + 0.00000000000000000001 = 11111111111111111111.11111111111111111111

  A very simple operation. But note that in the case of decimal, it is much
  more complicated than multiplication.

- multiply-large. Multiplication of large numbers:

  123456789 * 123456789 * 123456789 * 123456789 * 123456789 * 123456789 * 123456789 * 123456789 * 123456789 * 123456789 = 822526259147102579504761143661535547764137892295514168093701699676416207799736601

  A simple operation for decimal. It is impossible to make a mistake in it.
  There is no simpler operation.

- multiply-small. Multiplication of small numbers:

  0.0123456789 * 0.0123456789 * 0.0123456789 * 0.0123456789 * 0.0123456789 * 0.0123456789 * 0.0123456789 * 0.0123456789 * 0.0123456789 * 0.0123456789 = 0.0000000000000000000822526259147102579504761143661535547764137892295514168093701699676416207799736601

  A simple operation, but not all packages are ready to handle numbers that
  have more than 20 decimal places.

- divide-large. Division of large numbers:

  822526259147102579504761143661535547764137892295514168093701699676416207799736601 / 123456789 / 123456789 / 123456789 / 123456789 / 123456789 / 123456789 / 123456789 / 123456789 / 123456789 / 123456789 = 1

  Division is not the strongest point of most packages. Even integers! Even the
  result of which is also an integer!

- divide-small. Division of small numbers:

  1 / 256 / 256 / 256 / 256 / 256 / 256 / 256 / 256 / 256 = 0.000000000000000000000211758236813575084767080625169910490512847900390625

  It's a difficult task. It's easy to stumble over.
  [decimal](https://pub.dev/packages/decimal) solves it, but at what cost! Some
  packages use the `double` trick and stumble over it. And some don't even try.

- divide-large-and-view and divide-small-and-view. Division of numbers and
  converting the result in a readable format:

  Packages can use intermediate results in their work, which speed up the speed
  of operations, but do not have a decimal form understandable to the user.
  (This is what [decimal](https://pub.dev/packages/decimal) did until version
  3.2.0). Therefore, the divide-large and divide-small test, where only
  division is performed, may be far from real life. This tests perform the
  same operation as divide-large and divide-small, but additionally convert the
  result of the operation (only the operation, not each step in this operation)
  into a readable form. (And in this tests [decimal](https://pub.dev/packages/decimal)
  used to lose a lot of performance before).

  I'll be honest, it took me a long time to find a solution that satisfied me
  in terms of performance.

- raw-view. Convert newly created numbers into a readable format:

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

  This is usually a resource-intensive task, as the package does not have time
  to do any optimizations with the number.

- raw-view-zeros. Convert newly created numbers with lots of leading and
  trailing zeros into a readable format:

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

  Converting such numbers is technically quite different from converting
  numbers without zeros in raw-view. Each of the tests (raw-view and
  raw-vew-zeros) separately can give a wrong idea of performance, so they
  should be considered only together.

- prepared-view. Conversion of prepared numbers (if the package supports it)
  into a readable format:

  Packages may use optimization mechanisms in their work (for example, saving
  previously calculated values). The raw-view test does not allow you to
  evaluate the fruits of this optimization. This test gives such an opportunity
  by performing the same operation as raw-view, but adding optimization.
  Compare the results of both tests.

  Packages [decimal_type](https://pub.dev/packages/decimal_type),
  [fixed](https://pub.dev/packages/fixed), [big_decimal](https://pub.dev/packages/big_decimal)
  do without optimization.

- prepared-view-zeros. Conversion of prepared numbers (if the package supports
  it) with a large number of initial or final zeros into a readable format:

  See description of previous tests.

In early January 2025, the column with the [decimal](https://pub.dev/packages/decimal)
looked quite different. The values were two orders of magnitude higher.
We can only be happy for such improvements.

<a id="decimal-vs-decimal2"></a>
### [decimal](https://pub.dev/packages/decimal) vs decimal2

The last thing I want to do is compete with the author of
[decimal](https://pub.dev/packages/decimal), especially when I see how long
this package has been around and how well supported it is. I don't think I have
anything overtly new to offer in the usual approach to вecimal. Even using
different approaches under the hood, the end result will be on the outside, not
the inside. And it's pretty much the same feature set with pretty much the same
performance.

But actually the decision to write my own decimal2 was not only influenced by
the poor (at the time) performance of [decimal](https://pub.dev/packages/decimal).
There was another reason. For my task I needed a lightweight decimal, which
needed a regular `int` instead of `BigInt` to store values under the hood. My
values fit even in int32. These are the results of training: geoposition,
distance, altitude gain, pace, heart rate, cadence, power. As an old generation
programmer, it's morally hard for me to waste resources in places where
where it's not necessary. Especially I expect a large amount of data and
calculations with them. And I was surprised to find no ready-made solution on
[pub.dev](https://pub.dev).

So, `Decimal` was not originally the main purpose of the package. The main goal
was `ShortDecimal`. `Decimal` was just a natural evolution of the package.

<a id="decimal-vs-short-decimal"></a>
## `Decimal` vs `ShortDecimal`

<a id="short-decimal-limitations"></a>
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
// -                   100000000000000000000000
// = 922337203685477580600000000000000000000000
print(b - (ShortDecimal(1) << 23)); // 922337203685477580600000000000000000000000 <- ok

//   922337203685477580700000000000000000000000
// -                                          1
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
final d1 = Decimal.parse('1.2');
final d2 = Decimal.parse('5');
print(d1.debugToString()); // Decimal(base: 12, scale: 1)
print(d2.debugToString()); // Decimal(base: 5, scale: 0)

final sd1 = ShortDecimal.parse('1.2');
final sd2 = ShortDecimal.parse('5');
print(sd1.debugToString()); // ShortDecimal(base: 12, scale: 1)
print(sd2.debugToString()); // ShortDecimal(base: 5, scale: 0)
```

Multiplication of such numbers is quite a simple operation: the bases are
multiplied and the scales are added. The result will be: (base: 60, scale: 1).
This is 6. And `Decimal` doesn't need to reduce it to (base: 6, scale: 0). But
for `ShortDecimal` it is vital.

```dart
final d3 = d1 * d2;
print(d3); // 6
print(d3.debugToString()); // Decimal(base: 60, scale: 1)

final sd3 = sd1 * sd2;
print(sd3); // 6
print(sd3.debugToString()); // ShortDecimal(base: 6, scale: 0)
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
print(a.debugToString()); // Decimal(base: 10000000000000000000, scale: 19)
print(a); // 1

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
print(a.debugToString()); // ShortDecimal(base: 1, scale: 0)
print(a); // 1
```

<a id="short-decimal-performance"></a>
### Performance

|                       |     package decimal |         Decimal | ShortDecimal |
|:----------------------|--------------------:|----------------:|-------------:|
| add                   |      (▼4x) 0.713 µs |  (▼4x) 0.646 µs |   ★ 0.155 µs |
| multiply-large        |      (▼4x) 0.121 µs |  (▼3x) 0.115 µs |   ★ 0.030 µs |
| multiply-small        |      (▼4x) 0.120 µs |  (▼3x) 0.114 µs |   ★ 0.030 µs |
| divide-large          |    (▼103x) 6.455 µs | (▼26x) 1.683 µs |   ★ 0.063 µs |
| divide-small          | (▼1196x) 114.617 µs | (▼71x) 6.834 µs |   ★ 0.096 µs |
| divide-large-and-view |    (▼103x) 6.664 µs | (▼26x) 1.686 µs |   ★ 0.065 µs |
| divide-small-and-view |  (▼339x) 116.035 µs | (▼21x) 7.376 µs |   ★ 0.342 µs |
| raw-view              |     (▼4x) 10.474 µs |  (▼3x) 6.882 µs |   ★ 2.137 µs |
| raw-view-zeros        |    (▼30x) 37.261 µs |  (▼5x) 6.966 µs |   ★ 1.232 µs |
| prepared-view         |      (▼3x) 6.354 µs |  (▼3x) 6.640 µs |   ★ 2.082 µs |
| prepared-view-zeros   |          ★ 1.274 µs |        1.339 µs |   ★ 1.186 µs |

For a description of the tests, see [Package performance](#package-performance).

The `Decimal` and `ShortDecimal` use the same algorithms. The difference in
performance is the difference between `BigInt` and `int`.

Chances are, you will rarely use the division operation in your application.
You probably won't have a large number of decimal calculations either. In this
case, the difference 3-5x can be neglected. The use of `Decimal` in both
packages will most likely not lead to significant performance losses in the
whole application. That's why you can choose `Decimal` in
[decimal](https://pub.dev/packages/decimal) as well as `Decimal` in decimal2.

But if you need both performance and maximum memory saving, choose
`ShortDecimal`, but do not forget about its limitations.

<a id="decimal-optimization"></a>
### `Decimal` optimization

When it is necessary to return to the user the properties of a number,
understandable to human perception, for example, the number of significant
digits after the decimal point, it is impossible to do without packing the
number. And having a packed number, you can do some operations, for example,
converting a number into a string, much faster. This packing of a number is
what optimization consists in, due to which some tests are executed much faster
and some, on the contrary, much slower, when optimization costs do not pay off
in time.

In `Decimal` I tried to find a balance: pack a number only where it is needed,
and use it only if it is there, and do without it if it is not. But I added
an `optimize` method that will allow you to manually pack a number to optimize
performance when the algorithm doesn't do it itself. This method can be called
safely many times. In reality, it will only pack the value once.

The `optimize` method is clearly refers to internal implementation, not
business logic. And I don't really like its presence, but I haven't found
a better solution, since I couldn't decide for the user in which case it's
better to use number packing and in which case it's better to avoid it. All I
could do to keep the implementation from sticking out so obviously was to call
the method `optimize` rather than `pack` or `rescale`. The user doesn't need to
know about packing and scaling a value, nor does the user need to know about
`base` and `scale` at all.

In the following example, the optimization significantly speeds up the
conversion of a number to a string:

```dart
final v = Decimal(1000000000000000000) >> 18; // = 1

final sw = Stopwatch()..start();
for (var i = 0; i < 10000000; i++) {
  v.toString(); // "1"
}
sw.stop();
print(sw.elapsed); // 0:00:02.445964

v.optimize();

sw
  ..reset()
  ..start();
for (var i = 0; i < 10000000; i++) {
  v.toString(); // "1"
}
sw.stop();
print(sw.elapsed); // 0:00:00.048106
```

But if we get new numbers each time, and we do optimization along with each
conversion to a string, we will lose performance. Whereas the absence of
unjustified optimization would save resources. That's why I didn't make it
mandatory inside `toString`.

```dart
var v = Decimal(1000000000000000000) >> 18; // = 1

final sw = Stopwatch()..start();
for (var i = 0; i < 10000000; i++) {
  // Simulate the situation when new numbers arrive.
  v = -v;
  v.toString(); // "1" or "-1"
}
sw.stop();
print(sw.elapsed); // 0:00:02.568405

sw
  ..reset()
  ..start();
for (var i = 0; i < 10000000; i++) {
  v = -v; // "1" or "-1"
  // If we only need to output numbers once and will not use them anywhere
  // else, this optimization is unnecessary. Optimization will still be
  // optimization, but we will pay too much for it.
  v.optimize();
  v.toString(); // 0:00:15.578125
}
sw.stop();
print(sw.elapsed);
```

`ShortDecimal` does not need to optimize since it optimizes the value in each
operation.
