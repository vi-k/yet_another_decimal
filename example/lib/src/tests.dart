// ignore_for_file: lines_longer_than_80_chars, avoid_js_rounded_ints

import 'operations.dart';

/// How many cycles' worth of values a pooled view benchmark holds.
///
/// `raw-view` is meant to be a first conversion, so it may not convert a value
/// a package could still remember. A pool this many times larger than one
/// cycle, walked in order, is larger than any cache in the comparison: by the
/// time the cursor comes back around the entry has been evicted, and a table
/// keyed by the value misses as surely as one keyed by the object.
const int viewPoolCycles = 103;

/// Writes a value out from its digits and its scale, and nothing else.
///
/// The reference the view benchmarks are checked against. It is built from the
/// same `(unscaled, scale)` pair every package is handed and borrows no code
/// from any of them — the answers must not be able to agree with a package by
/// sharing its mistake.
///
/// Trailing zeros after the point are dropped, which is the canonical form.
/// A package that prints them keeps its result: the runner compares without
/// them too and calls that a warning, not an error.
String plainString(BigInt unscaled, int scale) {
  if (scale <= 0) {
    return (unscaled * BigInt.from(10).pow(-scale)).toString();
  }

  final digits = unscaled.toString();
  final String result;
  if (digits.length > scale) {
    result = '${digits.substring(0, digits.length - scale)}'
        '.${digits.substring(digits.length - scale)}';
  } else {
    result = '0.${'0' * (scale - digits.length)}$digits';
  }

  if (!result.contains('.')) {
    return result;
  }

  var end = result.length;
  while (result[end - 1] == '0') {
    end--;
  }
  if (result[end - 1] == '.') {
    end--;
  }

  return result.substring(0, end);
}

