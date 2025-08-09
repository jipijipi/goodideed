# Repository Guidelines

## Project Structure & Modules
- `lib/`: App source. Key areas: `widgets/chat_screen/` (service_manager, message_display_manager, user_interaction_handler), `services/` (ChatService, UserDataService, SessionService, LoggerService, SemanticContentService), `models/`.
- `assets/sequences/`: JSON conversation flows (dynamic first-message via `SequenceManager.getFirstMessageId`).
- `test/`: Mirrors `lib/` structure; widget/service/model tests.
- `tool/`: Dev helpers (`tdd_runner.dart`, `quick_test_summary.sh`, `test_aliases.sh`).
- `noexc-authoring-tool/`: React Flow editor for sequences.

## Build, Test, and Development
- Install deps: `flutter pub get`.
- Run app: `flutter run`.
- Full tests (quiet): `flutter test --reporter failures-only` or `flutter test --reporter compact`.
- TDD loop (ultra-quiet): `dart tool/tdd_runner.dart --quiet test/specific_test.dart`.
- Quick summary: `./tool/quick_test_summary.sh`.
- Targeted: `flutter test test/services/ --reporter compact` (or `test/models/`, `test/widgets/`).
- Aliases: `source tool/test_aliases.sh` then `tq`, `tf`, `tc`, `ts`.

## Coding Style & Naming
- Dart/Flutter, 2-space indent; follow `package:flutter_lints/flutter.yaml`.
- Constructors: prefer `const`; include `super.key` in widgets.
- Names: PascalCase types, lowerCamelCase members, `snake_case.dart` files.
- Logging: never use `print`; use `LoggerService` (`debug/info/warning/error/critical`, plus `route/semantic/ui`).
- UI state: keep `AnimatedList` in sync (always pair data changes with `insertItem/removeItem`).

## Testing Guidelines
- Framework: `flutter_test`. TDD is mandatory; write tests first.
- Structure: tests mirror `lib/` paths and file names.
- Helpers: `setupQuietTesting()`, `setupSilentTesting()`, `withSuppressedErrorsAsync()` to reduce noise.
- Coverage goal: ≥80%; add tests for new/changed code.
- Example: `flutter test test/widgets/chat_screen/..._test.dart --reporter compact`.

## Commit & Pull Requests
- Commits: concise, imperative subject (≤72 chars), explain why + what; group related changes only.
- PRs: include description, linked issues, test evidence (output or screenshots), UI screenshots when relevant.
- Requirements: all tests green, lints passing, docs updated (sequences validated, `AGENTS.md`/readme touched if behavior changes).

## Environment & Configuration
- Flutter 3.29.3, Dart SDK `^3.7.2`; private package (`publish_to: none`).
- Sequences must validate and support non-1 starting IDs; avoid assumptions about message `id=1`.
