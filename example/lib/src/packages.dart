enum Package {
  decimal('decimal', 'Decimal'),
  decimalType('decimal_type', 'Decimal'),
  fixed('fixed', 'Fixed'),
  bigDecimal('big_decimal', 'BigDecimal'),
  decimals('decimals-decimal', 'Decimal', {'decimals'}),
  decimalsShort('decimals-short-decimal', 'ShortDecimal', {'decimals'}, true);

  final String id;
  final String type;
  final Set<String> tags;
  final bool excludeFromComparision;

  const Package(
    this.id,
    this.type, [
    this.tags = const {},
    this.excludeFromComparision = false,
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
