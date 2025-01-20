import 'operations.dart';

enum Test {
  addBigInt('add-big-int', Op.add),
  addInt('add-int', Op.add),
  multiplyBigInt('multiply-big-int', Op.multiply),
  multiplyInt('multiply-int', Op.multiply),
  divideBigInt('divide-big-int', Op.divide),
  divideInt('divide-int', Op.divide),
  convertToStringBigInt('to-string-big-int', Op.convertToString),
  convertToStringInt('to-string-int', Op.convertToString);

  final String id;
  final Op operation;

  const Test(this.id, this.operation);

  static Test? byId(String id) {
    for (final value in values) {
      if (value.id == id) return value;
    }

    return null;
  }

  static List<Test> byOperation(String operation) {
    final packages = <Test>[];

    for (final value in values) {
      if (value.operation.id == operation) {
        packages.add(value);
      }
    }

    return packages;
  }
}
