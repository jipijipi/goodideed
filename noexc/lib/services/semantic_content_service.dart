import 'package:noexc/services/content/semantic_content_resolver.dart';

class SemanticContentService {
  static final SemanticContentService _instance =
      SemanticContentService._internal();

  /// Singleton instance
  static SemanticContentService get instance => _instance;

  SemanticContentService._internal();

  /// Resolve content using semantic key with fallback to original text
  /// 
  /// [randomize] - When true, bypasses cache to get a fresh random variant each time
  Future<String> getContent(String? semanticKey, String originalText, {bool randomize = false}) async {
    // Handle null or empty semantic keys
    if (semanticKey == null || semanticKey.isEmpty) {
      return originalText;
    }

    return await SemanticContentResolver.resolveContent(
      semanticKey,
      originalText,
      bypassCache: randomize,
    );
  }

  /// Clear the internal cache
  void clearCache() {
    SemanticContentResolver.clearCache();
  }
}
