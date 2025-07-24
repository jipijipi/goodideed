import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/semantic_content_service.dart';

void main() {
  group('SemanticContentService', () {
    late SemanticContentService service;
    
    setUp(() {
      service = SemanticContentService.instance;
      service.clearCache(); // Clear cache before each test
    });
    
    test('should be a singleton', () {
      SemanticContentService instance1 = SemanticContentService.instance;
      SemanticContentService instance2 = SemanticContentService.instance;
      
      expect(identical(instance1, instance2), isTrue);
    });
    
    test('should resolve content using semantic key', () async {
      String result = await service.getContent(
        'bot.acknowledge.completion.positive', 
        'fallback text'
      );
      
      // Should at least return fallback since no content files exist yet
      expect(result, isNotNull);
      expect(result.isNotEmpty, isTrue);
    });
    
    test('should handle empty semantic keys gracefully', () async {
      String result = await service.getContent('', 'original text');
      expect(result, equals('original text'));
    });
    
    test('should handle null semantic keys gracefully', () async {
      String result = await service.getContent(null, 'original text');
      expect(result, equals('original text'));
    });
    
    test('should clear cache when requested', () async {
      // Make a request to populate cache
      await service.getContent('bot.test.key', 'test');
      
      // Clear cache
      service.clearCache();
      
      // Cache should be empty (we can't directly test this, but subsequent calls should behave consistently)
      String result = await service.getContent('bot.test.key', 'test');
      expect(result, equals('test'));
    });
    
    test('should handle invalid semantic keys', () async {
      String result = await service.getContent('invalid.key', 'fallback');
      expect(result, equals('fallback'));
    });
    
    test('should maintain consistent behavior across calls', () async {
      String result1 = await service.getContent('bot.acknowledge.test', 'original');
      String result2 = await service.getContent('bot.acknowledge.test', 'original');
      
      expect(result1, equals(result2));
    });
  });
}