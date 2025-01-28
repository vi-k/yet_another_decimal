enum Package {
  decimal('decimal', 'Decimal'),
  decimalType('decimal_type', 'Decimal'),
  fixed('fixed', 'Fixed'),
  bigDecimal('big_decimal', 'BigDecimal'),
  decimal2('decimal2-decimal', 'Decimal', {'decimal2'}),
  decimal2Short('decimal2-short-decimal', 'ShortDecimal', {'decimal2'}, true);

  final String id;
  final String type;
  final Set<String> tags;
  final bool excludeFromWinners;

  const Package(
    this.id,
    this.type, [
    this.tags = const {},
    this.excludeFromWinners = false,
  ]);

  static Package? byId(String id) {
    for (final value in values) {
      if (value.id == id) {
        return value;
      }
    }

    return null;
  }

  static List<Package> byTag(String tag) {
    final packages = <Package>[];

    for (final value in values) {
      if (value.tags.contains(tag)) {
        packages.add(value);
      }
    }

    return packages;
  }
}
