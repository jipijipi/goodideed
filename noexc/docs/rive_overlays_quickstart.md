Rive Overlays Quickstart

Overview
- Global overlay animations are triggered via script events and rendered by zone hosts in the chat screen.
- Zones: 2 (front, above UI), 4 (mid, above messages, below panels), 3 (behind UI).
- Multiple overlays can run concurrently in the same zone when given distinct ids.

Events
- overlay_rive: Show an overlay
  - Required: asset: string (path to .riv)
  - Common: zone: int (default 2), align: string, fit: string
  - Data: bindings: { string: number|string }, useDataBinding: bool (default false)
  - Identity: id: string (recommended when you plan to update/hide or run multiple overlays in a zone)
  - Control:
    - policy: 'replace' | 'queue' | 'ignore' (default 'replace')
    - autoHideMs: int (optional, schedules hide)
    - minShowMs: int (optional, prevents hiding before elapsed)
    - zIndex: int (optional, default 0; stacking within the zone)

- overlay_rive_update: Update bindings for an overlay
  - Target: zone (default 2), id (optional; defaults to the zone’s legacy id)
  - Payload: bindings: { string: number|string }
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
- Provide numeric bindings either directly (numbers) or via templated strings such as '{user.streak}' or shorthand paths 'user.streak'.
- Non-numeric results after templating are ignored with a warning.
- If Rive data binding is not available for a given asset, bindings are buffered until it becomes available; a one-time warning is logged.

Examples
- Show and auto-hide after 2s:
  {
    "event": "overlay_rive",
    "asset": "assets/animations/confetti.riv",
    "zone": 4,
    "id": "confetti",
    "policy": "replace",
    "autoHideMs": 2000,
    "zIndex": 5
  }

- Update a score binding and schedule hide in 1s:
  {
    "event": "overlay_rive_update",
    "zone": 4,
    "id": "badge",
    "bindings": {"score": "user.streak"},
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

