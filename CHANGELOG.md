## 1.2.0

**The package is now called `denary`.** It was published as
`yet_another_decimal` up to 1.1.2; that name is discontinued and points here.
Nothing inside changed with it: the types are still `Decimal` and
`ShortDecimal`, and only the import lines move.

```dart
import 'package:denary/denary.dart';        // was yet_another_decimal.dart
import 'package:denary/decimal.dart';
import 'package:denary/short_decimal.dart';
```

Beside the name: fifteen defects closed, the gaps in the public API filled in,
and the whole package measured. Almost all of it is a fix or an addition; the
handful of places where working code can notice the difference are gathered
under Changed.

### Compatibility

- The SDK floor comes down from `^3.9.0` to `^3.6.0`, and `meta` from
  `^1.17.0` to `^1.15.0`. Flutter takes `meta` out of its own SDK at an exact
  version — 1.15.0 on Flutter 3.27, 1.16.0 on 3.29 — so the old constraint put
  the real Flutter floor at 3.35 whatever the SDK range said. The package now
  resolves on Flutter 3.27 and later. Nothing in it needed a language feature
  newer than 3.6; the whole test suite runs on Dart 3.6.0.

### Added

- Total division. `divideOrNull` returns null where the result has no finite
  decimal form, `divide(other, scaleOnInfinitePrecision: n)` rounds to `n`
  digits, and `isDivisibleBy` asks the question in advance. `operator /` still
  throws and stays the fast form for the case where the division is known to be
  exact.
- Exponential notation in `parse` and `tryParse`: `Decimal.parse('1.5e21')`.
- `toStringAsExponential` and `toStringAsPrecision` in both families. They used
  to throw `UnimplementedError` in `Decimal` and were absent from
  `ShortDecimal`.
- A bridge between the families: `ShortDecimal.toDecimal()` and
  `Decimal.toShortDecimalOrNull()`.
- The members only one of the two families had: `toJson` and `fromJson`,
  `Decimal.toInt`, `ShortDecimal.toBigInt`, `precision`, `isPositive`,
  `inverse`, `pow` with a negative exponent, `ShortFraction.toShortDecimal`,
  and `compareTo`, `abs`, `inverse` and `toDouble` on both fraction types.
- `normalized()`, which answers with the value in its canonical form. It
  replaces `optimize()`, which returned nothing and changed the receiver
  instead and is gone from this package (see Removed).
- `unscaledValue` and `exponent`: the number taken apart. Both read the
  canonical form, so equal decimals answer equally whatever produced them.
- `movePointLeft` and `movePointRight` — the same thing as `>>` and `<<`,
  spelled out. `>>` moves the point left, which is easy to read the wrong way
  round.
- Two narrow entry points beside the umbrella one: `package:denary/decimal.dart`
  and `package:denary/short_decimal.dart`. Whoever needs one family no longer
  carries the other.
- `ShortDecimal` is annotated `vm:deeply-immutable`: the VM may share its
  instances between isolates. `Decimal` cannot be — a `BigInt` field is
  rejected by that annotation.

### Removed

Both members below existed in `yet_another_decimal` and are not carried over.
Nothing in `denary` ever exposed them, and moving to `denary` is a hand edit of
`pubspec.yaml` and of every import line anyway — there is no better moment to
leave a deprecation behind than the one where the code is already being
touched.

- The `toDecimal()` extensions on `int` and `BigInt`. Package `decimal` carries
  the same two, and while both exist a plain `5.toDecimal()` is ambiguous —
  including the call meant for the other package. Use `Decimal(value)` and
  `Decimal.fromBigInt(value)`. The two packages now coexist: what is left to
  sort out is the type name `Decimal`, which both of them use, and a `hide` or
  a `show` settles that the way it does for any two packages.
- `optimize()`, which packed the receiver in place and returned nothing. Use
  `normalized()`, which answers with the value instead.

### Changed

- Dividing by zero throws `UnsupportedError` everywhere. `~/`, `%` and
  `remainder` used to throw `IntegerDivisionByZeroException` while `/` threw
  `UnsupportedError`: one mistake, two types. The SDK marks the first
  deprecated, and it implements the second, so code catching `UnsupportedError`
  sees no change.
- `parse` and `tryParse` no longer read hexadecimal, a lone `-` or `+0` —
  neither for the two number types nor for the two fraction types, where
  `Fraction.parse('0x10')` used to be sixteen. Whitespace around a number is
  still read, as it always was.
