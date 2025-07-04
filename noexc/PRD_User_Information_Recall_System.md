# Product Requirements Document (PRD)
## User Information Recall System for noexc Chat App

### 1. Overview

**Product**: User Information Recall System  
**Version**: 1.0  
**Date**: Current  
**Status**: New Feature  

### 2. Problem Statement

The current chat application collects user information through:
- **Choice selections** (e.g., "App features", "Getting started", "Troubleshooting")
- **Text inputs** (e.g., user's name in message ID 23)

However, this information is not persisted or recalled in subsequent conversations, leading to:
- Repetitive questions asking for the same information
- Poor user experience due to lack of personalization
- Inability to reference previous user preferences or inputs

### 3. Product Goals

**Primary Goals:**
- Enable the app to remember user choices and text inputs across conversation sessions
- Provide personalized responses based on previously collected information
- Reduce friction by avoiding repetitive questions

**Secondary Goals:**
- Maintain user privacy with local storage only
- Keep the implementation simple and lightweight

### 4. User Stories

**As a user, I want to:**
1. Have the app remember my name so I don't have to re-enter it
2. Have the app recall my previous interests/choices to provide relevant suggestions
3. See personalized greetings that reference my previous interactions

**As a developer, I want to:**
1. Easily access previously stored user information in chat scripts

### 5. Functional Requirements

#### 5.1 Core Features

**Information Storage:**
- Store user text inputs and relevant choice selections (e.g., name, preferences) locally on device
- Persist data across app sessions
- Support key-value storage with simple data types (String, int, bool, List<String>)

**Information Retrieval:**
- Provide simple API to check if information exists
- Retrieve stored values with default fallbacks
- Support dynamic text templating using stored values


#### 5.2 Chat Script Integration

**New Message Properties:**
```json
{
  "id": 25,
  "text": "Welcome back, {user.name}!",
  "storeKey": "user.name"
}
```

**Text Templating:**
- Dynamic text substitution using stored values with `{key}` syntax
- Fallback to original text if stored value doesn't exist
- Support for nested object notation (e.g., `{user.name}`, `{preferences.theme}`)


### 6. Technical Requirements

#### 6.1 Data Storage
- Use Flutter's `shared_preferences` package for local storage
- JSON serialization for complex data structures

#### 6.2 New Classes/Services

**UserDataService:**
```dart
class UserDataService {
  Future<void> storeValue(String key, dynamic value);
  Future<T?> getValue<T>(String key);
  Future<bool> hasValue(String key);
  Future<void> removeValue(String key);
  Future<void> clearAllData();
  Future<Map<String, dynamic>> getAllData();
}
```

**Enhanced ChatMessage:**
```dart
class ChatMessage {
  // Existing properties...
  final String? storeKey;        // Key to store user input/choice
}
```



### 12. Appendix



#### A. Example Implementation
```dart
// Example of enhanced chat message with recall capability
{
  "id": 23,
  "text": "What's your name so I can personalize your experience?",
  "delay": 1000,
  "sender": "bot",
  "isTextInput": true,
  "storeKey": "user.name",
  "nextMessageId": 24
}

// Personalized follow-up message with templating
{
  "id": 24,
  "text": "Nice to meet you, {user.name}! How would you like to get started?",
  "delay": 1500,
  "sender": "bot"
}
```

#### C. Data Schema
```json
{
  "user.name": "John Doe",
  "user.interests": ["App features", "Chat system"],
  "user.lastVisit": "2024-01-15T10:30:00Z",
  "user.completedFlows": ["getting_started", "troubleshooting"],
  "preferences.skipIntro": true
}
```