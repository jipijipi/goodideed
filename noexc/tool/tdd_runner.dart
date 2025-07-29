#!/usr/bin/env dart

import 'dart:io';
import 'dart:async';

/// Streamlined test runner for TDD workflows
/// Reduces verbosity and focuses on essential test results only
void main(List<String> args) async {
  final runner = TDDTestRunner();
  await runner.run(args);
}

class TDDTestRunner {
  static const String version = '1.0.0';

  Future<void> run(List<String> args) async {
    if (args.contains('--help') || args.contains('-h')) {
      _printHelp();
      return;
    }

    if (args.contains('--version') || args.contains('-v')) {
      print('TDD Test Runner v$version');
      return;
    }

    final config = _parseArgs(args);
    await _runTests(config);
  }

  TestConfig _parseArgs(List<String> args) {
    final config = TestConfig();

    for (int i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--quiet':
        case '-q':
          config.quiet = true;
          break;
        case '--verbose':
          config.verbose = true;
          break;
        case '--watch':
        case '-w':
          config.watch = true;
          break;
        case '--file':
        case '-f':
          if (i + 1 < args.length) {
            config.testFile = args[++i];
          }
          break;
        case '--name':
        case '-n':
          if (i + 1 < args.length) {
            config.testName = args[++i];
          }
          break;
        case '--tag':
        case '-t':
          if (i + 1 < args.length) {
            config.tags.add(args[++i]);
          }
          break;
        case '--concurrency':
        case '-j':
          if (i + 1 < args.length) {
            config.concurrency = int.tryParse(args[++i]) ?? 4;
          }
          break;
        default:
          // Treat as test path if it doesn't start with -
          if (!args[i].startsWith('-')) {
            config.testPath = args[i];
          }
          break;
      }
    }

    return config;
  }

  Future<void> _runTests(TestConfig config) async {
    final testArgs = _buildTestCommand(config);
    
    if (!config.quiet) {
      print('🧪 Running tests with minimal output...');
      if (config.testFile != null) {
        print('📁 File: ${config.testFile}');
      }
      if (config.testName != null) {
        print('🎯 Pattern: ${config.testName}');
      }
      print('');
    }

    final process = await Process.start(
      'flutter',
      testArgs,
      mode: ProcessStartMode.normal,
    );

    final completer = Completer<int>();
    
    // Handle stdout with filtering
    process.stdout
        .transform(const SystemEncoding().decoder)
        .listen((data) {
      _handleOutput(data, config);
    });

    // Handle stderr
    process.stderr
        .transform(const SystemEncoding().decoder)
        .listen((data) {
      if (!config.quiet || data.contains('FAILED') || data.contains('ERROR')) {
        stderr.write(data);
      }
    });

    process.exitCode.then((exitCode) {
      completer.complete(exitCode);
    });

    final exitCode = await completer.future;
    
    if (!config.quiet) {
      if (exitCode == 0) {
        print('\n✅ All tests passed!');
      } else {
        print('\n❌ Some tests failed (exit code: $exitCode)');
      }
    }

    exit(exitCode);
  }

  List<String> _buildTestCommand(TestConfig config) {
    final args = ['test'];

    // Add quiet flags for minimal output
    if (config.quiet || !config.verbose) {
      args.addAll(['--reporter', 'compact']);
    }

    // Add concurrency
    args.addAll(['--concurrency', config.concurrency.toString()]);

    // Add test path or file
    if (config.testFile != null) {
      args.add(config.testFile!);
    } else if (config.testPath != null) {
      args.add(config.testPath!);
    }

    // Add name pattern
    if (config.testName != null) {
      args.addAll(['--name', config.testName!]);
    }

    // Add tags
    for (final tag in config.tags) {
      args.addAll(['--tags', tag]);
    }

    return args;
  }

  void _handleOutput(String data, TestConfig config) {
    if (config.quiet) {
      // In quiet mode, only show test results and failures
      final lines = data.split('\n');
      for (final line in lines) {
        if (_isImportantLine(line)) {
          print(line);
        }
      }
    } else if (config.verbose) {
      // In verbose mode, show everything
      stdout.write(data);
    } else {
      // In normal mode, filter out compilation noise
      final lines = data.split('\n');
      for (final line in lines) {
        if (_shouldShowLine(line)) {
          print(line);
        }
      }
    }
  }

  bool _isImportantLine(String line) {
    // Only show test results, failures, and summary
    return line.contains('PASSED') ||
           line.contains('FAILED') ||
           line.contains('ERROR') ||
           line.contains('All tests passed') ||
           line.contains('Some tests failed') ||
           line.contains('tests passed') ||
           line.contains('tests failed') ||
           line.startsWith('✓') ||
           line.startsWith('✗') ||
           line.startsWith('❌') ||
           line.startsWith('✅');
  }

  bool _shouldShowLine(String line) {
    // Filter out compilation and framework overhead
    if (line.contains('executing:') ||
        line.contains('Exit code') ||
        line.contains('Found plugin') ||
        line.contains('Artifact Instance') ||
        line.contains('Skipping pub get') ||
        line.contains('Generating') ||
        line.contains('Compiling') ||
        line.contains('flutter_test_compiler') ||
        line.contains('Listening to compiler') ||
        line.contains('Runtime for phase') ||
        line.contains('Deleting') ||
        line.contains('killing pid') ||
        line.startsWith('[') && line.contains('ms]')) {
      return false;
    }

    return true;
  }

  void _printHelp() {
    print('''
TDD Test Runner v$version - Streamlined testing for Test-Driven Development

USAGE:
    dart tool/tdd_runner.dart [OPTIONS] [TEST_PATH]

OPTIONS:
    -q, --quiet          Minimal output - only show pass/fail results
    -v, --verbose        Show full output (overrides --quiet)
    -w, --watch          Watch mode (not implemented yet)
    -f, --file <FILE>    Run specific test file
    -n, --name <NAME>    Run tests matching name pattern
    -t, --tag <TAG>      Run tests with specific tag
    -j, --concurrency <N> Set concurrency level (default: 4)
    -h, --help           Show this help message
    --version            Show version information

EXAMPLES:
    # Quick TDD - minimal output
    dart tool/tdd_runner.dart --quiet test/services/logger_service_test.dart

    # Run specific test by name
    dart tool/tdd_runner.dart --name "should handle errors"

    # Run tagged tests
    dart tool/tdd_runner.dart --tag tdd

    # Run directory with minimal output
    dart tool/tdd_runner.dart --quiet test/models/

    # Verbose mode for debugging
    dart tool/tdd_runner.dart --verbose test/services/
''');
  }
}

class TestConfig {
  bool quiet = false;
  bool verbose = false;
  bool watch = false;
  String? testFile;
  String? testPath;
  String? testName;
  List<String> tags = [];
  int concurrency = 4;
}