enum Test {
  addBigInt(
    'add-big-int',
    Op.add,
    'Add numbers (BigInt version).',
    {'big-int', 'add'},
  ),
  addInt(
    'add-int',
    Op.add,
    'Add numbers (int version).',
    {'int', 'add'},
  ),
  addDirtyBigInt(
    'add-dirty-big-int',
    Op.add,
    'Add numbers with nothing round about them (BigInt version).',
    {'big-int', 'add', 'dirty'},
  ),
  addDirtyInt(
    'add-dirty-int',
    Op.add,
    'Add numbers with nothing round about them (int version).',
    {'int', 'add', 'dirty'},
  ),
  multiplyLargeBigInt(
    'multiply-large-big-int',
    Op.multiply,
    'Multiply large numbers (BigInt version).',
    {'big-int', 'multiply', 'multiply-large'},
  ),
  multiplyLargeInt(
    'multiply-large-int',
    Op.multiply,
    'Multiply large numbers (int version).',
    {'int', 'multiply', 'multiply-large'},
  ),
  multiplySmallBigInt(
    'multiply-small-big-int',
    Op.multiply,
    'Multiply small numbers (BigInt version).',
    {'big-int', 'multiply', 'multiply-small'},
  ),
  multiplySmallInt(
    'multiply-small-int',
    Op.multiply,
    'Multiply small numbers (int version).',
    {'int', 'multiply', 'multiply-small'},
  ),
  multiplyDirtyBigInt(
    'multiply-dirty-big-int',
    Op.multiply,
    'Multiply numbers with nothing round about them: no factor of the'
        '\nresult cancels against another (BigInt version).',
    {'big-int', 'multiply', 'dirty'},
  ),
  multiplyDirtyInt(
    'multiply-dirty-int',
    Op.multiply,
    'Multiply numbers with nothing round about them: no factor of the'
        '\nresult cancels against another (int version).',
    {'int', 'multiply', 'dirty'},
  ),
  divideLargeBigInt(
    'divide-large-big-int',
    Op.divide,
    'Divide large numbers (BigInt version).',
    {'big-int', 'divide', 'divide-large'},
  ),
  divideLargeInt(
    'divide-large-int',
    Op.divide,
    'Divide large numbers (int version).',
    {'int', 'divide', 'divide-large'},
  ),
  divideSmallBigInt(
    'divide-small-big-int',
    Op.divide,
    'Divide small numbers (BigInt version).',
    {'big-int', 'divide', 'divide-small'},
  ),
  divideSmallInt(
    'divide-small-int',
    Op.divide,
    'Divide small numbers (int version).',
    {'int', 'divide', 'divide-small'},
  ),
  divideDirtyBigInt(
    'divide-dirty-big-int',
    Op.divide,
    'Divide a product back by its factors, none of them round:'
        '\nthe division is exact, but only `gcd` can see it (BigInt version).',
    {'big-int', 'divide', 'dirty'},
  ),
  divideDirtyInt(
    'divide-dirty-int',
    Op.divide,
    'Divide a product back by its factors, none of them round:'
        '\nthe division is exact, but only `gcd` can see it (int version).',
    {'int', 'divide', 'dirty'},
  ),
  divideLargeAndViewBigInt(
    'divide-large-and-view-big-int',
    Op.divideAndView,
    'Divide large numbers and convert the result'
        '\nto a readable format  (BigInt version).',
    {'big-int', 'divide-and-view', 'divide-and-view-large'},
  ),
  divideLargeAndViewInt(
    'divide-large-and-view-int',
    Op.divideAndView,
    'Divide large numbers and convert the result'
        '\nto a readable format (int version).',
    {'int', 'divide-and-view', 'divide-and-view-large'},
  ),
  divideSmallAndViewBigInt(
    'divide-small-and-view-big-int',
    Op.divideAndView,
    'Divide small numbers and convert the result'
        '\nto a readable format (BigInt version).',
    {'big-int', 'divide-and-view', 'divide-and-view-small'},
  ),
  divideSmallAndViewInt(
    'divide-small-and-view-int',
    Op.divideAndView,
    'Divide small numbers and convert the result'
        '\nto a readable format (int version).',
    {'int', 'divide-and-view', 'divide-and-view-small'},
  ),
  rawViewBigInt(
    'raw-view-big-int',
    Op.rawView,
    'Convert newly created numbers to a readable format (BigInt version).',
    {'big-int', 'raw-view'},
  ),
  rawViewInt(
    'raw-view-int',
    Op.rawView,
    'Convert newly created numbers to a readable format (int version).',
    {'int', 'raw-view'},
  ),
  rawViewZerosBigInt(
    'raw-view-zeros-big-int',
    Op.rawView,
    'Convert newly created numbers with lots of leading and trailing zeros'
        '\n to a readable format (BigInt version).',
    {'big-int', 'raw-view', 'raw-view-zeros'},
  ),
  rawViewZerosInt(
    'raw-view-zeros-int',
    Op.rawView,
    'Convert newly created numbers with lots of leading and trailing zeros'
        '\n to a readable format (int version).',
    {'int', 'raw-view', 'raw-view-zeros'},
  ),
  repeatViewBigInt(
    'repeat-view-big-int',
    Op.repeatView,
    'Convert numbers that have already been converted once'
        '\nto a readable format (BigInt version).',
    {'big-int', 'repeat-view'},
  ),
  repeatViewInt(
    'repeat-view-int',
    Op.repeatView,
    'Convert numbers that have already been converted once'
        '\nto a readable format (int version).',
    {'int', 'repeat-view'},
  ),
  repeatViewZerosBigInt(
    'repeat-view-zeros-big-int',
    Op.repeatView,
    'Convert numbers with lots of leading and trailing zeros that have'
        '\nalready been converted once to a readable format (BigInt version).',
    {'big-int', 'repeat-view', 'repeat-view-zeros'},
  ),
  repeatViewZerosInt(
    'repeat-view-zeros-int',
    Op.repeatView,
    'Convert numbers with lots of leading and trailing zeros that have'
        '\nalready been converted once to a readable format (int version).',
    {'int', 'repeat-view', 'repeat-view-zeros'},
  ),
  parse(
    'parse',
    Op.parse,
    'Read numbers out of decimal strings.',
    {'int', 'parse', 'money'},
  ),
  compare(
    'compare',
    Op.compare,
    'Compare neighbours of the same magnitude: the scales differ, so the'
        '\ncomparison cannot be decided by the exponent alone.',
    {'int', 'compare', 'money'},
  ),
  round(
    'round',
    Op.round,
    'Round to two digits.',
    {'int', 'round', 'money'},
  ),
  toDouble(
    'to-double',
    Op.toDouble,
    'Convert to the nearest double.',
    {'int', 'to-double', 'money'},
  ),
  toDoubleWide(
    'to-double-wide',
    Op.toDouble,
    'Convert to the nearest double numbers that hold more significant digits'
        '\nthan a double does — the case where correct rounding is the whole'
        '\nquestion (BigInt version).',
    {'big-int', 'to-double', 'wide'},
  ),
  toStringAsFixed(
    'to-string-as-fixed',
    Op.toStringAsFixed,
    'Write out with exactly two digits after the point.',
    {'int', 'to-string-as-fixed', 'money'},
  ),
  unrepresentableDivide(
    'unrepresentable-divide',
    Op.unrepresentableDivide,
    'Divide by three. Not one of the results has a finite decimal form,'
        '\nso every one of them has to be rounded to ten digits.',
    {'int', 'unrepresentable-divide', 'money'},
  );

