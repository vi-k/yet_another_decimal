// Runs the General Decimal Arithmetic test vectors against this package.
//
// The vectors are not in this repository and never will be: they are
// IBM copyright, offered as-is, with no grant to redistribute them. Download
// them yourself and point this script at the unpacked files:
//
//   curl -sSL -o dectest.zip https://speleotrove.com/decimal/dectest.zip
//   unzip -q dectest.zip -d .dectest
//   dart run tool/dectest.dart --dir=.dectest
//
// Two thirds of the suite does not apply to us, and that is by design, not by
// omission: GDA rounds every operation to a context precision and carries
// NaN and Infinity, while this package is exact or refuses. What is left is a
// stranger's oracle for the arithmetic we do have — see
// docs/records/2026-08-29[4]-gda-scope-design.md.
//
// Exit code is 1 if any applicable case disagrees.

import 'dart:io';

import 'package:denary/denary.dart';

/// Runs the vectors and reports; see the notes at the top of this file.
void main(List<String> args) {
  final dir = _dirFromArgs(args);
  if (dir == null) {
    stderr.writeln('Usage: dart run tool/dectest.dart --dir=<unpacked files>');
    exit(2);
  }

  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.dectest'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (files.isEmpty) {
    stderr.writeln('No .decTest files in ${dir.path}');
    exit(2);
  }

  final run = _Run();
  files.forEach(run.file);
  run.report();

  exit(run.failures.isEmpty && run.shortFailures.isEmpty ? 0 : 1);
}

Directory? _dirFromArgs(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--dir=')) {
      final dir = Directory(arg.substring('--dir='.length));

      return dir.existsSync() ? dir : null;
    }
  }

  return null;
}

/// Why a case was not run.
///
/// Every one of these is a property of the suite meeting our model, not a
/// defect: the counts are printed so that a change in them is noticed.
enum _Skip {
  operation('operation we do not have'),
  special('NaN, sNaN or Infinity'),
  contextRounded('the context rounded the answer, we are exact'),
  hugeExponent('exponent past our parsing limit'),
  rounding('rounding mode we do not have'),
  power('power that is not an integer one'),
  spelling('a trailing point, which we refuse on purpose'),
  shortTooBig('does not fit the short family'),
  encoded('a value in an encoding test, not a number'),
  inexactDivide('quotient with no finite decimal form');

  const _Skip(this.explanation);

  final String explanation;
}

/// The rounding modes of GDA that we have, and what we call them.
const _rounding = <String, Decimal Function(Decimal, int)>{
  'half_even': _roundToEven,
  'half_up': _round,
  'floor': _floor,
  'down': _truncate,
  'up': _roundAwayFromZero,
  'ceiling': _ceil,
};

Decimal _roundToEven(Decimal v, int digits) => v.roundToEven(digits);
Decimal _round(Decimal v, int digits) => v.round(digits);
Decimal _floor(Decimal v, int digits) => v.floor(digits);
Decimal _truncate(Decimal v, int digits) => v.truncate(digits);
Decimal _roundAwayFromZero(Decimal v, int digits) =>
    v.roundAwayFromZero(digits);
Decimal _ceil(Decimal v, int digits) => v.ceil(digits);

/// The same six, in the short family.
const _shortRounding = <String, ShortDecimal Function(ShortDecimal, int)>{
  'half_even': _shortRoundToEven,
  'half_up': _shortRound,
  'floor': _shortFloor,
  'down': _shortTruncate,
  'up': _shortRoundAwayFromZero,
  'ceiling': _shortCeil,
};

ShortDecimal _shortRoundToEven(ShortDecimal v, int digits) =>
    v.roundToEven(digits);
ShortDecimal _shortRound(ShortDecimal v, int digits) => v.round(digits);
ShortDecimal _shortFloor(ShortDecimal v, int digits) => v.floor(digits);
ShortDecimal _shortTruncate(ShortDecimal v, int digits) => v.truncate(digits);
ShortDecimal _shortRoundAwayFromZero(ShortDecimal v, int digits) =>
    v.roundAwayFromZero(digits);
ShortDecimal _shortCeil(ShortDecimal v, int digits) => v.ceil(digits);

/// The operations we answer, by their GDA name.
const _operations = <String>{
  'add',
  'subtract',
  'multiply',
  'divide',
  'divideint',
  'remainder',
  'compare',
  'power',
  'abs',
  'plus',
  'minus',
  'quantize',
  'tointegralx',
  'tointegral',
};

/// The two whose whole job is to round, so a rounded answer is no obstacle.
const _roundingOperations = <String>{'quantize', 'tointegralx', 'tointegral'};

