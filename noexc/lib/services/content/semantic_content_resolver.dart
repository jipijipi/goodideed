import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class SemanticContentResolver {
  static final Map<String, String> _cache = {};
  
  static Future<String> resolveContent(String semanticKey, String originalText) async {
    developer.log('🔍 SEMANTIC_CONTENT: Starting resolution for key: "$semanticKey"', name: 'SemanticContent');
    print('🔍 SEMANTIC_CONTENT: Starting resolution for key: "$semanticKey"');
    
    // Check cache first
    if (_cache.containsKey(semanticKey)) {
      developer.log('⚡ SEMANTIC_CONTENT: Cache hit for key: "$semanticKey"', name: 'SemanticContent');
      print('⚡ SEMANTIC_CONTENT: Cache hit for key: "$semanticKey"');
      return _cache[semanticKey]!;
    }
    
    final parsed = parseSemanticKey(semanticKey);
    developer.log('📝 SEMANTIC_CONTENT: Parsed key - actor: ${parsed['actor']}, action: ${parsed['action']}, subject: ${parsed['subject']}, modifiers: ${parsed['modifiers']}', name: 'SemanticContent');
    print('📝 SEMANTIC_CONTENT: Parsed key - actor: ${parsed['actor']}, action: ${parsed['action']}, subject: ${parsed['subject']}, modifiers: ${parsed['modifiers']}');
    
    // Validate semantic key
    if (parsed['actor'] == null || parsed['action'] == null || parsed['subject'] == null) {
      developer.log('❌ SEMANTIC_CONTENT: Invalid semantic key format, using original text', name: 'SemanticContent');
      _cache[semanticKey] = originalText;
      return originalText;
    }
    
    String actor = parsed['actor']!;
    String action = parsed['action']!;
    String subject = parsed['subject']!;
    List<String> modifiers = parsed['modifiers'] ?? [];
    
    // Build fallback chain
    List<String> fallbackPaths = buildFallbackChain(actor, action, subject, modifiers);
    developer.log('🔗 SEMANTIC_CONTENT: Built fallback chain with ${fallbackPaths.length} paths:', name: 'SemanticContent');
    for (int i = 0; i < fallbackPaths.length; i++) {
      developer.log('   ${i + 1}. ${fallbackPaths[i]}', name: 'SemanticContent');
    }
    
    // Try each path in order
    for (int i = 0; i < fallbackPaths.length; i++) {
      String path = fallbackPaths[i];
      developer.log('🔍 SEMANTIC_CONTENT: Trying path ${i + 1}/${fallbackPaths.length}: $path', name: 'SemanticContent');
      print('🔍 SEMANTIC_CONTENT: Trying path ${i + 1}/${fallbackPaths.length}: $path');
      String? content = await _tryLoadFile(path);
      if (content != null) {
        developer.log('✅ SEMANTIC_CONTENT: Success! Found content at path: $path', name: 'SemanticContent');
        developer.log('📄 SEMANTIC_CONTENT: Content preview: "${content.length > 100 ? content.substring(0, 100) + '...' : content}"', name: 'SemanticContent');
        print('✅ SEMANTIC_CONTENT: Success! Found content at path: $path');
        print('📄 SEMANTIC_CONTENT: Content preview: "${content.length > 100 ? content.substring(0, 100) + '...' : content}"');
        _cache[semanticKey] = content;
        return content;
      } else {
        developer.log('❌ SEMANTIC_CONTENT: Path not found: $path', name: 'SemanticContent');
        print('❌ SEMANTIC_CONTENT: Path not found: $path');
      }
    }
    
    // Final fallback to original text
    developer.log('🔄 SEMANTIC_CONTENT: All paths failed, falling back to original text: "$originalText"', name: 'SemanticContent');
    print('🔄 SEMANTIC_CONTENT: All paths failed, falling back to original text: "$originalText"');
    _cache[semanticKey] = originalText;
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
  
  static List<String> buildFallbackChain(String actor, String action, String subject, List<String> modifiers) {
    List<String> paths = [];
    
    // 1. Try with all modifiers in order
    if (modifiers.isNotEmpty) {
      String fullModifierChain = modifiers.join('_');
      paths.add('content/$actor/$action/${subject}_${fullModifierChain}.txt');
      
      // 2. Try reducing modifiers from the end (keep most important first)
      for (int i = modifiers.length - 1; i > 0; i--) {
        String partialChain = modifiers.take(i).join('_');
        paths.add('content/$actor/$action/${subject}_${partialChain}.txt');
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
        paths.add('content/$actor/$action/${genericSubject}_${fullModifierChain}.txt');
        
        // Try generic subject with reduced modifiers
        for (int i = modifiers.length - 1; i > 0; i--) {
          String partialChain = modifiers.take(i).join('_');
          paths.add('content/$actor/$action/${genericSubject}_${partialChain}.txt');
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
      'completion', 'failure', 'success', 'error', 'input', 'name', 
      'welcome', 'save', 'delete', 'update', 'create', 'status',
      'selection', 'permission', 'creation', 'modification'
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
      developer.log('📂 SEMANTIC_CONTENT: Attempting to load file: assets/$path', name: 'SemanticContent');
      // Try to load from assets
      String content = await rootBundle.loadString('assets/$path');
      developer.log('📋 SEMANTIC_CONTENT: File loaded successfully, raw content length: ${content.length}', name: 'SemanticContent');
      
      List<String> lines = content
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      
      developer.log('🔢 SEMANTIC_CONTENT: Processed into ${lines.length} non-empty lines', name: 'SemanticContent');
      for (int i = 0; i < lines.length; i++) {
        developer.log('   Line ${i + 1}: "${lines[i]}"', name: 'SemanticContent');
      }
      
      if (lines.isNotEmpty) {
        // Return random variant
        int selectedIndex = Random().nextInt(lines.length);
        String selectedVariant = lines[selectedIndex];
        developer.log('🎲 SEMANTIC_CONTENT: Selected variant ${selectedIndex + 1}/${lines.length}: "$selectedVariant"', name: 'SemanticContent');
        return selectedVariant;
      } else {
        developer.log('⚠️ SEMANTIC_CONTENT: File exists but contains no valid lines', name: 'SemanticContent');
      }
    } catch (e) {
      developer.log('💥 SEMANTIC_CONTENT: Failed to load file assets/$path - Error: $e', name: 'SemanticContent');
    }
    return null;
  }
  
  static void clearCache() {
    _cache.clear();
  }
}