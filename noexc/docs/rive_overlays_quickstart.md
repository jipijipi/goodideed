Rive Overlays Quickstart

Overview
- Global overlay animations are triggered via script events and rendered by zone hosts in the chat screen.
- Zones: 2 (front, above UI), 4 (mid, above messages, below panels), 3 (behind UI).
- Multiple overlays can run concurrently in the same zone when given distinct ids.

Events
- overlay_rive: Show an overlay
  - Required: asset: string (path to .riv)
  - Common: zone: int (default 2), align: string, fit: string
  - Data (all optional):
    - bindings: { nameOrPath: number | string }
    - bindingsBool: { nameOrPath: boolean | 0 | 1 | string('true'|'false'|'0'|'1'|template) }
    - bindingsString: { nameOrPath: string | template }
    - bindingsColor: { nameOrPath: ARGB int | hex string (#RRGGBB | #AARRGGBB | 0xAARRGGBB | template) }
    - useDataBinding: bool (default false; auto-enabled when any bindings are provided)
  - Identity: id: string (recommended when you plan to update/hide or run multiple overlays in a zone)
  - Selection (optional):
    - artboard: string (artboard name; default uses file/editor default)
    - stateMachine: string (state machine name; default uses editor default)
    - dataModel: string (view model name; default uses artboard’s default)
    - dataInstanceMode: 'default' | 'blank' | 'byName' | 'byIndex' (default 'default')
    - dataInstance: string (when using mode 'byName')
    - dataInstanceIndex: number (when using mode 'byIndex')
  - Control:
    - policy: 'replace' | 'queue' | 'ignore' (default 'replace')
    - autoHideMs: int (optional, schedules hide)
    - minShowMs: int (optional, prevents hiding before elapsed)
    - zIndex: int (optional, default 0; stacking within the zone)

- overlay_rive_update: Update bindings for an overlay
  - Target: zone (default 2), id (optional; defaults to the zone’s legacy id)
  - Payload (any subset):
    - bindings: { nameOrPath: number | string }
    - bindingsBool: { nameOrPath: boolean | 0 | 1 | string('true'|'false'|'0'|'1'|template) }
    - bindingsString: { nameOrPath: string | template }
    - bindingsColor: { nameOrPath: ARGB int | hex string (#RRGGBB | #AARRGGBB | 0xAARRGGBB | template) }
  - Control: autoHideMs: int (optional, schedules hide from now)

- overlay_rive_hide: Hide overlays
  - Target: zone (default 2), id (optional)
  - all: bool (optional; if true or when id is missing, hides all overlays in the zone)

Defaults and Compatibility
- Defaults remain backward compatible with previous behavior when using a single overlay per zone:
  - overlay_rive defaults to zone 2.
  - overlay_rive_update now also defaults to zone 2.
  - If no id is provided, a legacy id is synthesized per zone, so show → update → hide continues to work.

Replacement Semantics (policy)
- replace (default): Immediately replaces the existing overlay with the new one for the same target id.
- ignore: Drops the new request if the target id is currently active.
- queue: Enqueues the request; it will show after the current overlay for that id is hidden.
  - Swap signals supported in this iteration: explicit overlay_rive_hide, or autoHideMs elapsing.
  - minShowMs delays hiding (including auto-hide) until the minimum time is reached.

Multiple Overlays per Zone
- Use distinct ids to run more than one overlay simultaneously within a zone.
- Stack order is controlled by zIndex (lower values render first, higher values on top).
- overlay_rive_update/hide target a specific overlay by id. If id is omitted, the “legacy” overlay for that zone is targeted.

Bindings and Data
- Numeric: numbers or templated strings such as '{user.streak}' or shorthand paths 'user.streak'.
- Boolean: true/false, 0/1, or templated strings resolving to those.
- String: direct string or template; dotted paths resolve via templating.
- Color: ARGB int or hex strings (#RRGGBB, #AARRGGBB, 0xAARRGGBB) or templates resolving to those. If #RRGGBB is used, alpha defaults to FF (opaque).
- Nested paths: Use slash-delimited names to target nested view-model properties, e.g., 'Card/Title/text'. This works for all binding types.
- Missing properties: unknown names/paths are ignored with a one-time warning per overlay instance, plus concise diagnostics.
- Data binding availability: If the asset lacks a view model at load time, bindings are buffered and applied once available (warning logged once).

Examples
- Show with multiple bindings and auto-hide after 2s:
  {
    "event": "overlay_rive",
    "asset": "assets/animations/confetti.riv",
    "zone": 4,
    "id": "confetti",
    "policy": "replace",
    "autoHideMs": 2000,
    "zIndex": 5,
    "bindings": {"ProgressBar/value": 0.75},
    "bindingsBool": {"Toggles/Sound/enabled": true},
    "bindingsString": {"Card/Title/text": "Hello {user.name}"},
    "bindingsColor": {"Theme/accent": "#FF3366"},
    "artboard": "Main",
    "stateMachine": "Loop",
    "dataModel": "HUD",
    "dataInstanceMode": "default"
  }

- Update a score binding and schedule hide in 1s:
  {
    "event": "overlay_rive_update",
    "zone": 4,
    "id": "badge",
    "bindings": {"score": "user.streak"},
    "bindingsBool": {"meta/isNew": "true"},
    "bindingsString": {"label": "Streak: {user.streak}"},
    "bindingsColor": {"accent": "0xFF112233"},
    "autoHideMs": 1000
  }

- Queue a badge reveal to play after the current one ends:
  {
    "event": "overlay_rive",
    "asset": "assets/animations/badge.riv",
    "zone": 4,
    "id": "badge",
    "policy": "queue",
    "minShowMs": 1200
  }

- Hide a specific overlay:
  {
    "event": "overlay_rive_hide",
    "zone": 4,
    "id": "badge"
  }

- Hide all overlays in a zone:
  {
    "event": "overlay_rive_hide",
    "zone": 4,
    "all": true
  }

Authoring Tips
- Always set an id for overlays you plan to update or hide.
- Prefer update for data changes; only show again when changing asset/artboard/state machine.
- Use autoHideMs to chain queued items, or overlay_rive_hide to force a swap.
- Use nested paths for view-model hierarchies (e.g., 'Profile/Card/Title/text').
- Colors: prefer #AARRGGBB for explicit alpha; #RRGGBB assumes opaque.

Details
- Event fields
  - asset: Path to the .riv file. Required for show.
  - zone: Integer zone; 2 by default for both show and update.
  - id: String identifier for targeting the specific overlay within a zone. If omitted, a legacy id is synthesized and only one overlay is supported per zone.
  - align/fit/margin: Position and scaling of the overlay.
  - zIndex: Higher zIndex draws above lower ones within the same zone.
  - bindings / bindingsBool / bindingsString / bindingsColor / useDataBinding: Properties to bind via Rive data model. Templates are supported and resolved via the templating service.
  - artboard / stateMachine: Selectors to pick which artboard/state machine to run. If omitted, defaults from the Rive file are used.
  - dataModel / dataInstanceMode / dataInstance / dataInstanceIndex: View model and instance selection. If omitted, the artboard’s default view model is used and a default instance is assumed.
  - autoHideMs: Schedules a hide after the given duration. Applies to show and can be applied at update time as well.
  - minShowMs: Prevents an overlay from hiding before the specified duration has elapsed since it was shown.
  - policy (show only): 'replace' | 'queue' | 'ignore'. Controls behavior when the same id is already active.

- Policies
  - replace (default): Disposes the currently active overlay with the same id and immediately shows the new request. This restarts the animation.
  - ignore: Drops the new request if an overlay with the same id is already active; the current animation continues uninterrupted.
  - queue: Enqueues the new request for the same id and shows it only after the current one hides (via autoHideMs or explicit hide). Useful when you want a sequence of reveals.

- Targeting and identity
  - Provide a stable id per conceptual overlay (e.g., 'badge', 'confetti').
  - overlay_rive_update and overlay_rive_hide operate on that id. If id is missing, they act on the legacy single overlay for the zone.
  - Multiple overlays per zone require distinct ids. Use zIndex to control stacking.

- Multiple overlays per zone
  - Supported by providing different ids on overlay_rive events. The host maintains a stack of active instances.
  - Updates and hides must target the desired id to avoid unintended effects.

- Timing controls
  - autoHideMs: Schedules a hide for an overlay. When it fires, queued items (if any) for the same id are shown next.
  - minShowMs: Ensures overlays are visible long enough to avoid flicker when scripts loop quickly. Hides (including auto-hide or explicit hide) are delayed until the guard is satisfied.

- Bindings and data binding
  - Bindings are applied via Rive's data binding system when available. If the asset lacks an exported view model, bindings are buffered and a one-time warning is logged.
  - Use overlay_rive_update to change numeric values without reloading the asset.

Authoring Patterns
- Update without restart (loop-friendly)
  - When looping back in a sequence and the overlay should persist, do NOT resend overlay_rive with the same id to change values. Instead, send overlay_rive_update with that id and new bindings. This keeps the current animation running and avoids a restart.
  - If the script currently emits overlay_rive on each loop iteration, set policy: 'ignore' (to keep the current one) and follow it with overlay_rive_update to change values.

- Replace vs. Update
  - Replace when switching to a different asset/artboard/state machine or when you want a fresh start.
  - Update when changing only numeric parameters or small state flags exposed via bindings.

Rendering and Diagnostics
- Overlays appear as soon as their controller is ready; host rebuilds on readiness to avoid invisible overlays.
- When bindings fail to resolve, the system logs a one-time warning per instance and basic asset diagnostics (default artboard/state machine/view model presence).
 - Note on data model instances: Instance selection fields are accepted and future-proofed. In the current pinned runtime version, binding is performed via auto-bind; property updates still apply by name/path. When the runtime exposes explicit instance binding, these fields will take effect without breaking changes.

More Examples
- Show with named instance and nested paths:
  {
    "event": "overlay_rive",
    "asset": "assets/animations/hud.riv",
    "zone": 4,
    "id": "hud",
    "artboard": "HUD",
    "stateMachine": "Main",
    "dataModel": "HUDModel",
    "dataInstanceMode": "byName",
    "dataInstance": "NightTheme",
    "bindingsString": {
      "Header/Title/text": "Welcome, {user.name}"
    },
    "bindingsColor": {
      "Theme/accent": "#FF00AA"
    },
    "bindingsBool": {
      "Flags/isPremium": "{user.isPremium}"
    }
  }

- Show with blank instance and numeric + color int bindings:
  {
    "event": "overlay_rive",
    "asset": "assets/animations/progress.riv",
    "zone": 3,
    "id": "progress",
    "artboard": "Progress",
    "stateMachine": "Default",
    "dataModel": "ProgressVM",
    "dataInstanceMode": "blank",
    "bindings": {
      "Bar/value": 0.25
    },
    "bindingsColor": {
      "Bar/color": 4281545523
    }
  }

- Queue two overlays with stacking order (zIndex):
  {
    "event": "overlay_rive",
    "asset": "assets/animations/confetti.riv",
    "zone": 2,
    "id": "confetti",
    "policy": "queue",
    "zIndex": 1,
    "autoHideMs": 1500
  }
  {
    "event": "overlay_rive",
    "asset": "assets/animations/badge.riv",
    "zone": 2,
    "id": "confetti",
    "policy": "queue",
    "zIndex": 2,
    "minShowMs": 800
  }

- Update only timing (no bindings):
  {
    "event": "overlay_rive_update",
    "zone": 2,
    "id": "toast",
    "autoHideMs": 500
  }

- Legacy single overlay per zone (no id):
  {
    "event": "overlay_rive",
    "asset": "assets/animations/toast.riv",
    "zone": 4,
    "bindingsString": {"Text/value": "Saved"}
  }
  {
    "event": "overlay_rive_update",
    "zone": 4,
    "bindingsString": {"Text/value": "Updated"}
  }
  {
    "event": "overlay_rive_hide",
    "zone": 4
  }

- Boolean bindings via numeric and templates:
  {
    "event": "overlay_rive",
    "asset": "assets/animations/flags.riv",
    "zone": 3,
    "id": "flags",
    "bindingsBool": {
      "Flags/isActive": 1,
      "Flags/showBeta": "{session.isBeta}"
    }
  }

- Color via template and hex without alpha (assumes FF alpha):
  {
    "event": "overlay_rive_update",
    "zone": 3,
    "id": "hud",
    "bindingsColor": {
      "Theme/accent": "#3366FF",
      "Theme/bg": "{theme.bgColorHex}"
    }
  }

FAQ
- Can a policy update a running animation instead of restarting on repeated overlay_rive?
  - In this iteration, no single policy automatically converts a repeated overlay_rive into an in-place update. Policies control whether the new show request replaces, queues, or is ignored. To update a running animation without restarting, use overlay_rive_update targeting the same zone and id. A possible future enhancement is a 'merge' policy that detects identical assets and applies bindings instead of replacing.
