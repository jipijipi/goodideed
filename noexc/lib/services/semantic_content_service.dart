import 'package:noexc/services/content/semantic_content_resolver.dart';
import 'dart:developer' as developer;

class SemanticContentService {
  static final SemanticContentService _instance = SemanticContentService._internal();
  
  /// Singleton instance
  static SemanticContentService get instance => _instance;
  
  SemanticContentService._internal();
  
  /// Resolve content using semantic key with fallback to original text
  Future<String> getContent(String? semanticKey, String originalText) async {
    developer.log('🚀 SEMANTIC_SERVICE: Request for contentKey: "$semanticKey", originalText: "$originalText"', name: 'SemanticContentService');
    
    // Handle null or empty semantic keys
    if (semanticKey == null || semanticKey.isEmpty) {
      developer.log('🔄 SEMANTIC_SERVICE: Empty/null semantic key, returning original text', name: 'SemanticContentService');
      return originalText;
    }
    
    final result = await SemanticContentResolver.resolveContent(semanticKey, originalText);
    developer.log('✨ SEMANTIC_SERVICE: Final result: "$result"', name: 'SemanticContentService');
    return result;
  }
  
  /// Clear the internal cache
  void clearCache() {
    SemanticContentResolver.clearCache();
  }
}