/// Anything past this in an exponent we do not try to build.
const _exponentLimit = 1000000;

class _Run {
  final failures = <String>[];
  final skipped = <_Skip, int>{};
  final okByOperation = <String, int>{};
  final okByRounding = <String, int>{};
  final shortFailures = <String>[];
  int shortSkipped = 0;
  int shortOk = 0;
  int total = 0;

  void file(File file) {
    var rounding = 'half_up';

    for (final raw in file.readAsLinesSync()) {
      final line = _stripComment(raw).trim();
      if (line.isEmpty) {
        continue;
      }

      final directive = _directive(line);
      if (directive != null) {
        if (directive.$1 == 'rounding') {
          rounding = directive.$2;
        }
        continue;
      }

      final test = _Case.parse(line, rounding);
      if (test != null) {
        _one(test);
      }
    }
  }

  void _one(_Case test) {
    total++;

    final skip = test.skip();
    if (skip != null) {
      skipped.update(skip, (n) => n + 1, ifAbsent: () => 1);

      return;
    }

    final String answer;
    try {
      answer = test.run();
    } on _Inapplicable catch (e) {
      skipped.update(e.reason, (n) => n + 1, ifAbsent: () => 1);

      return;
    } on Object catch (e) {
      failures.add('${test.id}: threw ${e.runtimeType}: $e');

      return;
    }

    if (answer == _agreed) {
      okByOperation.update(test.operation, (n) => n + 1, ifAbsent: () => 1);
      if (_roundingOperations.contains(test.operation)) {
        okByRounding.update(test.rounding, (n) => n + 1, ifAbsent: () => 1);
      }
    } else {
      failures.add('${test.id}: $answer');

      return;
    }

    _short(test);
  }

  /// The same case again, in the short family, when it fits there.
  void _short(_Case test) {
    final String answer;
    try {
      answer = test.runShort();
    } on _Inapplicable {
      shortSkipped++;

      return;
    } on Object catch (e) {
      shortFailures.add('${test.id}: threw ${e.runtimeType}: $e');

      return;
    }

    if (answer == _agreed) {
      shortOk++;
    } else {
      shortFailures.add('${test.id}: $answer');
    }
  }

  void report() {
    final ok = okByOperation.values.fold(0, (a, b) => a + b);
    final skips = skipped.values.fold(0, (a, b) => a + b);

    print('Cases in the suite: $total');
    print('Applicable and run: ${ok + failures.length}');
    print('Agreed:             $ok');
    print('Disagreed:          ${failures.length}');
    print('');

    print('By operation:');
    _table(okByOperation);
    print('');

    print('By rounding mode, over the operations that round:');
    _table(okByRounding);
    print('');

    print('Short family, over the same cases:');
    print('  ${shortOk.toString().padLeft(6)}  agreed');
    print('  ${shortFailures.length.toString().padLeft(6)}  disagreed');
    print('  ${shortSkipped.toString().padLeft(6)}  did not fit an int');
    print('');

    print('Not run ($skips):');
    final reasons = skipped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in reasons) {
      final count = entry.value.toString().padLeft(6);
      print('  $count  ${entry.key.explanation}');
    }

    if (shortFailures.isNotEmpty) {
      print('');
      print('Short family disagreements — an overflow is by design, a wrong');
      print('answer that fits is not; both need reading:');
      for (final failure in shortFailures.take(40)) {
        print('  $failure');
      }
      if (shortFailures.length > 40) {
        print('  ... and ${shortFailures.length - 40} more');
      }
    }

    if (failures.isNotEmpty) {
      print('');
      print('Disagreements, by shape:');
      final shapes = <String, List<String>>{};
      for (final failure in failures) {
        final shape = failure.replaceAll(RegExp('[0-9]+'), 'N');
        shapes.putIfAbsent(shape, () => <String>[]).add(failure);
      }
      final byCount = shapes.entries.toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));
      for (final shape in byCount) {
        print('  ${shape.value.length.toString().padLeft(6)}  '
            '${shape.value.first}');
      }
    }
  }

  void _table(Map<String, int> counts) {
    final rows = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final row in rows) {
      print('  ${row.value.toString().padLeft(6)}  ${row.key}');
    }
  }
}

/// The answer a case gives when it agrees; anything else describes the gap.
const _agreed = '';

/// Thrown when a case turns out not to apply only once we start running it.
class _Inapplicable implements Exception {
  _Inapplicable(this.reason);

  final _Skip reason;
}

class _Case {
  _Case({
    required this.id,
    required this.operation,
    required this.operands,
    required this.expected,
    required this.conditions,
    required this.rounding,
  });

