# NOEXC Variant Generation Tool — Quick Guide

## What It Does
Generate multiple high‑quality text variants for chat messages OR mobile notifications using the semantic content system.

## Key Paths
- CLI: `tool/gen_variants.dart`
- Config: `tool/variants_config.yaml`
- State files (examples): `tool/state/*.yaml`
- Content files: `assets/content/...`
- Sequences: `assets/sequences/*.json`
- Archives: `tool/ai_archive/YYYY/MM/DD/*.json`

## Prerequisites
- Dart/Flutter installed (repo already configured).
- For OpenAI:
  - `OPENAI_API_KEY` exported in your shell OR set in VS Code launch config.
  - A valid model (e.g., `gpt-4o-mini`).

## Configure Once
Edit `tool/variants_config.yaml` with your provider and preferences. See the full reference below.

### Quick Start (OpenAI Chat)
```yaml
provider:
  name: openai-chat
  base_url: ""                # uses https://api.openai.com/v1/chat/completions
  model: gpt-4o-mini          # pick a model you can access
  api_key_env: OPENAI_API_KEY
  mock: false
  timeout_ms: 20000

gen:
  num_variants: 8
  temperature: 0.7
  top_p: 0.9
  max_bubbles_per_line: 3
  max_chars_per_bubble: 90
  dedupe_threshold: 0.82
  max_tokens: 768
  include_sampling_params: true

context:
  history_bubbles: 4
  include_sibling_exemplars: false
  max_exemplars: 10
  include_node_samples: true
  samples_per_node: 3
  prefer_node_samples: true

style:
  tone: [friendly, concise, supportive]
  forbid_emojis: true
  allow_pipes: true
  preserve_placeholders: true

io:
  archive_dir: tool/ai_archive
  dry_run: false              # set true for no-network dry runs
  verbose: false
  fail_fast: false

rate_limit:
  rpm: 60
  retry_count: 3
  retry_backoff_ms: 1500

safety:
  blocklist: [shit, fuck]
  pii_regexes: []

prompt:
  system_message: "You are a UX writer for NOEXC, a friendly accountability bot."

notification:
  max_chars_total: 60          # Stricter character limit for notifications
  include_time_context: true   # Consider timing in variant generation
  style_override:
    tone: [urgent, motivating, brief, direct]
    max_bubbles_per_line: 1    # Notifications are single-line only
    forbid_emojis: true        # Strict no-emoji policy for notifications
    require_actionable: true   # Must contain action/motivational words
```

### Reasoning Model (OpenAI gpt‑5) Notes
- Use: `provider.model: gpt-5` (or specific version).
- Set `gen.include_sampling_params: false` (temperature/top_p not supported).
- Consider lower `gen.max_tokens` (e.g., 256–384) if you see empty responses.
- JSON mode is kept by default; if the model frequently returns empty content, consider switching model for this task.

---

## Configuration Reference

### provider
- `name`: Adapter to use. Supported: `openai-chat` (Chat Completions), `generic-json` (raw POST with `{model, prompt, ...}`).
- `base_url`: Leave empty for OpenAI default endpoint; set a custom URL for proxies.
- `model`: Your target model (e.g., `gpt-4o-mini`, `gpt-4.1-mini`, `gpt-5`).
- `api_key_env`: Environment variable name holding your API key (default `OPENAI_API_KEY`).
- `mock`: `true` to synthesize responses locally for testing.
- `timeout_ms`: HTTP timeout per request.

### gen
- `num_variants`: How many alternatives to request (validator may drop near‑duplicates). Typical: 5–12.
- `temperature`, `top_p`: Sampling controls. Disable with `include_sampling_params: false` (required for some reasoning models).
- `max_tokens`: Completion budget (sent as `max_completion_tokens` for OpenAI chat).
- `max_bubbles_per_line`: Safety cap for `|||` bubble splits in a single variant.
- `max_chars_per_bubble`: Per‑bubble length cap (post-split).
- `dedupe_threshold`: Similarity threshold (Jaccard‑like) to drop near‑duplicates.
- `include_sampling_params`: When `true`, send `temperature`/`top_p`; set `false` for models that don’t accept them (e.g., `gpt‑5`).

### context
- `history_bubbles`: How many turns before the target to include.
- `include_node_samples`: Attach `examples` from content files for items with a `contentKey`.
- `samples_per_node`: How many lines to sample from each content file.
- `prefer_node_samples`: When `true` and node examples exist, omit the global `exemplars` block in the prompt.
- `include_sibling_exemplars`: When `true`, include sibling exemplars under `prompt.exemplars` (useful fallback).

