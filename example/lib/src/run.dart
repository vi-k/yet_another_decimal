import 'dart:io';
import 'dart:math';

import 'package:ansi_escape_codes/ansi_escape_codes.dart';
import 'package:denary/denary.dart';
import 'package:example/src/tests/big_double_test.dart';
import 'package:format/format.dart';

import 'operations.dart';
import 'packages.dart';
import 'tests.dart';
import 'tests/big_decimal_test.dart';
import 'tests/decimal_test.dart';
import 'tests/decimal_type_test.dart';
import 'tests/denary_short_test.dart';
import 'tests/denary_test.dart';
import 'tests/fixed_test.dart';
import 'tests/my_benchmark_base.dart';
import 'tests/precise_decimal_test.dart';
import 'utils/output.dart';

/// How many times every benchmark is measured when the number is not given.
///
/// The machine drifts by up to 15 % between runs, so a single measurement says
/// nothing. The summary shows the median of the series.
const int defaultRuns = 5;

/// How many times the whole sweep is measured when the number is not given.
///
/// One pass is enough to see where a package stands; numbers worth quoting
/// need two. A burst of unrelated load outlasts the series of a single
/// benchmark, and then its median is as wrong as any one run of it — only a
/// pass measured at another time can tell.
const int defaultPasses = 1;

typedef Summary = Map<(Package, Test), MyBenchmarkBase>;

typedef CreateBigIntTestCallback = MyBenchmarkBase Function(
  List<(BigInt, int)> values,
  Op operation,
  Object result,
);

typedef CreateIntTestCallback = MyBenchmarkBase Function(
  List<(int, int)> values,
  Op operation,
  Object result,
);

/// Runs the stand, or only checks its answers; `false` if a package got one
/// wrong.
///
/// The answer check is not the measurement and does not need it: every
/// benchmark verifies itself against the expected result in `setup()`, before
/// a single measured cycle. Asking for that alone takes seconds instead of
/// hours, which is what makes it something CI can do — see
/// `docs/records/2026-08-31[10]-bench-check-report.md`.
bool run({
  required Set<Package> packages,
  required Set<Test> tests,
  int runs = defaultRuns,
  int passes = defaultPasses,
  bool check = false,
}) {
  if (!check) {
    _printEnvironment(packages, runs, passes);
  }
  _printPackages(packages);
  _printTests(tests);

  // ignore: omit_local_variable_types
  final Summary summary = {};

  if (check) {
    _measurePass(summary, packages, tests, runs, 1, 1, check: true);

    return _printCheck(summary);
  }

  for (var pass = 1; pass <= passes; pass++) {
    _measurePass(summary, packages, tests, runs, pass, passes);

    for (final benchmark in summary.values) {
      benchmark.endPass();
    }
  }

  _printSummary(packages, tests, summary, passes);

  return true;
}

/// The verdict of a check run: what answered wrongly, and whether anything did.
///
/// A `WARNING` is not a wrong answer — it means the answer matches down to
/// trailing zeros, which is a difference in how a package spells a value, not
/// in what it computed. Only [MyBenchmarkBase.error] counts, and that already
/// excuses the packages allowed to disagree.
bool _printCheck(Summary summary) {
  final wrong = <(String, String), String>{};
  for (final MapEntry(key: (package, test), value: benchmark)
      in summary.entries) {
    final error = benchmark.error;
    if (error != null) {
      wrong[(package.id, test.id)] = error;
    }
  }

  final appeared =
      wrong.keys.where((pair) => !_knownWrongAnswers.contains(pair)).toList();
  final vanished =
      _knownWrongAnswers.where((pair) => !wrong.containsKey(pair)).toList();

  print('');
  print(special('Answers'));
  print('');

  if (appeared.isEmpty && vanished.isEmpty) {
    print(
      ok(
        '${summary.length} cells checked;'
        ' the ${wrong.length} wrong answers are the known ones',
      ),
    );

    return true;
  }

  for (final pair in appeared) {
    print(
      '${accentError('new')} ${accent('${pair.$1} ${pair.$2}')}:'
      ' ${wrong[pair]}',
    );
  }

  for (final pair in vanished) {
    print(
      '${accentWarning('gone')} ${accent('${pair.$1} ${pair.$2}')}:'
      ' answers correctly now, and the list still says it does not',
    );
  }

  print('');
  print(
    error(
      'The set of wrong answers is not the recorded one:'
      ' ${appeared.length} new, ${vanished.length} gone.',
    ),
  );

  return false;
}

