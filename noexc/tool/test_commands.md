# Compact Test Running Commands

## Quick Test Overview

### Ultra-Compact Commands
```bash
# Show only failures
flutter test --reporter failures-only

# Compact format (one line per test)
flutter test --reporter compact

# JSON output for analysis
flutter test --reporter json --file-reporter json:results.json

# TDD runner (quietest)
dart tool/tdd_runner.dart --quiet

# Quick summary script
./tool/quick_test_summary.sh
```

### Category-Based Testing
```bash
# Core functionality (86 failures)
flutter test test/services/ --reporter failures-only

# CLI tools (33 failures) 
flutter test test/cli/ --reporter failures-only

# Models (2 failures - simple fixes)
flutter test test/models/ --reporter failures-only

# Widgets (1 failure)
flutter test test/widgets/ --reporter failures-only

# Validation (3 failures)
flutter test test/validation/ --reporter failures-only
```

### Parallel Testing Strategy
```bash
# Run categories in parallel with sharding
flutter test test/services/ --total-shards=4 --shard-index=0 --reporter compact &
flutter test test/cli/ --total-shards=4 --shard-index=1 --reporter compact &
flutter test test/models/ --total-shards=4 --shard-index=2 --reporter compact &
flutter test test/widgets/ --total-shards=4 --shard-index=3 --reporter compact &
wait
```

### Targeted Testing
```bash
# Specific test patterns
flutter test --name "ChatMessage" --reporter failures-only
flutter test --name "SemanticContent" --reporter failures-only
flutter test --name "ErrorHandler" --reporter failures-only

# Single test files
flutter test test/models/chat_message_test.dart --reporter expanded
flutter test test/services/error_handler_test.dart --reporter failures-only
```

## Current Failure Analysis (27 total failures)

### High Priority Fixes (2 failures - Easy)
- **Models**: `chat_message_test.dart` - Default delay expectation wrong (Expected: 100, Actual: 1000)

### Medium Priority Fixes (119 failures - Systematic)  
- **Services**: Error handling, semantic content, chat service issues
- **CLI**: Conversation runner tests mostly timing/output related

### Low Priority (Informational failures)
- **Debug/Logging**: Tests that print expected debug output but "fail" due to output expectations
- **Validation**: Asset validation edge cases

## Recommended Fix Strategy

### Phase 1: Quick Wins (30 minutes)
1. Fix models delay expectation: `test/models/chat_message_test.dart`
2. Fix widget screen loading test

### Phase 2: Systematic Service Fixes (2-3 hours)
1. Error handling tests (consistent patterns)
2. Semantic content resolver tests
3. Chat service message processing

### Phase 3: CLI Integration (1-2 hours)
1. Conversation runner output expectations
2. Template processing integration

### Phase 4: Validation & Edge Cases (30 minutes)
1. Asset validation edge cases
2. Debug logging output cleanup