### style
- `tone`: Array of tone tags included in the system message.
- `forbid_emojis`: If `true`, non‑ASCII example lines are filtered out.
- `allow_pipes`: Keep `|||` splits allowed.
- `preserve_placeholders`: Keep `{...}` tokens intact.

### prompt
- `system_message`: Persona/role instruction used for the system message (e.g., “You are a UX writer…”).

### io
- `archive_dir`: Where JSON archives are written.
- `dry_run`: If `true`, still builds prompt/request and archives, but does not call the network.
- `verbose`: Future expansion for extra logging.
- `fail_fast`: Stop on first failure in batch runs.

### rate_limit
- `rpm`: Intended request‑per‑minute budget (advisory).
- `retry_count`: How many times to retry on certain HTTP failures (e.g., 400 sampling params for reasoning models, 5xx).
- `retry_backoff_ms`: Delay between retries.

### safety
- `blocklist`: Substrings to filter out from accepted variants.
- `pii_regexes`: Optional regex patterns to drop variants containing sensitive info.

### notification
- `max_chars_total`: Character limit for notification variants (default: 60).
- `include_time_context`: Whether to consider timing context in generation.
- `style_override`: Notification-specific style settings that override general style config:
  - `tone`: Tone tags for notifications (e.g., urgent, motivating, brief, direct).
  - `max_bubbles_per_line`: Always 1 for notifications (no pipe splits).
  - `forbid_emojis`: Strict no-emoji policy for mobile notifications.
  - `require_actionable`: Ensures variants contain action/motivational words.

### How Prompt Assembly Works (FYI)
- `prompt.system` uses `prompt.system_message` + tone/constraints from `style`/`gen`.
- The user message contains the structured JSON with:
  - `task`: includes `contentKey`, `targetPath`, `constraints` and also `defaultText` and `existingVariants` for the target.
  - `context`: resolved path turns with `sender`, `type`, `ref`, `default`, and `examples` (if any).
  - Optional `exemplars`: only when `prefer_node_samples: false` and `include_sibling_exemplars: true`.

### Choosing Variants Count
- Short one‑liners: 5–12 per call is a good default (ask for a bit more than needed; dedupe will prune).
- Larger requests yield more repetition and fewer accepted variants.

### Environment
- Ensure `OPENAI_API_KEY` is available to the process:
  - Terminal (zsh): `echo 'export OPENAI_API_KEY="sk-..."' >> ~/.zprofile && source ~/.zprofile`
  - VS Code launch: set `"env": { "OPENAI_API_KEY": "<KEY>" }` in a Dart launch config.
  - On macOS, GUI apps (VS Code) might need to be launched from a terminal that has the key; or set with `launchctl setenv`.
- `provider.name: openai-chat`
- `provider.base_url: ""` (uses `https://api.openai.com/v1/chat/completions`)
- `provider.model: gpt-4o-mini` (recommended)
- `provider.mock: false`, `io.dry_run: false` for real calls
- `gen.max_tokens: 512–768` (typical)
- Context sampling:
  - `include_node_samples: true`, `samples_per_node: 3`, `prefer_node_samples: true`
- System message persona:
  - `prompt.system_message: "You are a UX writer for NOEXC, a friendly accountability bot."`

Tip: For reasoning models (e.g., `gpt-5`), set `gen.include_sampling_params: false` and consider lowering `gen.max_tokens`.

## Authoring Requirements (to get examples)
- Messages/choices should have a `contentKey` in the sequence JSON.
- Provide variants as one‑per‑line in the resolved content file under `assets/content/...`.
- Without a `contentKey`, the tool shows only the default script text (no examples to sample).

## State Files
State files deterministically resolve a single, concrete path from a start node to your target message so the prompt context reflects the exact journey.

### Location & Naming
- Store them under `tool/state/`.
- Use descriptive names: `<sequence>_<message>_<scenario>.yaml` (e.g., `overdue_seq_90_failure.yaml`).

### Schema (YAML)
- `entry` (where to start):
  - `start_sequence`: e.g., `welcome_seq`
  - `start_message`: e.g., `1`
- `routing` (how to handle autoroutes):
  - `autoroutes`: `resolve` | `default`
    - `resolve`: evaluate each route’s condition using `values`; take first match; else default.
    - `default`: ignore conditions; always take `{ default: true }` routes.
