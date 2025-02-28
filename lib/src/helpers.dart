extension BigIntInternals on BigInt {
  // https://github.com/dart-lang/sdk/issues/46180
  BigInt fastGcd(BigInt other) {
    var gcd = this;
    while (other != BigInt.zero) {
      final tmp = other;
      other = gcd % other;
      gcd = tmp;
    }

    return gcd.abs();
  }
}

extension IntInternals on int {
  int fastGcd(int other) {
    var gcd = this;
    while (other != 0) {
      final tmp = other;
      other = gcd % other;
      gcd = tmp;
    }

    return gcd.abs();
  }
}

extension StringInternals on String {
  (String, String) splitByIndex(int index) =>
      (substring(0, index), substring(index));
}
