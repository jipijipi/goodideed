# Repository Guidelines

## Project Map
- `lib/widgets/chat_screen/`: UI surface. Start with `chat_screen.dart` → `chat_message_list.dart` → `message_bubble.dart` (renders text, inputs, choices, and images/Rive). State entry: `chat_state_manager.dart` (delegates to `state_management/`).
- `lib/services/`: Orchestration and logic. Key: `chat_service/` (`sequence_loader.dart`, `message_processor.dart`, `route_processor.dart`), `flow/` (`flow_orchestrator.dart`, `message_renderer.dart`, `sequence_manager.dart`).
- `assets/sequences/`: JSON chat flows (first message is dynamic via `SequenceManager.getFirstMessageId`).
- `test/`: Mirrors `lib/`. Use quiet helpers in `test/test_helpers.dart`.
- `tool/`: Dev tooling (`tdd_runner.dart`, `quick_test_summary.sh`, `test_aliases.sh`).

## Build & Test
- Install: `flutter pub get`
- Run: `flutter run`
- Always start quiet (TDD): `dart tool/tdd_runner.dart --quiet test/specific_test.dart` or `flutter test --reporter failures-only` — minimizes log noise and token usage.
- Targeted runs: `flutter test test/services/ --reporter compact`
- Aliases: `source tool/test_aliases.sh` → `tq`, `tf`, `tc`, `ts`

## Message Delays
- Adaptive default: Bot text messages use adaptive delays based on word count when the script does not specify a `delay`. Formula: `dynamicDelayBaseMs + words * dynamicDelayPerWordMs` clamped to `[dynamicDelayMinMs, dynamicDelayMaxMs]` (see `AppConstants`).
- Override: If a message has an explicit `delay` in the sequence JSON, that value takes precedence. For programmatically created messages, any non‑default `delay` is treated as explicit.
- Instant mode: Use the debug panel switch “Instant display (test mode)” to disable delays for faster testing.

## Coding Rules
- Lints: `flutter_lints` (2-space indent). Prefer `const`; include `super.key` in widgets.
- Logging only via `LoggerService` (no `print`). Use `debug/info/warning/error/critical` and `route/semantic/ui` components.
- AnimatedList: every data change must notify the list. Insert/remove at index 0 when `reverse: true`.

## Rive & Animations
- Dependency: `rive: 0.14.0-dev.5` (pinned). Rive bubbles live in `message_bubble.dart` (`_RiveAnimationWrapper`).
- Prevent replay on new messages: give stable keys to items (`ValueKey(message)`), keep Rive state in a `StatefulWidget` with `AutomaticKeepAliveClientMixin`, and create controllers once in `initState`/`onInit`.
- Optional: cache `RiveFile` at a higher layer and clone artboards for multiple instances.

## Debug Panel
- Location: Open via the bug icon in the app bar. The panel provides Reset/Clear/Reload controls, data management, sequence switcher, and now a delay toggle.
- Delay toggle: `Instant display (test mode)` flips between production adaptive delays and instant rendering to speed up TDD and manual QA.

## Testing (TDD First)
- Non‑negotiable: Practice TDD. Write a failing test (Red), implement minimally (Green), then refactor. No feature merges without tests.
- Start quiet: Use `tdd_runner --quiet` or failures‑only reporters first to reduce output and token cost; expand only when debugging.
- Framework: `flutter_test`. Coverage goal ≥ 80% for new/changed code.
- Helpers: `setupQuietTesting()`, `setupSilentTesting()`, `withSuppressedErrorsAsync()` to suppress expected errors and keep logs minimal.

## PR Checklist
- Green tests + lints, updated docs (sequences validated), clear description with linked issues and screenshots when UI changes.