- `values` (used by route conditions):
  - Keys mirror your app’s conditions, e.g.: `session.visitCount`, `user.ProfileSetupStatus`, `user.name`, `task.status`, `task.activeDays`.
  - Types supported: booleans, numbers, strings (quoted or bare), `null`, lists (`[1,2,3]`). Bare tokens (e.g., `inProgress`) compare as strings in conditions like `user.ProfileSetupStatus == inProgress`.
- `choices` (optional, force a specific selection at a choice node):
  - Each entry:
    - `at: { sequenceId: <id>, messageId: <id> }`
    - `by: index | text | contentKey`
    - `select: <int or string>`
- `limits` (safety caps):
  - `max_depth`: e.g., `60`
  - `max_paths`: e.g., `20`

### Minimal Template
```yaml
entry:
  start_sequence: welcome_seq
  start_message: 1
routing:
  autoroutes: resolve
values:
  session.visitCount: 1
choices: []
limits:
  max_depth: 60
  max_paths: 20
```

### Common Scenarios
- Overdue → failure (reach `overdue_seq:90`):
```yaml
entry:
  start_sequence: welcome_seq
  start_message: 1
routing:
  autoroutes: resolve
values:
  session.visitCount: 1
  user.ProfileSetupStatus: complete
  task.status: overdue
choices: []
limits:
  max_depth: 60
  max_paths: 20
```

- Onboarding intro (reach `onboarding_seq:3`):
```yaml
entry:
  start_sequence: welcome_seq
  start_message: 1
routing:
  autoroutes: resolve
values:
  session.visitCount: 1
  user.name: null          # ensures intro route is eligible
  user.isOnboarded: false
  user.ProfileSetupStatus: inProgress
choices: []
limits:
  max_depth: 60
  max_paths: 20
```

- Task setting with forced choice:
```yaml
entry:
  start_sequence: welcome_seq
  start_message: 1
routing:
  autoroutes: resolve
values:
  session.visitCount: 1
  user.ProfileSetupStatus: complete
  task.status: upcoming
choices:
  - at: { sequenceId: settask_seq, messageId: 26 }
    by: text
    select: "Yes, that's it"   # or by: contentKey / index
limits:
  max_depth: 60
  max_paths: 20
```

### How Resolution Works
- The tool uses BFS to find the shortest path from `entry` to your target:
  - Autoroutes follow `routing.autoroutes` rules.
  - Choices: use your directive if present; otherwise explore branches and pick the first that reaches the target.
  - Cross-sequence jumps (`message.sequenceId` or `route.sequenceId`) go to the first message of that sequence.
  - Non-display nodes (`autoroute`, `dataAction`) are traversed but not shown in context.
- The prompt context uses the last `history_bubbles` turns before the target and includes:
  - `sender`, `type`, `ref` (contentKey or text), `default` (script text), `examples` (sampled from content files for nodes with a `contentKey`).

### Best Practices
- Prefer `resolve` unless you explicitly want to bypass conditions.
- Always set `contentKey` on choice options to enable examples for choice turns.
- Use `choices` directives sparingly—only when multiple branches can reach the target and you need a specific one.
- Keep `values` aligned with real app state; mirror keys used in `assets/sequences/*.json` conditions.

### Debugging & Validation
- After a run, open the latest archive in `tool/ai_archive/YYYY/MM/DD/`:
  - `resolvedPath`: the sequence of nodes from start to target (should stop at your target).
  - `prompt.context`: verify each turn has the expected `ref`, `default`, and `examples`.
- If the path is wrong:
  - Add/adjust `choices` directives at the relevant nodes.
  - Toggle `routing.autoroutes` to `default` to sanity-check flows without conditions.
  - Tweak `values` to satisfy the intended route conditions.
  - Increase `limits.max_depth` slightly if needed.

### Quick Checklist
- [ ] `entry` points to a valid sequence/message.
- [ ] `routing.autoroutes` set as intended (`resolve` vs `default`).
- [ ] `values` cover keys used in route conditions along the way.
- [ ] `choices` provided where necessary to disambiguate.
- [ ] Target message has a `contentKey` and its content file exists (for examples).

## Usage

### Chat Messages
- Dry‑run (preview + archive):
  - `dart tool/gen_variants.dart --sequence <seq> --message <id> --state <file.yaml>`
