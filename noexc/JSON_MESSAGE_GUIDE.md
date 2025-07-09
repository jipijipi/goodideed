# 📝 Chat Sequence JSON Message Guide

A comprehensive guide for creating chat sequences with all supported message types.

## 🏗️ Basic Sequence Structure

```json
{
  "sequenceId": "your_sequence_name",
  "name": "Human Readable Name",
  "description": "Brief description of what this sequence does",
  "messages": [
    // Array of message objects
  ]
}
```

## 💬 Message Types

### 1. **Basic Bot Message**
Simple message from the bot to the user.

```json
{
  "id": 1,
  "text": "Hello! Welcome to our app.",
  "sender": "bot",
  "delay": 1000,
  "nextMessageId": 2
}
```

**Properties:**
- `id` - Unique identifier within the sequence
- `text` - Message content (supports templating)
- `sender` - "bot" or "user"
- `delay` - Milliseconds to wait before showing
- `nextMessageId` - ID of next message to display

### 2. **User Message**
Message that appears as if sent by the user (for conversation flow).

```json
{
  "id": 5,
  "text": "Thanks for the help!",
  "sender": "user",
  "delay": 500,
  "nextMessageId": 6
}
```

### 3. **Choice Message**
Presents buttons for user to select from.

```json
{
  "id": 10,
  "text": "What would you like to do?",
  "sender": "bot",
  "delay": 1000,
  "isChoice": true,
  "storeKey": "user_preference",
  "choices": [
    {
      "text": "Learn more",
      "nextMessageId": 11
    },
    {
      "text": "Get started",
      "nextMessageId": 15
    },
    {
      "text": "Go to settings",
      "sequenceId": "settings",
      "nextMessageId": 1
    }
  ]
}
```

**Choice Properties:**
- `text` - Button label
- `nextMessageId` - Next message in current sequence
- `sequenceId` - Switch to different sequence (optional)

### 4. **Text Input Message**
Allows user to type a response.

```json
{
  "id": 20,
  "text": "What's your name?",
  "sender": "bot",
  "delay": 1000,
  "isTextInput": true,
  "storeKey": "name",
  "placeholderText": "Enter your name...",
  "nextMessageId": 21
}
```

**Text Input Properties:**
- `isTextInput: true` - Enables text input field
- `storeKey` - Key to store user's input
- `placeholderText` - Hint text in input field

### 5. **Autoroute Message** ⭐ *New Feature*
Invisible routing based on user attributes.

```json
{
  "id": 30,
  "text": "ROUTE",
  "sender": "system",
  "isAutoRoute": true,
  "routes": [
    {
      "condition": "user.subscription == 'premium'",
      "sequenceId": "premium_features",
      "nextMessageId": 1
    },
    {
      "condition": "user.experience_level == 'beginner'",
      "sequenceId": "tutorial",
      "nextMessageId": 1
    },
    {
      "condition": "user.name != null",
      "nextMessageId": 31
    },
    {
      "default": true,
      "nextMessageId": 35
    }
  ]
}
```

**Autoroute Properties:**
- `isAutoRoute: true` - Marks as routing message (invisible to users)
- `routes` - Array of routing conditions
- `condition` - Expression to evaluate (optional for default route)
- `default: true` - Fallback route when no conditions match

## 🎯 Advanced Features

### **Text Templating**
Use stored user data in messages with fallback values.

```json
{
  "id": 40,
  "text": "Welcome back, {name|valued user}! Your subscription is {subscription|free}.",
  "sender": "bot",
  "delay": 1000,
  "nextMessageId": 41
}
```

**Template Syntax:**
- `{key}` - Use stored value or leave unchanged if not found
- `{key|fallback}` - Use stored value or fallback if not found

### **Data Storage**
Store user responses and choices for later use.

```json
{
  "id": 50,
  "text": "What's your experience level?",
  "sender": "bot",
  "isChoice": true,
  "storeKey": "experience_level",
  "choices": [
    {"text": "Beginner", "nextMessageId": 51},
    {"text": "Intermediate", "nextMessageId": 52},
    {"text": "Expert", "nextMessageId": 53}
  ]
}
```

### **Cross-Sequence Navigation**
Jump between different conversation flows.

```json
{
  "id": 60,
  "text": "Would you like to continue or get help?",
  "sender": "bot",
  "isChoice": true,
  "choices": [
    {
      "text": "Continue tutorial",
      "nextMessageId": 61
    },
    {
      "text": "Get help",
      "sequenceId": "support",
      "nextMessageId": 1
    }
  ]
}
```

