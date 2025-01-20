enum Package {
  decimal('decimal', 'Decimal'),
  decimalType('decimal_type', 'Decimal'),
  fixed('fixed', 'Fixed'),
  decimal2('decimal2-decimal', 'Decimal', 'decimal2'),
  decimal2Short('decimal2-short-decimal', 'ShortDecimal', 'decimal2');

  final String id;
  final String type;
  final String? group;

  const Package(this.id, this.type, [this.group]);

  static Package? byId(String id) {
    for (final value in values) {
      if (value.id == id) {
        return value;
      }
    }

    return null;
  }

  static List<Package> byGroup(String group) {
    final packages = <Package>[];

    for (final value in values) {
      if (value.group == group) {
        packages.add(value);
      }
    }

    return packages;
  }
}
