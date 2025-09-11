import 'dart:math';
import 'package:flutter/services.dart';
import '../logger_service.dart';

class SemanticContentResolver {
  static final Map<String, String> _cache = {};

  static Future<String> resolveContent(
    String semanticKey,
    String originalText, {
    bool bypassCache = false,
  }) async {
    // Check cache first (unless bypassing)
    if (!bypassCache && _cache.containsKey(semanticKey)) {
      return _cache[semanticKey]!;
    }

    final parsed = parseSemanticKey(semanticKey);

    // Validate semantic key
    if (parsed['actor'] == null ||
        parsed['action'] == null ||
        parsed['subject'] == null) {
      logger.semantic(
        'Invalid key format: "$semanticKey"',
        level: LogLevel.warning,
      );
      // Only cache result if not bypassing cache
      if (!bypassCache) {
        _cache[semanticKey] = originalText;
      }
      return originalText;
    }

    String actor = parsed['actor']!;
    String action = parsed['action']!;
    String subject = parsed['subject']!;
    List<String> modifiers = parsed['modifiers'] ?? [];

    // Build fallback chain
    List<String> fallbackPaths = buildFallbackChain(
      actor,
      action,
      subject,
      modifiers,
    );

    // Try each path in order
    for (String path in fallbackPaths) {
      String? content = await _tryLoadFile(path);
      if (content != null) {
        // Only cache result if not bypassing cache
        if (!bypassCache) {
          _cache[semanticKey] = content;
        }
        return content;
      }
    }

    // Final fallback to original text
    logger.semantic(
      'No content found for "$semanticKey", using fallback',
      level: LogLevel.warning,
    );
    // Only cache result if not bypassing cache
    if (!bypassCache) {
      _cache[semanticKey] = originalText;
    }
    return originalText;
  }

  static Map<String, dynamic> parseSemanticKey(String semanticKey) {
    final parts = semanticKey.split('.');

    if (parts.length < 3) {
      return {
        'actor': null,
        'action': null,
        'subject': null,
        'modifiers': <String>[],
      };
    }

    return {
      'actor': parts[0],
      'action': parts[1],
      'subject': parts[2],
      'modifiers': parts.length > 3 ? parts.skip(3).toList() : <String>[],
    };
  }

  static List<String> buildFallbackChain(
    String actor,
    String action,
    String subject,
    List<String> modifiers,
  ) {
    List<String> paths = [];

    // 1. Try with all modifiers in order
    if (modifiers.isNotEmpty) {
      String fullModifierChain = modifiers.join('_');
      paths.add('content/$actor/$action/${subject}_$fullModifierChain.txt');

      // 2. Try reducing modifiers from the end (keep most important first)
      for (int i = modifiers.length - 1; i > 0; i--) {
        String partialChain = modifiers.take(i).join('_');
        paths.add('content/$actor/$action/${subject}_$partialChain.txt');
      }
    }

    // 3. Try subject without modifiers
    paths.add('content/$actor/$action/$subject.txt');

    // 4. Try generic subject fallback
    String genericSubject = extractGenericSubject(subject);
    if (genericSubject != subject) {
      if (modifiers.isNotEmpty) {
        // Try generic subject with all modifiers
        String fullModifierChain = modifiers.join('_');
        paths.add(
          'content/$actor/$action/${genericSubject}_$fullModifierChain.txt',
        );

        // Try generic subject with reduced modifiers
        for (int i = modifiers.length - 1; i > 0; i--) {
          String partialChain = modifiers.take(i).join('_');
          paths.add(
            'content/$actor/$action/${genericSubject}_$partialChain.txt',
          );
        }
      }
      // Try generic subject without modifiers
      paths.add('content/$actor/$action/$genericSubject.txt');
    }

    // 5. Try action default
    paths.add('content/$actor/$action/default.txt');

    return paths;
  }

  static String extractGenericSubject(String subject) {
    // Extract generic part from specific subjects
    List<String> commonSuffixes = [
      'completion',
      'failure',
      'success',
      'error',
      'input',
      'name',
      'welcome',
      'save',
      'delete',
      'update',
      'create',
      'status',
      'selection',
      'permission',
      'creation',
      'modification',
    ];

    for (String suffix in commonSuffixes) {
      if (subject.endsWith(suffix) && subject != suffix) {
        return suffix;
      }
    }

    return subject; // No generic pattern found
  }

  static Future<String?> _tryLoadFile(String path) async {
    try {
      String content = await rootBundle.loadString('assets/$path');

      List<String> lines =
          content
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toList();

      if (lines.isNotEmpty) {
        // Return random variant
        int selectedIndex = Random().nextInt(lines.length);
        return lines[selectedIndex];
      }
    } catch (e) {
      // File not found or other error - this is expected in fallback chain
    }
    return null;
  }

  static void clearCache() {
    _cache.clear();
  }
}
