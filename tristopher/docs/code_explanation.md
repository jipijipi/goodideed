# Tristopher App - Code Explanation

## Overview

Tristopher is a Flutter application designed to help users build habits through a unique approach that combines daily goal tracking, financial incentives, and a quirky de-motivational character named Tristopher. The app implements the "anti-charity" concept where users risk money that will be donated to causes they oppose if they fail to meet their goals.

## Application Architecture

The app follows a standard Flutter architecture with some specific patterns:

- **State Management**: Uses Flutter Riverpod for reactive state management
- **Persistence**: Utilizes SharedPreferences for simple data storage
- **UI**: Implements a chat-based interface with Tristopher as the primary interaction method

## Core Components

### Models

1. **UserModel** (`lib/models/user_model.dart`)
   - Core data structure for user information
   - Contains personal details, goal information, stake amounts, streaks, and achievements
   - Implements serialization methods for persistence
   - Provides helper methods for formatting and state checking

2. **DailyLogModel** (`lib/models/daily_log_model.dart`)
   - Records daily goal completion status
   - Tracks stake amounts and whether stakes were lost
   - Used for historical tracking and analytics

3. **MessageModel** (`lib/models/message_model.dart`)
   - Represents different types of messages in the chat interface
   - Supports text, options, input, achievement, and streak notifications
   - Factory methods for creating different message types

### Services

1. **UserService** (`lib/services/user_service.dart`)
   - Manages user data persistence
   - Handles creating, reading, and updating user profiles
   - Manages daily check-ins and streak calculations
   - Implements achievement tracking and verification

2. **StoryService** (`lib/services/story_service.dart`)
   - Provides contextual dialogue for Tristopher
   - Adapts messaging based on user state (streaks, failures, etc.)
   - Contains multiple response options for variety
   - Manages the tone and character of the application

3. **OnboardingService** (`lib/services/onboarding_service.dart`)
   - Controls the user onboarding flow
   - Tracks completion of onboarding steps
   - Determines when users should see onboarding vs. main functionality

### State Management

1. **Providers** (`lib/providers/providers.dart`)
   - Defines Riverpod providers for accessing services and state
   - Manages chat message state through `ChatMessagesNotifier`
   - Implements reactive state for UI components
   - Provides access to user data and completion history

### Screens

1. **Main Screens**
   - `SplashScreen`: Initial loading screen
   - `OnboardingScreen`: User setup and goal definition
   - `MainChatScreen`: Primary interface for interacting with Tristopher
   - `GoalScreen`: For setting and managing goals
   - `AccountScreen`: User profile and settings

## Data Flow

1. **User Registration**
   - New users go through onboarding to set up their profile
   - Goal and stake information is collected
   - User data is persisted via UserService

2. **Daily Check-ins**
   - Users report whether they completed their goal
   - Success updates streak counts and triggers potential achievements
   - Failure resets streaks and (conceptually) transfers stake to anti-charity
   - Results are saved in daily logs

3. **Chat Interaction**
   - UI primarily driven by chat interface
   - Tristopher provides feedback, reminders, and responses
   - Story service adapts dialogue based on user history and state

## Memory Persistence

1. **User Data**
   - Stored as JSON under the `user_data` key in SharedPreferences
   - Contains all profile, goal, and progress information
   - Loaded on app startup and updated as needed

2. **Daily Logs**
   - Stored as JSON under the `daily_logs` key in SharedPreferences
   - Keyed by date for efficient lookup
   - Used for streak calculation and history display

## Key Features

1. **66-Day Challenge**
   - Based on research about habit formation timeframes
   - Tracks progress toward the 66-day milestone
   - Awards achievements for completing the challenge

2. **Anti-Charity Concept**
   - Users stake money that goes to causes they oppose if they fail
   - Provides stronger motivation than positive incentives alone
   - Stake amounts can be adjusted over time

3. **Streak Tracking**
   - Counts consecutive days of goal completion
   - Records and displays the longest streak achieved
   - Provides contextual responses based on streak length

4. **Achievement System**
   - Recognizes milestones like streak lengths (7 days, 30 days)
   - Acknowledges completing the 66-day challenge
   - Even has a "first failure" achievement for realism

## Technical Implementation Details

1. **Message System**
   - Implements a flexible message model for different interaction types
   - Chat messages are held in memory during a session
   - Different message types render with appropriate UI components

2. **State Notifications**
   - Riverpod providers enable reactive UI updates
   - State changes (like streak updates) trigger UI refreshes
   - Future providers handle asynchronous data loading

3. **Preference Storage**
   - SharedPreferences provides simple key-value storage
   - JSON serialization handles complex object storage
   - Date conversions maintain temporal data accurately

## Future Improvements

Potential areas for enhancement:

1. **Cloud Sync**: Move from local storage to a cloud backend
2. **Actual Payment Processing**: Implement real stake payments
3. **Analytics**: More detailed tracking and visualization of progress
4. **Social Features**: Accountability partners or community challenges
5. **Expanded Achievement System**: More milestones and rewards
