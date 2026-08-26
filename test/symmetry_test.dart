/// Симметрия двух семейств.
///
/// Интерфейс `FixedPoint` держит вместе то, что можно выразить типами:
/// экземплярные члены с совпадающими сигнатурами. Он не покрывает статику —
/// конструкторы, `parse`, `tryParse`, константы — и члены, у которых типы в
/// семействах разные. Их держит этот тест.
///
/// Расхождения не запрещены. Они обязаны быть **перечислены**: список ниже и
/// есть тот самый «осознанный», который иначе живёт в чьей-то голове.
library;

import 'dart:io';

import 'package:test/test.dart';

/// Осознанные расхождения по составу: член есть у одного семейства и нет у
/// другого.
const _knownDivergences = <String, String>{
  'fromBigInt': 'Decimal строится из BigInt, ShortDecimal — из int',
  'конструктор: shiftLeft':
      'у ShortDecimal сдвиг влево — параметр '
      'конструктора, у Decimal только оператор <<',
  'optimize':
      'ленивая нормализация есть только у Decimal: '
      'у ShortDecimal она немедленная',
};

/// Осознанные расхождения по типу: член есть у обоих, но типы разные.
///
/// Этот тест сверяет имена и такое поймать не может — и `FixedPoint` тоже: он
/// самоограничен по `T`, а эти члены возвращают типы, у которых общего
/// супертипа нет. Список здесь для того, чтобы расхождение было записано хоть
/// где-то.
const _typeDivergences = <String, String>{
  'inverse': 'Fraction против ShortFraction',
  'divideToFraction': 'Fraction против ShortFraction',
  'divideWithRemainder': 'Division против ShortDivision',
  'operator ~/': 'BigInt против int',
};

/// Публичные члены класса из его исходника.
///
/// Разбор регуляркой, а не через `dart:mirrors`: зависимость ради одного
/// теста дороже, чем несколько правил ниже. Чтобы разбор не «сошёлся» молча на
/// пустых множествах, есть отдельный тест на само извлечение.
Set<String> _members(String path, String className) {
  final source = File(path).readAsLinesSync();
  final members = <String>{};
  var inside = false;

  for (final line in source) {
    if (line.startsWith('final class $className')) {
      inside = true;
      continue;
    }
    if (inside && line.startsWith('}')) {
      break;
    }
    if (!inside || !line.startsWith('  ') || line.startsWith('   ')) {
      continue;
    }

    final trimmed = line.trim();
    if (trimmed.isEmpty ||
        trimmed.startsWith('//') ||
        trimmed.startsWith('@') ||
        trimmed.startsWith('return ') ||
        trimmed.startsWith('}')) {
      continue;
    }

    members.addAll(_namesOf(trimmed, className));
  }

  return members..removeWhere((name) => name.startsWith('_'));
}

/// Имена, которые объявляет строка.
Set<String> _namesOf(String line, String className) {
  // Именованный конструктор — только в начале строки, иначе `Decimal._asIs`
  // внутри тела съел бы объявление самого метода.
  final named = RegExp('^(?:factory )?$className\\.(\\w+)').firstMatch(line);
  if (named != null) {
    return {named.group(1)!};
  }

  // Безымянный конструктор: имя у семейств разное, поэтому оно нормализуется,
  // а различаются они именованными параметрами — там и живёт `shiftLeft`.
  final unnamed = RegExp('^(?:factory )?$className\\(').firstMatch(line);
  if (unnamed != null) {
    final parameters = RegExp(r'\{([^}]*)\}').firstMatch(line);

    return {
      'конструктор',
      if (parameters != null)
        for (final match in RegExp(
          r'(\w+)\s*=',
        ).allMatches(parameters.group(1)!))
          'конструктор: ${match.group(1)}',
    };
  }

  final operator = RegExp(r'\boperator\s+(\S+)\s*\(').firstMatch(line);
  if (operator != null) {
    return {'operator ${operator.group(1)}'};
  }

  final getter = RegExp(r'\bget\s+(\w+)').firstMatch(line);
  if (getter != null) {
    return {getter.group(1)!};
  }

  // Метод или поле: имя стоит вплотную к `(`, `=` или `;`. Пробел перед
  // скобкой не допускается нарочно — иначе `static (BigInt, int) …` даёт
  // «static».
  final member = RegExp(r'(\w+)(?=\(|\s*=|\s*;)').firstMatch(line);

  return member == null ? const {} : {member.group(1)!};
}

void main() {
  group('наборы публичных членов совпадают', () {
    final wide = _members('lib/src/decimal/decimal.dart', 'Decimal');
    final short = _members(
      'lib/src/short_decimal/short_decimal.dart',
      'ShortDecimal',
    );

    test('извлечение вообще работает', () {
      // Если регулярка перестанет что-то ловить, тест обязан упасть здесь,
      // а не «сойтись» на двух пустых множествах.
      expect(wide, contains('parse'));
      expect(wide, contains('toStringAsFixed'));
      expect(wide, contains('operator +'));
      expect(wide.length, greaterThan(30));
      expect(short.length, greaterThan(30));
    });

    test('у ShortDecimal нет ничего лишнего', () {
      final extra = short.difference(wide)..removeAll(_knownDivergences.keys);
      expect(extra, isEmpty, reason: 'нет у Decimal и не объявлено осознанным');
    });

    test('у Decimal нет ничего лишнего', () {
      final extra = wide.difference(short)..removeAll(_knownDivergences.keys);
      expect(
        extra,
        isEmpty,
        reason: 'нет у ShortDecimal и не объявлено осознанным',
      );
    });

    test('расхождения по типу всё ещё существуют', () {
      // Если типы сойдутся, член переедет в FixedPoint, а запись отсюда
      // уйдёт. Пока — оба семейства обязаны такой член иметь.
      for (final name in _typeDivergences.keys) {
        expect(wide, contains(name), reason: name);
        expect(short, contains(name), reason: name);
      }
    });

    test('список расхождений не протух', () {
      final diverged = wide.difference(short).union(short.difference(wide));
      for (final name in _knownDivergences.keys) {
        expect(
          diverged,
          contains(name),
          reason:
              '$name числится расхождением, а семейства уже сошлись — '
              'вычеркнуть из списка',
        );
      }
    });
  });

  group('дроби', () {
    final wide = _members('lib/src/decimal/fraction.dart', 'Fraction');
    final short = _members(
      'lib/src/short_decimal/short_fraction.dart',
      'ShortFraction',
    );

    test('наборы совпадают', () {
      const known = {'toDecimal', 'toShortDecimal'};
      expect(wide.difference(short).difference(known), isEmpty);
      expect(short.difference(wide).difference(known), isEmpty);
    });
  });

  group('деление с остатком', () {
    final wide = _members('lib/src/decimal/division.dart', 'Division');
    final short = _members(
      'lib/src/short_decimal/short_division.dart',
      'ShortDivision',
    );

    test('наборы совпадают', () {
      expect(wide.difference(short), isEmpty);
      expect(short.difference(wide), isEmpty);
    });
  });
}