  final String id;
  final Op operation;
  final String description;
  final Set<String> tags;

  const Test(
    this.id,
    this.operation,
    this.description,
    this.tags,
  );

  static Test? byId(String id) {
    for (final value in values) {
      if (value.id == id) return value;
    }

    return null;
  }

  static List<Test> byTag(String tag) {
    final packages = <Test>[];

    for (final value in values) {
      if (value.tags.contains(tag)) {
        packages.add(value);
      }
    }

    return packages;
  }

  ({
    List<(BigInt, int)> bigIntValues,
    List<(int, int)>? intValues,
    Object result
  }) data() {
    switch (this) {
      case addBigInt:
        final values = List<(BigInt, int)>.generate(
          40,
          (index) => (BigInt.parse('10000000000000000000'), index),
          growable: false,
        );

        return (
          bigIntValues: values,
          intValues: null,
          result: '11111111111111111111.11111111111111111111',
        );

      case Test.addInt:
        final values = List<(int, int)>.generate(
          16,
          (index) => (10000000, index),
          growable: false,
        );

        return (
          bigIntValues: bigIntValuesFromIntValues(values),
          intValues: values,
          result: '11111111.11111111',
        );

      case Test.addDirtyBigInt:
        final values = <(BigInt, int)>[
          for (final (index, base) in _dirtyBigBases.indexed)
            (BigInt.parse(base), index),
        ];

        return (
          bigIntValues: values,
          intValues: null,
          result: '97576969007209553094.5667209055520561472',
        );

      case Test.addDirtyInt:
        final values = <(int, int)>[
          for (final (index, base) in _dirtyIntBases.indexed) (base, index),
        ];

        return (
          bigIntValues: bigIntValuesFromIntValues(values),
          intValues: values,
          result: '78725.255535813',
        );

      case Test.multiplyLargeBigInt:
        final values = List<(BigInt, int)>.generate(
          10,
          (index) => (BigInt.from(123456789), 0),
          growable: false,
        );

        return (
          bigIntValues: values,
          intValues: null,
          result:
              '822526259147102579504761143661535547764137892295514168093701699676416207799736601',
        );

      case Test.multiplyLargeInt:
        final values = List<(int, int)>.generate(
          9,
          (index) => (123000, 0),
          growable: false,
        );

        return (
          bigIntValues: bigIntValuesFromIntValues(values),
          intValues: values,
          result: '6443858614676334363000000000000000000000000000',
        );

      case Test.multiplySmallBigInt:
        final values = List<(BigInt, int)>.generate(
          10,
          (index) => (BigInt.from(123456789), 10),
          growable: false,
        );

        return (
          bigIntValues: values,
          intValues: null,
          result:
              '0.0000000000000000000822526259147102579504761143661535547764137892295514168093701699676416207799736601',
        );

      case Test.multiplySmallInt:
        final values = List<(int, int)>.generate(
          9,
          (index) => (123, 4),
          growable: false,
        );

        return (
          bigIntValues: bigIntValuesFromIntValues(values),
          intValues: values,
          result: '0.000000000000000006443858614676334363',
        );

      case Test.multiplyDirtyBigInt:
        final values = <(BigInt, int)>[
          for (final (index, base) in _dirtyBigFactors.indexed)
            (BigInt.parse(base), index),
        ];

        return (
          bigIntValues: values,
          intValues: null,
          result: '121699422226741716930046498844488893313223095339'
              '.4836450636947381144674123776',
        );

      case Test.multiplyDirtyInt:
        final values = <(int, int)>[
          for (final (index, base) in _dirtyIntFactors.indexed)
            (base, index + 1),
        ];

        return (
          bigIntValues: bigIntValuesFromIntValues(values),
          intValues: values,
          result: '242429.5111104776',
        );

      case Test.divideDirtyBigInt:
        final values = <(BigInt, int)>[
          (BigInt.parse(_dirtyBigProduct), 28),
          for (final (index, base) in _dirtyBigFactors.indexed)
            (BigInt.parse(base), index),
        ];

        return (
          bigIntValues: values,
          intValues: null,
          result: '1',
        );

      case Test.divideDirtyInt:
        final values = <(int, int)>[
          (_dirtyIntProduct, 10),
          for (final (index, base) in _dirtyIntFactors.indexed)
            (base, index + 1),
        ];

        return (
          bigIntValues: bigIntValuesFromIntValues(values),
          intValues: values,
          result: '1',
        );

      case Test.divideLargeBigInt:
      case Test.divideLargeAndViewBigInt:
        final values = List<(BigInt, int)>.generate(
          11,
          (index) => index == 0
              ? (
                  BigInt.parse(
                    '822526259147102579504761143661535547764137892295514168093701699676416207799736601',
                  ),
                  0
                )
              : (BigInt.from(123456789), 0),
          growable: false,
        );

        return (
          bigIntValues: values,
          intValues: null,
          result: '1',
        );

      case Test.divideLargeInt:
      case Test.divideLargeAndViewInt:
        final values = List<(int, int)>.generate(
          10,
          (index) => index == 0 ? (6443858614676334363, -27) : (123000, 0),
          growable: false,
        );

        return (
          bigIntValues: bigIntValuesFromIntValues(values),
          intValues: values,
          result: '1',
        );

      case Test.divideSmallBigInt:
      case Test.divideSmallAndViewBigInt:
        final values = List<(BigInt, int)>.generate(
          10,
          (index) => index == 0 ? (BigInt.one, 0) : (BigInt.from(256), 0),
          growable: false,
        );

        return (
          bigIntValues: values,
          intValues: null,
          result: '0.000000000000000000000'
              '211758236813575084767080625169910490512847900390625',
        );

      case Test.divideSmallInt:
      case Test.divideSmallAndViewInt:
        final values = List<(int, int)>.generate(
          10,
          (index) => index == 0 ? (1, 0) : (8, 0),
          growable: false,
        );

        return (
          bigIntValues: bigIntValuesFromIntValues(values),
          intValues: values,
          result: '0.000000007450580596923828125',
        );

      case Test.repeatViewBigInt:
        const v = '123456789012345678901234567890123456789';
        final values = List<(BigInt, int)>.generate(
          20,
          (index) => (BigInt.parse(v), index * 2),
          growable: false,
        );

        return (
          bigIntValues: values,
          intValues: null,
          result: <String>[
            for (final (value, scale) in values) plainString(value, scale),
          ],
        );

      case Test.rawViewBigInt:
        // A pool of [viewPoolCycles] cycles: every cycle converts twenty
        // values that no cycle before it converted, so nothing a package
        // remembers can answer for the conversion being measured. Only digits
        // low in the number move, so every value keeps its thirty-nine digits
        // and its last digit stays non-zero.
        final base = BigInt.parse('123456789012345678901234567890123456789');
        final values = <(BigInt, int)>[
          for (var cycle = 0; cycle < viewPoolCycles; cycle++)
            for (var i = 0; i < 20; i++)
              (base + BigInt.from(1000 * cycle), i * 2),
        ];

        return (
          bigIntValues: values,
          intValues: null,
          result: <String>[
            for (final (value, scale) in values) plainString(value, scale),
          ],
        );

      case Test.repeatViewInt:
        final values = List<(int, int)>.generate(
          19,
          (index) => (1234567890123456789, index),
          growable: false,
        );

        return (
          bigIntValues: bigIntValuesFromIntValues(values),
          intValues: values,
          result: <String>[
            for (final (value, scale) in values)
              plainString(BigInt.from(value), scale),
          ],
        );

      case Test.rawViewInt:
        final values = <(int, int)>[
          for (var cycle = 0; cycle < viewPoolCycles; cycle++)
            for (var i = 0; i < 19; i++)
              (1234567890123456789 + 1000 * cycle, i),
        ];

        return (
          bigIntValues: bigIntValuesFromIntValues(values),
          intValues: values,
          result: <String>[
            for (final (value, scale) in values)
              plainString(BigInt.from(value), scale),
          ],
        );

      case Test.repeatViewZerosBigInt:
        final values = List<(BigInt, int)>.generate(
          20,
          (index) => (
            BigInt.parse('100000000000000000000000000000000000000'),
            index * 4
          ),
          growable: false,
        );

        return (
          bigIntValues: values,
          intValues: null,
          result: <String>[
            for (final (value, scale) in values) plainString(value, scale),
          ],
        );

      case Test.rawViewZerosBigInt:
        // The zeros are the point of the set, so the digits that move are the
        // three at the head. An odd head never ends in a zero, so the trailing
        // run of them stays as long as it was, and a head of fixed width keeps
        // every value at the magnitude the set was built at.
        final values = <(BigInt, int)>[
          for (var cycle = 0; cycle < viewPoolCycles; cycle++)
            for (var i = 0; i < 20; i++)
              (
                BigInt.parse(
                  '${101 + cycle * 2}'.padRight(39, '0'),
                ),
                i * 4
              ),
        ];

        return (
          bigIntValues: values,
          intValues: null,
          result: <String>[
            for (final (value, scale) in values) plainString(value, scale),
          ],
        );

      case Test.parse:
        return (
          bigIntValues: bigIntValuesFromIntValues(_moneyValues),
          intValues: _moneyValues,
          result: _moneyStrings,
        );

      case Test.compare:
        return (
          bigIntValues: bigIntValuesFromIntValues(_moneyValues),
          intValues: _moneyValues,
          result: _moneyCompareSum,
        );

      case Test.round:
        return (
          bigIntValues: bigIntValuesFromIntValues(_moneyValues),
          intValues: _moneyValues,
          result: _moneyRounded,
        );

      case Test.toDouble:
        return (
          bigIntValues: bigIntValuesFromIntValues(_moneyValues),
          intValues: _moneyValues,
          result: _moneyDoubles,
        );

      case Test.toDoubleWide:
        return (
          bigIntValues: [
            for (final (digits, scale) in _wideValues)
              (BigInt.parse(digits), scale),
          ],
          intValues: null,
          result: _wideDoubles,
        );

      case Test.toStringAsFixed:
        return (
          bigIntValues: bigIntValuesFromIntValues(_moneyValues),
          intValues: _moneyValues,
          result: _moneyFixed,
        );

      case Test.unrepresentableDivide:
        return (
          bigIntValues: bigIntValuesFromIntValues(_moneyValues),
          intValues: _moneyValues,
          result: _moneyThirds,
        );

      case Test.repeatViewZerosInt:
        final values = List<(int, int)>.generate(
          20,
          (index) => (1000000000000000000, index * 2 - 1),
          growable: false,
        );

        return (
          bigIntValues: bigIntValuesFromIntValues(values),
          intValues: values,
          result: <String>[
            for (final (value, scale) in values)
              plainString(BigInt.from(value), scale),
          ],
        );

      case Test.rawViewZerosInt:
        // The head is always three digits, so the value keeps its magnitude
        // and its nineteen digits: 101 to 305, and 3.05e18 is well inside
        // int64. A two-digit head would not be — 93 padded out is 9.3e18,
        // past the end of the type.
        final values = <(int, int)>[
          for (var cycle = 0; cycle < viewPoolCycles; cycle++)
            for (var i = 0; i < 20; i++)
              (int.parse('${101 + cycle * 2}'.padRight(19, '0')), i * 2 - 1),
        ];

        return (
          bigIntValues: bigIntValuesFromIntValues(values),
          intValues: values,
          result: <String>[
            for (final (value, scale) in values)
              plainString(BigInt.from(value), scale),
          ],
        );
    }
  }

