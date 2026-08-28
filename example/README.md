# Example

Two things live here: a short tour of the package, and the bench the numbers
in the [main README](../README.md) come from.

## The tour

```bash
dart run example/bin/example.dart
```

[`bin/example.dart`](bin/example.dart) walks through exact arithmetic, the four
ways of dividing by three, a bill with tax split three ways, and the fast
`int`-based family together with the bridge between the two.

## The bench

```bash
# every test, every package
dart run bin/benchmark.dart all

# one test, or everything tagged with it
dart run bin/benchmark.dart divide
dart run bin/benchmark.dart money --runs=1

# numbers worth quoting: two sweeps, the best of them per cell
dart run bin/benchmark.dart all --passes=2

# everything except one package
dart run bin/benchmark.dart -denary

# what the tags are
dart run bin/benchmark.dart --help
```

For numbers worth quoting, compile it first — the JIT and the AOT answers are
not the same:

```bash
dart compile exe example/bin/benchmark.dart
example/bin/benchmark.exe all --passes=2
```

### What it measures, and how

Seven packages are compared on the same values: this one in both of its
families,
[decimal](https://pub.dev/packages/decimal),
[fixed](https://pub.dev/packages/fixed),
[big_decimal](https://pub.dev/packages/big_decimal),
[decimal_type](https://pub.dev/packages/decimal_type),
[precise_decimal](https://pub.dev/packages/precise_decimal) and
[big_double](https://pub.dev/packages/big_double).

A few rules keep the answers honest:

- **Every result is checked.** Each benchmark knows the right answer and is
  compared against it before being timed: `OK`, `WARNING` when only trailing
  zeros differ, `ERROR` when the value itself does. An `ERROR` costs the row
  its number — the summary shows the mismatch where the time would have been.
  One package is exempt on purpose: [big_double](https://pub.dev/packages/big_double)
  is a floating-point type, so an inexact answer is its nature rather than its
  defect, and it is timed all the same. It earns no mark for it — a wrong
  answer never takes the `★★` below.
- **A package that has no such operation shows `—`**, not an error. An absent
  method is not a defect, and nothing is made to look slow for the lack of one.
- **`★` is the winner of the comparison** and everyone within 10 % of it.
  `ShortDecimal` and `big_double` stand outside that reckoning — int64 and
  floating point are not the same job as `BigInt` — and carry `★★` instead,
  which marks a package that is faster than everyone inside the comparison.
  The point of it is the absence: a row where `ShortDecimal` has no `★★` is a
  row where int64 buys nothing. A wrong answer never earns the mark.
- **A cache is not a faster algorithm, and `raw-view` does not let one
  answer.** The row is meant to be a first conversion and `repeat-view` every
  later one. A fresh object is not enough to keep the first honest: a package
  may keep its printed strings in one table for the whole library, keyed by the
  value rather than the object, and then a new object with an old value is
  answered from memory just the same.
  [precise_decimal](https://pub.dev/packages/precise_decimal) keeps such a
  table. So the `raw-view` sets are pools a hundred cycles deep, walked in
  order: every cycle converts values no cycle before it converted, and a pool
  larger than any cache in the comparison has nothing left in it by the time
  the cursor comes back around. What the pool is worth is visible in the
  numbers — with it, that package's row went from 2.7 µs to 31.4, and the two
  packages it had been beating went back to winning.
- **The whole pool is checked, not just the cycle that is timed.** The values
  a check never looks at are the ones a package could get wrong unnoticed, so
  every value in the pool is converted once outside the measurement and
  compared against `plainString` in `lib/src/tests.dart` — a reference built
  from the same `(unscaled, scale)` pair every package is handed, borrowing no
  code from any of them.

Values come in two flavours. The round ones — powers of ten, one factor
repeated — are the best case for stripping zeros, for `gcd` and for the fast
path of division. The ones tagged `dirty` have nothing round about them, which
is what money actually looks like.

### Adding a package

1. Add it to `pubspec.yaml`.
2. Add an entry to `lib/src/packages.dart`.
3. Add an adapter to `lib/src/tests/` — a subclass of `MyBenchmarkBase` that
   builds the package's values in its constructor and implements the
   operations. Operations the package does not have are simply not overridden:
   the base class reports them as unsupported.
4. Register it in `_bigIntPackages` (or `_intPackages`) in `lib/src/run.dart`.