/// The cells where a package is known to answer wrongly.
///
/// Neither a defect list of ours nor a shame list of theirs: it is what the
/// stand already publishes about these packages, written down so that CI can
/// tell a known difference from a new one. Every pair is a model that cannot
/// give the answer the test asks for — an inexact quotient refused or rounded,
/// a comparison that reads the scale, a double built through a string.
///
/// Both directions fail. A pair that disappears means either the package has
/// changed under us or our expectation has; either wants reading before the
/// line is deleted.
const _knownWrongAnswers = <(String, String)>{
  ('decimal', 'to-double-wide'),
  ('big_decimal', 'to-double-wide'),
  ('big_decimal', 'divide-small-big-int'),
  ('big_decimal', 'divide-small-int'),
  ('big_decimal', 'divide-small-and-view-big-int'),
  ('big_decimal', 'divide-small-and-view-int'),
  ('fixed', 'compare'),
  ('fixed', 'divide-small-big-int'),
  ('fixed', 'divide-small-int'),
  ('fixed', 'divide-small-and-view-big-int'),
  ('fixed', 'divide-small-and-view-int'),
  ('decimal_type', 'divide-large-big-int'),
  ('decimal_type', 'divide-large-int'),
  ('decimal_type', 'divide-small-big-int'),
  ('decimal_type', 'divide-small-int'),
  ('decimal_type', 'divide-dirty-big-int'),
  ('decimal_type', 'divide-dirty-int'),
  ('decimal_type', 'divide-large-and-view-big-int'),
  ('decimal_type', 'divide-large-and-view-int'),
  ('decimal_type', 'divide-small-and-view-big-int'),
  ('decimal_type', 'divide-small-and-view-int'),
};

/// One sweep over every test, filling a pass into every benchmark.
void _measurePass(
  Summary summary,
  Set<Package> packages,
  Set<Test> tests,
  int runs,
  int pass,
  int passes, {
  bool check = false,
}) {
  if (passes > 1) {
    print('');
    print(special('Pass $pass of $passes'));
  }

  for (final test in tests) {
    _printTitle(test);

    final (bigIntValues: bigIntValues, intValues: intValues, result: result) =
        test.data();

    // The values are the same in every pass; printing them once is enough,
    // and a check does not need them at all.
    if (pass == 1 && !check) {
      _printValues(bigIntValues, test.operation.sign, result);
    }

    // The same input for every package: what a package prints is its own
    // business, what it is given must not be.
    final inputs = [
      for (final (base, scale) in bigIntValues)
        Decimal.fromBigInt(base, shiftRight: scale).toString(),
    ];

    _measureBigIntTestsAndPrint(
      summary,
      packages,
      bigIntValues,
      test,
      result,
      runs,
      inputs,
      pass,
      check: check,
    );

    if (intValues != null) {
      _measureIntTestsAndPrint(
        summary,
        packages,
        intValues,
        test,
        result,
        runs,
        inputs,
        pass,
        check: check,
      );
    }
  }
}

/// How many values one cycle of [test] converts.
///
/// The `raw-view` sets are pools of [viewPoolCycles] cycles — a value is not
/// converted twice while a package could still remember it — so one cycle is
/// that much less than the whole set. Every other set is one cycle.
int _viewWindow(Test test, int length) =>
    test.operation == Op.rawView ? length ~/ viewPoolCycles : length;

final _bigIntPackages = <Package, CreateBigIntTestCallback>{
  Package.decimal: DecimalTest.new,
  Package.fixed: FixedTest.new,
  Package.decimalType: DecimalTypeTest.new,
  Package.bigDecimal: BigDecimalTest.new,
  Package.preciseDecimal: PreciseDecimalTest.new,
  Package.yetAnotherDecimal: YetAnotherDecimalTest.new,
  Package.bigDouble: BigDoubleTest.new,
};

final _intPackages = <Package, CreateIntTestCallback>{
  Package.yetAnotherDecimalShort: YetAnotherDecimalShortTest.new,
};

