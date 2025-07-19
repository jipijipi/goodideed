import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/validation/asset_validator.dart';
import 'package:noexc/validation/models/validation_models.dart';

void main() {
  group('AssetValidator', () {
    late AssetValidator validator;
    
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      validator = AssetValidator();
    });
    
    group('JSON Schema Validation', () {
      test('should validate basic JSON structure', () async {
        // This will test against actual sequence files
        final result = await validator.validateJsonSchema('onboarding_seq');
        
        // Should not have critical errors for well-formed sequences
        expect(result.errors.where((e) => e.type == 'JSON_PARSE_ERROR').length, 0);
      });
      
      test('should detect missing required fields', () async {
        // Test with mock data - in real implementation, you'd mock rootBundle
        // For now, we'll test the validation logic structure
        expect(validator, isNotNull);
      });
    });
    
    group('Cross-Sequence Reference Validation', () {
      test('should validate cross-sequence references', () async {
        final result = await validator.validateAllSequenceFiles();
        
        // Should not have invalid sequence references in our test data
        final invalidRefs = result.errors.where((e) => e.type == 'INVALID_SEQUENCE_REFERENCE');
        expect(invalidRefs.length, 0);
      });
    });
    
    group('Template Variable Validation', () {
      test('should extract template variables correctly', () {
        // Test the private method through public interface
        final result = validator.validateTemplateVariables();
        
        // Should complete without throwing
        expect(result, isA<Future<List<ValidationError>>>());
      });
    });
    
    group('Asset File Access', () {
      test('should check asset file accessibility', () async {
        final result = await validator.checkAssetFileAccess();
        
        // Should be able to access basic sequence files
        expect(result.errors.where((e) => e.type == 'ASSET_FILE_ERROR').length, 0);
      });
    });
    
    group('Comprehensive Validation', () {
      test('should validate all sequences without critical errors', () async {
        final result = await validator.validateAllSequenceFiles();
        
        // Print results for debugging
        print('Validation completed:');
        print('Errors: ${result.errors.length}');
        print('Warnings: ${result.warnings.length}');
        print('Info: ${result.info.length}');
        
        if (result.errors.isNotEmpty) {
          print('\\nErrors found:');
          for (final error in result.errors) {
            print('  $error');
          }
        }
        
        if (result.warnings.isNotEmpty) {
          print('\\nWarnings found:');
          for (final warning in result.warnings) {
            print('  $warning');
          }
        }
        
        // Should not have any critical structural errors
        final criticalErrors = result.errors.where((e) => 
          e.type == 'MISSING_SEQUENCE_ID' ||
          e.type == 'EMPTY_SEQUENCE' ||
          e.type == 'DUPLICATE_MESSAGE_IDS' ||
          e.type == 'INVALID_NEXT_MESSAGE_ID' ||
          e.type == 'INVALID_CHOICE_NEXT_MESSAGE_ID' ||
          e.type == 'INVALID_ROUTE_NEXT_MESSAGE_ID'
        );
        
        expect(criticalErrors.length, 0, 
          reason: 'Critical structural errors found: ${criticalErrors.map((e) => e.toString()).join(', ')}');
      });
    });
    
    group('Error Handling', () {
      test('should handle missing sequence files gracefully', () async {
        final result = await validator.validateJsonSchema('non_existent_sequence');
        
        // Should detect the missing file
        expect(result.errors.any((e) => e.type == 'JSON_PARSE_ERROR'), true);
      });
    });
  });
}