- A negative shift in a constructor throws `ArgumentError` instead of tripping
  an assertion. `Decimal(1, shiftRight: -3)` used to crash a debug build and
  quietly answer `1000` in a release one, and `ShortDecimal` had three such
  assertions, one of them for `shiftLeft` and `shiftRight` given together. A
  shift is an argument, and an argument is checked in every build.

### Fixed

- `divideToFraction` truncated a ratio that has no fraction in int64 instead of
  refusing it, and `divide` rounded the truncated pair — a wrong answer with
  nothing to give it away.
- `ShortFraction.floor` and `ceil` lost their direction when the result needed
  more digits than int64 holds: both answered with the closest value, so a
  floor could come back above its own fraction. They now drop digits the way
  they were asked to.
- `ShortFraction.toDouble` rounded twice past 2^53 and missed the nearest
  double. It now takes the exact path, as `Fraction` does.
- Division let the scale overflow where the shifts refuse it. A quotient whose
  scale wrapped printed as an integer and compared as one; now it throws with
  the name of the argument, in both families.
- Division by a negative number gave the wrong sign.
- Division by zero hung instead of throwing.
- Comparison, sorting, rounding and `toInt` broke on values whose scales were
  more than eighteen apart, and answered differently on the VM and on the web.
- `toBigInt` lost the magnitude of a scaled value.
- `toStringAsFixed` did not pad the result out to the number of digits asked
  for.
- `divideToDouble` returned `NaN` where the ratio did not fit a `BigInt`
  division.
- `ShortDecimal.ten` was stored in a non-canonical form, so its `hashCode`
  disagreed with an equal value built another way.
- `Fraction` rejected a negative number of fraction digits, which `Decimal`
  accepted.
- `ShortFraction` overflowed on values that fit into int64, and lost the sign
  of `int.min`.
- `ShortDecimal` multiplication overflowed where the exact result fits.
- Assertions crashed a debug build on values a release build handled.
- `normalized()` did not recognise its own answer as canonical, so calling it
  on the result packed and allocated all over again.
- `ShortDecimal.inverse` wrapped around past ten to the eighteenth and answered
  a positive number with a negative one. Where the fraction has no int64 to
  live in it throws now.
- The scale wrapped around silently: `Decimal.parse('0.01').pow(int.max)`
  printed `100`. `pow`, `<<`, `>>` and both `movePoint` methods refuse such a
  shift now, in both families.
- A power of ten past ten to the millionth is refused rather than attempted.
  `Decimal.one.round(-1000000000)` went looking for ten to the billionth and
  took the memory of the process with it; the same held for `floor`, `ceil`,
  `truncate`, `divide`, the three `toStringAs…` methods and both fraction
  types. The bound is the one `parse` has always had, so no number this package
  can read in needs more, and it is checked both where the request comes in and
  where the power would be built — so a scale shifted that far is caught as
  well.
- `DecimalDivideException.forTest` and its twin accepted a zero divisor, and
  everything about the exception it built — `toString` included — threw.
- `ShortDecimal.divide(other, scaleOnInfinitePrecision: n)` threw
  `ArgumentError` when the divisor was `int.min`. The ratio has no fraction in
  int64 — a denominator of 2^63 cannot be positive there — but the rounded
  quotient it was asked for is an ordinary number, and it is answered now.

### Performance

Addition and subtraction are a tenth faster on `Decimal`, and a fifth where the
two scales already match: the alignment is written out in the operators instead
of being taken from a helper that returned a record, and the record was an
allocation on the shortest operation in the package. Division is several times
faster, printing the same value twice costs almost nothing, `toDouble` no longer goes through a string, and rounding a quotient
that has no finite decimal form — `divide(other, scaleOnInfinitePrecision: n)`
— is about 1.6 times faster than it was, having stopped building an exact
fraction only to divide it again, and then twice as fast again: where the
divisor is coprime with ten, which is every division by three, the remainder of
the rounding answers by itself whether there was a finite form to return
instead, and the division that used to ask separately was half the cost of the
operation. `divideOrNull` and `isDivisibleBy` are about 1.8 times faster on
such a divisor for the same reason — a gcd that could not change the answer is
no longer spent. `ShortDecimal.divide` with a digit count is twenty times
faster: it folds both scales and the digits asked for into one power of ten
instead of aligning the pair into a fraction and scaling that, which used to
carry the arithmetic out of int64 and into `BigInt` on values that fit int64
comfortably. The table in the
README is a fresh run of the bench in `example/`, which was rebuilt for this
release: it checks every answer before timing it, measures a series and reports
the median, and no longer reports an absent method as a failure.

## 1.1.0-1.1.2

- Update dependencies.
- Fix links in README.

## 1.0.0-1.0.2

- Initial version.
