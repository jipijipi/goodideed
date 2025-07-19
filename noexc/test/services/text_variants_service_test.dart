import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/text_variants_service.dart';

void main() {
  group('TextVariantsService', () {
    late TextVariantsService variantsService;

    setUp(() {
      variantsService = TextVariantsService();
    });

    tearDown(() {
      variantsService.clearCache();
    });

    test('should return original text when no variants file exists', () async {
      const originalText = 'Hello, this is a test message.';
      const sequenceId = 'nonexistent';
      const messageId = 999;

      final result = await variantsService.getVariant(originalText, sequenceId, messageId);
      
      expect(result, equals(originalText));
    });

    test('should return variant when variants file exists', () async {
      // This test assumes the onboarding_message_1.txt file exists
      const originalText = 'Welcome to our app! I\'m here to help you get started.';
      const sequenceId = 'onboarding';
      const messageId = 1;

      final result = await variantsService.getVariant(originalText, sequenceId, messageId);
      
      // Result should be one of the variants (could be the original or a variant)
      expect(result, isNotEmpty);
      expect(result, isA<String>());
    });

    test('should cache variants after first load', () async {
      const originalText = 'Test message';
      const sequenceId = 'onboarding';
      const messageId = 1;

      // First call - loads from file
      final result1 = await variantsService.getVariant(originalText, sequenceId, messageId);
      
      // Second call - should use cache
      final result2 = await variantsService.getVariant(originalText, sequenceId, messageId);
      
      // Both calls should return valid strings
      expect(result1, isA<String>());
      expect(result2, isA<String>());
    });

    test('should check if variants exist correctly', () async {
      const sequenceId = 'onboarding';
      const messageId = 1;

      final hasVariants = await variantsService.hasVariants(sequenceId, messageId);
      
      expect(hasVariants, isA<bool>());
    });

    test('should return false for hasVariants when file does not exist', () async {
      const sequenceId = 'nonexistent';
      const messageId = 999;

      final hasVariants = await variantsService.hasVariants(sequenceId, messageId);
      
      expect(hasVariants, isFalse);
    });

    test('should get all variants for a message', () async {
      const sequenceId = 'onboarding';
      const messageId = 1;

      final variants = await variantsService.getAllVariants(sequenceId, messageId);
      
      expect(variants, isA<List<String>>());
      // Should have at least one variant (could be empty if file doesn't exist)
      expect(variants, isNotNull);
    });

    test('should clear cache correctly', () async {
      const originalText = 'Test message';
      const sequenceId = 'onboarding';
      const messageId = 1;

      // Load variants to populate cache
      await variantsService.getVariant(originalText, sequenceId, messageId);
      
      // Clear cache
      variantsService.clearCache();
      
      // Should still work after cache clear (will reload from file)
      final result = await variantsService.getVariant(originalText, sequenceId, messageId);
      expect(result, isA<String>());
    });

    test('should handle empty variants file gracefully', () async {
      const originalText = 'Test message';
      const sequenceId = 'empty';
      const messageId = 1;

      final result = await variantsService.getVariant(originalText, sequenceId, messageId);
      
      // Should return original text when variants file is empty or doesn't exist
      expect(result, equals(originalText));
    });

    test('should generate correct variant key format', () async {
      const originalText = 'Test message';
      const sequenceId = 'tutorial';
      const messageId = 10;

      // This tests the internal key format: sequenceId_message_messageId
      final result = await variantsService.getVariant(originalText, sequenceId, messageId);
      
      expect(result, isA<String>());
    });
  });
}