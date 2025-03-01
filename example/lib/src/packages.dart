enum Package {
  decimal('decimal', 'Decimal'),
  decimalType('decimal_type', 'Decimal'),
  fixed('fixed', 'Fixed'),
  bigDecimal('big_decimal', 'BigDecimal'),
  yetAnotherDecimal(
    'yet_another_decimal-decimal',
    'Decimal',
    tags: {'yet_another_decimal'},
  ),
  yetAnotherDecimalShort(
    'yet_another_decimal-short-decimal',
    'ShortDecimal',
    tags: {'yet_another_decimal'},
    excludeFromComparision: true,
  ),
  bigDouble(
    'big_double',
    'BigDouble',
    excludeFromComparision: true,
    ignoreMatchingErrors: true,
  );

  final String id;
  final String type;
  final Set<String> tags;
  final bool excludeFromComparision;
  final bool ignoreMatchingErrors;

  const Package(
    this.id,
    this.type, {
    this.tags = const {},
    this.excludeFromComparision = false,
    this.ignoreMatchingErrors = false,
  });

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
