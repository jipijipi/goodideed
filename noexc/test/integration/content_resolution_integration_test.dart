import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noexc/services/semantic_content_service.dart';
import 'package:noexc/services/content/semantic_content_resolver.dart';

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
      const key = 'bot.acknowledge.completion.positive';

      final result = await service.getContent(key, 'fallback text');

      // Should not be the fallback since we have actual content
      expect(result, isNot('fallback text'));
      expect(result.isNotEmpty, isTrue);

      // Should be one of the variants found in the resolved asset files
      final expectedSet = await _loadAllVariantLinesForKey(key);
      expect(expectedSet, isNotEmpty);
      expect(expectedSet.contains(result), isTrue);
    });

    test('should fallback correctly when specific file not found', () async {
      const key = 'bot.acknowledge.completion.celebratory.first_time';
      final result = await service.getContent(key, 'fallback text');

      // Should fallback to an existing variant from the fallback chain
      expect(result, isNot('fallback text'));
      final expectedSet = await _loadAllVariantLinesForKey(key);
      expect(expectedSet, isNotEmpty);
      expect(expectedSet.contains(result), isTrue);
    });

    test('should handle generic subject fallback', () async {
      const key = 'bot.acknowledge.task_completion.positive';
      final result = await service.getContent(key, 'fallback text');

      // Should fallback to generic subject and still resolve a variant
      expect(result, isNot('fallback text'));
      final expectedSet = await _loadAllVariantLinesForKey(key);
      expect(expectedSet, isNotEmpty);
      expect(expectedSet.contains(result), isTrue);
    });

    test(
      'should return fallback for completely non-existent content',
      () async {
        String result = await service.getContent(
          'bot.nonexistent.action.modifier',
          'original fallback text',
        );

        expect(result, equals('original fallback text'));
      },
    );

    test('should cache resolved content', () async {
      // First call
      String result1 = await service.getContent(
        'bot.acknowledge.completion.positive',
        'fallback',
      );

      // Second call should return same cached result
      String result2 = await service.getContent(
        'bot.acknowledge.completion.positive',
        'fallback',
      );

      expect(result1, equals(result2));
    });

    test('should handle user content files', () async {
      const key = 'user.choose.task_status';
      final result = await service.getContent(key, 'fallback');

      expect(result, isNot('fallback'));
      final expectedSet = await _loadAllVariantLinesForKey(key);
      expect(expectedSet, isNotEmpty);
      expect(expectedSet.contains(result), isTrue);
    });

    test('should resolve modifier chain correctly', () async {
      const key = 'bot.request.input.gentle.first_time';
      final result = await service.getContent(key, 'fallback');

      // Should resolve to one of the variants found along the modifier fallback chain
      expect(result, isNot('fallback'));
      final expectedSet = await _loadAllVariantLinesForKey(key);
      expect(expectedSet, isNotEmpty);
      expect(expectedSet.contains(result), isTrue);
    });
  });
}

/// Helper: build the full fallback chain for a semantic key and load all non-empty
/// variant lines from all existing files in the chain.
Future<Set<String>> _loadAllVariantLinesForKey(String semanticKey) async {
  final parsed = SemanticContentResolver.parseSemanticKey(semanticKey);
  final actor = parsed['actor'] as String?;
  final action = parsed['action'] as String?;
  final subject = parsed['subject'] as String?;
  final modifiers = (parsed['modifiers'] as List<String>? ?? <String>[]);

  if (actor == null || action == null || subject == null) {
    return <String>{};
  }

  final paths = SemanticContentResolver.buildFallbackChain(
    actor,
    action,
    subject,
    modifiers,
  );

  final variants = <String>{};
  for (final relativePath in paths) {
    try {
      final content = await rootBundle.loadString('assets/$relativePath');
      final lines = content
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      variants.addAll(lines);
    } catch (_) {
      // Skip missing files
    }
  }
  return variants;
}
