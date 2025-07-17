import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/validation/sequence_validator.dart';
import 'package:noexc/validation/asset_validator.dart';
import 'package:noexc/validation/models/validation_models.dart';
import 'package:noexc/constants/app_constants.dart';

/// Comprehensive validation test runner
/// Run this to validate all sequences before deployment
void main() {
  group('Comprehensive Sequence Validation', () {
    late AssetValidator assetValidator;
    
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      assetValidator = AssetValidator();
    });
    
    test('Validate all sequence files for structural integrity', () async {
      print('\\n=== COMPREHENSIVE SEQUENCE VALIDATION ===\\n');
      
      final result = await assetValidator.validateAllSequenceFiles();
      
      // Print summary
      print('Validation Summary:');
      print('  Total Sequences: ${AppConstants.availableSequences.length}');
      print('  Errors: ${result.errors.length}');
      print('  Warnings: ${result.warnings.length}');
      print('  Info: ${result.info.length}');
      print('  Overall Status: ${result.isValid ? "✅ PASS" : "❌ FAIL"}');
      
      if (result.errors.isNotEmpty) {
        print('\\n🚨 ERRORS FOUND:');
        for (final error in result.errors) {
          print('  ❌ $error');
        }
      }
      
      if (result.warnings.isNotEmpty) {
        print('\\n⚠️  WARNINGS:');
        for (final warning in result.warnings) {
          print('  ⚠️  $warning');
        }
      }
      
      if (result.info.isNotEmpty && result.info.length <= 10) {
        print('\\nℹ️  INFO (showing first 10):');
        for (final info in result.info.take(10)) {
          print('  ℹ️  $info');
        }
        if (result.info.length > 10) {
          print('  ... and ${result.info.length - 10} more info items');
        }
      }
      
      // Break down errors by type
      if (result.errors.isNotEmpty) {
        print('\\n📊 ERROR BREAKDOWN:');
        final errorsByType = <String, int>{};
        for (final error in result.errors) {
          errorsByType[error.type] = (errorsByType[error.type] ?? 0) + 1;
        }
        for (final entry in errorsByType.entries) {
          print('  ${entry.key}: ${entry.value}');
        }
      }
      
      // Break down warnings by type
      if (result.warnings.isNotEmpty) {
        print('\\n📊 WARNING BREAKDOWN:');
        final warningsByType = <String, int>{};
        for (final warning in result.warnings) {
          warningsByType[warning.type] = (warningsByType[warning.type] ?? 0) + 1;
        }
        for (final entry in warningsByType.entries) {
          print('  ${entry.key}: ${entry.value}');
        }
      }
      
      // Sequence-specific issues
      if (result.errors.isNotEmpty || result.warnings.isNotEmpty) {
        print('\\n🔍 ISSUES BY SEQUENCE:');
        final issuesBySequence = <String, List<ValidationError>>{};
        for (final issue in [...result.errors, ...result.warnings]) {
          if (issue.sequenceId != null) {
            issuesBySequence.putIfAbsent(issue.sequenceId!, () => []).add(issue);
          }
        }
        
        for (final entry in issuesBySequence.entries) {
          print('  ${entry.key}: ${entry.value.length} issues');
          for (final issue in entry.value) {
            final icon = issue.severity == 'error' ? '❌' : '⚠️';
            print('    $icon ${issue.type}: ${issue.message}');
          }
        }
      }
      
      print('\\n=== VALIDATION COMPLETE ===\\n');
      
      // Test assertions
      expect(result.errors.length, 0, 
        reason: 'Validation failed with ${result.errors.length} errors. See output above for details.');
      
      // You can choose to fail on warnings too:
      // expect(result.warnings.length, 0, 
      //   reason: 'Validation found ${result.warnings.length} warnings. See output above for details.');
    });
    
    test('Validate asset file accessibility', () async {
      print('\\n=== ASSET FILE ACCESS VALIDATION ===\\n');
      
      final result = await assetValidator.checkAssetFileAccess();
      
      print('Asset Access Summary:');
      print('  Accessible Files: ${result.info.length}');
      print('  Inaccessible Files: ${result.errors.length}');
      
      if (result.errors.isNotEmpty) {
        print('\\n🚨 INACCESSIBLE FILES:');
        for (final error in result.errors) {
          print('  ❌ $error');
        }
      }
      
      print('\\n=== ASSET ACCESS VALIDATION COMPLETE ===\\n');
      
      expect(result.errors.length, 0, 
        reason: 'Some asset files are not accessible. See output above for details.');
    });
    
    test('Validate template variable consistency', () async {
      print('\\n=== TEMPLATE VARIABLE VALIDATION ===\\n');
      
      final warnings = await assetValidator.validateTemplateVariables();
      
      print('Template Variable Summary:');
      print('  Shared Variables: ${warnings.length}');
      
      if (warnings.isNotEmpty) {
        print('\\nℹ️  SHARED TEMPLATE VARIABLES:');
        for (final warning in warnings) {
          print('  ℹ️  $warning');
        }
      }
      
      print('\\n=== TEMPLATE VARIABLE VALIDATION COMPLETE ===\\n');
      
      // This is informational, not an error
      expect(warnings, isA<List<ValidationError>>());
    });
    
    test('Validate JSON schema compliance', () async {
      print('\\n=== JSON SCHEMA VALIDATION ===\\n');
      
      final allErrors = <ValidationError>[];
      final allWarnings = <ValidationError>[];
      
      for (final sequenceId in AppConstants.availableSequences) {
        final result = await assetValidator.validateJsonSchema(sequenceId);
        allErrors.addAll(result.errors);
        allWarnings.addAll(result.warnings);
      }
      
      print('JSON Schema Summary:');
      print('  Sequences Validated: ${AppConstants.availableSequences.length}');
      print('  Schema Errors: ${allErrors.length}');
      print('  Schema Warnings: ${allWarnings.length}');
      
      if (allErrors.isNotEmpty) {
        print('\\n🚨 SCHEMA ERRORS:');
        for (final error in allErrors) {
          print('  ❌ $error');
        }
      }
      
      if (allWarnings.isNotEmpty) {
        print('\\n⚠️  SCHEMA WARNINGS:');
        for (final warning in allWarnings) {
          print('  ⚠️  $warning');
        }
      }
      
      print('\\n=== JSON SCHEMA VALIDATION COMPLETE ===\\n');
      
      expect(allErrors.length, 0, 
        reason: 'JSON schema validation failed with ${allErrors.length} errors.');
    });
    
    test('Performance test: Validation should complete quickly', () async {
      final stopwatch = Stopwatch()..start();
      
      await assetValidator.validateAllSequenceFiles();
      
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      
      print('\\n⏱️  PERFORMANCE:');
      print('  Validation Time: ${duration}ms');
      print('  Sequences: ${AppConstants.availableSequences.length}');
      print('  Avg Time per Sequence: ${duration / AppConstants.availableSequences.length}ms');
      
      // Validation should complete in reasonable time (adjust threshold as needed)
      expect(duration, lessThan(5000), 
        reason: 'Validation took too long: ${duration}ms');
    });
  });
  
  group('Individual Sequence Validation', () {
    test('Validate each sequence individually', () async {
      final assetValidator = AssetValidator();
      
      for (final sequenceId in AppConstants.availableSequences) {
        try {
          // Validate JSON schema first
          final jsonResult = await assetValidator.validateJsonSchema(sequenceId);
          
          print('\\n📋 $sequenceId:');
          print('  JSON Schema Errors: ${jsonResult.errors.length}');
          print('  JSON Schema Warnings: ${jsonResult.warnings.length}');
          
          if (jsonResult.errors.isNotEmpty) {
            print('  JSON Issues:');
            for (final error in jsonResult.errors) {
              print('    ❌ ${error.type}: ${error.message}');
            }
          }
          
          // Individual sequences should not have critical JSON errors
          expect(jsonResult.errors.length, 0, 
            reason: 'Sequence "$sequenceId" has ${jsonResult.errors.length} JSON errors');
        } catch (e) {
          fail('Failed to validate sequence "$sequenceId": $e');
        }
      }
    });
  });
}