/// Everything the numbers depend on but the table does not show.
///
/// Goes under the table in `README.md`: without it the numbers cannot be
/// compared with a run made a year later on another machine.
void _printEnvironment(Set<Package> packages, int runs, int passes) {
  const isProduct = bool.fromEnvironment('dart.vm.product');

  print('Environment:');
  print('${faintAccent('Dart:  ')} ${accent(Platform.version)}');
  print('${faintAccent('OS:    ')} ${accent(Platform.operatingSystemVersion)}');
  final cpus = Platform.numberOfProcessors;
  print('${faintAccent('CPUs:  ')} ${accent('$cpus')}');
  print(
    '${faintAccent('Mode:  ')} '
    '${accent(isProduct ? 'AOT (dart compile exe)' : 'JIT (dart run)')}',
  );
  print(
    '${faintAccent('Runs:  ')} '
    '${accent(runs == 1 ? '1' : '$runs (median of the series)')}',
  );
  print(
    '${faintAccent('Passes:')} '
    '${accent(passes == 1 ? '1' : '$passes (the best of them per cell)')}',
  );

  final versions = _lockedVersions();
  if (versions.isEmpty) {
    return;
  }

  final named = <String>[];
  for (final package in packages) {
    final name = package.pubName;
    final version = versions[name];
    if (version != null && !named.any((e) => e.startsWith('$name '))) {
      named.add('$name $version');
    }
  }

  if (named.isNotEmpty) {
    print('${faintAccent('Deps:  ')} ${accent(named.join(', '))}');
  }
}

/// Versions of the compared packages, read from `pubspec.lock`.
///
/// The lock file is looked up next to the current directory and above it: the
/// benchmark is run both by `dart run` from `example/` and as a compiled
/// executable from the root of the repository.
Map<String, String> _lockedVersions() {
  final file = _findLock();
  if (file == null) {
    return const {};
  }

  final packageLine = RegExp(r'^  ([a-z_0-9]+):$');
  final versionLine = RegExp(r'^    version: "([^"]+)"$');
  final versions = <String, String>{};
  String? name;

  for (final line in file.readAsLinesSync()) {
    final package = packageLine.firstMatch(line);
    if (package != null) {
      name = package[1];
      continue;
    }

    final version = versionLine.firstMatch(line);
    if (version != null && name != null) {
      versions[name] = version[1]!;
      name = null;
    }
  }

  // The package under test is a path dependency: the lock file has no version
  // for it, only `pubspec.yaml` has.
  final own = _findOwnVersion();
  if (own != null) {
    versions['denary'] = own;
  }

  return versions;
}

File? _findLock() => _findUp(
      // The lock of `example/` comes first: it is the one that pins the
      // compared packages, and the root has a lock of its own.
      (dir) => [
        File('${dir.path}/example/pubspec.lock'),
        File('${dir.path}/pubspec.lock'),
      ],
    );

String? _findOwnVersion() {
  var dir = Directory.current;

  for (var i = 0; i < 4; i++) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (pubspec.existsSync()) {
      final lines = pubspec.readAsLinesSync();
      // `example/pubspec.yaml` is found first and has a version of its own.
      if (lines.contains('name: denary')) {
        for (final line in lines) {
          final match = RegExp(r'^version: (.+)$').firstMatch(line);
          if (match != null) {
            return match[1]!.trim();
          }
        }
      }
    }

    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }

  return null;
}

File? _findUp(List<File> Function(Directory dir) candidates) {
  var dir = Directory.current;

  for (var i = 0; i < 4; i++) {
    for (final file in candidates(dir)) {
      if (file.existsSync()) {
        return file;
      }
    }

    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }

  return null;
}

void _printPackages(Set<Package> packages) {
  print('Packages:');
  for (final package in packages) {
    print(accent(package.id));
  }
}

void _printTests(Set<Test> tests) {
  print('\nTests:');
  for (final test in tests) {
    print(accent(test.id));
  }
}

void _measureBigIntTestsAndPrint(
  Summary results,
  Set<Package> packages,
  List<(BigInt, int)> values,
  Test test,
  Object result,
  int runs,
  List<String> inputs,
  int pass, {
  bool check = false,
}) {
  for (final MapEntry(key: package, value: create) in _bigIntPackages.entries) {
    if (!packages.contains(package)) {
      continue;
    }

    // A pair missing from the summary after the first pass is one the package
    // cannot do: asking it again every pass would only reprint the answer.
    var benchmark = results[(package, test)];
    if (benchmark == null) {
      if (pass > 1) {
        continue;
      }

      benchmark = create(values, test.operation, result)
        ..inputs = inputs
        ..viewWindow = _viewWindow(test, values.length);
    }

    if (_measureTest(benchmark, runs, check: check)) {
      results[(package, test)] = benchmark;
    }
  }
}

void _measureIntTestsAndPrint(
  Summary results,
  Set<Package> packages,
  List<(int, int)> values,
  Test test,
  Object result,
  int runs,
  List<String> inputs,
  int pass, {
  bool check = false,
}) {
  for (final MapEntry(key: package, value: create) in _intPackages.entries) {
    if (!packages.contains(package)) {
      continue;
    }

    // A pair missing from the summary after the first pass is one the package
    // cannot do: asking it again every pass would only reprint the answer.
    var benchmark = results[(package, test)];
    if (benchmark == null) {
      if (pass > 1) {
        continue;
      }

      benchmark = create(values, test.operation, result)
        ..inputs = inputs
        ..viewWindow = _viewWindow(test, values.length);
    }

    if (_measureTest(benchmark, runs, check: check)) {
      results[(package, test)] = benchmark;
    }
  }
}

