# PRD: Direct User Input in Conversation Flow

## Overview
Add the ability for users to type free-form text responses within the scripted conversation flow, complementing the existing multiple choice system.

## Current State
- ✅ Two-sided chat with bot and user messages
- ✅ Multiple choice interactions as clickable user bubbles
- ✅ Basic branching based on choice selection
- ✅ Nested choice points in conversation flow

## Goal
Enable direct text input at specific points in the conversation while maintaining the simple, maintainable architecture.

## Core Concept
- Bot asks an open-ended question
- Text input field appears in conversation flow as a user message bubble
- Input field styled like user messages (right-aligned, same colors)
- User types response and submits
- Input field transforms into regular user message
- Conversation continues with bot's scripted response

## Visual Flow Example
```
Bot: "What's your name?"

[User message bubble with text input: "Type your answer..."] [Send]
                                                           ↑
                                    Right-aligned like user messages

User types "Alice" and presses Send →

Bot: "What's your name?"
User: "Alice"                    ← Now a regular user message
Bot: "Nice to meet you, Alice! How can I help you today?"
```

## Technical Design

### 1. Enhanced Message Types
```dart
enum MessageType { text, choice, input }

class ChatMessage {
  // ... existing fields
  final MessageType type;           // NEW: message type
  final String? inputPrompt;        // NEW: placeholder text for input
  final String? inputVariable;      // NEW: variable name to store input
  final int? nextMessageId;         // EXISTING: where to go after input
}
```

### 2. Updated JSON Structure
```json
{
  "id": 5,
  "text": "What's your name?",
  "delay": 1000,
  "sender": "bot",
  "type": "input",
  "inputPrompt": "Type your name here...",
  "inputVariable": "userName",
  "nextMessageId": 6
}
```

### 3. Variable Storage & Templating
```dart
class ConversationState {
  final Map<String, String> userInputs = {};
  
  void storeInput(String variable, String value) {
    userInputs[variable] = value;
  }
  
  String replaceVariables(String text) {
    String result = text;
    userInputs.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }
}
```

### 4. Template Messages
```json
{
  "id": 6,
  "text": "Nice to meet you, {{userName}}! How can I help you today?",
  "delay": 1500,
  "sender": "bot"
}
```

## Implementation Plan

### Phase 1: Basic Input Support (2 hours)

#### Step 1: Update Models (30 min)
- Add `MessageType` enum
- Add `type`, `inputPrompt`, `inputVariable` to ChatMessage
- Update JSON parsing and tests

#### Step 2: Update UI (60 min)
- Add text input widget that appears for input messages
- Handle input submission
- Hide input field after submission
- Style input field to match app design

#### Step 3: Basic Variable Storage (30 min)
- Create ConversationState class
- Store user inputs by variable name
- Basic template replacement in bot messages

### Phase 2: Enhanced Features (1 hour)

#### Step 4: Input Validation (30 min)
- Optional input validation rules
- Error messages for invalid input
- Required vs optional inputs

#### Step 5: Polish & Testing (30 min)
- Keyboard handling (Enter to submit)
- Focus management
- Comprehensive tests

## UI Components

### Input Widget
```dart
class ChatInputBubble extends StatefulWidget {
  final String prompt;
  final Function(String) onSubmit;
  final String? validationPattern;
  
  // Styled as user message bubble (right-aligned, user colors)
  // Contains text field with send button inside bubble
  // Validates input before submission
  // Handles keyboard events
}
```

### Updated Message Bubble Builder
```dart
Widget _buildMessageBubble(ChatMessage message) {
  if (message.isChoice && message.choices != null) {
    return _buildChoiceBubbles(message);
  }
  if (message.type == MessageType.input) {
    return _buildInputBubble(message);
  }
  return _buildRegularBubble(message);
}

Widget _buildInputBubble(ChatMessage message) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end, // Right-aligned like user
      children: [
        Flexible(
          child: Container(
            // Same styling as user message bubbles
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ChatInputField(
              prompt: message.inputPrompt ?? "Type your response...",
              onSubmit: (text) => _onInputSubmitted(text, message),
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: const Icon(Icons.person, color: Colors.white),
        ),
      ],
    ),
  );
}
```

## JSON Examples

### Simple Input
```json
{
  "id": 10,
  "text": "What's your favorite color?",
  "delay": 1000,
  "sender": "bot",
  "type": "input",
  "inputPrompt": "Enter a color...",
  "inputVariable": "favoriteColor",
  "nextMessageId": 11
}
```

### Input with Validation
```json
{
  "id": 15,
  "text": "Please enter your email address:",
  "delay": 1000,
  "sender": "bot",
  "type": "input",
  "inputPrompt": "your@email.com",
  "inputVariable": "userEmail",
  "validationPattern": "^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$",
  "errorMessage": "Please enter a valid email address",
  "nextMessageId": 16
}
```

### Using Stored Variables
```json
{
  "id": 20,
  "text": "Thanks {{userName}}! Your favorite color {{favoriteColor}} is beautiful.",
  "delay": 1500,
  "sender": "bot"
}
```

## Mixed Conversation Flow
```json
{
  "messages": [
    {
      "id": 1,
      "text": "Hi! Let's get to know each other.",
      "delay": 1000,
      "sender": "bot"
    },
    {
      "id": 2,
      "text": "What's your name?",
      "delay": 1500,
      "sender": "bot",
      "type": "input",
      "inputPrompt": "Type your name...",
      "inputVariable": "userName",
      "nextMessageId": 3
    },
    {
      "id": 3,
      "text": "Nice to meet you, {{userName}}! What would you like to do?",
      "delay": 1500,
      "sender": "bot"
    },
    {
      "id": 4,
      "text": "CHOICES",
      "delay": 1000,
      "sender": "user",
      "isChoice": true,
      "choices": [
        {"text": "Learn about features", "nextMessageId": 10},
        {"text": "Get personalized help", "nextMessageId": 20}
      ]
    }
  ]
}
```

## Benefits

### For Users
- **Natural interaction**: Can express themselves in their own words
- **Personalized experience**: Bot uses their name and preferences
- **Flexible responses**: Not limited to predefined choices

### For Developers
- **Simple integration**: Builds on existing choice system
- **Maintainable**: Clean separation of input handling
- **Extensible**: Easy to add validation and advanced features

### For Content Creators
- **Rich conversations**: Mix of structured choices and open input
- **Personalization**: Use collected data in later messages
- **Easy authoring**: Simple JSON structure

## Technical Considerations

### Input Handling
- Sanitize user input for security
- Handle empty/whitespace-only input
- Graceful error handling for validation failures

### State Management
- Store user inputs persistently during conversation
- Clear state when conversation restarts
- Handle app backgrounding/foregrounding

### UI/UX
- **Consistent styling**: Input bubble matches user message appearance exactly
- **Smooth transformation**: Input field morphs into regular message on submit
- **Visual continuity**: Maintains conversation flow without layout shifts
- **Focus management**: Auto-focus input when it appears
- **Keyboard handling**: Enter to submit, proper keyboard dismissal
- **Accessible design**: Screen reader support for input prompts

## Success Metrics
- **User engagement**: Measure completion rates for input prompts
- **Input quality**: Track meaningful vs empty responses
- **Technical performance**: Input response time < 100ms
- **Error rates**: < 5% validation failures

## Future Enhancements
- **Rich input types**: Numbers, dates, multiple lines
- **Input suggestions**: Auto-complete based on context
- **Voice input**: Speech-to-text integration
- **Smart validation**: Context-aware input checking

## Total Implementation Time: ~3 hours
This maintains the simple architecture while adding powerful personalization capabilities through direct user input.