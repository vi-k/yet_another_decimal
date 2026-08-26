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
dart run bin/benchmark.dart -yet_another_decimal

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

Six packages are compared on the same values: this one in both of its families,
[decimal](https://pub.dev/packages/decimal),
[fixed](https://pub.dev/packages/fixed),
[big_decimal](https://pub.dev/packages/big_decimal),
[decimal_type](https://pub.dev/packages/decimal_type) and
[big_double](https://pub.dev/packages/big_double).

A few rules keep the answers honest:

- **Every result is checked.** Each benchmark knows the right answer and is
  compared against it before being timed: `OK`, `WARNING` when only trailing
  zeros differ, `ERROR` when the value itself does. A wrong answer is never
  reported as a fast one.
- **A package that has no such operation shows `—`**, not an error. An absent
  method is not a defect, and nothing is made to look slow for the lack of one.
- **Every benchmark is measured five times** (`--runs=N`), and the summary
  shows the median; the console shows the whole spread next to it. One run
  says nothing: the machine drifts by up to 15 % between them.
- **For numbers worth publishing, sweep twice** (`--passes=N`): each cell then
  shows the better of the two medians. A median of five protects against one
  bad run, not against a burst of unrelated load that outlasts the whole
  series — and such a burst can only make a benchmark look slower, never
  faster. The second sweep reaches a given benchmark some twenty minutes after
  the first, which is what makes the two independent. They disagreed on 15
  cells out of 190 the last time the README table was measured.
- **The result of every measured cycle goes into a sink**, so that the
  optimizer cannot drop the work the cycle was there to do.
- **What the run depends on is printed above it**: the Dart version, the OS,
  the number of cores, JIT or AOT, and the version of every compared package.

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
