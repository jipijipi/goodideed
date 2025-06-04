import 'dart:convert';

/// The Script model represents a complete conversation script for Tristopher.
/// 
/// To understand this model, think of it like a sophisticated decision tree
/// combined with a state machine. Each script defines:
/// 1. What Tristopher says in different situations
/// 2. How he responds to user choices
/// 3. When certain events should trigger
/// 4. How the conversation branches based on user behavior
/// 
/// The beauty of this design is that it separates content (what Tristopher says)
/// from logic (when and how he says it). This allows content creators to focus
/// on writing engaging dialogue while developers handle the technical implementation.
/// 
/// Key concepts:
/// - Events: Things that happen (like daily check-ins)
/// - Variants: Different ways an event can play out
/// - Conditions: Rules that determine which variant to use
/// - Variables: State that persists across conversations
class Script {
  final String id;
  final String version;
  final ScriptMetadata metadata;
  final Map<String, dynamic> globalVariables;
  final List<DailyEvent> dailyEvents;
  final Map<String, PlotDay> plotTimeline;
  final Map<String, MessageTemplate> messageTemplates;
  
  Script({
    required this.id,
    required this.version,
    required this.metadata,
    required this.globalVariables,
    required this.dailyEvents,
    required this.plotTimeline,
    required this.messageTemplates,
  });

  /// Load a script from JSON (typically from database or external file)
  factory Script.fromJson(Map<String, dynamic> json) {
    return Script(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      version: json['version'],
      metadata: ScriptMetadata.fromJson(json['metadata']),
      globalVariables: json['global_variables'] ?? {},
      dailyEvents: (json['daily_events'] as List)
          .map((e) => DailyEvent.fromJson(e))
          .toList(),
      plotTimeline: (json['plot_timeline'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, PlotDay.fromJson(value))),
      messageTemplates: (json['message_templates'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, MessageTemplate.fromJson(value))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version': version,
      'metadata': metadata.toJson(),
      'global_variables': globalVariables,
      'daily_events': dailyEvents.map((e) => e.toJson()).toList(),
      'plot_timeline': plotTimeline.map((key, value) => 
          MapEntry(key, value.toJson())),
      'message_templates': messageTemplates.map((key, value) => 
          MapEntry(key, value.toJson())),
    };
  }
}

/// Metadata about the script - useful for version control and management
class ScriptMetadata {
  final String author;
  final DateTime createdAt;
  final String description;
  final List<String> supportedLanguages;
  final bool isActive;
  
  ScriptMetadata({
    required this.author,
    required this.createdAt,
    required this.description,
    required this.supportedLanguages,
    required this.isActive,
  });

  factory ScriptMetadata.fromJson(Map<String, dynamic> json) {
    return ScriptMetadata(
      author: json['author'],
      createdAt: DateTime.parse(json['created_at']),
      description: json['description'],
      supportedLanguages: List<String>.from(json['supported_languages']),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'created_at': createdAt.toIso8601String(),
      'description': description,
      'supported_languages': supportedLanguages,
      'is_active': isActive,
    };
  }
}

/// A DailyEvent represents something that can happen on any day based on conditions.
/// 
/// Think of these as Tristopher's "routines" - things he does regularly but with
/// variation. For example, the morning check-in happens every day, but what he says
/// depends on the user's streak, recent performance, and other factors.
/// 
/// The variant system is powerful because it allows for tremendous variety without
/// requiring complex code. Content creators can write dozens of variants for each
/// event, and the system will automatically choose the most appropriate one.
class DailyEvent {
  final String id;
  final EventTrigger trigger;
  final List<EventVariant> variants;
  final Map<String, EventResponse> responses;
  final int priority; // Higher priority events execute first
  
  DailyEvent({
    required this.id,
    required this.trigger,
    required this.variants,
    required this.responses,
    this.priority = 0,
  });

  factory DailyEvent.fromJson(Map<String, dynamic> json) {
    return DailyEvent(
      id: json['id'],
      trigger: EventTrigger.fromJson(json['trigger']),
      variants: (json['variants'] as List)
          .map((v) => EventVariant.fromJson(v))
          .toList(),
      responses: (json['responses'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, EventResponse.fromJson(value))),
      priority: json['priority'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trigger': trigger.toJson(),
      'variants': variants.map((v) => v.toJson()).toList(),
      'responses': responses.map((key, value) => 
          MapEntry(key, value.toJson())),
      'priority': priority,
    };
  }
}

/// EventTrigger defines when an event should fire.
/// 
/// This is like setting an alarm clock with extra conditions. You can specify
/// not just WHEN something should happen (time window) but also under what
/// circumstances (conditions). This prevents irrelevant events from firing.
class EventTrigger {
  final String type; // 'time_window', 'user_action', 'achievement', etc.
  final String? startTime; // Format: "HH:MM"
  final String? endTime;   // Format: "HH:MM"
  final Map<String, dynamic> conditions;
  
  EventTrigger({
    required this.type,
    this.startTime,
    this.endTime,
    required this.conditions,
  });

  factory EventTrigger.fromJson(Map<String, dynamic> json) {
    return EventTrigger(
      type: json['type'],
      startTime: json['start'],
      endTime: json['end'],
      conditions: json['conditions'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (startTime != null) 'start': startTime,
      if (endTime != null) 'end': endTime,
      'conditions': conditions,
    };
  }
}

/// EventVariant represents one possible way an event can play out.
/// 
/// Why variants? Imagine if Tristopher said the exact same thing every morning -
/// users would quickly get bored. Variants add the spice of unpredictability while
/// maintaining narrative consistency. Each variant can have different conditions
/// and weights, creating a dynamic experience.
/// 
/// The weight system works like a lottery - higher weights mean higher chances
/// of being selected, but conditions must also be met.
class EventVariant {
  final String id;
  final double weight; // Probability weight (0.0 to 1.0)
  final Map<String, dynamic> conditions;
  final List<ScriptMessage> messages;
  final Map<String, dynamic>? setVariables;
  
