import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/content/semantic_content_resolver.dart';

void main() {
  group('SemanticContentResolver', () {
    group('_buildFallbackChain', () {
      test('should build correct fallback chain for basic key', () {
        List<String> chain = SemanticContentResolver.buildFallbackChain(
          'bot',
          'acknowledge',
          'completion',
          [],
        );

        expect(
          chain,
          equals([
            'content/bot/acknowledge/completion.txt',
            'content/bot/acknowledge/default.txt',
          ]),
        );
      });

      test('should build correct fallback chain with single modifier', () {
        List<String> chain = SemanticContentResolver.buildFallbackChain(
          'bot',
          'acknowledge',
          'completion',
          ['positive'],
        );

        expect(
          chain,
          equals([
            'content/bot/acknowledge/completion_positive.txt',
            'content/bot/acknowledge/completion.txt',
            'content/bot/acknowledge/default.txt',
          ]),
        );
      });

      test('should build correct fallback chain with multiple modifiers', () {
        List<String> chain = SemanticContentResolver.buildFallbackChain(
          'bot',
          'acknowledge',
          'task_completion',
          ['positive', 'first_time', 'celebratory'],
        );

        expect(
          chain,
          equals([
            'content/bot/acknowledge/task_completion_positive_first_time_celebratory.txt',
            'content/bot/acknowledge/task_completion_positive_first_time.txt',
            'content/bot/acknowledge/task_completion_positive.txt',
            'content/bot/acknowledge/task_completion.txt',
            'content/bot/acknowledge/completion_positive_first_time_celebratory.txt',
            'content/bot/acknowledge/completion_positive_first_time.txt',
            'content/bot/acknowledge/completion_positive.txt',
            'content/bot/acknowledge/completion.txt',
            'content/bot/acknowledge/default.txt',
          ]),
        );
      });

      test('should handle generic subject extraction correctly', () {
        List<String> chain = SemanticContentResolver.buildFallbackChain(
          'bot',
          'request',
          'task_name',
          ['gentle'],
        );

        expect(chain, contains('content/bot/request/name_gentle.txt'));
        expect(chain, contains('content/bot/request/name.txt'));
      });
    });

    group('_extractGenericSubject', () {
      test('should extract generic subjects from specific ones', () {
        expect(
          SemanticContentResolver.extractGenericSubject('task_completion'),
          equals('completion'),
        );
        expect(
          SemanticContentResolver.extractGenericSubject('profile_save'),
          equals('save'),
        );
        expect(
          SemanticContentResolver.extractGenericSubject('user_name'),
          equals('name'),
        );
        expect(
          SemanticContentResolver.extractGenericSubject('deadline_selection'),
          equals('selection'),
        );
        expect(
          SemanticContentResolver.extractGenericSubject('account_creation'),
          equals('creation'),
        );
      });

      test('should return original subject if no generic pattern found', () {
        expect(
          SemanticContentResolver.extractGenericSubject('completion'),
          equals('completion'),
        );
        expect(
          SemanticContentResolver.extractGenericSubject('randomword'),
          equals('randomword'),
        );
      });
    });

    group('resolveContent', () {
      test('should return original text for invalid semantic keys', () async {
        String result = await SemanticContentResolver.resolveContent(
          'invalid',
          'original text',
        );
        expect(result, equals('original text'));

        result = await SemanticContentResolver.resolveContent(
          'bot.only',
          'original text',
        );
        expect(result, equals('original text'));
      });

      test('should return original text when no content files exist', () async {
        String result = await SemanticContentResolver.resolveContent(
          'bot.acknowledge.nonexistent',
          'original text',
        );
        expect(result, equals('original text'));
      });

      test('should use cache for repeated requests', () async {
        // Clear cache first
        SemanticContentResolver.clearCache();

        // First call should miss cache
        String result1 = await SemanticContentResolver.resolveContent(
          'bot.acknowledge.test',
          'original text',
        );

        // Second call should hit cache
        String result2 = await SemanticContentResolver.resolveContent(
          'bot.acknowledge.test',
          'original text',
        );

        expect(result1, equals(result2));
      });
    });

    group('semantic key parsing', () {
      test('should parse semantic keys correctly', () {
        var parsed = SemanticContentResolver.parseSemanticKey(
          'bot.acknowledge.completion.positive.first_time',
        );

        expect(parsed['actor'], equals('bot'));
        expect(parsed['action'], equals('acknowledge'));
        expect(parsed['subject'], equals('completion'));
        expect(parsed['modifiers'], equals(['positive', 'first_time']));
      });

      test('should handle keys without modifiers', () {
        var parsed = SemanticContentResolver.parseSemanticKey(
          'user.choose.option',
        );

        expect(parsed['actor'], equals('user'));
        expect(parsed['action'], equals('choose'));
        expect(parsed['subject'], equals('option'));
        expect(parsed['modifiers'], equals([]));
      });
    });
  });
}