  List<(BigInt, int)> bigIntValuesFromIntValues(List<(int, int)> intValues) =>
      intValues.map((e) {
        var value = BigInt.from(e.$1);
        var scale = e.$2;

        if (scale < 0) {
          value *= BigInt.from(10).pow(-scale);
          scale = 0;
        }

        return (value, scale);
      }).toList(growable: false);
}

/// Bases with nothing round about them.
///
/// Every other set here is built out of powers of ten or out of one factor
/// repeated — the best case for stripping zeros, for `gcd` and for the fast
/// path of division. Money does not look like that.
///
/// Generated once with a fixed seed and written out, so that the results the
/// sets are checked against can be verified by hand and stay verifiable.
const _dirtyBigBases = <String>[
  '89125394327232142231',
  '78429882591495295293',
  '56988635373487688272',
  '36748917985131948835',
  '17525293135184895389',
  '16296152677961238449',
  '29355485286173934417',
  '53848468499211452132',
  '82684625543317326747',
  '82326742493671271822',
  '84125123933323594987',
  '31324293129596129128',
  '27196853555338264469',
  '88442876716538737432',
  '58886862882751846529',
  '46914178876783797189',
  '78854619947777993633',
  '15911269627682577828',
  '79372911559894344294',
  '62535415685778912732',
];

