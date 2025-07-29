#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'dart:async';

/// Automated test analyzer for comprehensive failure analysis and grouping
/// Provides compact test execution with intelligent failure categorization
void main(List<String> args) async {
  final analyzer = TestAnalyzer();
  await analyzer.run(args);
}

class TestAnalyzer {
  static const String version = '1.0.0';
  
  Future<void> run(List<String> args) async {
    if (args.contains('--help') || args.contains('-h')) {
      _printHelp();
      return;
    }

    if (args.contains('--version')) {
      print('Test Analyzer v$version');
      return;
    }

    final config = _parseArgs(args);
    
    print('🧪 Test Analyzer v$version');
    print('📊 Running comprehensive test analysis...\n');
    
    // Run tests and collect results
    final results = await _runTestsWithAnalysis(config);
    
    // Analyze and report
    await _analyzeResults(results, config);
  }

  AnalyzerConfig _parseArgs(List<String> args) {
    final config = AnalyzerConfig();
    
    for (int i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--quick':
        case '-q':
          config.quickMode = true;
          break;
        case '--verbose':
        case '-v':
          config.verbose = true;
          break;
        case '--failures-only':
        case '-f':
          config.failuresOnly = true;
          break;
        case '--category':
        case '-c':
          if (i + 1 < args.length) {
            config.category = args[++i];
          }
          break;
        case '--output':
        case '-o':
          if (i + 1 < args.length) {
            config.outputFile = args[++i];
          }
          break;
        case '--parallel':
        case '-p':
          config.parallelMode = true;
          break;
      }
    }
    
