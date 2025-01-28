// ignore_for_file: lines_longer_than_80_chars, avoid_js_rounded_ints

import 'operations.dart';

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
  preparedViewBigInt(
    'prepared-view-big-int',
    Op.preparedView,
    'Convert prepared numbers to a readable format (BigInt version).',
    {'big-int', 'prepared-view'},
  ),
  preparedViewInt(
    'prepared-view-int',
    Op.preparedView,
    'Convert prepared numbers to a readable format (int version).',
    {'int', 'prepared-view'},
  ),
  preparedViewZerosBigInt(
    'prepared-view-zeros-big-int',
    Op.preparedView,
    'Convert prepared numbers with lots of leading and trailing zeros'
        '\n to a readable format (BigInt version).',
    {'big-int', 'prepared-view', 'prepared-view-zeros'},
  ),
  preparedViewZerosInt(
    'prepared-view-zeros-int',
    Op.preparedView,
    'Convert prepared numbers with lots of leading and trailing zeros'
        '\n to a readable format (int version).',
    {'int', 'prepared-view', 'prepared-view-zeros'},
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

      case Test.rawViewBigInt:
      case Test.preparedViewBigInt:
        const v = '123456789012345678901234567890123456789';
        final values = List<(BigInt, int)>.generate(
          20,
          (index) => (BigInt.parse(v), index * 2),
          growable: false,
        );
        final result = <String>[
          v,
          for (var i = 1; i < 20; i++)
            '${v.substring(0, 39 - i * 2)}.${v.substring(39 - i * 2, v.length)}',
        ];

        return (
          bigIntValues: values,
          intValues: null,
          result: result,
        );

      case Test.rawViewInt:
      case Test.preparedViewInt:
        final values = List<(int, int)>.generate(
          19,
          (index) => (1234567890123456789, index),
          growable: false,
        );
        const v = '1234567890123456789';
        final result = <String>[
          v,
          for (var i = 1; i < 19; i++)
            '${v.substring(0, 19 - i)}.${v.substring(19 - i, v.length)}',
        ];

        return (
          bigIntValues: bigIntValuesFromIntValues(values),
          intValues: values,
          result: result,
        );

      case Test.rawViewZerosBigInt:
      case Test.preparedViewZerosBigInt:
        final values = List<(BigInt, int)>.generate(
          20,
          (index) => (
            BigInt.parse('100000000000000000000000000000000000000'),
            index * 4
          ),
          growable: false,
        );
        final result = <String>[
          for (var i = 0; i < 10; i++) '1${'0' * ((9 - i) * 4 + 2)}',
          for (var i = 0; i < 10; i++) '0.${'0' * (i * 4 + 1)}1',
        ];

        return (
          bigIntValues: values,
          intValues: null,
          result: result,
        );

      case Test.rawViewZerosInt:
      case Test.preparedViewZerosInt:
        final values = List<(int, int)>.generate(
          20,
          (index) => (1000000000000000000, index * 2 - 1),
          growable: false,
        );
        final result = <String>[
          for (var i = 0; i < 10; i++) '1${'0' * ((9 - i) * 2 + 1)}',
          for (var i = 0; i < 10; i++) '0.${'0' * (i * 2)}1',
        ];

        return (
          bigIntValues: bigIntValuesFromIntValues(values),
          intValues: values,
          result: result,
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
