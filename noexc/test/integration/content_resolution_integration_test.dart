import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/semantic_content_service.dart';

void main() {
  group('Content Resolution Integration', () {
    late SemanticContentService service;
    
    setUpAll(() async {
      // Initialize Flutter services for asset loading
      TestWidgetsFlutterBinding.ensureInitialized();
    });
    
    setUp(() {
      service = SemanticContentService.instance;
      service.clearCache();
    });
    
    test('should resolve exact match content from files', () async {
      String result = await service.getContent(
        'bot.acknowledge.completion.positive', 
        'fallback text'
      );
      
      // Should not be the fallback since we have actual content
      expect(result, isNot(equals('fallback text')));
      expect(result.isNotEmpty, isTrue);
      
      // Should be one of the variants in the file
      List<String> expectedVariants = [
        'Fantastic work!',
        'Outstanding job completing that task!',
        'Excellent! You have successfully finished.',
        'Brilliant work - task completed!',
        'Amazing job! Well done.',
      ];
      expect(expectedVariants.contains(result), isTrue);
    });
    
    test('should fallback correctly when specific file not found', () async {
      String result = await service.getContent(
        'bot.acknowledge.completion.celebratory.first_time', 
        'fallback text'
      );
      
      // Should fallback to completion.txt since celebratory variant doesn't exist
      expect(result, isNot(equals('fallback text')));
      
      List<String> expectedVariants = [
        'Great work!',
        'Task completed successfully.',
        'Well done!',
        'Excellent job!',
        'Perfect!',
      ];
      expect(expectedVariants.contains(result), isTrue);
    });
    
    test('should handle generic subject fallback', () async {
      String result = await service.getContent(
        'bot.acknowledge.task_completion.positive', 
        'fallback text'
      );
      
      // Should fallback to generic "completion" subject
      expect(result, isNot(equals('fallback text')));
      
      // Should get content from either task_completion_positive.txt (if it existed)
      // or completion_positive.txt (fallback)
      List<String> possibleVariants = [
        'Fantastic work!',
        'Outstanding job completing that task!',
        'Excellent! You have successfully finished.',
        'Brilliant work - task completed!',
        'Amazing job! Well done.',
      ];
      expect(possibleVariants.contains(result), isTrue);
    });
    
    test('should return fallback for completely non-existent content', () async {
      String result = await service.getContent(
        'bot.nonexistent.action.modifier', 
        'original fallback text'
      );
      
      expect(result, equals('original fallback text'));
    });
    
    test('should cache resolved content', () async {
      // First call
      String result1 = await service.getContent(
        'bot.acknowledge.completion.positive', 
        'fallback'
      );
      
      // Second call should return same cached result
      String result2 = await service.getContent(
        'bot.acknowledge.completion.positive', 
        'fallback'
      );
      
      expect(result1, equals(result2));
    });
    
    test('should handle user content files', () async {
      String result = await service.getContent(
        'user.choose.task_status', 
        'fallback'
      );
      
      expect(result, isNot(equals('fallback')));
      
      List<String> expectedOptions = [
        'Completed',
        'In Progress', 
        'Not Started',
        'Failed',
        'Cancelled',
      ];
      expect(expectedOptions.contains(result), isTrue);
    });
    
    test('should resolve modifier chain correctly', () async {
      String result = await service.getContent(
        'bot.request.input.gentle.first_time', 
        'fallback'
      );
      
      // Should fallback to input_gentle.txt since input_gentle_first_time.txt doesn't exist
      expect(result, isNot(equals('fallback')));
      
      List<String> expectedVariants = [
        'Could you please provide some information?',
        'When you are ready, please share your thoughts.',
        'I would appreciate your input when convenient.',
        'Please let me know what you think.',
        'Your input would be helpful.',
      ];
      expect(expectedVariants.contains(result), isTrue);
    });
  });
}