  /// Parses one line, or returns null if it is not a test case.
  static _Case? parse(String line, String rounding) {
    final tokens = _tokens(line);
    final arrow = tokens.indexOf('->');
    if (arrow < 2 || arrow + 1 >= tokens.length) {
      return null;
    }

    return _Case(
      id: tokens[0],
      operation: tokens[1].toLowerCase(),
      operands: tokens.sublist(2, arrow),
      expected: tokens[arrow + 1],
      conditions: tokens.sublist(arrow + 2).map((c) => c.toLowerCase()).toSet(),
      rounding: rounding,
    );
  }

  final String id;
  final String operation;
  final List<String> operands;
  final String expected;
  final Set<String> conditions;
  final String rounding;

  /// Why this case does not apply, or null if it does.
  _Skip? skip() {
    if (!_operations.contains(operation)) {
      return _Skip.operation;
    }

    for (final value in [...operands, expected]) {
      if (value.contains('#')) {
        return _Skip.encoded;
      }
      if (_isSpecial(value)) {
        return _Skip.special;
      }
      if (_hasTrailingPoint(value)) {
        return _Skip.spelling;
      }
      if (_exponentOf(value).abs() > _exponentLimit) {
        return _Skip.hugeExponent;
      }
    }

    final rounded =
        conditions.contains('rounded') || conditions.contains('inexact');
    if (rounded && !_roundingOperations.contains(operation)) {
      return _Skip.contextRounded;
    }

    if (_roundingOperations.contains(operation) &&
        !_rounding.containsKey(rounding)) {
      return _Skip.rounding;
    }

    return null;
  }

  /// Runs the case; returns [_agreed], or a description of the disagreement.
  String run() {
    final values = operands.map(Decimal.parse).toList(growable: false);

    if (operation == 'compare') {
      final actual = values[0].compareTo(values[1]).sign;
      final want = int.parse(expected);

      return actual == want ? _agreed : 'compare gave $actual, wanted $want';
    }

    if (operation == 'divideint') {
      final actual = Decimal.fromBigInt(values[0] ~/ values[1]);

      return _same(actual);
    }

    final Decimal actual;
    switch (operation) {
      case 'add':
        actual = values[0] + values[1];
      case 'subtract':
        actual = values[0] - values[1];
      case 'multiply':
        actual = values[0] * values[1];
      case 'divide':
        final quotient = values[0].divideOrNull(values[1]);
        if (quotient == null) {
          throw _Inapplicable(_Skip.inexactDivide);
        }
        actual = quotient;
      case 'remainder':
        actual = values[0].remainder(values[1]);
      case 'power':
        actual = values[0].pow(_integerPower(operands[1]));
      case 'abs':
        actual = values[0].abs();
      case 'plus':
        actual = values[0];
      case 'minus':
        actual = -values[0];
      case 'quantize':
        actual =
            _rounding[rounding]!(values[0], -_writtenExponent(operands[1]));
      default:
        actual = _rounding[rounding]!(values[0], 0);
    }

    return _same(actual);
  }

  /// The exponent of a `power` case, or [_Inapplicable] if it is not one.
  int _integerPower(String exponent) {
    final written = _writtenExponent(exponent);
    final digits = exponent.replaceAll(RegExp('[eE].*'), '');
    if (written != 0 || digits.contains('.')) {
      throw _Inapplicable(_Skip.power);
    }

    final n = int.tryParse(digits);
    if (n == null || n.abs() > 1000000) {
      throw _Inapplicable(_Skip.power);
    }

    return n;
  }

  /// Runs the case again in the short family.
  ///
  /// Both the operands and the answer have to fit an int: an overflow inside
  /// is silent by design, and a case whose answer needs more than a machine
  /// word would be measuring that rather than the arithmetic.
  String runShort() {
    final values = <ShortDecimal>[];
    for (final operand in operands) {
      final value = Decimal.parse(operand).toShortDecimalOrNull();
      if (value == null) {
        throw _Inapplicable(_Skip.shortTooBig);
      }
      values.add(value);
    }

    if (operation == 'compare') {
      final actual = values[0].compareTo(values[1]).sign;
      final want = int.parse(expected);

      return actual == want
          ? _agreed
          : 'short compare gave $actual, wanted $want';
    }

    final want = Decimal.parse(expected).toShortDecimalOrNull();
    if (want == null) {
      throw _Inapplicable(_Skip.shortTooBig);
    }

    final ShortDecimal actual;
    switch (operation) {
      case 'add':
        actual = values[0] + values[1];
      case 'subtract':
        actual = values[0] - values[1];
      case 'multiply':
        actual = values[0] * values[1];
      case 'divide':
        final quotient = values[0].divideOrNull(values[1]);
        if (quotient == null) {
          throw _Inapplicable(_Skip.inexactDivide);
        }
        actual = quotient;
      case 'divideint':
        actual = ShortDecimal(values[0] ~/ values[1]);
      case 'remainder':
        actual = values[0].remainder(values[1]);
      case 'power':
        actual = values[0].pow(_integerPower(operands[1]));
      case 'abs':
        actual = values[0].abs();
      case 'plus':
        actual = values[0];
      case 'minus':
        actual = -values[0];
      case 'quantize':
        actual = _shortRounding[rounding]!(
          values[0],
          -_writtenExponent(operands[1]),
        );
      default:
        actual = _shortRounding[rounding]!(values[0], 0);
    }

    return actual == want
        ? _agreed
        : 'short $operation gave ${_brief(actual)}, wanted ${_brief(want)}';
  }

