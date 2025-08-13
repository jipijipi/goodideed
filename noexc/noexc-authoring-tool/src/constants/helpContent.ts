export interface HelpContent {
  title: string;
  description: string;
  examples?: string[];
  tips?: string[];
}

export const helpContent: Record<string, HelpContent> = {
  nodeId: {
    title: "Node ID",
    description: "Unique identifier for this message. Used for navigation and references.",
    examples: ["1", "2", "welcome", "user_input"],
    tips: [
      "Use sequential numbers for simple flows",
      "Use descriptive names for complex flows",
      "Must be unique within the sequence"
    ]
  },

  contentKey: {
    title: "Content Key",
    description: "Semantic identifier for this content. Used for organization, analytics, and content management.",
    examples: ["welcome_message", "error_response", "user_name_input", "main_menu", "difficulty_selection"],
    tips: [
      "Use descriptive, readable names",
      "Follow consistent naming conventions",
      "Helps with content tracking and analytics",
      "Optional but recommended for better organization"
    ]
  },

  botMessage: {
    title: "Bot Message",
    description: "Text message from the bot to the user. Supports templates and multi-text.",
    examples: [
      "Hello! How can I help you?",
      "Your score is {user.score|0} points!",
      "Welcome back {user.name|there}!"
    ],
    tips: [
      "Use {key|fallback} for dynamic content",
      "Use ||| to split into multiple messages",
      "Keep messages conversational and friendly"
    ]
  },

  userMessage: {
    title: "User Message",
    description: "Predefined message that appears to come from the user. Used for conversation flow.",
    examples: [
      "Yes, I'd like to continue",
      "Tell me more about this",
      "I'm ready to start"
    ],
    tips: [
      "Use for scripted conversations",
      "Keep responses natural and varied",
      "Consider user's likely responses"
    ]
  },

  choice: {
    title: "Choice Options",
    description: "Present buttons for user to select from. Can store values and navigate to different sequences.",
    examples: [
      "Continue → next message",
      "Start Tutorial → @tutorial",
      "Beginner::skill_level → store 'beginner' in user data"
    ],
    tips: [
      "Use clear, actionable text",
      "Use :: to store custom values",
      "Use @ for cross-sequence navigation",
      "Always provide meaningful options"
    ]
  },

  textInput: {
    title: "Text Input",
    description: "Collect text input from the user and store it in user data.",
    examples: [
      "Store Key: user.name",
      "Placeholder: Enter your name...",
      "Store Key: user.email"
    ],
    tips: [
      "Always provide a store key",
      "Use clear placeholder text",
      "Validate important inputs",
      "Consider user privacy"
    ]
  },

  autoroute: {
    title: "Auto-Route",
    description: "Invisible decision point that routes users based on conditions. Evaluates user data and directs flow.",
    examples: [
      "user.score >= 100",
      "session.visitCount > 1",
      "user.name != null"
    ],
    tips: [
      "Always include a 'default' route",
      "Use && for AND, || for OR",
      "Test conditions thoroughly",
      "Consider edge cases"
    ]
  },

  dataAction: {
    title: "Data Actions",
    description: "Modify user data and trigger events. Invisible to users but essential for tracking progress.",
    examples: [
      "Set: user.score = 0",
      "Increment: user.score += 10",
      "Trigger: achievement_unlocked",
      "Append: task.activeDays add 2 (Tuesday)",
      "Remove: task.activeDays remove 6 (Saturday)"
    ],
    tips: [
      "Use 'set' to initialize values",
      "Use 'increment'/'decrement' for counters",
      "Use 'trigger' for achievements",
      "Use 'append'/'remove' for list management",
      "Always continue to next message"
    ]
  },

  dataActionType: {
    title: "Data Action Types",
    description: "Different types of data operations you can perform.",
    examples: [
      "set - Set a value",
      "increment - Add to a number",
      "decrement - Subtract from a number",
      "reset - Reset to default value",
      "trigger - Fire an event",
      "append - Add item to a list",
      "remove - Remove item from a list"
    ],
    tips: [
      "Set: For initial values or updates",
      "Increment/Decrement: For scores, counters",
      "Reset: For clearing data",
      "Trigger: For events, achievements",
      "Append: For adding to lists (prevents duplicates)",
      "Remove: For removing items from lists"
    ]
  },

  dataActionKey: {
    title: "Data Key",
    description: "The path to the data property you want to modify. Use dot notation for nested properties.",
    examples: [
      "user.score",
      "user.name",
      "achievements.first_login",
      "session.current_level"
    ],
    tips: [
      "Use dot notation for nested data",
      "Follow consistent naming conventions",
      "Use descriptive property names",
      "Group related data together"
    ]
  },

  dataActionValue: {
    title: "Data Value",
    description: "The value to set, or amount to increment/decrement. Type depends on the operation.",
    examples: [
      "For set: 100, 'John', true",
      "For increment: 10, 1, 5",
      "For reset: 0, null, ''"
    ],
    tips: [
      "Numbers: Use for scores, counters",
      "Strings: Use for names, text",
      "Booleans: Use for flags, settings",
      "Match the expected data type"
    ]
  },

  triggerEvent: {
    title: "Trigger Event",
    description: "Event name to fire when this trigger action executes. Used for achievements, notifications, etc.",
    examples: [
      "achievement_unlocked",
      "level_up",
      "milestone_reached",
      "user_registered"
    ],
    tips: [
      "Use descriptive event names",
      "Follow consistent naming patterns",
      "Consider what the app should do",
      "Document custom events"
    ]
  },

  triggerData: {
    title: "Trigger Data",
    description: "JSON object containing event details. This data is passed to the event handler.",
    examples: [
      '{"achievement": "first_score", "points": 100}',
      '{"level": 2, "bonus": 25}',
      '{"milestone": "tutorial_complete"}'
    ],
    tips: [
      "Use valid JSON format",
      "Include relevant event details",
      "Keep data structure consistent",
      "Test with actual event handlers"
    ]
  },

  storeKey: {
    title: "Store Key",
    description: "Where to save the user's input or choice. Uses dot notation for nested properties.",
    examples: [
      "user.name",
      "user.preferences.theme",
      "profile.contact.email"
    ],
    tips: [
      "Use descriptive property names",
      "Group related data together",
      "Consider data privacy",
      "Use consistent naming"
    ]
  },

  placeholder: {
    title: "Placeholder Text",
    description: "Hint text shown in the input field before user types. Helps users understand what to enter.",
    examples: [
      "Enter your name...",
      "Your email address",
      "Type your message here"
    ],
    tips: [
      "Be clear and specific",
      "Show expected format",
      "Keep it concise",
      "Use encouraging language"
    ]
  },

  crossSequence: {
    title: "Cross-Sequence Navigation",
    description: "Navigate between different conversation sequences using @sequence_id in edge labels.",
    examples: [
      "@tutorial",
      "@onboarding",
      "@support"
    ],
    tips: [
      "Use @ followed by sequence ID",
      "Ensure target sequence exists",
      "Test navigation flow",
      "Consider user context"
    ]
  },

  templateSystem: {
    title: "Template System",
    description: "Insert dynamic values from user data into your messages using {key|fallback} syntax.",
    examples: [
      "{user.name|User}",
      "{user.score|0}",
      "{session.visitCount|1}"
    ],
    tips: [
      "Use | for fallback values",
      "Test with missing data",
      "Use descriptive fallbacks",
      "Keep templates readable"
    ]
  },

  multiText: {
    title: "Multi-Text Messages",
    description: "Split a single message into multiple bubbles using ||| separator.",
    examples: [
      "Hello! ||| How are you today? ||| Ready to begin?",
      "Welcome back! ||| Your progress has been saved. ||| Let's continue."
    ],
    tips: [
      "Use ||| to separate messages",
      "Each part becomes a separate bubble",
      "Keep each part conversational",
      "Don't overuse - 2-3 parts max"
    ]
  },

  edgeContentKey: {
    title: "Edge Content Key",
    description: "Semantic identifier for this choice or condition edge. Used for analytics, content management, and robust references.",
    examples: [
      "main_menu_option",
      "difficulty_selection",
      "continue_button",
      "retry_choice",
      "exit_condition"
    ],
    tips: [
      "Use descriptive, readable names",
      "Follow consistent naming conventions",
      "Helps identify choices in analytics",
      "Useful for content tracking and A/B testing",
      "Optional but recommended for important choices"
    ]
  }
};