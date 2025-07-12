# Cross-Sequence Navigation

This document explains the cross-sequence navigation feature in the React Flow authoring tool.

## Overview

Cross-sequence navigation allows you to create flows where nodes can transition between different sequences (groups). This enables complex multi-sequence workflows where users can jump from one conversation flow to another.

## How It Works

### Visual Indicators
- **Cross-sequence edges** appear as purple dashed lines (vs normal gray solid lines)
- **Cross-sequence labels** have purple background and bold text
- **Condition edges** appear as orange solid lines

### Syntax Options

#### 1. Explicit Cross-Sequence Navigation
Use `@sequence_id` in edge labels to explicitly navigate to another sequence:
- `@onboarding` - Navigate to "onboarding" sequence (starts at message 1)
- `@tutorial` - Navigate to "tutorial" sequence 
- `@main` - Navigate to main/ungrouped sequence

#### 2. Auto-Detection
The system automatically detects cross-sequence navigation when:
- An edge connects nodes in different groups
- An edge connects a grouped node to an ungrouped node

#### 3. Standard Edge Labels
- `choice_text::value` - For choice options with custom values
- `condition_expression` - For autoroute conditions (==, !=, >, <, etc.)
- `default` or empty - For default routes

## Export Behavior

### Group Export (`📁 Export Groups as Sequences`)
When exporting groups as sequences:

1. **Each group** becomes a separate JSON sequence file
2. **Cross-sequence navigation** is preserved with `sequenceId` field
3. **Ungrouped nodes** are ignored (not exported)
4. **Group metadata** (groupId, title, description) becomes sequence metadata

### Example Output
```json
{
  "sequenceId": "onboarding",
  "name": "User Onboarding",
  "description": "Initial user setup flow",
  "messages": [
    {
      "id": 1,
      "type": "bot", 
      "text": "Welcome! Ready to get started?",
      "nextMessageId": 2
    },
    {
      "id": 2,
      "type": "choice",
      "storeKey": "user.ready",
      "choices": [
        {
          "text": "Yes, let's go!",
          "value": true,
          "sequenceId": "tutorial",
          "nextMessageId": 1
        },
        {
          "text": "Maybe later",
          "value": false,
          "nextMessageId": 3
        }
      ]
    }
  ]
}
```

## Usage Instructions

### Creating Cross-Sequence Navigation

1. **Create Groups**: Select multiple nodes with Shift+click and create groups
2. **Set Group Metadata**: Double-click group info panel to set groupId, title, description
3. **Add Cross-Sequence Edges**: 
   - Create edges between nodes in different groups (auto-detected)
   - OR use `@sequence_id` syntax in edge labels (explicit)
4. **Export**: Use "📁 Export Groups as Sequences" button

### Edge Label Examples
- `@menu` - Jump to menu sequence
- `Yes::true` - Choice with boolean value  
- `user.age >= 18` - Conditional route
- `default` - Default/fallback route

## Flutter Integration

The exported JSON sequences are compatible with the Flutter chat app and support:
- **sequenceId navigation** - Switch between sequences  
- **Dynamic content** - Template substitution and text variants
- **Conditional routing** - Logic-based sequence switching
- **Choice persistence** - User selections stored and available across sequences

## Benefits

- **Modular Design**: Break complex flows into manageable sequences
- **Reusability**: Sequences can be referenced from multiple places
- **Maintainability**: Easier to update and debug specific conversation flows
- **Scalability**: Support for large, multi-path conversation systems