## 🔧 Condition Syntax Reference

### **Supported Operators:**
- `==` - Equality: `"user.subscription == 'premium'"`
- `!=` - Inequality: `"user.name != null"`
- **Boolean**: `"user.is_premium"` (checks if truthy)

### **Value Types:**
- **Strings**: `'premium'`, `"free"` (use quotes)
- **Null**: `null`
- **Booleans**: `true`, `false`
- **Numbers**: `5`, `10.5`

### **Common Patterns:**

**Check if data exists:**
```json
{"condition": "user.name != null"}
```

**Check subscription type:**
```json
{"condition": "user.subscription == 'premium'"}
```

**Check experience level:**
```json
{"condition": "user.experience_level == 'beginner'"}
```

**Check boolean flags:**
```json
{"condition": "user.onboarding_complete == true"}
```

## 📋 Complete Example Sequence

```json
{
  "sequenceId": "user_onboarding",
  "name": "User Onboarding Flow",
  "description": "Welcome new users and collect preferences",
  "messages": [
    {
      "id": 1,
      "text": "Welcome! Let's get you started.",
      "sender": "bot",
      "delay": 1000,
      "nextMessageId": 2
    },
    {
      "id": 2,
      "text": "What's your name?",
      "sender": "bot",
      "delay": 1000,
      "isTextInput": true,
      "storeKey": "name",
      "placeholderText": "Enter your name...",
      "nextMessageId": 3
    },
    {
      "id": 3,
      "text": "Nice to meet you, {name}! What's your experience level?",
      "sender": "bot",
      "delay": 1000,
      "isChoice": true,
      "storeKey": "experience_level",
      "choices": [
        {"text": "Beginner", "nextMessageId": 4},
        {"text": "Intermediate", "nextMessageId": 4},
        {"text": "Expert", "nextMessageId": 4}
      ]
    },
    {
      "id": 4,
      "text": "ROUTE",
      "sender": "system",
      "isAutoRoute": true,
      "routes": [
        {
          "condition": "user.experience_level == 'Beginner'",
          "sequenceId": "tutorial",
          "nextMessageId": 1
        },
        {
          "condition": "user.experience_level == 'Expert'",
          "sequenceId": "advanced_features",
          "nextMessageId": 1
        },
        {
          "default": true,
          "sequenceId": "main_menu",
          "nextMessageId": 1
        }
      ]
    }
  ]
}
```

## 🎮 Testing Your Sequences

### **Using the Debug Panel:**
1. **Run the app**: `flutter run`
2. **Open Debug Panel**: Tap bug icon (🐛)
3. **Add your sequence**: Update `lib/constants/app_constants.dart`
4. **Test routing**: Use "Reset" and "Clear All Data" for clean tests
5. **Check user data**: View stored values in debug panel

### **Sequence File Location:**
Place your JSON files in: `assets/sequences/your_sequence.json`

### **Register New Sequences:**
Add to `lib/constants/app_constants.dart`:
```dart
static const List<String> availableSequences = [
  'onboarding', 
  'tutorial', 
  'support', 
  'menu', 
  'your_sequence'  // Add here
];
```

Add display name to `lib/config/chat_config.dart`:
```dart
static const Map<String, String> sequenceDisplayNames = {
  'your_sequence': 'Your Sequence Name',
};
```

## 🚀 Best Practices

### **Message IDs:**
- Use sequential numbering: 1, 2, 3, 4...
- Keep gaps for future insertions: 10, 20, 30...
- Use consistent numbering within sequences

### **Autorouting:**
- Always include a `default: true` route as fallback
- Test all condition paths thoroughly
- Use descriptive condition expressions
- Place autoroute messages after data collection

### **Data Storage:**
- Use consistent key naming: `user.name`, `user.subscription`
- Store important choices for routing decisions
- Provide fallback values in templates: `{name|Guest}`

### **User Experience:**
- Add appropriate delays between messages
- Use clear, actionable choice text
- Provide helpful placeholder text for inputs
- Test conversation flow from user perspective

## 📚 Additional Resources

- **Main Documentation**: See `.agent.md` for complete system overview
- **Test Sequences**: Check `assets/sequences/` for working examples
- **Debug Tools**: Use debug panel for rapid testing and iteration
- **User Data**: All stored data persists across app sessions

Happy sequence building! 🎉