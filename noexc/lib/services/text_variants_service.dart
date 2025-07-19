import 'dart:math';
import 'package:flutter/services.dart';

class TextVariantsService {
  static const String _variantsBasePath = 'assets/variants/';
  static const String _variantsFileExtension = '.txt';
  
  // Cache for loaded variants to avoid repeated file reads
  final Map<String, List<String>> _variantsCache = {};
  final Random _random = Random();

  /// Get a random variant for the given text
  /// If no variants file exists, returns the original text
  /// Supports multi-text messages with separator
  Future<String> getVariant(String originalText, String sequenceId, int messageId) async {
    // Create a unique key for this message's variants
    final variantKey = '${sequenceId}_message_$messageId';
    
    try {
      // Check cache first
      if (_variantsCache.containsKey(variantKey)) {
        final variants = _variantsCache[variantKey]!;
        if (variants.isNotEmpty) {
          return variants[_random.nextInt(variants.length)];
        }
        return originalText;
      }
      
      // Try to load variants file
      final variants = await _loadVariants(variantKey);
      if (variants.isNotEmpty) {
        return variants[_random.nextInt(variants.length)];
      }
      
      return originalText;
    } catch (e) {
      // If variants file doesn't exist or can't be loaded, return original text
      return originalText;
    }
  }

  /// Load variants from file and cache them
  Future<List<String>> _loadVariants(String variantKey) async {
    try {
      final assetPath = '$_variantsBasePath$variantKey$_variantsFileExtension';
      final String content = await rootBundle.loadString(assetPath);
      
      // Split by lines and filter out empty lines
      final variants = content
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      
      // Cache the variants
      _variantsCache[variantKey] = variants;
      
      return variants;
    } catch (e) {
      // File doesn't exist or can't be loaded
      _variantsCache[variantKey] = [];
      return [];
    }
  }

  /// Clear the variants cache (useful for testing or memory management)
  void clearCache() {
    _variantsCache.clear();
  }

  /// Check if variants exist for a specific message
  Future<bool> hasVariants(String sequenceId, int messageId) async {
    final variantKey = '${sequenceId}_message_$messageId';
    
    if (_variantsCache.containsKey(variantKey)) {
      return _variantsCache[variantKey]!.isNotEmpty;
    }
    
    try {
      final variants = await _loadVariants(variantKey);
      return variants.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get all available variants for a message (useful for debugging)
  Future<List<String>> getAllVariants(String sequenceId, int messageId) async {
    final variantKey = '${sequenceId}_message_$messageId';
    
    if (_variantsCache.containsKey(variantKey)) {
      return List.from(_variantsCache[variantKey]!);
    }
    
    return await _loadVariants(variantKey);
  }
}