/// Measures one benchmark, `false` if the package has no such operation.
///
/// With [check] the answer is all that is wanted: `setup()` runs one cycle and
/// compares it with the expected result, and nothing is measured.
bool _measureTest(MyBenchmarkBase benchmark, int runs, {bool check = false}) {
  try {
    if (check) {
      benchmark.setup();

      final package = benchmark.package;
      final answer = benchmark.resultMessage;
      print(
        '${accent(package.id)} (${package.type}):'
        ' ${answer ?? faintAccent('nothing to check against')}',
      );

      return true;
    }

    for (var i = 0; i < runs; i++) {
      benchmark.scores.add(
        benchmark.measure() / benchmark.operation.numberOfCycles,
      );
    }

    final score = benchmark.currentPass!;
    final (best, worst) = benchmark.spread!;

    final msg = benchmark.resultMessage;
    final package = benchmark.package;

    print(
      '${accent(package.id)} (${package.type}):'
      ' ${accent('${format('{:.3f}', score)} µs')}'
      '${runs == 1 ? '' : faintAccent(
          ' [${format('{:.3f}', best)}…${format('{:.3f}', worst)}]',
        )}'
      '${msg == null ? '' : ' $msg'}',
    );

    return true;
  } on UnsupportedOperation catch (e) {
    print('${accent(benchmark.package.id)}: ${faintAccent('$e')}');

    return false;
    // ignore: unused_catch_stack
  } on Object catch (e, s) {
    benchmark.error = e.toString();
    print('${accent(benchmark.name)} ${accentError('ERROR')} ${error('$e')}');
    // print(s);

    return true;
  }
}

void _printValues(
  List<(BigInt, int)> values,
  String? op,
  Object result,
) {
  final decimals =
      values.map((e) => Decimal.fromBigInt(e.$1, shiftRight: e.$2));
  if (op != null) {
    print('${decimals.join(' $op ')} = $result');
    print('');
  } else {
    for (final d in decimals) {
      print('$d');
    }
    print('');
  }
}

void _printTitle(Test test) {
  final title = 'Test: ${special(test.id)}'
      ', tags: ${accent(test.tags.map(faintAccent).join(', '))}'
      '$reset';

  final titleLen = title.lengthWithoutEscapeCodes;
  final description = test.description.split('\n');
  const descriptionTitle = 'Description: ';
  final descriptionLen = description.fold(0, (l, s) => max(l, s.length));

  final len = max(titleLen, descriptionTitle.length + descriptionLen);

  print('');
  print(special('─' * len));
  print(title);
  print('$descriptionTitle${faintAccent(description[0])}');
  for (final d in description.skip(1)) {
    print('${' ' * descriptionTitle.length}${faintAccent(d)}');
  }
  print('');
}

String _sup(int number) => number
    .toString()
    .replaceAll('0', '⁰')
    .replaceAll('1', '¹')
    .replaceAll('2', '²')
    .replaceAll('3', '³')
    .replaceAll('4', '⁴')
    .replaceAll('5', '⁵')
    .replaceAll('6', '⁶')
    .replaceAll('7', '⁷')
    .replaceAll('8', '⁸')
    .replaceAll('9', '⁹');

// String _sub(int number) => number
//     .toString()
//     .replaceAll('0', '₀')
//     .replaceAll('1', '₁')
//     .replaceAll('2', '₂')
//     .replaceAll('3', '₃')
//     .replaceAll('4', '₄')
//     .replaceAll('5', '₅')
//     .replaceAll('6', '₆')
//     .replaceAll('7', '₇')
//     .replaceAll('8', '₈')
//     .replaceAll('9', '₉');