const _dirtyIntBases = <int>[
  72864,
  56329,
  13649,
  86429,
  47283,
  61823,
  85913,
  35486,
  47152,
  72693,
];

/// Factors of [_dirtyBigProduct], each at the scale of its index.
const _dirtyBigFactors = <String>[
  '1732164824',
  '3229214656',
  '1295732572',
  '1562979347',
  '9627874111',
  '2123976622',
  '4467846511',
  '1175859388',
];

/// The product of [_dirtyBigFactors], scale 28.
const _dirtyBigProduct =
    '1216994222267417169300464988444888933132230953394836450636947381144674123776';

/// Factors of [_dirtyIntProduct], each at the scale of its index plus one.
const _dirtyIntFactors = <int>[
  4789,
  8236,
  7462,
  8237,
];

/// The product of [_dirtyIntFactors], scale 10.
const _dirtyIntProduct = 2424295111104776;

/// Money-like values: a handful of digits before the point and three to
/// eight after, none of them round, all of the same magnitude.
///
/// One set feeds [Test.parse], [Test.compare], [Test.round],
/// [Test.toDouble], [Test.toStringAsFixed] and
/// [Test.unrepresentableDivide]: the operations differ, the numbers do
/// not. Generated once with a fixed seed; every expected answer below is
/// computed from these values by exact rational arithmetic, outside Dart.
const _moneyValues = <(int, int)>[
  (8912539432, 3),
  (88635373487, 4),
  (688272367489, 5),
  (1798513194883, 6),
  (48953891629615, 7),
  (267796123844929, 8),
  (3554852861, 3),
  (48468499211, 4),
  (478232674249, 5),
  (3671271822841, 6),
  (59612912827196, 7),
  (853555338264469, 8),
  (8844287671, 3),
  (65387374325, 4),
  (184652946914, 5),
  (1788767837971, 6),
  (89788546199477, 7),
  (372911559894344, 8),
  (2946253541, 3),
  (56857789127, 4),
];

