enum Op {
  add('add', '+', 100),
  multiply('multiply', '*', 100),
  divide('divide', '/', 1000),
  divideAndView('divide-and-view', '/', 100),
  rawView('raw-view', null, 100),
  preparedView('prepared-view', null, 100);

  final String id;
  final String? sign;
  final int numberOfCycles;

  const Op(this.id, this.sign, this.numberOfCycles);

  static Op? byId(String id) {
    for (final value in values) {
      if (value.id == id) return value;
    }

    return null;
  }
}
