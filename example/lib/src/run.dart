import 'dart:math';

import 'package:ansi_escape_codes/ansi_escape_codes.dart';
import 'package:ansi_escape_codes/extensions.dart';
import 'package:example/src/tests/big_decimal_test.dart';
import 'package:format/format.dart';
import 'package:yet_another_decimal/yet_another_decimal.dart';

import 'operations.dart';
import 'packages.dart';
import 'tests.dart';
import 'tests/decimal_test.dart';
import 'tests/decimal_type_test.dart';
import 'tests/fixed_test.dart';
import 'tests/my_benchmark_base.dart';
import 'tests/yet_another_decimal_short_test.dart';
import 'tests/yet_another_decimal_test.dart';
import 'utils/output.dart';

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

void run({
  required Set<Package> packages,
  required Set<Test> tests,
}) {
  _printPackages(packages);
  _printTests(tests);

  // ignore: omit_local_variable_types
  final Summary summary = {};

  for (final test in tests) {
    _printTitle(test);

    final (bigIntValues: bigIntValues, intValues: intValues, result: result) =
        test.data();

    _printValues(bigIntValues, test.operation.sign, result);

    _measureBigIntTestsAndPrint(
      summary,
      packages,
      bigIntValues,
      test,
      result,
    );

    if (intValues != null) {
      _measureIntTestsAndPrint(
        summary,
        packages,
        intValues,
        test,
        result,
      );
    }
  }

  _printSummary(packages, tests, summary);
}

final _bigIntPackages = <Package, CreateBigIntTestCallback>{
  Package.decimal: DecimalTest.new,
  Package.fixed: FixedTest.new,
  Package.decimalType: DecimalTypeTest.new,
  Package.bigDecimal: BigDecimalTest.new,
  Package.yetAnotherDecimal: YetAnotherDecimalTest.new,
};

final _intPackages = <Package, CreateIntTestCallback>{
  Package.yetAnotherDecimalShort: YetAnotherDecimalShortTest.new,
};

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
) {
  for (final MapEntry(key: package, value: create) in _bigIntPackages.entries) {
    if (packages.contains(package)) {
      final benchmark = create(values, test.operation, result);
      results[(package, test)] = benchmark;
      _measureTest(benchmark);
    }
  }
}

void _measureIntTestsAndPrint(
  Summary results,
  Set<Package> packages,
  List<(int, int)> values,
  Test test,
  Object result,
) {
  for (final MapEntry(key: package, value: create) in _intPackages.entries) {
    if (packages.contains(package)) {
      final benchmark = create(values, test.operation, result);
      results[(package, test)] = benchmark;
      _measureTest(benchmark);
    }
  }
}

void _measureTest(MyBenchmarkBase benchmark) {
  try {
    final score = benchmark.measure() / benchmark.operation.numberOfCycles;
    benchmark.score = score;

    final msg = benchmark.resultMessage;
    final package = benchmark.package;

    print(
      '${accent(package.id)} (${package.type}):'
      ' ${accent('${format('{:.3f}', score)} µs')}'
      '${msg == null ? '' : ' $msg'}',
    );
    // ignore: unused_catch_stack
  } on Object catch (e, s) {
    benchmark.error = e.toString();
    print('${accent(benchmark.name)} ${accentError('ERROR')} ${error('$e')}');
    // print(s);
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

  final titleLen = title.removeEscapeCodes().length;
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
) {
  final table = <List<String>>[];
  final widths = List<int>.filled(packages.length + 1, 0);
  final footnotes = <String>[];
  var hasWinner = false;

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
  widths[0] = max(widths[0], firstRow[0].removeEscapeCodes().length);

  for (final (index, package) in packages.indexed) {
    var title = accent(package.id);
    if (package.excludeFromComparision) {
      title = '$title${footnote('Excluded from comparision')}';
    }
    firstRow[index + 1] = title;
    widths[index + 1] =
        max(widths[index + 1], title.removeEscapeCodes().length);
  }
  table.add(firstRow);

  for (final test in tests) {
    final row = List<String>.filled(packages.length + 1, '');
    final title = accent(test.id);
    row[0] = title;
    widths[0] = max(widths[0], title.removeEscapeCodes().length);
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
          }
        }
      }

      row[index + 1] = text;
      widths[index + 1] =
          max(widths[index + 1], text.removeEscapeCodes().length);
    }
  }

  print('');
  print('Summary:');
  print('');

  for (final (index, row) in table.indexed) {
    final buf = StringBuffer();
    for (final (col, text) in row.indexed) {
      final colWidth = widths[col];
      final textWidth = text.removeEscapeCodes().length;

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

    for (var (index, footnote) in footnotes.indexed) {
      final parser = AnsiParser(footnote);
      final matches = parser.matches.toList();
      if (matches.isEmpty) {
        if (!footnote.endsWith('.')) {
          footnote += '.';
        }
      } else {
        var lastSeq = matches.last;
        if (lastSeq.end != footnote.length) {
          if (!footnote.endsWith('.')) {
            footnote += '.';
          }
        } else {
          var index = matches.length - 1;
          while (index > 0 && matches[index - 1].end == lastSeq.start) {
            lastSeq = matches[index - 1];
            index--;
          }

          if (lastSeq.start > 0 && footnote[lastSeq.start - 1] != '.') {
            footnote = '${footnote.substring(0, lastSeq.start)}.'
                '${footnote.substring(lastSeq.start)}';
          }
        }
      }

      parser.replaceAll(
        (e) => e.string,
        replacePlainText: (t) => t.string.showControlCodes(),
      );

      print('${accentWarning('${index + 1}')} $footnote');
    }
  }
}