/// [_moneyValues] written out: the input of [Test.parse] and its answer.
const _moneyStrings = <String>[
  '8912539.432',
  '8863537.3487',
  '6882723.67489',
  '1798513.194883',
  '4895389.1629615',
  '2677961.23844929',
  '3554852.861',
  '4846849.9211',
  '4782326.74249',
  '3671271.822841',
  '5961291.2827196',
  '8535553.38264469',
  '8844287.671',
  '6538737.4325',
  '1846529.46914',
  '1788767.837971',
  '8978854.6199477',
  '3729115.59894344',
  '2946253.541',
  '5685778.9127',
];

/// [_moneyValues] rounded to two digits, half away from zero.
const _moneyRounded = <String>[
  '8912539.43',
  '8863537.35',
  '6882723.67',
  '1798513.19',
  '4895389.16',
  '2677961.24',
  '3554852.86',
  '4846849.92',
  '4782326.74',
  '3671271.82',
  '5961291.28',
  '8535553.38',
  '8844287.67',
  '6538737.43',
  '1846529.47',
  '1788767.84',
  '8978854.62',
  '3729115.6',
  '2946253.54',
  '5685778.91',
];

/// [_moneyValues] as `toStringAsFixed(2)` writes them.
const _moneyFixed = <String>[
  '8912539.43',
  '8863537.35',
  '6882723.67',
  '1798513.19',
  '4895389.16',
  '2677961.24',
  '3554852.86',
  '4846849.92',
  '4782326.74',
  '3671271.82',
  '5961291.28',
  '8535553.38',
  '8844287.67',
  '6538737.43',
  '1846529.47',
  '1788767.84',
  '8978854.62',
  '3729115.60',
  '2946253.54',
  '5685778.91',
];