// Summary.
void _printSummary(
  Set<Package> packages,
  Set<Test> tests,
  Summary summary,
  int passes,
) {
  final table = <List<String>>[];
  final widths = List<int>.filled(packages.length + 1, 0);
  final footnotes = <String>[];
  var hasWinner = false;
  var hasOutsider = false;

  String footnote(String text) {
    final index = footnotes.indexOf(text);
    if (index != -1) {
      return accentWarning(_sup(index + 1));
    }

    footnotes.add(text);
    return accentWarning(_sup(footnotes.length));
  }

  // Заголовок.
  final firstRow = List<String>.filled(packages.length + 1, '');
  firstRow[0] = '';
  widths[0] = max(widths[0], firstRow[0].lengthWithoutEscapeCodes);

  for (final (index, package) in packages.indexed) {
    var title = accent(package.id);
    if (package.excludeFromComparision) {
      title = '$title${footnote('Excluded from comparision')}';
    }
    firstRow[index + 1] = title;
    widths[index + 1] = max(widths[index + 1], title.lengthWithoutEscapeCodes);
  }
  table.add(firstRow);

  for (final test in tests) {
    final row = List<String>.filled(packages.length + 1, '');
    final title = accent(test.id);
    row[0] = title;
    widths[0] = max(widths[0], title.lengthWithoutEscapeCodes);
    table.add(row);
    double? minScore;

    for (final package in packages) {
      final benchmark = summary[(package, test)];
      if (benchmark != null) {
        if (!package.excludeFromComparision && !benchmark.hasError) {
          final score = benchmark.score;
          if (score != null && (minScore == null || score < minScore)) {
            minScore = score;
          }
        }
      }
    }

    for (final (index, package) in packages.indexed) {
      final benchmark = summary[(package, test)];
      String text;

      if (benchmark == null) {
        text = '—${footnote('Not supported')}';
      } else {
        final err = benchmark.error;
        if (err != null) {
          text = '${error('ERROR')}${footnote(error(err))}';
        } else {
          final score = benchmark.score!;
          text = format('{:.3f} µs', score);

          if (!package.excludeFromComparision && minScore != null) {
            final isWinner = (score - minScore).abs() <= minScore * 0.1;
            if (isWinner) {
              text = ok('★ $text');
              hasWinner = true;
            } else {
              final k = (score / minScore).abs().floor();
              if (k > 1) {
                var ktext = '(▼${k}x)';
                ktext = k < 10 ? warning(ktext) : error(ktext);
                text = '$ktext $text';
              }
            }
          } else if (package.excludeFromComparision &&
              minScore != null &&
              !benchmark.wrongAnswer &&
              score <= minScore) {
            // Вне зачёта, но быстрее всех, кто в зачёте. Отметка нужна не
            // ради похвалы, а ради её отсутствия: где её нет, там пакет
            // проигрывает, и это видно сразу.
            text = ok('★★ $text');
            hasOutsider = true;
          }
        }
      }

      row[index + 1] = text;
      widths[index + 1] = max(widths[index + 1], text.lengthWithoutEscapeCodes);
    }
  }

  print('');
  print('Summary:');
  print('');
  if (passes == 1) {
    print(
      warning(
        'Measured in a single pass. A burst of load outlasts the series of one'
        ' benchmark, and no median inside it can tell. For numbers worth'
        ' quoting use --passes=2.',
      ),
    );
  } else {
    print(
      faintAccent(
        'Each cell is the best of $passes passes; every pass is above.',
      ),
    );
  }
  print('');

  for (final (index, row) in table.indexed) {
    final buf = StringBuffer();
    for (final (col, text) in row.indexed) {
      final colWidth = widths[col];
      final textWidth = text.lengthWithoutEscapeCodes;

      if (col == 0) {
        buf
          ..write('| ')
          ..write(text)
          ..write(' ' * (colWidth - textWidth))
          ..write(' |');
      } else {
        buf
          ..write(' ')
          ..write(' ' * (colWidth - textWidth))
          ..write(text)
          ..write(' |');
      }
    }
    buf.write(reset);
    print(buf);

    if (index == 0) {
      final buf = StringBuffer();
      for (final (col, _) in row.indexed) {
        final colWidth = widths[col];

        if (col == 0) {
          buf
            ..write('|:')
            ..write('-' * (colWidth + 1))
            ..write('|');
        } else {
          buf
            ..write('-' * (colWidth + 1))
            ..write(':|');
        }
      }
      print(buf);
    }
  }

  if (footnotes.isNotEmpty || hasWinner) {
    print('');

    if (hasWinner) {
      print('${ok('★')} Winner or near winner (<= 10%)');
    }

    if (hasOutsider) {
      print(
        '${ok('★★')} Outside the comparison and faster than everyone in it',
      );
    }

    for (final (index, footnote) in footnotes.indexed) {
      // The full stop belongs to the text, not after the escape codes that
      // close its style: the parser puts it where the last visible character
      // is, whatever follows it in the string.
      final parser = Parser(footnote);
      final text = parser.endsWith('.')
          ? footnote
          : parser.insertAfter(parser.length, '.');

      print('${accentWarning('${index + 1}')} $text');
    }
  }
}