  /// Compares by value, not by spelling.
  ///
  /// GDA keeps trailing zeros — `2.50 + 0.50` is `3.00` there — and we hold
  /// the canonical form, so `3.00 == 3` is the agreement we want.
  String _same(Decimal actual) {
    final want = Decimal.parse(expected);
    if (actual == want) {
      return _agreed;
    }

    return '$operation gave ${_brief(actual)}, wanted ${_brief(want)}';
  }
}

/// A value cut down for a message: some of these are a million digits long.
String _brief(Object value) {
  final text = value.toString();

  return text.length <= 60 ? text : '${text.substring(0, 57)}...';
}

/// Whether the digits end with a point, as in `0.` or `2.E-3`.
///
/// GDA allows that spelling and so does `double.parse`, and we refuse it: a
/// point here has to be followed by digits, which is why `.5` is a number and
/// `5.` is not. That is a decision, taken before this script existed and held
/// by both families — see the group named for it in
/// `test/competitors_test.dart`. These cases are counted, not silently
/// dropped, so that the day the decision changes the count says so.
bool _hasTrailingPoint(String value) {
  final at = value.indexOf(RegExp('[eE]'));
  final digits = at < 0 ? value : value.substring(0, at);

  return digits.endsWith('.');
}

bool _isSpecial(String value) {
  final lower = value.toLowerCase();

  return lower.contains('nan') ||
      lower.contains('inf') ||
      lower.startsWith('#') ||
      lower.contains('?');
}

/// The exponent written after `e`, or zero if there is none.
int _exponentOf(String value) {
  final at = value.indexOf(RegExp('[eE]'));

  return at < 0 ? 0 : int.tryParse(value.substring(at + 1)) ?? 0;
}

/// How many digits a literal keeps after the point, exponent included.
///
/// Written, not canonical: `1e+2` asks for hundreds, and the parsed value
/// would no longer say so.
int _writtenExponent(String value) {
  final exponent = _exponentOf(value);
  final at = value.indexOf(RegExp('[eE]'));
  final digits = at < 0 ? value : value.substring(0, at);
  final point = digits.indexOf('.');
  final fraction = point < 0 ? 0 : digits.length - point - 1;

  return exponent - fraction;
}

/// Splits a line into tokens, leaving quoted values whole.
List<String> _tokens(String line) {
  final tokens = <String>[];
  final buffer = StringBuffer();
  String? quote;
  var started = false;

  for (var i = 0; i < line.length; i++) {
    final char = line[i];

    if (quote != null) {
      if (char == quote) {
        quote = null;
      } else {
        buffer.write(char);
      }
      continue;
    }

    if (char == "'" || char == '"') {
      quote = char;
      started = true;
      continue;
    }

    if (char == ' ' || char == '\t') {
      if (started) {
        tokens.add(buffer.toString());
        buffer.clear();
        started = false;
      }
      continue;
    }

    buffer.write(char);
    started = true;
  }

  if (started) {
    tokens.add(buffer.toString());
  }

  return tokens;
}

/// Everything from an unquoted `--` to the end of the line is a comment.
String _stripComment(String line) {
  String? quote;

  for (var i = 0; i < line.length - 1; i++) {
    final char = line[i];

    if (quote != null) {
      if (char == quote) {
        quote = null;
      }
      continue;
    }

    if (char == "'" || char == '"') {
      quote = char;
      continue;
    }

    if (char == '-' && line[i + 1] == '-') {
      return line.substring(0, i);
    }
  }

  return line;
}

/// A `name: value` line, or null if this is not one.
(String, String)? _directive(String line) {
  final colon = line.indexOf(':');
  if (colon <= 0) {
    return null;
  }

  final name = line.substring(0, colon).trim().toLowerCase();
  if (name.contains(' ')) {
    return null;
  }

  return (name, line.substring(colon + 1).trim().toLowerCase());
}
