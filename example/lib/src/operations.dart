enum Op {
  add('add', '+', 100),
  multiply('multiply', '*', 100),
  divide('divide', '/', 1000),
  divideAndView('divide-and-view', '/', 100),
  rawView('raw-view', null, 100),
  repeatView('repeat-view', null, 100),
  parse('parse', null, 100),
  compare('compare', null, 100),
  round('round', null, 100),
  toDouble('to-double', null, 100),
  toStringAsFixed('to-string-as-fixed', null, 100),
  unrepresentableDivide('unrepresentable-divide', '/', 100),
  unrepresentableDivideWide('unrepresentable-divide-wide', '/', 100);

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
