# Multi-Text Separator System

## Overview

The Multi-Text Separator System allows creating multiple consecutive messages from a single JSON message using a text separator (`|||`). This replaces the previous array-based approach with a simpler, more maintainable solution that works seamlessly with the variants system.

## Key Features

- **Simple Separator**: Use `|||` to split text into multiple messages
- **Variants Compatible**: Works with the text variants system for dynamic content
- **Uniform Delays**: All split messages use the same delay value
- **Clean JSON**: Reduces verbosity compared to array-based approach
- **Backward Compatible**: Existing single-text messages work unchanged

## Separator Format

### Basic Usage
```json
{
  "id": 2,
  "text": "First message ||| Second message ||| Third message",
  "delay": 1500,
  "sender": "bot",
  "nextMessageId": 3
}
```

### With Template Variables
```json
{
  "id": 5,
  "text": "Hello {user.name|there}! ||| Welcome to our app. ||| Let's get started!",
  "delay": 1000,
  "sender": "bot",
  "nextMessageId": 6
}
```

### With Variants Support
Create `assets/variants/sequence_message_2.txt`:
```
First message ||| Second message ||| Third message
Starting here ||| Continuing now ||| Finishing up
Begin sequence ||| Middle part ||| End sequence
```

## Technical Implementation

### ChatMessage Model
- `hasMultipleTexts`: Detects presence of separator in text
- `allTexts`: Splits text on separator and trims whitespace
- `allDelays`: Returns array of same delay for each split text
- `expandToIndividualMessages()`: Creates individual ChatMessage objects

### Text Processing
1. **Separator Detection**: `text.contains('|||')`
2. **Text Splitting**: `text.split('|||').map((t) => t.trim())`
3. **Empty Filtering**: Removes empty segments after splitting
4. **Delay Distribution**: Same delay applied to all segments

### Variants Integration
- Variants work with the full text (including separators)
- Random variant selection includes separator-formatted text
- Template processing applied after variant selection
- Multi-text messages excluded from variants (single-text only)

## Comparison: Old vs New

### Old Array-Based Approach
```json
{
  "id": 2,
  "text": "Multi-text sequence",
  "texts": [
    "This is the first message in a sequence.",
    "This is the second message that follows immediately.",
    "And this is the third message, all from one JSON object!"
  ],
  "delays": [1000, 1500, 2000],
  "sender": "bot",
  "nextMessageId": 3
}
```

### New Separator-Based Approach
```json
{
  "id": 2,
  "text": "This is the first message in a sequence. ||| This is the second message that follows immediately. ||| And this is the third message, all from one JSON object!",
  "delay": 1500,
  "sender": "bot",
  "nextMessageId": 3
}
```

## Benefits

### Simplicity
- **Single Field**: Only `text` field needed, no `texts` or `delays` arrays
- **Uniform Timing**: One delay value for all messages
- **Less Configuration**: Fewer fields to manage in JSON

### Maintainability
- **Easier Editing**: Edit all related messages in one place
- **Version Control**: Better diff visualization for changes
- **Reduced Complexity**: Simpler data structure

### Variants Compatibility
- **Full Integration**: Works seamlessly with variants system
- **Dynamic Content**: Variants can include separator-formatted text
- **Template Support**: Full template processing on variant text

### Performance
- **Reduced Memory**: No separate arrays for texts and delays
- **Faster Parsing**: Simple string operations vs array processing
- **Efficient Storage**: Compact JSON representation

## Usage Guidelines

### When to Use Multi-Text
- **Related Messages**: Logically connected content that should flow together
- **Explanatory Sequences**: Step-by-step instructions or explanations
- **Narrative Flow**: Story-like content that builds progressively
- **Information Chunks**: Breaking down complex information

### When to Use Single Messages
- **Interactive Points**: Messages followed by choices or input
- **Different Delays**: When messages need different timing
- **Variants**: When you want text variations (variants don't work with multi-text)
- **Independent Content**: Unrelated messages

### Best Practices
- **Consistent Spacing**: Use ` ||| ` (space-separator-space) for readability
- **Logical Grouping**: Keep related content together in one multi-text message
- **Reasonable Length**: Don't create overly long multi-text sequences
- **Clear Separation**: Ensure each segment is complete and meaningful

## Migration Guide

### From Array-Based to Separator-Based

1. **Identify Multi-Text Messages**: Find messages with `texts` array
2. **Combine Text**: Join array elements with ` ||| ` separator
3. **Use Single Delay**: Replace `delays` array with single `delay` value
4. **Remove Arrays**: Delete `texts` and `delays` fields
5. **Test Functionality**: Verify message flow works correctly

### Example Migration
```json
// Before
{
  "texts": ["Hello!", "How are you?", "Ready to start?"],
  "delays": [1000, 1500, 1000]
}

// After
{
  "text": "Hello! ||| How are you? ||| Ready to start?",
  "delay": 1200
}
```

## Configuration

### Separator Constant
```dart
// lib/config/chat_config.dart
static const String multiTextSeparator = '|||';
```

### Customization
To change the separator:
1. Update `ChatConfig.multiTextSeparator`
2. Update existing JSON files
3. Update variant files
4. Run tests to verify compatibility

## Testing

### Test Coverage
- Separator detection and text splitting
- Delay distribution for multi-text messages
- Message expansion to individual messages
- Empty segment filtering
- Whitespace handling around separators
- Integration with variants system

### Example Tests
```dart
test('should detect multi-text message with separator', () {
  final message = ChatMessage(
    id: 1,
    text: 'First ||| Second ||| Third',
    sender: 'bot',
  );
  expect(message.hasMultipleTexts, isTrue);
});
```

## Future Enhancements

### Potential Features
- **Custom Separators**: Per-message separator configuration
- **Delay Modifiers**: Simple syntax for delay variations (e.g., `|||+500`)
- **Conditional Segments**: Show/hide segments based on user data
- **Nested Separators**: Support for hierarchical message structures

### Backward Compatibility
The system maintains full backward compatibility:
- Existing single-text messages work unchanged
- No breaking changes to existing APIs
- Gradual migration path available
- Legacy array support can be maintained if needed

## Conclusion

The Multi-Text Separator System provides a cleaner, more maintainable approach to multi-message sequences while maintaining full compatibility with the variants system and existing functionality. The `|||` separator offers an intuitive way to create flowing conversations without the complexity of array-based configurations.