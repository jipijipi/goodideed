# Semantic Content Authoring Guide
## Complete Documentation for Content Authors

This guide covers everything content authors need to know about creating, organizing, and managing semantic content for the chat application.

---

## **Table of Contents**

1. [Overview](#overview)
2. [Semantic Key Structure](#semantic-key-structure)
3. [File Organization](#file-organization)
4. [Content Creation](#content-creation)
5. [Authoring Best Practices](#authoring-best-practices)
6. [Testing and Validation](#testing-and-validation)
7. [Advanced Techniques](#advanced-techniques)
8. [Troubleshooting](#troubleshooting)

---

## **Overview**

The Semantic Content Management System allows you to create dynamic, reusable content that adapts to different contexts and user states. Instead of hardcoding text in JSON sequences, you use **semantic keys** that reference content files with multiple variants.

### **Key Benefits**
- **Reusability**: Same content used across multiple sequences
- **Variety**: Multiple text variations prevent repetitive interactions
- **Organization**: Content organized by meaning, not file structure
- **Scalability**: Easy to add new content without code changes
- **Localization Ready**: Clean separation for multi-language support

### **How It Works**
```
JSON Sequence: "contentKey": "bot.acknowledge.completion.positive"
↓
System looks for: assets/content/bot/acknowledge/completion_positive.txt
↓
Returns random variant: "Fantastic work!" or "Outstanding job!" etc.
```

---

## **Semantic Key Structure**

### **Core Pattern**
```
{actor}.{action}.{subject}[.modifier1][.modifier2][...]
```

### **Component Definitions**

#### **Actor** (Required)
Who is performing the communication:

| Actor | Purpose | Examples |
|-------|---------|----------|
| `bot` | AI assistant messages | Responses, questions, reactions |
| `user` | User interaction prompts | Choice options, input requests |
| `system` | System notifications | Errors, status updates |
| `narrator` | Contextual explanations | Help text, tutorials |

#### **Action** (Required)
What communicative function is being performed:

| Action | Purpose | Use Cases |
|--------|---------|-----------|
| `acknowledge` | Confirming receipt/completion | Task completion, user input received |
| `request` | Asking for input/action | Name input, status selection |
| `inform` | Providing information | Welcome messages, explanations |
| `react` | Emotional/evaluative responses | Success celebrations, failure support |
| `guide` | Directing user flow | Next steps, navigation |
| `suggest` | Making recommendations | Alternative actions, improvements |
| `explain` | Educational content | Feature explanations, help |
| `announce` | Notifications/updates | New features, status changes |
| `validate` | Confirming correctness | Input validation, confirmation |
| `correct` | Providing corrections | Error corrections, clarifications |
| `conclude` | Ending interactions | Goodbyes, session wrap-ups |
| `transition` | Moving between topics | Topic changes, flow transitions |

#### **Subject** (Required)
What the action is about or applied to:

| Type | Examples | Reusability |
|------|----------|-------------|
| **Generic** | `completion`, `failure`, `input`, `name` | High - used across contexts |
| **Specific** | `task_completion`, `profile_save` | Medium - targeted use |
| **Context-Specific** | `onboarding_welcome`, `critical_error` | Low - single context |

#### **Modifiers** (Optional, Unlimited)
Contextual variations affecting tone, timing, or presentation:

| Category | Examples | Purpose |
|----------|----------|---------|
| **Tone** | `positive`, `supportive`, `celebratory`, `gentle` | Emotional context |
| **Experience** | `first_time`, `returning`, `expert`, `beginner` | User familiarity |
| **Timing** | `immediate`, `delayed`, `urgent`, `scheduled` | Time sensitivity |
| **Context** | `onboarding`, `error_recovery`, `celebration` | Situational context |
| **Intensity** | `mild`, `moderate`, `severe`, `extreme` | Strength of message |
| **Formality** | `casual`, `formal`, `professional`, `friendly` | Communication style |

### **Semantic Key Examples**

#### **Basic Examples**
```
bot.acknowledge.completion                    # Simple completion acknowledgment
bot.request.input.gentle                      # Gentle input request
user.choose.task_status                       # Task status choice options
system.inform.connectivity                   # Connection status information
```

#### **With Modifiers**
```
bot.acknowledge.completion.positive           # Positive completion acknowledgment
bot.acknowledge.completion.positive.first_time # First-time user completion
bot.request.input.gentle.onboarding          # Gentle onboarding input request
user.choose.deadline.urgent                  # Urgent deadline selection
```

#### **Complex Examples**
```
bot.acknowledge.task_completion.celebratory.first_time.immediate
bot.react.failure.supportive.gentle.returning
user.choose.notification_frequency.casual.experienced
```

---

## **File Organization**

### **Directory Structure**
```
assets/content/
├── bot/                    # AI assistant content
│   ├── acknowledge/        # Confirmations and acknowledgments
│   ├── request/           # Requests for user input/action
│   ├── inform/            # Informational messages
│   ├── react/             # Emotional responses
│   ├── guide/             # Flow direction and guidance
│   ├── suggest/           # Recommendations
│   ├── explain/           # Educational content
│   ├── announce/          # Notifications and updates
│   ├── validate/          # Confirmations and validation
│   ├── correct/           # Corrections and clarifications
│   ├── conclude/          # Endings and wrap-ups
│   └── transition/        # Topic transitions
├── user/                  # User interaction prompts
│   ├── provide/           # Data provision prompts
│   ├── choose/            # Choice selection prompts
│   ├── confirm/           # Confirmation prompts
│   └── report/            # Status reporting prompts
├── system/                # System messages
│   ├── inform/            # System information
│   └── announce/          # System announcements
└── narrator/              # Contextual content
    ├── explain/           # Explanatory content
    └── describe/          # Descriptive content
```

### **File Naming Convention**

#### **Basic Files**
```
{subject}.txt                    # completion.txt
{subject}_{modifier}.txt         # completion_positive.txt
{subject}_{modifier1}_{modifier2}.txt  # completion_positive_first_time.txt
```

#### **Examples**
```
content/bot/acknowledge/
├── completion.txt                        # Basic completion
├── completion_positive.txt               # Positive completion
├── completion_positive_first_time.txt    # First-time positive completion
├── failure.txt                          # Basic failure
├── failure_supportive.txt               # Supportive failure
├── task_completion.txt                  # Task-specific completion
└── task_completion_celebratory.txt      # Celebratory task completion
```

---

## **Content Creation**

### **File Format**

Each content file contains multiple variants, one per line:

```
# content/bot/acknowledge/completion_positive.txt
Fantastic work!
Outstanding job completing that task!
Excellent! You have successfully finished.
Brilliant work - task completed!
Amazing job! Well done.
```

#### **File Format Rules**
- **One variant per line**
- **Empty lines ignored**
- **No special formatting required**
- **UTF-8 encoding**
- **Max ~200 characters per variant (recommended)**

### **Multi-Text Content**

For content that should split into multiple message bubbles, use `|||` separator:

```
# content/bot/inform/onboarding_welcome.txt
Welcome to the app! ||| I'm here to help you stay organized. ||| Let's get started together.
Hello and welcome! ||| This app will help you track your daily goals. ||| Ready to begin?
Great to have you here! ||| We'll work together to build productive habits. ||| Let's dive in!
```

### **Content Variants Guidelines**

#### **Variety in Length**
```
✅ Good - Mix of lengths:
Great work!
Task completed successfully!
Excellent job finishing that task today!

❌ Avoid - All same length:
Great work!
Good stuff!
Nice job!
```

#### **Variety in Tone**
```
✅ Good - Consistent but varied:
Fantastic work!
Well done!
Excellent job!
Outstanding effort!

❌ Avoid - Inconsistent tone:
Great job!
Task done.
OMG AMAZING!!!
```

#### **Appropriate Formality**
```
✅ Casual context:
Nice work!
Way to go!
You did it!

✅ Professional context:
Task completed successfully.
Excellent work on this deliverable.
Thank you for completing this task.
```

---

## **Content Creation Workflow**

### **Step 1: Identify Content Needs**

When creating new content, ask:
1. **Who is speaking?** (actor)
2. **What are they doing?** (action)
3. **What is it about?** (subject)
4. **What's the context?** (modifiers)

### **Step 2: Choose Reusability Level**

#### **High Reusability** (Generic subjects)
Use when content applies to many contexts:
```
bot.acknowledge.completion.positive
→ Used for: task completion, profile saves, form submissions, etc.
```

#### **Medium Reusability** (Specific subjects)
Use when content is context-specific but still reusable:
```
bot.acknowledge.task_completion.positive
→ Used for: task completions only, but across all task types
```

#### **Low Reusability** (Highly specific)
Use when content is unique to one situation:
```
bot.acknowledge.onboarding_task_completion.celebratory.first_time
→ Used for: first-ever task completion during onboarding only
```

### **Step 3: Create Content Files**

1. **Create directory structure** if it doesn't exist
2. **Start with basic file** (no modifiers)
3. **Add modifier files** as needed
4. **Test with different semantic keys**

### **Step 4: Test Content Resolution**

Use the debug panel or write tests to verify:
- Content resolves correctly
- Fallback chain works as expected
- All variants are appropriate for context

---

## **Authoring Best Practices**

### **Content Quality Guidelines**

#### **1. Maintain Consistent Voice**
All variants within a file should sound like the same speaker:

```
✅ Consistent voice:
Great work on completing that task!
Excellent job finishing everything!
Well done getting that completed!

❌ Inconsistent voice:
Great work on completing that task!
Task done.
WOOHOO! YOU'RE AMAZING!
```

#### **2. Match Context and Tone**
Ensure all variants fit the intended context:

```
✅ Supportive failure context:
That's okay, these things happen.
Don't worry, we can try again.
No problem, let's work through this together.

❌ Wrong tone for failure:
That's okay, these things happen.
Great job trying!
You failed, but that's fine.
```

#### **3. Appropriate Length Variation**
Mix short and long variants for natural variety:

```
✅ Good length variation:
Perfect!
Great work!
Excellent job completing that!
Outstanding work finishing everything today!

❌ Poor length variation:
Perfect!
Great!
Nice!
Good!
```

#### **4. Avoid Repetitive Patterns**
Don't start every variant the same way:

```
✅ Varied openings:
Great work!
Well done!
Perfect!
Excellent job!

❌ Repetitive openings:
Great work!
Great job!
Great effort!
Great stuff!
```

### **Fallback Strategy**

Design your content files with the fallback chain in mind:

#### **Most Specific → Most Generic**
```
1. bot/acknowledge/task_completion_positive_first_time.txt  # Most specific
2. bot/acknowledge/task_completion_positive.txt            # Remove last modifier
3. bot/acknowledge/task_completion.txt                     # Remove all modifiers
4. bot/acknowledge/completion_positive_first_time.txt      # Generic subject + modifiers
5. bot/acknowledge/completion_positive.txt                 # Generic subject + fewer modifiers
6. bot/acknowledge/completion.txt                          # Generic subject only
7. bot/acknowledge/default.txt                             # Action default
8. [original text from JSON]                              # Final fallback
```

#### **Content Strategy**
- **Always create** basic files (no modifiers)
- **Prioritize** high-traffic modifiers (`positive`, `supportive`, `gentle`)
- **Consider** generic subjects for maximum reuse
- **Test** fallback paths work smoothly

### **Modifier Usage Guidelines**

#### **Recommended Modifier Order**
When using multiple modifiers, follow this priority order:

```
1. Tone (positive, supportive, celebratory)
2. Experience (first_time, returning, expert)
3. Context (onboarding, error_recovery)
4. Intensity (mild, severe, extreme)
5. Timing (immediate, urgent, delayed)
6. Formality (casual, formal, professional)
```

#### **Example Application**
```
bot.acknowledge.completion.positive.first_time.onboarding.immediate
      ↑ subject    ↑ tone   ↑ experience ↑ context   ↑ timing
```

### **Performance Considerations**

#### **File Size Guidelines**
- **5-15 variants per file** (recommended)
- **Maximum 50 variants** (performance limit)
- **Each variant < 500 characters** (UI compatibility)

#### **Caching Strategy**
- Frequently used content is cached automatically
- Generic subjects cached more aggressively
- Consider file size impact on mobile devices

---

## **Testing and Validation**

### **Manual Testing Methods**

#### **1. Debug Panel Testing**
Use the debug panel to test semantic key resolution:
```
1. Open debug panel (bug icon)
2. Enter semantic key: "bot.acknowledge.completion.positive"
3. Click "Test Resolution"
4. Verify returned content is appropriate
5. Test fallback by using non-existent modifiers
```

#### **2. Sequence Testing**
Test content in actual sequences:
```
1. Add contentKey to sequence JSON
2. Run sequence in app
3. Verify content appears correctly
4. Check multiple runs for variety
```

### **Validation Checklist**

Before publishing content, verify:

#### **File Structure**
- [ ] Files in correct directory structure
- [ ] File names match semantic key pattern
- [ ] No typos in file names
- [ ] UTF-8 encoding

#### **Content Quality**
- [ ] All variants appropriate for context
- [ ] Consistent voice and tone
- [ ] No spelling/grammar errors
- [ ] Appropriate length variation
- [ ] No offensive or inappropriate content

#### **Technical Validation**
- [ ] Files load correctly in app
- [ ] Semantic keys resolve properly
- [ ] Fallback chain works as expected
- [ ] Performance acceptable (< 50 variants per file)

### **Common Issues and Solutions**

#### **Content Not Loading**
```
Problem: Semantic key doesn't resolve to content
Solutions:
1. Check file path matches semantic key exactly
2. Verify file exists in assets/content/ directory
3. Check file encoding is UTF-8
4. Ensure file is included in pubspec.yaml assets
```

#### **Wrong Content Appearing**
```
Problem: Different content than expected
Solutions:
1. Check fallback chain - content may be from generic fallback
2. Verify semantic key structure is correct
3. Check for typos in file names
4. Clear cache and test again
```

#### **Repetitive Content**
```
Problem: Same variant appears repeatedly
Solutions:
1. Add more variants to the file (minimum 3-5 recommended)
2. Check that file has proper line breaks
3. Verify no empty lines at end of file
```

---

## **Advanced Techniques**

### **Content Templating**

For highly dynamic content, you can use template variables within content files:

```
# content/bot/inform/personalized_welcome.txt
Welcome back, {user.name|friend}!
Hello {user.name|there}, ready for another productive day?
Hi {user.name|friend}, let's tackle today's goals together!
```

**Template Syntax:**
- `{key}` - Use stored value or leave unchanged if not found
- `{key|fallback}` - Use stored value or fallback if not found
- Supports dot notation: `{user.profile.name|friend}`

### **Conditional Content**

For content that varies significantly based on user state:

```
# content/bot/react/streak_achievement.txt
Amazing! You've completed {user.streak|several} tasks in a row!
Fantastic streak of {user.streak|multiple} completed tasks!
You're on fire with {user.streak|many} tasks completed!
Incredible {user.streak|task} completion streak!
```

### **Seasonal and Contextual Content**

Create time-sensitive or context-aware content:

```
# content/bot/acknowledge/completion_celebratory_seasonal.txt
Great work! Perfect way to finish your {session.timeOfDay|day}!
Excellent! You're crushing your {session.dayOfWeek|goals}!
Amazing job! {session.season|This} is your most productive time!
```

### **Cross-Language Content Strategy**

Prepare for localization with consistent content organization:

```
assets/content/
├── en/                    # English content
│   ├── bot/acknowledge/
│   └── user/choose/
├── es/                    # Spanish content
│   ├── bot/acknowledge/
│   └── user/choose/
└── fr/                    # French content
    ├── bot/acknowledge/
    └── user/choose/
```

### **A/B Testing Content**

Create variants for testing different approaches:

```
# Traditional approach
content/bot/acknowledge/completion_positive.txt

# A/B test variants
content/bot/acknowledge/completion_positive_variant_a.txt
content/bot/acknowledge/completion_positive_variant_b.txt
```

---

## **Troubleshooting**

### **Common Problems and Solutions**

#### **1. Content Not Appearing**

**Symptoms:** Original JSON text appears instead of content variants

**Possible Causes:**
- File doesn't exist at expected path
- File not included in pubspec.yaml assets
- Semantic key malformed
- File encoding issues

**Solutions:**
1. Check file exists: `assets/content/bot/acknowledge/completion.txt`
2. Verify pubspec.yaml includes: `- assets/content/`
3. Test semantic key format: `actor.action.subject.modifier`
4. Ensure UTF-8 encoding without BOM

#### **2. Wrong Content Resolution**

**Symptoms:** Content from unexpected file appears

**Possible Causes:**
- Fallback chain activating
- Generic subject fallback
- File name doesn't match semantic key

**Debug Steps:**
1. Check exact semantic key used
2. Verify file name matches key exactly
3. Test fallback chain manually
4. Clear cache and retry

#### **3. Cache Issues**

**Symptoms:** Old content appears after file changes

**Solutions:**
1. Hot restart app (not just hot reload)
2. Clear app cache
3. Use debug panel to test specific keys
4. Verify file changes saved correctly

#### **4. Performance Issues**

**Symptoms:** Slow content loading, app lag

**Possible Causes:**
- Too many variants in files (>50)
- Large file sizes
- Too many modifier combinations

**Solutions:**
1. Reduce variants per file to 5-15
2. Split large files into multiple specific files
3. Optimize content file sizes
4. Review modifier usage patterns

### **Debug Tools**

#### **Debug Panel Features**
- Test semantic key resolution
- View fallback chain
- Clear content cache
- Browse content directory
- Test content with different user states

#### **Console Logging**
Enable debug logging to trace content resolution:
```dart
// In SemanticContentResolver
print('Resolving: $semanticKey');
print('Trying path: $path');
print('Fallback chain: $fallbackPaths');
```

---

## **Quick Reference**

### **Semantic Key Cheat Sheet**
```
Pattern: {actor}.{action}.{subject}[.modifier1][.modifier2]

Actors: bot, user, system, narrator
Actions: acknowledge, request, inform, react, guide, suggest, explain, announce, validate, correct, conclude, transition
Common Subjects: completion, failure, input, name, status, welcome, save, delete, update
Common Modifiers: positive, supportive, gentle, first_time, returning, urgent, casual, formal
```

### **File Location Quick Reference**
```
Semantic Key: bot.acknowledge.completion.positive
File Path: assets/content/bot/acknowledge/completion_positive.txt

Semantic Key: user.choose.task_status
File Path: assets/content/user/choose/task_status.txt

Semantic Key: system.inform.connectivity.urgent
File Path: assets/content/system/inform/connectivity_urgent.txt
```

### **Common Patterns**
```
# Bot acknowledgments
bot.acknowledge.completion.positive
bot.acknowledge.failure.supportive
bot.acknowledge.task_completion.celebratory

# User interactions
user.choose.task_status
user.provide.task_name
user.confirm.deletion

# Information sharing
bot.inform.welcome.casual.first_time
bot.explain.feature.detailed
system.announce.update.important
```

---

## **Getting Help**

### **Resources**
- **Technical Documentation**: See `CLAUDE.md` for system details
- **Example Content**: Check existing content files for patterns
- **Debug Tools**: Use debug panel for testing and validation

### **Best Practices Summary**
1. **Start simple** - Create basic files first, add modifiers as needed
2. **Think reusability** - Use generic subjects when possible
3. **Test thoroughly** - Verify content in actual app usage
4. **Maintain consistency** - Keep voice and tone appropriate
5. **Plan for fallbacks** - Ensure graceful degradation
6. **Document decisions** - Keep notes on content strategy choices

This comprehensive guide should enable content authors to create effective, maintainable semantic content that enhances the user experience while maintaining system performance and scalability.