# Rive Overlays Quickstart (Scripts)

This guide shows how to trigger and control Rive animations from your chat scripts.

Works with rive: `0.14.0-dev.5` (Rive 0.14). The app already calls `RiveNative.init()` at startup.

## Zones
- Zone 2: Foreground overlay (above all UI). Ideal for trophies/achievements. Typically auto-hides.
- Zone 3: Background overlay (behind chat content, above the app background). Ideal for persistent, data‑bound visuals (e.g., streak counter, growing tree).

Both zones are always mounted; they render only after you trigger them.

## Events (Script Triggers)

Use a `dataAction` with `type: "trigger"` and `event` as below:

1) `overlay_rive` — show an overlay
- `asset` (string, required): Path to a `.riv` asset under `assets/animations/`.
- `zone` (int, optional): `2` (foreground) or `3` (background). Default `2`.
- `align` (string, optional): one of `topLeft|topCenter|topRight|centerLeft|center|centerRight|bottomLeft|bottomCenter|bottomRight`. Default `center`.
- `fit` (string, optional): one of `contain|cover|fill|fitWidth|fitHeight|none|scaleDown`. Default `contain`.
- `autoHideMs` (int, optional): Auto-hide delay in milliseconds. Omit for persistent overlays (e.g., zone 3 backgrounds).
- `bindings` (object, optional): Key/value pairs for Rive data binding (numbers only), e.g. `{ "streak": 17 }`.
- `useDataBinding` (bool, optional): Force-enable data binding even if you don’t pass initial `bindings`. Default `false`.

2) `overlay_rive_update` — update bindings for an existing overlay
- `zone` (int, optional): Target zone. Default `3`.
- `bindings` (object, required): Key/value pairs (numbers) to update.

Note: Script-driven explicit hide for an overlay is not implemented. Use `autoHideMs` (zone 2), or leave persistent (zone 3). Programmatic hides are available in code via `RiveOverlayService.hide(zone: ...)`.

## Examples

### A. Simple trophy (zone 2), auto-hide
```json
{
  "type": "trigger",
  "key": "fx",
  "event": "overlay_rive",
  "data": {
    "asset": "assets/animations/intro_logo_animated.riv",
    "zone": 2,
    "align": "center",
    "fit": "contain",
    "autoHideMs": 1800
  }
}
```

### B. Trophy with future data binding (opt‑in)
```json
{
  "type": "trigger",
  "key": "fx",
  "event": "overlay_rive",
  "data": {
    "asset": "assets/animations/trophy_with_stars.riv",
    "zone": 2,
    "useDataBinding": true,
    "autoHideMs": 2000
  }
}
```
Later in the flow (or immediately), update bound properties:
```json
{
  "type": "trigger",
  "key": "fx",
  "event": "overlay_rive_update",
  "data": {
    "zone": 2,
    "bindings": { "stars": 3 }
  }
}
```

### C. Background with live streak (zone 3), persistent
Show once (no auto‑hide) with initial binding:
```json
{
  "type": "trigger",
  "key": "fx",
  "event": "overlay_rive",
  "data": {
    "asset": "assets/animations/streakcount_test.riv",
    "zone": 3,
    "align": "center",
    "fit": "contain",
    "useDataBinding": true,
    "bindings": { "streak": 17 }
  }
}
```
Update the streak later:
```json
{
  "type": "trigger",
  "key": "fx",
  "event": "overlay_rive_update",
  "data": {
    "zone": 3,
    "bindings": { "streak": 18 }
  }
}
```

### D. Bindings from stored values (templating)
- To bind a stored value, use the templating syntax with braces, or a shorthand path. Both resolve through the stored data (user/session/task):

Show with stored user streak:
```json
{
  "type": "trigger",
  "key": "fx",
  "event": "overlay_rive",
  "data": {
    "asset": "assets/animations/streakcount_test.riv",
    "zone": 3,
    "useDataBinding": true,
    "bindings": { "streak": "{user.streak}" }
  }
}
```

Update from a stored path using shorthand (no braces):
```json
{
  "type": "trigger",
  "key": "fx",
  "event": "overlay_rive_update",
  "data": {
    "zone": 3,
    "bindings": { "streak": "user.streak" }
  }
}
```

Notes:
- Values must resolve to numbers (int/double). Non‑numeric results are skipped with a warning (not coerced to 0).
- Supported roots: `user.*`, `session.*`, `task.*` (from stored data).
- Property names in the Rive file must match binding keys (e.g., `streak`).

## Authoring Notes (Rive)
- For data binding, the Rive file must export a View Model and expose matching property names (e.g., `streak`, `posx`, `posy`).
- Bindings are numeric (`double`) values. Strings/booleans are not supported by this quick path.
- If the file has no exported View Model, binding is skipped automatically and a single warning is logged. The animation still plays.

## Best Practices
- Zone 2 (trophies):
  - Omit `bindings`/`useDataBinding` unless you actually need them.
  - Prefer `autoHideMs` to avoid overlaying the UI for too long.
- Zone 3 (backgrounds):
  - Use `useDataBinding: true` and pass initial `bindings`, then update via `overlay_rive_update` when data changes (e.g., `user.streak`).
  - Keep alignment/fit consistent with your layout.
- Property names: Match the exact names in the Rive file’s View Model.
- Performance: Reuse a single persistent background (zone 3) and update it instead of re‑showing.

## Troubleshooting
- Error: `RiveDataBindException: Default view model instance not found`
  - The asset doesn’t export a View Model. Remove `bindings`/`useDataBinding` for this asset, or export a VM in Rive if you need binding.
- Overlay not visible:
  - Check the asset path and that the `.riv` is included under `assets/animations/` in `pubspec.yaml`.
  - Ensure you didn’t set `autoHideMs` for a background that should persist.
- Updates not applying:
  - Confirm property names match the Rive file’s View Model.
  - Ensure the zone matches the one you used in the initial `overlay_rive`.
