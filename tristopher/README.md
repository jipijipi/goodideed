# TRISTOPHER APP

## Summary

**Meet Tristopher, your brutally honest companion that helps you stick to your goals by putting your money where your hate is. This habit-forming app turns your procrastination into real-world consequences - miss your daily target and watch your cash flow to organizations you'd never willingly support. Unprecedented motivation for lasting change.**

## Quick Start for Developers

```bash
# Setup the project
make setup

# Run in development mode
make dev

# Run in staging mode
make staging

# Run in production mode
make prod
```

**📖 For detailed environment setup, see [ENVIRONMENT_SETUP.md](ENVIRONMENT_SETUP.md)**

## Available Commands

```bash
make help          # Show all available commands
make dev           # Run development environment
make staging       # Run staging environment
make prod          # Run production environment
make build-dev     # Build development version
make build-staging # Build staging version
make build-prod    # Build production version
make test          # Run tests
make clean         # Clean build files
```

## Environment Overview

Tristopher is configured with three environments:
- **Development** - Local development with test payments ($0.01 stakes)
- **Staging** - Pre-production testing with realistic test payments ($0.10 stakes)
- **Production** - Live app with real payments ($1.00+ stakes)

Each environment has separate Firebase projects, API endpoints, and feature flags.

---

## Executive Summary

Tristopher is a revolutionary habit formation app that transforms procrastination into real-world consequences. Unlike traditional habit trackers that rely on positive reinforcement, Tristopher leverages the power of loss aversion and negative reinforcement through its unique "anti-charity" system. Users put their money at stake, and if they fail to complete their habits, that money goes to organizations they actively oppose. Paired with a distinctive pessimistic robot personality that employs reverse psychology, Tristopher creates unprecedented motivation for lasting behavioral change.

## The Problem

Despite good intentions, most people fail to maintain new habits:

* 80% of New Year's resolutions fail by February
* Traditional habit apps have high abandonment rates after 2-3 weeks
* Positive reinforcement alone proves insufficient for many users
* People need stronger accountability and consequences to overcome procrastination

The habit formation market is saturated with "cheerleader" apps that offer gentle reminders and gold stars, but users continue to struggle with consistent follow-through.

## The Solution

Tristopher provides a fundamentally different approach to habit formation:

### Core Mechanics:

1. **Anti-Charity Wagering System:** Users place money at stake that goes to organizations they oppose if they fail their daily goals

2. **Pessimistic Robot Interface:** A chatbot with a distinctive personality that uses reverse psychology and brutal honesty

3. **Visual Consequence Representation:** A visual element (like a cute animal) that thrives or suffers based on the user's habit completion

4. **Streak Tracking with Stakes:** Financial consequences increase with consecutive failures to maintain urgency

## The Science Behind Tristopher

Tristopher is built on established principles from behavioral economics and psychology:

* **Loss Aversion:** People are twice as motivated to avoid losses as they are to acquire gains (Kahneman & Tversky, 1979)

* **Commitment Devices:** Voluntary arrangements that restrict future choices by making certain behaviors more costly (Bryan et al., 2010)

* **Psychological Reactance:** People are motivated to prove wrong those who expect them to fail (Brehm, 1966)

* **Value-Based Motivation:** Connecting habit failure to actions that contradict one's identity creates powerful motivation

## Target Market

Our market research identifies four primary customer segments:

1. **Habit Formation Strugglers:** People who have tried and abandoned traditional habit apps

2. **Negative Reinforcement Responders:** Individuals who respond better to "tough love" than positive encouragement

3. **Financial Stakes Motivators:** Users who need real-world consequences to stay accountable

4. **Strong Opinion Holders:** People with strong values who would be horrified to fund opposing causes

### Key Demographics:

* **Age Range:** Primarily 23-42 years old
* **Income Levels:** From students ($25,000) to professionals ($120,000+)
* **Psychographic Profile:** Tech-savvy, strong opinions, dark humor appreciation, previous failed attempts at habit formation

## Market Opportunity

The habit formation and personal development market presents significant opportunities:

* The global self-improvement market is valued at $41 billion, growing at 6.7% annually
* Digital wellness apps are projected to reach $86.9 billion by 2025
* Remote work trends have increased demand for self-discipline tools
* 92% of habit app users report dissatisfaction with current offerings' effectiveness

Tristopher targets an underserved niche of users who need stronger motivation than what conventional apps provide.

## Business Model

Tristopher features multiple revenue streams:

1. **Payment Tiers:**
   * Stakes: from $1 to $99 one-time payments, renewable after completion or failure
   * Program 66: Advanced tracking, higher stakes, customizable robot personality

## Flutter Development

This project is built with Flutter and uses Riverpod for state management.

### Prerequisites
- Flutter SDK (latest stable version)
- Firebase CLI
- Android Studio / Xcode for respective platforms

### Project Structure
- `lib/main.dart` - Production entry point
- `lib/main_dev.dart` - Development entry point  
- `lib/main_staging.dart` - Staging entry point
- `lib/config/environment.dart` - Environment configuration
- `config/` - Environment variable files
- `scripts/` - Build and run scripts

### Key Features Implementation
- **Anti-Charity System**: Core wagering functionality with environment-specific payment handling
- **Tristopher Robot**: Configurable personality levels (1-5) with brutal honesty mode
- **Firebase Integration**: Separate projects per environment for data isolation
- **Payment Processing**: Test payments in dev/staging, real payments in production

For detailed development instructions, see [ENVIRONMENT_SETUP.md](ENVIRONMENT_SETUP.md).

This project is built with Flutter. If you're working on this codebase:

- Make sure you have Flutter installed and properly set up
- Run `flutter pub get` to install dependencies
- Use `flutter run` to launch the app in debug mode

For more information on Flutter development, check out the [official documentation](https://docs.flutter.dev/).
