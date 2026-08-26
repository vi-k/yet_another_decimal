## 1.2.0

Fifteen defects closed, the gaps in the public API filled in, and the whole
package measured. Nothing is broken on the way: every item below is either a
fix or an addition.

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
- Parsing accepted hexadecimal, a lone `-`, `+0` and whitespace.
- `ShortFraction` overflowed on values that fit into int64, and lost the sign
  of `int.min`.
- `ShortDecimal` multiplication overflowed where the exact result fits.
- Assertions crashed a debug build on values a release build handled.

### Performance

Division is several times faster, printing the same value twice costs almost
nothing, and `toDouble` no longer goes through a string. The table in the
README is a fresh run of the bench in `example/`, which was rebuilt for this
release: it checks every answer before timing it, measures a series and reports
the median, and no longer reports an absent method as a failure.

## 1.1.0-1.1.2

- Update dependencies.
- Fix links in README.

## 1.0.0-1.0.2

- Initial version.
