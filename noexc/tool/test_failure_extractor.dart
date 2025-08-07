#!/usr/bin/env dart

/// Flutter Test Failure Extractor
/// 
/// Processes `flutter test --machine` JSON output stream and extracts only 
/// test failures into a structured JSON format for analysis and prioritization.
///
/// Usage:
///   flutter test --machine | dart tool/test_failure_extractor.dart
///   flutter test --machine test/services/ | dart tool/test_failure_extractor.dart > failures.json
///   flutter test --machine --concurrency=1 2>/dev/null | dart tool/test_failure_extractor.dart
///
/// Output JSON structure:
///   {
///     "metadata": {
///       "extracted_at": "ISO8601 timestamp",
///       "total_failures": number,
///       "extractor_version": "1.0.0"
///     },
///     "failures": [
///       {
///         "name": "Full test name with group prefixes",
///         "file": "Absolute path to test file",
///         "suite": "Test suite name (derived from file)",
///         "group": "Group hierarchy (joined with >)",
///         "error": "Error message from test failure",
///         "testId": "Internal test ID for reference",
///         "line": "Line number where test was defined",
///         "column": "Column number (optional)",
///         "stackTrace": "Stack trace (if available)",
///         "isFailure": "Boolean indicating test failure vs error",
///         "timestamp": "Time in milliseconds when failure occurred",
///         "category": "Categorized failure type (assertion|timeout|runtime_error|unknown)"
///       }
///     ]
///   }

import 'dart:convert';
import 'dart:io';

class TestFailureExtractor {
  final Map<int, Map<String, dynamic>> tests = {};
  final Map<int, Map<String, dynamic>> groups = {};
  final Map<int, Map<String, dynamic>> suites = {};
  final Map<int, Map<String, dynamic>> errors = {};
  final List<Map<String, dynamic>> failures = [];

  void processLine(String line) {
    if (line.trim().isEmpty) return;
    
    // Skip non-JSON lines (like [{"event":"test.startedProcess"...] format)
    if (line.startsWith('[{')) return;
    
    try {
      final data = json.decode(line) as Map<String, dynamic>;
      final type = data['type'] as String?;
      
      switch (type) {
        case 'suite':
          _processSuite(data);
          break;
        case 'group':
          _processGroup(data);
          break;
        case 'testStart':
          _processTestStart(data);
          break;
        case 'error':
          _processError(data);
          break;
        case 'testDone':
          _processTestDone(data);
          break;
      }
    } catch (e) {
      // Silently skip malformed JSON lines
    }
  }

  void _processSuite(Map<String, dynamic> data) {
    final suite = data['suite'] as Map<String, dynamic>?;
    if (suite != null) {
      final id = suite['id'] as int;
      suites[id] = {
        'id': id,
        'platform': suite['platform'],
        'path': suite['path'],
      };
    }
  }

  void _processGroup(Map<String, dynamic> data) {
    final group = data['group'] as Map<String, dynamic>?;
    if (group != null) {
      final id = group['id'] as int;
      groups[id] = {
        'id': id,
        'suiteID': group['suiteID'],
        'parentID': group['parentID'],
        'name': group['name'],
        'line': group['line'],
        'column': group['column'],
        'url': group['url'],
      };
    }
  }

  void _processTestStart(Map<String, dynamic> data) {
    final test = data['test'] as Map<String, dynamic>?;
    if (test != null) {
      final id = test['id'] as int;
      tests[id] = {
        'id': id,
        'name': test['name'],
        'suiteID': test['suiteID'],
        'groupIDs': List<int>.from(test['groupIDs'] ?? []),
        'line': test['line'],
        'column': test['column'],
        'url': test['url'],
        'metadata': test['metadata'],
      };
    }
  }

  void _processError(Map<String, dynamic> data) {
    final testID = data['testID'] as int?;
    if (testID != null) {
      errors[testID] = {
        'testID': testID,
        'error': data['error'],
        'stackTrace': data['stackTrace'],
        'isFailure': data['isFailure'],
        'time': data['time'],
      };
    }
  }