- Append variants to content file:
  - `dart tool/gen_variants.dart --sequence <seq> --message <id> --state <file.yaml> --write`

### Notifications
- Single notification dry‑run:
  - `dart tool/gen_variants.dart --notification app.remind.start`
- Write notification variants:
  - `dart tool/gen_variants.dart --notification app.remind.start --write`
- Batch notifications from file:
  - `dart tool/gen_variants.dart --notification-list notification_targets.txt --write`

#### Notification Target File Format
Create a text file with one semantic key per line:
```
app.remind.start
app.remind.deadline  
app.remind.progress
app.remind.comeback
```

#### Available Notification Types
- `app.remind.start` - Task start notifications
- `app.remind.deadline` - Deadline approach/overdue notifications  
- `app.remind.progress` - Progress check notifications
- `app.remind.comeback` - Re-engagement notifications

#### Notification Examples
```
Time to pretend you're productive, start now!
Final call! Your deadline is knocking.
Deadline alert! Time to panic like a pro.
Your future self called; they want you to start.
```

Notes:
- On `--write`, the tool appends lines and ensures newlines are correct.
- Archives always record the full prompt, request, resolved path, and accepted variants.

## What The Tool Puts In The Prompt
- Uses the resolved path as context (last N turns):
  - Each turn includes: `sender`, `type`, `ref` (contentKey or text), `default` (script text), and `examples` (sampled from content files).
  - Choice turns show the selected option and sample from the choice’s content file when available.
- The `task` block includes the target’s `defaultText` and `existingVariants` (from the target file).

## OpenAI Setup
- Export key in shell (zsh): `echo 'export OPENAI_API_KEY="sk-..."' >> ~/.zprofile && source ~/.zprofile`
- OR use VS Code launch: `.vscode/launch.json` → add `env: { "OPENAI_API_KEY": "<KEY>" }` in a launch config.

## Model Tips
- Recommended: `gpt-4o-mini` (fast, reliable JSON mode).
- Reasoning models (`gpt-5`):
  - Disable sampling: `gen.include_sampling_params: false`.
  - Consider lower `gen.max_tokens` and avoid strict JSON mode if you see empty responses.

## Troubleshooting

### General Issues
- "Missing API key env": ensure `echo $OPENAI_API_KEY` prints in the same terminal; or set it in VS Code launch.
- 400 `max_tokens` error: the tool uses `max_completion_tokens` for OpenAI chat.
- 400 temperature/top_p: the tool retries without those for models that don't support sampling.
- Empty `acceptedVariants`: check archive `response` → content; adjust model/params; ensure `contentKey` exists and content files have lines.

### Notification-Specific Issues
- "Notification file not found": ensure the semantic key maps to an existing file in `assets/content/` (e.g., `app.remind.start` → `assets/content/app/remind/start.txt`).
- Variants too long: check `notification.max_chars_total` setting (default: 60 characters).
- Variants contain pipe splits: notification validator automatically rejects variants with `|||` separators.
- No actionable content: ensure `notification.style_override.require_actionable: true` is set to enforce motivational language.

## VS Code Quick Launch (optional)
Add launches to `.vscode/launch.json`:
```json
{
  "name": "Gen Variants - Chat Messages",
  "type": "dart",
  "request": "launch",
  "program": "tool/gen_variants.dart",
  "args": ["--sequence","overdue_seq","--message","90","--state","tool/state/onboarding_to_msg90.yaml","--write"],
  "env": { "OPENAI_API_KEY": "<PASTE_KEY_HERE>" }
},
{
  "name": "Gen Variants - Notifications",
  "type": "dart",
  "request": "launch",
  "program": "tool/gen_variants.dart",
  "args": ["--notification","app.remind.start","--write"],
  "env": { "OPENAI_API_KEY": "<PASTE_KEY_HERE>" }
}
```

## Best Practices

### Chat Messages
- Generate 5–12 variants per call; ask for more than needed since dedupe removes near‑duplicates.
- Keep choice options authored with `contentKey` so the tool can attach examples.
- Keep sibling exemplars off by default; rely on per‑node examples from content files.

### Notifications
- Use shorter variant counts (5-8) since notifications have stricter constraints.
- Keep notification content files updated with good examples to improve generation quality.
- Test generated variants on actual devices to ensure they fit notification UI properly.
- Consider timing context—deadline notifications should feel more urgent than start notifications.
- Maintain the app's personality (satirical, deadpan) while keeping notifications actionable.
