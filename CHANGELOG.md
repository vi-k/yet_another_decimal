## 1.2.0

Fifteen defects closed, the gaps in the public API filled in, and the whole
package measured. Almost all of it is a fix or an addition; the handful of
places where working code can notice the difference are gathered under
Changed.

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
  instead.
- `unscaledValue` and `exponent`: the number taken apart. Both read the
  canonical form, so equal decimals answer equally whatever produced them.
- `movePointLeft` and `movePointRight` — the same thing as `>>` and `<<`,
  spelled out. `>>` moves the point left, which is easy to read the wrong way
  round.
- Two narrow entry points beside the umbrella one:
  `package:yet_another_decimal/decimal.dart` and
  `package:yet_another_decimal/short_decimal.dart`. Whoever needs one family
  no longer carries the other.
- `ShortDecimal` is annotated `vm:deeply-immutable`: the VM may share its
  instances between isolates. `Decimal` cannot be — a `BigInt` field is
  rejected by that annotation.

### Deprecated

- `optimize()`. Use `normalized()`.
- The `toDecimal()` extensions on `int` and `BigInt`. Package `decimal` carries
  the same two, and the two packages cannot be resolved together while they
  exist. Use `Decimal(value)` and `Decimal.fromBigInt(value)`.

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
- `ShortDecimal.divide(other, scaleOnInfinitePrecision: n)` threw
  `ArgumentError` when the divisor was `int.min`. The ratio has no fraction in
  int64 — a denominator of 2^63 cannot be positive there — but the rounded
  quotient it was asked for is an ordinary number, and it is answered now.

### Performance

Division is several times faster, printing the same value twice costs almost
nothing, `toDouble` no longer goes through a string, and rounding a quotient
that has no finite decimal form — `divide(other, scaleOnInfinitePrecision: n)`
— is about 1.6 times faster than it was, having stopped building an exact
fraction only to divide it again. The table in the
README is a fresh run of the bench in `example/`, which was rebuilt for this
release: it checks every answer before timing it, measures a series and reports
the median, and no longer reports an absent method as a failure.

## 1.1.0-1.1.2

- Update dependencies.
- Fix links in README.

## 1.0.0-1.0.2

- Initial version.