  void _processTestDone(Map<String, dynamic> data) {
    final testID = data['testID'] as int?;
    final result = data['result'] as String?;
    
    if (testID != null && (result == 'failure' || errors.containsKey(testID))) {
      _extractFailure(testID);
    }
  }

  void _extractFailure(int testID) {
    final test = tests[testID];
    final error = errors[testID];
    
    if (test == null) return;

    final suiteID = test['suiteID'] as int?;
    final suite = suiteID != null ? suites[suiteID] : null;
    final groupIDs = test['groupIDs'] as List<int>? ?? [];
    
    // Build group hierarchy
    final groupNames = <String>[];
    for (final groupID in groupIDs) {
      final group = groups[groupID];
      if (group != null) {
        final name = group['name'] as String?;
        if (name != null && name.isNotEmpty) {
          groupNames.add(name);
        }
      }
    }

    // Extract file path from URL or suite path
    String? filePath;
    if (test['url'] != null) {
      final url = test['url'] as String;
      filePath = url.startsWith('file://') ? url.substring(7) : url;
    } else if (suite != null) {
      filePath = suite['path'] as String?;
    }

    // Extract suite name from file path
    String? suiteName;
    if (filePath != null) {
      final parts = filePath.split('/');
      suiteName = parts.isNotEmpty ? parts.last.replaceAll('_test.dart', '') : null;
    }

    final failure = <String, dynamic>{
      'name': test['name'],
      'file': filePath,
      'suite': suiteName,
      'group': groupNames.join(' > '),
      'error': error?['error'] ?? 'Unknown error',
      'testId': testID,
      'line': test['line'],
      'column': test['column'],
    };

    // Add optional fields if available
    if (error?['stackTrace'] != null) {
      failure['stackTrace'] = error!['stackTrace'];
    }
    
    if (error?['isFailure'] != null) {
      failure['isFailure'] = error!['isFailure'];
    }
    
    if (error?['time'] != null) {
      failure['timestamp'] = error!['time'];
    }

    // Add priority indicators based on error patterns
    final errorText = failure['error'] as String;
    if (errorText.contains('Expected:') || errorText.contains('Actual:')) {
      failure['category'] = 'assertion';
    } else if (errorText.contains('TimeoutException') || errorText.contains('timeout')) {
      failure['category'] = 'timeout';
    } else if (errorText.contains('NoSuchMethodError') || errorText.contains('TypeError')) {
      failure['category'] = 'runtime_error';
    } else {
      failure['category'] = 'unknown';
    }

    failures.add(failure);
  }

  Map<String, dynamic> getResults() {
    return {
      'metadata': {
        'extracted_at': DateTime.now().toIso8601String(),
        'total_failures': failures.length,
        'extractor_version': '1.0.0',
      },
      'failures': failures,
    };
  }
}

void main(List<String> args) async {
  if (args.isNotEmpty && (args.contains('--help') || args.contains('-h'))) {
    print('''
Flutter Test Failure Extractor

Processes `flutter test --machine` JSON output and extracts only failures.

Usage:
  flutter test --machine | dart tool/test_failure_extractor.dart
  flutter test --machine test/services/ | dart tool/test_failure_extractor.dart > failures.json
  flutter test --machine --concurrency=1 2>/dev/null | dart tool/test_failure_extractor.dart

Options:
  --help, -h    Show this help message

The script reads from stdin and outputs JSON to stdout.
Redirect stderr to suppress flutter test verbose output: 2>/dev/null
''');
    exit(0);
  }

  final extractor = TestFailureExtractor();
  
  try {
    await for (final line in stdin.transform(utf8.decoder).transform(LineSplitter())) {
      extractor.processLine(line);
    }
  } on Exception catch (e) {
    stderr.writeln('Error processing input: $e');
    exit(1);
  }

  final results = extractor.getResults();
  
  try {
    print(json.encode(results));
  } on Exception catch (e) {
    stderr.writeln('Error encoding output: $e');
    exit(1);
  }
}