  EventVariant({
    required this.id,
    required this.weight,
    required this.conditions,
    required this.messages,
    this.setVariables,
  });

  factory EventVariant.fromJson(Map<String, dynamic> json) {
    return EventVariant(
      id: json['id'],
      weight: (json['weight'] ?? 1.0).toDouble(),
      conditions: json['conditions'] ?? {},
      messages: (json['messages'] as List)
          .map((m) => ScriptMessage.fromJson(m))
          .toList(),
      setVariables: json['set_variables'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weight': weight,
      'conditions': conditions,
      'messages': messages.map((m) => m.toJson()).toList(),
      if (setVariables != null) 'set_variables': setVariables,
    };
  }
}

/// ScriptMessage represents a single message in the script.
/// 
/// This is more abstract than EnhancedMessageModel because it's the template
/// that gets transformed into an actual message. Think of it as the difference
/// between a recipe (ScriptMessage) and the actual dish (EnhancedMessageModel).
class ScriptMessage {
  final String type;
  final String sender;
  final String? content;
  final String? contentKey; // For localized content
  final Map<String, dynamic>? properties; // Visual properties
  final int? delayMs;
  final List<Map<String, dynamic>>? options;
  
  ScriptMessage({
    required this.type,
    required this.sender,
    this.content,
    this.contentKey,
    this.properties,
    this.delayMs,
    this.options,
  });

  factory ScriptMessage.fromJson(Map<String, dynamic> json) {
    return ScriptMessage(
      type: json['type'],
      sender: json['sender'],
      content: json['content'],
      contentKey: json['content_key'],
      properties: json['properties'],
      delayMs: json['delay'],
      options: json['options'] != null 
          ? List<Map<String, dynamic>>.from(json['options'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'sender': sender,
      if (content != null) 'content': content,
      if (contentKey != null) 'content_key': contentKey,
      if (properties != null) 'properties': properties,
      if (delayMs != null) 'delay': delayMs,
      if (options != null) 'options': options,
    };
  }
}

/// EventResponse defines what happens when a user makes a choice.
/// 
/// This is the "consequence" part of the conversation. When a user clicks
/// "Yes, I completed my goal," this defines what happens next - what event
/// to trigger, what variables to update, etc.
class EventResponse {
  final String? nextEventId;
  final Map<String, dynamic>? setVariables;
  final String? achievementId;
  
  EventResponse({
    this.nextEventId,
    this.setVariables,
    this.achievementId,
  });

  factory EventResponse.fromJson(Map<String, dynamic> json) {
    return EventResponse(
      nextEventId: json['next_event'],
      setVariables: json['set_variables'],
      achievementId: json['achievement_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (nextEventId != null) 'next_event': nextEventId,
      if (setVariables != null) 'set_variables': setVariables,
      if (achievementId != null) 'achievement_id': achievementId,
    };
  }
}

/// PlotDay represents the scripted events for a specific day in the user's journey.
/// 
/// While DailyEvents can happen any day based on conditions, PlotDays are tied
/// to specific days in the user's journey. This creates a narrative arc - like
/// chapters in a book that unfold as the user progresses.
class PlotDay {
  final List<PlotEvent> events;
  final Map<String, dynamic>? conditions; // Optional conditions for this day
  
  PlotDay({
    required this.events,
    this.conditions,
  });

  factory PlotDay.fromJson(Map<String, dynamic> json) {
    return PlotDay(
      events: (json['events'] as List)
          .map((e) => PlotEvent.fromJson(e))
          .toList(),
      conditions: json['conditions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'events': events.map((e) => e.toJson()).toList(),
      if (conditions != null) 'conditions': conditions,
    };
  }
}

/// PlotEvent is a scripted story moment tied to a specific day.
class PlotEvent {
  final String id;
  final List<ScriptMessage> messages;
  final Map<String, dynamic>? conditions;
  final Map<String, dynamic>? setVariables;
  
  PlotEvent({
    required this.id,
    required this.messages,
    this.conditions,
    this.setVariables,
  });

  factory PlotEvent.fromJson(Map<String, dynamic> json) {
    return PlotEvent(
      id: json['id'],
      messages: (json['messages'] as List)
          .map((m) => ScriptMessage.fromJson(m))
          .toList(),
      conditions: json['conditions'],
      setVariables: json['set_variables'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messages': messages.map((m) => m.toJson()).toList(),
      if (conditions != null) 'conditions': conditions,
      if (setVariables != null) 'set_variables': setVariables,
    };
  }
}

/// MessageTemplate allows for dynamic content with variable substitution.
/// 
/// This is incredibly powerful for personalization. Instead of writing
/// "Did you exercise yesterday?" for everyone, you can write
/// "Did you {{goal_action}} yesterday?" and the system fills in each
/// user's specific goal. This makes conversations feel personal while
/// keeping the script manageable.
class MessageTemplate {
  final String text;
  final List<String> variables;
  
  MessageTemplate({
    required this.text,
    required this.variables,
  });

  factory MessageTemplate.fromJson(Map<String, dynamic> json) {
    return MessageTemplate(
      text: json['text'],
      variables: List<String>.from(json['variables']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'variables': variables,
    };
  }

  /// Apply variables to the template to produce final text.
  /// For example: "Hello {{name}}" with {name: "John"} becomes "Hello John"
  String apply(Map<String, dynamic> values) {
    String result = text;
    for (final variable in variables) {
      final value = values[variable]?.toString() ?? '';
      result = result.replaceAll('{{$variable}}', value);
    }
    return result;
  }
}