/// [_moneyValues] as the nearest `double` prints itself.
const _moneyDoubles = <String>[
  '8912539.432',
  '8863537.3487',
  '6882723.67489',
  '1798513.194883',
  '4895389.1629615',
  '2677961.23844929',
  '3554852.861',
  '4846849.9211',
  '4782326.74249',
  '3671271.822841',
  '5961291.2827196',
  '8535553.38264469',
  '8844287.671',
  '6538737.4325',
  '1846529.46914',
  '1788767.837971',
  '8978854.6199477',
  '3729115.59894344',
  '2946253.541',
  '5685778.9127',
];

/// [_moneyValues] divided by three, rounded to ten digits.
///
/// None of the bases is a multiple of three, so not one of these
/// divisions has a finite decimal form.
const _moneyThirds = <String>[
  '2970846.4773333333',
  '2954512.4495666667',
  '2294241.2249633333',
  '599504.3982943333',
  '1631796.3876538333',
  '892653.7461497633',
  '1184950.9536666667',
  '1615616.6403666667',
  '1594108.9141633333',
  '1223757.2742803333',
  '1987097.0942398667',
  '2845184.4608815633',
  '2948095.8903333333',
  '2179579.1441666667',
  '615509.8230466667',
  '596255.9459903333',
  '2992951.5399825667',
  '1243038.5329811467',
  '982084.5136666667',
  '1895259.6375666667',
];

/// The sum of the signs of `compareTo` over the neighbours in
/// [_moneyValues].
const _moneyCompareSum = 3;

/// Числа, у которых значащих цифр больше, чем помещается в `double`.
///
/// Набор сгенерирован вслепую — не подбором случаев, где кто-то ошибается, — и
/// ограничен величиной от 1e-4 до 1e16: в этом диапазоне Dart и Python
/// печатают `double` одинаково, так что ожидаемые значения ниже посчитаны вне
/// Dart и сверяются побайтово.
const _wideValues = <(String, int)>[
  ('125394326121903112096732', 16),
  ('98825914952952924587752427', 11),
  ('48757716912563780687490209', 23),
  ('8835064914182024073978428', 21),
  ('162961526779501273381825', 12),
  ('4852861739343064273736', 10),
  ('4992114510217159735144323', 17),
  ('31563679121563138256902', 22),
  ('82284124012829229125', 13),
  ('49873132418201848501801717', 17),
  ('9574244942271533587973318', 24),
  ('767165387374214977757518', 12),
  ('2751846519835980306797966', 17),
  ('37971896774350988936667', 16),
  ('936331591015851657914668', 15),
  ('28793729115598932331835143', 11),
  ('4156857789127318808573', 8),
  ('11728533373845299189025381', 21),
  ('26894113828328987314', 12),
  ('28853180312188757936172008', 23),
];

/// [_wideValues], округлённые к ближайшему `double`.
///
/// Посчитано точным преобразованием десятичной дроби в `double` вне Dart.
const _wideDoubles = <String>[
  '12539432.612190312',
  '988259149529529.2',
  '487.5771691256378',
  '8835.064914182025',
  '162961526779.50128',
  '485286173934.30646',
  '49921145.1021716',
  '3.156367912156314',
  '8228412.401282923',
  '498731324.18201846',
  '9.574244942271534',
  '767165387374.215',
  '27518465.198359802',
  '3797189.6774350987',
  '936331591.0158516',
  '287937291155989.3',
  '41568577891273.19',
  '11728.5333738453',
  '26894113.828328986',
  '288.5318031218876',
];
