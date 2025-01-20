enum Op {
  add('add', 10),
  multiply('multiply', 100),
  divide('divide', 100),
  convertToString('to-string', 10);

  final String id;
  final int numberOfCycles;

  const Op(this.id, this.numberOfCycles);

  static Op? byId(String id) {
    for (final value in values) {
      if (value.id == id) return value;
    }

    return null;
  }
}
