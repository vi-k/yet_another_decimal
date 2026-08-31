import 'dart:io';

import 'package:ansi_escape_codes/ansi_escape_codes.dart';
import 'package:example/benchmark.dart';

void printUsage() {
  print(
    'Usage:'
    ' ${accent('dart benchmark.dart')}'
    ' [${accent('-')}]${accent('tag')}'
    ' [${accent('-')}]${accent('tag')} …',
  );

  print('\nWhere tag:$reset\n');

  print('${accent('all')} - all packages and all tests');

  print('');
  print('Options:');
  print(
    '${accent('--runs=N')} - measure every benchmark N times'
    ' and take the median (default: $defaultRuns)',
  );
  print(
    '${accent('--passes=N')} - sweep every test N times and take the best'
    ' of the passes (default: $defaultPasses)',
  );
  print(
    '${accent('--check')} - check the answers and measure nothing;'
    ' exits non-zero if a package answers wrongly',
  );

  print('\nPackages:');
  for (final package in Package.values) {
    final tags = package.tags;
    print(
      '${accent(package.id)}'
      '${tags.isEmpty ? '' : ' (tags: ${tags.map(faintAccent).join(', ')})'}',
    );
  }

  print('');
  print('Tests:');
  for (final test in Test.values) {
    final tags = test.tags;
    print(
      '${accent(test.id)}'
      ' (tags: ${tags.map(faintAccent).join(', ')})',
    );
  }

  print('');
  print('Examples:');

  print('');
  print('All packages and all tests:');
  print('> ${accent('dart benchmark.dart all')}');

  print('');
  print('Test "divide" for all packages');
  print('> ${accent('dart benchmark.dart divide')}');

  print('');
  print('All tests for all packages excluding "denary"');
  print('> ${accent('dart benchmark.dart -denary')}');

  print('');
  print('Check every answer without measuring anything:');
  print('> ${accent('dart benchmark.dart all --check')}');

  print('');
  print('All packages and all tests, one run instead of a series:');
  print('> ${accent('dart benchmark.dart all --runs=1')}');

  print('');
  print('Numbers worth quoting: two passes over the whole set');
  print('> ${accent('dart benchmark.dart all --passes=2')}');
}

void main(List<String> arguments) {
  runZonedPrinter(
    defaultStyle: const Style(
      foreground: defaultFg,
    ),
    () {
      if (arguments.isEmpty ||
          arguments.isNotEmpty && arguments[0] == '--help') {
        printUsage();
        return;
      }

      var runs = defaultRuns;
      var passes = defaultPasses;
      var check = false;
      final includePackages = <Package>{};
      final excludePackages = <Package>{};
      final includeTests = <Test>{};
      final excludeTests = <Test>{};

      for (final arg in arguments) {
        switch (arg) {
          case 'all':
            includePackages.addAll(Package.values);
            includeTests.addAll(Test.values);

          case '--check':
            check = true;

          case final String a when a.startsWith('--runs='):
            final value = int.tryParse(a.substring('--runs='.length));
            if (value == null || value < 1) {
              print('${error('Not a number of runs:')} ${accentError(arg)}');
              print('');
              printUsage();
              return;
            }
            runs = value;

          case final String a when a.startsWith('--passes='):
            final value = int.tryParse(a.substring('--passes='.length));
            if (value == null || value < 1) {
              print('${error('Not a number of passes:')} ${accentError(arg)}');
              print('');
              printUsage();
              return;
            }
            passes = value;

          default:
            final exclude = arg.startsWith('-');
            final tag = exclude ? arg.substring(1) : arg;
            var ok = false;

            final package = Package.byId(tag);
            if (package != null) {
              exclude
                  ? excludePackages.add(package)
                  : includePackages.add(package);
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
              print('${error('Unknown argument:')} ${accentError(arg)}');
              print('');
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

      if (!run(
        packages: packages,
        tests: tests,
        runs: runs,
        passes: passes,
        check: check,
      )) {
        exitCode = 1;
      }
    },
  );
}
