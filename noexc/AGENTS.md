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
- Default mode: Instant display is ON by default (toggle in Debug Panel). This speeds up development and testing.
- Production (adaptive) mode: Bot text messages use adaptive delays when no `delay` is specified. Formula: `dynamicDelayBaseMs + words * dynamicDelayPerWordMs` clamped to `[dynamicDelayMinMs, dynamicDelayMaxMs]` (see `AppConstants`).
- Choice options: In production mode, choices appear after a constant delay (`choiceDisplayDelayMs`). In instant mode, they appear immediately.
- Override: If a message has an explicit `delay` in the sequence JSON, that value takes precedence. For programmatically created messages, any non‑default `delay` is treated as explicit.

## Coding Rules
- Lints: `flutter_lints` (2-space indent). Prefer `const`; include `super.key` in widgets.
- Logging only via `LoggerService` (no `print`). Use `debug/info/warning/error/critical` and `route/semantic/ui` components.
- AnimatedList: every data change must notify the list. Insert/remove at index 0 when `reverse: true`.

## Rive & Animations
- Dependency: `rive: 0.14.0-dev.5` (pinned). Rive bubbles live in `message_bubble.dart` (`_RiveAnimationWrapper`).
- Prevent replay on new messages: give stable keys to items (`ValueKey(message)`), keep Rive state in a `StatefulWidget` with `AutomaticKeepAliveClientMixin`, and create controllers once in `initState`/`onInit`.
- Optional: cache `RiveFile` at a higher layer and clone artboards for multiple instances.

### Rive 0.14 Runtime Notes (Flutter)
- Init/runtime: Call `await RiveNative.init()` at startup and use `Factory.rive` when loading files/images.
- Artboard selection: Prefer `ArtboardSelector.byDefault/.byName/.byIndex` via `RiveWidgetController` (or `RiveWidgetBuilder`).
- State machine selection: Use `StateMachineSelector.byName/.byIndex` in `RiveWidgetController` (default if omitted).
- Layout: If the artboard uses Rive Layouts, set `fit: Fit.layout` (optionally `layoutScaleFactor`). Otherwise, use `fit` + `alignment`.
- Data binding: Bind with `controller.dataBind(DataBind.auto())` or via file/view-model APIs. Properties supported include number, bool, string, color, trigger, enum, nested view models, image, and lists. Use slash paths for nested properties and dispose property handles when done.
- Assets: Embedded/Hosted/Referenced supported. For referenced, supply `assetLoader:` in `File.asset(...)` and return `true` when you handle an asset.
- Caching: You may keep a `File` alive and reuse it across widgets to avoid repeated decoding; always dispose when no longer needed.

### App Status vs Docs
- Bubbles: Load `.riv` and render via `RiveWidgetController(file)`; no artboard/state machine selection or data binding yet.
- Overlays: Zones/ids/queue policies supported; numeric data binding via `DataBind.auto()` implemented.

### Recommended Next Steps
- Add optional `artboard`, `stateMachine` (or `animation`), `dataModel`, and `bindings` to overlay/bubble APIs; apply bindings before first frame.
- Broaden bindings beyond numbers (bool/string/color; image as needed) and support nested paths.
- Introduce a simple `Rive` file cache (service-level) to reuse decoded files across instances.
- Expose `fit: 'layout' | 'contain' | ...` and optional `layoutScaleFactor` in APIs for authored Layouts.
- Add optional `assetLoader` support for referenced assets.

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
