import 'package:ansi_escape_codes/ansi_escape_codes.dart';
import 'package:decimal2/decimal2.dart';
import 'package:example/benchmark.dart';

void printUsage() {
  print(
    '${def}Usage:'
    ' ${accent}dart benchmark.dart'
    ' $def[$accent-$def]${accent}tag'
    ' $def[$accent-$def]${accent}tag$def ...$reset',
  );

  print('\n${def}Where tag:$reset\n');

  print('${accent}all$def (all packages and all tests)$reset');

  print('\n${def}Packages:$reset');
  for (final package in Package.values) {
    final tags = package.tags;
    print(
      '$accent${package.id}'
      '$def${tags.isEmpty ? '' : ' (tags: ${tags.join(', ')})'}'
      '$reset',
    );
  }

  print('\n${def}Tests:$reset');
  for (final test in Test.values) {
    final tags = test.tags;
    print(
      '$accent${test.id}'
      ' $def(tags: ${tags.join(', ')})$reset',
    );
  }

  print('\n${def}Examples:$reset');
  print('\n${def}All packages and all tests:$reset');
  print('$def> ${accent}dart benchmark.dart all$reset');
  print('\n${def}Test "divide" for all packages$reset');
  print('$def> ${accent}dart benchmark.dart divide$reset');
  print('\n${def}All tests for all packages excluding "decimal2"$reset');
  print('$def> ${accent}dart benchmark.dart -decimal2$reset');
}

void main(List<String> arguments) {
  final v = Decimal(1000000000000000000, shiftRight: 18);

  final sw = Stopwatch()..start();
  for (var i = 0; i < 10000000; i++) {
    v.toString();
  }
  sw.stop();
  print(sw.elapsed); // 0:00:02.406469

  sw
    ..reset()
    ..start();
  for (var i = 0; i < 10000000; i++) {
    // Это оптимизация, так как мы много раз используем одно и тоже значение.
    // Оптимизация выполнится только один раз. Остальное время мы вхолостую
    // будем запускать метод. В данном случае можно было бы выполнить
    // оптимизацию один раз до цикла.
    v.optimize();
    v.toString();
  }
  sw.stop();
  print(sw.elapsed); // 00:00:00.061205

  return;

  if (arguments.isEmpty || arguments.isNotEmpty && arguments[0] == '--help') {
    printUsage();
    return;
  }

  final includePackages = <Package>{};
  final excludePackages = <Package>{};
  final includeTests = <Test>{};
  final excludeTests = <Test>{};

  for (final arg in arguments) {
    switch (arg) {
      case 'all':
        includePackages.addAll(Package.values);
        includeTests.addAll(Test.values);

      default:
        final exclude = arg.startsWith('-');
        final tag = exclude ? arg.substring(1) : arg;
        var ok = false;

        final package = Package.byId(tag);
        if (package != null) {
          exclude ? excludePackages.add(package) : includePackages.add(package);
          ok = true;
        }

        final packagesByTag = Package.byTag(tag);
        if (packagesByTag.isNotEmpty) {
          exclude
              ? excludePackages.addAll(packagesByTag)
              : includePackages.addAll(packagesByTag);
          ok = true;
        }

        final test = Test.byId(tag);
        if (test != null) {
          exclude ? excludeTests.add(test) : includeTests.add(test);
          ok = true;
        }

        final testByTag = Test.byTag(tag);
        if (testByTag.isNotEmpty) {
          exclude
              ? excludeTests.addAll(testByTag)
              : includeTests.addAll(testByTag);
          ok = true;
        }

        if (!ok) {
          print('${error}Unknown argument: $accentError$arg$reset\n');
          printUsage();
          return;
        }
    }
  }

  if (includePackages.isEmpty) {
    includePackages.addAll(Package.values);
  }

  if (includeTests.isEmpty) {
    includeTests.addAll(Test.values);
  }

  final packages = includePackages.difference(excludePackages);
  final tests = includeTests.difference(excludeTests);

  run(
    packages: packages,
    tests: tests,
  );
}