    return config;
  }

  Future<TestResults> _runTestsWithAnalysis(AnalyzerConfig config) async {
    final results = TestResults();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final jsonFile = 'test_results_$timestamp.json';
    
    try {
      // Build test command
      final testArgs = _buildTestCommand(config, jsonFile);
      
      print('🚀 Executing: flutter ${testArgs.join(' ')}');
      if (config.verbose) {
        print('📄 JSON output: $jsonFile\n');
      }
      
      // Run tests
      final process = await Process.run('flutter', testArgs);
      results.exitCode = process.exitCode;
      results.stdout = process.stdout as String;
      results.stderr = process.stderr as String;
      
      // Parse JSON results if available
      final jsonFileObj = File(jsonFile);
      if (await jsonFileObj.exists()) {
        final jsonContent = await jsonFileObj.readAsString();
        results.jsonResults = _parseJsonResults(jsonContent);
        
        // Clean up temp file unless --output specified
        if (config.outputFile == null) {
          await jsonFileObj.delete();
        } else {
          await jsonFileObj.rename(config.outputFile!);
        }
      }
      
    } catch (e) {
      print('❌ Error running tests: $e');
      results.error = e.toString();
    }
    
    return results;
  }

  List<String> _buildTestCommand(AnalyzerConfig config, String jsonFile) {
    final args = ['test'];
    
    // Always use JSON reporter for analysis
    args.addAll(['--file-reporter', 'json:$jsonFile']);
    
    // Choose primary reporter based on config
    if (config.failuresOnly) {
      args.addAll(['--reporter', 'failures-only']);
    } else if (config.quickMode) {
      args.addAll(['--reporter', 'compact']);
    } else {
      args.addAll(['--reporter', 'expanded']);
    }
    
    // Add concurrency for performance
    if (config.parallelMode) {
      args.addAll(['--concurrency', '8']);
    } else {
      args.addAll(['--concurrency', '4']);
    }
    
    // Add category filter if specified
    if (config.category != null) {
      args.add('test/${config.category}/');
    }
    
    return args;
  }

  List<Map<String, dynamic>> _parseJsonResults(String jsonContent) {
    final results = <Map<String, dynamic>>[];
    
    for (final line in jsonContent.split('\n')) {
      if (line.trim().isEmpty) continue;
      
      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        results.add(json);
      } catch (e) {
        // Skip invalid JSON lines
      }
    }
    
    return results;
  }

  Future<void> _analyzeResults(TestResults results, AnalyzerConfig config) async {
    if (results.error != null) {
      print('❌ Analysis failed: ${results.error}');
      return;
    }
    
    print('📈 ANALYSIS RESULTS');
    print('═' * 50);
    
    // Basic stats
    _printBasicStats(results);
    
    // Detailed analysis if JSON available
    if (results.jsonResults.isNotEmpty) {
      print('\n📊 DETAILED BREAKDOWN');
      print('═' * 50);
      
      final analysis = _analyzeJsonResults(results.jsonResults);
      _printDetailedAnalysis(analysis, config);
      
      // Failure grouping
      if (analysis.failures.isNotEmpty) {
        print('\n🔍 FAILURE ANALYSIS');
        print('═' * 50);
        _printFailureAnalysis(analysis);
        
        print('\n🛠️  SUGGESTED FIX STRATEGY');
        print('═' * 50);
        _printFixStrategy(analysis);
      }
    }
    
    // Exit with appropriate code
    exit(results.exitCode);
  }

  void _printBasicStats(TestResults results) {
    print('Exit Code: ${results.exitCode}');
    
    if (results.exitCode == 0) {
      print('✅ Status: ALL TESTS PASSED');
    } else {
      print('❌ Status: SOME TESTS FAILED');
    }
    
    // Extract basic stats from stdout
    final stdout = results.stdout;
    if (stdout.contains('All tests passed!')) {
      final match = RegExp(r'(\d+) tests? passed').firstMatch(stdout);
      if (match != null) {
        print('📊 Total: ${match.group(1)} tests passed');
      }
    }
  }

  TestAnalysis _analyzeJsonResults(List<Map<String, dynamic>> jsonResults) {
    final analysis = TestAnalysis();
    
    for (final result in jsonResults) {
      final type = result['type'] as String?;
      
      switch (type) {
        case 'testStart':
          analysis.totalTests++;
          final testName = result['test']?['name'] as String? ?? 'unknown';
          final suitePath = result['test']?['root_url'] as String? ?? '';
          analysis.testsByCategory[_categorizeTest(suitePath)] = 
              (analysis.testsByCategory[_categorizeTest(suitePath)] ?? 0) + 1;
          break;
          
        case 'testDone':
          final testResult = result['result'] as String?;
          final testName = result['test']?['name'] as String? ?? 'unknown';
          final suitePath = result['test']?['root_url'] as String? ?? '';
          
          if (testResult == 'success') {
            analysis.passedTests++;
          } else if (testResult == 'failure') {
            analysis.failedTests++;
            analysis.failures.add(TestFailure(
              name: testName,
              category: _categorizeTest(suitePath),
              suitePath: suitePath,
              error: result['error'] as String? ?? 'Unknown error',
              stackTrace: result['stackTrace'] as String?,
            ));
          } else if (testResult == 'error') {
            analysis.errorTests++;
            analysis.failures.add(TestFailure(
              name: testName,
              category: _categorizeTest(suitePath),
              suitePath: suitePath,  
              error: result['error'] as String? ?? 'Unknown error',
              stackTrace: result['stackTrace'] as String?,
              isError: true,
            ));
          }
          break;
          
        case 'done':
          analysis.success = result['success'] as bool? ?? false;
          break;
      }
    }
    
    return analysis;
  }

  String _categorizeTest(String suitePath) {
    // Handle both suitePath and full file paths
    String testPath = suitePath;
    if (testPath.contains('/Users/')) {
      // Extract relative path from full path
      final testIndex = testPath.indexOf('/test/');
      if (testIndex != -1) {
        testPath = testPath.substring(testIndex + 1);
      }
    }
    
    if (testPath.contains('test/services/')) return 'services';
    if (testPath.contains('test/widgets/')) return 'widgets';
    if (testPath.contains('test/models/')) return 'models';
    if (testPath.contains('test/cli/')) return 'cli';
    if (testPath.contains('test/validation/')) return 'validation';
    if (testPath.contains('test/integration/')) return 'integration';
    if (testPath.contains('debug_logging_test.dart')) return 'debug';
    if (testPath.contains('widget_test.dart')) return 'widgets';
    if (testPath.contains('initialization_test.dart')) return 'initialization';
    return 'other';
  }

  void _printDetailedAnalysis(TestAnalysis analysis, AnalyzerConfig config) {
    print('Total Tests: ${analysis.totalTests}');
    print('Passed: ${analysis.passedTests} ✅');
    print('Failed: ${analysis.failedTests} ❌');
    print('Errors: ${analysis.errorTests} 💥');
    
    if (analysis.testsByCategory.isNotEmpty) {
      print('\n📂 Tests by Category:');
      final sortedCategories = analysis.testsByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (final entry in sortedCategories) {
        final category = entry.key;
        final count = entry.value;
        final failCount = analysis.failures
            .where((f) => f.category == category)
            .length;
        
        final status = failCount == 0 ? '✅' : '❌($failCount)';
        print('  $category: $count tests $status');
      }
    }
  }

  void _printFailureAnalysis(TestAnalysis analysis) {
    // Group failures by category
    final failuresByCategory = <String, List<TestFailure>>{};
    for (final failure in analysis.failures) {
      failuresByCategory.putIfAbsent(failure.category, () => []).add(failure);
    }
    
    // Group by error type
    final failuresByError = <String, List<TestFailure>>{};
    for (final failure in analysis.failures) {
      final errorType = _classifyError(failure.error);
      failuresByError.putIfAbsent(errorType, () => []).add(failure);
    }
    
    print('📊 Failures by Category:');
    for (final entry in failuresByCategory.entries) {
      print('  ${entry.key}: ${entry.value.length} failures');
      if (entry.value.length <= 3) {
        for (final failure in entry.value) {
          print('    • ${failure.name}');
        }
      }
    }
    
    print('\n🏷️  Failures by Error Type:');
    for (final entry in failuresByError.entries) {
      print('  ${entry.key}: ${entry.value.length} failures');
    }
  }

  String _classifyError(String error) {
    if (error.contains('timeout') || error.contains('pumpAndSettle timed out')) {
      return 'timeout';
    }
    if (error.contains('assertion') || error.contains('expect')) {
      return 'assertion';
    }
    if (error.contains('compilation') || error.contains('compile')) {
      return 'compilation';
    }
    if (error.contains('null')) {
      return 'null_error';
    }
    if (error.contains('type')) {
      return 'type_error';
    }
    return 'other';
  }

  void _printFixStrategy(TestAnalysis analysis) {
    final strategies = <String, List<String>>{};
    
    // Analyze failure patterns and suggest fixes
    for (final failure in analysis.failures) {
      final errorType = _classifyError(failure.error);
      final category = failure.category;
      
      switch (errorType) {
        case 'timeout':
          strategies.putIfAbsent('High Priority - Timeout Issues', () => [])
              .add('Fix ${failure.name} in $category: Add explicit timeouts or replace pumpAndSettle');
          break;
        case 'assertion':
          strategies.putIfAbsent('Medium Priority - Logic Issues', () => [])
              .add('Fix ${failure.name} in $category: Review test expectations');
          break;
        case 'null_error':
          strategies.putIfAbsent('High Priority - Null Safety', () => [])
              .add('Fix ${failure.name} in $category: Add null checks or proper initialization');
          break;
        case 'compilation':
          strategies.putIfAbsent('Critical Priority - Build Issues', () => [])
              .add('Fix ${failure.name} in $category: Resolve compilation errors');
          break;
      }
    }
    
    // Print strategies in priority order
    final priorityOrder = [
      'Critical Priority - Build Issues',
      'High Priority - Timeout Issues', 
      'High Priority - Null Safety',
      'Medium Priority - Logic Issues'
    ];
    
    for (final priority in priorityOrder) {
      if (strategies.containsKey(priority)) {
        print('\n$priority:');
        for (final strategy in strategies[priority]!.take(5)) {
          print('  • $strategy');
        }
        if (strategies[priority]!.length > 5) {
          print('  • ... and ${strategies[priority]!.length - 5} more');
        }
      }
    }
    
    // Suggested parallel execution strategy
    print('\n🔄 Parallel Fixing Strategy:');
    print('  1. Fix compilation errors first (blocks everything)');
    print('  2. Fix timeout issues in parallel by category');
    print('  3. Address null safety issues');
    print('  4. Review assertion failures last');
    
    print('\n💡 Quick Commands:');
    print('  • dart tool/test_analyzer.dart --category services --failures-only');
    print('  • dart tool/test_analyzer.dart --category widgets --quick');
    print('  • flutter test test/models/ --reporter failures-only');
  }

  void _printHelp() {
    print('''
Test Analyzer v$version - Comprehensive test failure analysis and grouping

USAGE:
    dart tool/test_analyzer.dart [OPTIONS]

OPTIONS:
    -q, --quick              Quick analysis with compact output
    -v, --verbose            Detailed analysis output
    -f, --failures-only      Focus only on failures
    -c, --category <CAT>     Analyze specific category (services/widgets/models/cli/validation/integration)
    -o, --output <FILE>      Save JSON results to file
    -p, --parallel           Use parallel execution for faster analysis
    -h, --help               Show this help message
    --version                Show version information

EXAMPLES:
    # Full analysis
    dart tool/test_analyzer.dart

    # Quick failures-only analysis
    dart tool/test_analyzer.dart --quick --failures-only

    # Analyze specific category
    dart tool/test_analyzer.dart --category services --verbose

    # Save results for later analysis
    dart tool/test_analyzer.dart --output test_analysis.json

    # Fast parallel analysis
    dart tool/test_analyzer.dart --parallel --quick
''');
  }
}

class AnalyzerConfig {
  bool quickMode = false;
  bool verbose = false;
  bool failuresOnly = false;
  bool parallelMode = false;
  String? category;
  String? outputFile;
}

class TestResults {
  int exitCode = 0;
  String stdout = '';
  String stderr = '';
  String? error;
  List<Map<String, dynamic>> jsonResults = [];
}

class TestAnalysis {
  int totalTests = 0;
  int passedTests = 0;
  int failedTests = 0;
  int errorTests = 0;
  bool success = false;
  Map<String, int> testsByCategory = {};
  List<TestFailure> failures = [];
}

class TestFailure {
  final String name;
  final String category;
  final String suitePath;
  final String error;
  final String? stackTrace;
  final bool isError;

  TestFailure({
    required this.name,
    required this.category,
    required this.suitePath,
    required this.error,
    this.stackTrace,
    this.isError = false,
  });
}