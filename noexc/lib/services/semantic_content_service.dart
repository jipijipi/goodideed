import 'package:noexc/services/content/semantic_content_resolver.dart';
import 'logger_service.dart';

class SemanticContentService {
  static final SemanticContentService _instance = SemanticContentService._internal();
  
  /// Singleton instance
  static SemanticContentService get instance => _instance;
  
  SemanticContentService._internal();
  
  /// Resolve content using semantic key with fallback to original text
  Future<String> getContent(String? semanticKey, String originalText) async {
    logger.semantic('Request for contentKey: "$semanticKey", originalText: "$originalText"');
    
    // Handle null or empty semantic keys
    if (semanticKey == null || semanticKey.isEmpty) {
      logger.semantic('Empty/null semantic key, returning original text');
      return originalText;
    }
    
    final result = await SemanticContentResolver.resolveContent(semanticKey, originalText);
    logger.semantic('Final result: "$result"', level: LogLevel.info);
    return result;
  }
  
  /// Clear the internal cache
  void clearCache() {
    SemanticContentResolver.clearCache();
  }
}