# Rive Animation Zones System

## Overview

The Rive animation system uses a 4-zone layered approach for different types of animations:

1. **Zone 1**: Inline chat bubble animations
2. **Zone 2**: Overlay animations (achievements, trophies) - Top layer
3. **Zone 3**: Background animations - Behind messages
4. **Zone 4**: Interactive animations - Above messages, below UI panels

## Zone Configuration

### Zone 2: Overlay Animations (Top Layer)
For achievements, trophies, and celebratory animations triggered by scripts.

```json
{
  "asset": "assets/animations/intro_logo_animated.riv",
  "zone": 2,
  "align": "center",
  "fit": "contain",
  "autoHideMs": 1800
}
```

### Zone 3: Background Animations
Behind message content, for ambient effects.

```json
{
  "asset": "assets/animations/test-sphere.riv",
  "zone": 3,
  "align": "center",
  "fit": "contain",
  "bindings": {
    "posx": 100,
    "posy": 200
  }
}
```

### Zone 4: Interactive Animations
React to user actions, positioned above messages but below UI panels.

```json
{
  "asset": "assets/animations/arm_rig_test.riv",
  "zone": 4,
  "align": "center",
  "fit": "contain",
  "useDataBinding": true,
  "bindings": {
    "hand_x": 300,
    "hand_y": 300
  }
}
```

## Animation Properties

### Basic Properties
- `asset` - Path to .riv file
- `zone` - Layer number (1-4)
- `align` - Alignment ("center", etc.)
- `fit` - Sizing behavior ("contain", "layout")
- `id` - Unique identifier for updates

### Timing Properties
- `autoHideMs` - Auto-hide after milliseconds
- `minShowMs` - Minimum display duration
- `policy` - Display policy ("ignore", "queue")

### Data Binding
- `useDataBinding: true` - Enable dynamic data
- `bindings` - Numeric data bindings
- `bindingsString` - String data bindings
- `bindingsEnum` - Enum data bindings
- `bindingsColor` - Color data bindings
- `bindingsBool` - Boolean data bindings

### Layout Properties
- `layoutScaleFactor` - Scale factor for layout fit
- `artboard` - Specific artboard name
- `dataModel` - Data model name for nested bindings

## Animation Examples

### Clock Animation
```json
{
  "asset": "assets/animations/stopwatch.riv",
  "zone": 4,
  "align": "center",
  "id": "clock",
  "policy": "ignore",
  "fit": "layout",
  "layoutScaleFactor": 1,
  "useDataBinding": true,
  "bindings": {
    "start": 0,
    "end": 24,
    "object_x": -0.5,
    "object_y": 1
  }
}
```

### Throttle/Intensity Control
```json
{
  "asset": "assets/animations/throttle.riv",
  "zone": 4,
  "align": "center",
  "id": "throttle",
  "policy": "ignore",
  "fit": "contain",
  "useDataBinding": true,
  "bindings": {
    "level": 0,
    "object_x": -0.5,
    "object_y": 1
  }
}
```

### Calendar Animation
```json
{
  "asset": "assets/animations/calendar.riv",
  "zone": 4,
  "align": "center",
  "id": "calendar",
  "policy": "ignore",
  "fit": "contain",
  "useDataBinding": true,
  "bindings": {
    "object_x": -0.5,
    "object_y": 0.5,
    "mon": "{session.mon_active}",
    "tue": "{session.tue_active}",
    "wed": "{session.wed_active}",
    "thu": "{session.thu_active}",
    "fri": "{session.fri_active}",
    "sat": "{session.sat_active}",
    "sun": "{session.sun_active}"
  }
}
```

### Achievement Animation
```json
{
  "asset": "assets/animations/achievement.riv",
  "zone": 4,
  "align": "center",
  "id": "achievement",
  "fit": "contain",
  "useDataBinding": true,
  "bindingsString": {
    "animation_status": "hidden"
  }
}
```

### Hand/Gesture Animations
```json
{
  "asset": "assets/animations/hands_mono_components_objects.riv",
  "zone": 4,
  "align": "center",
  "id": "hands",
  "fit": "layout",
  "artboard": "arm_artboard",
  "layoutScaleFactor": 0.6,
  "useDataBinding": true,
  "bindings": {
    "free_target_is_active": 1,
    "swing_target_is_active": 0,
    "free_target_x": -0.5,
    "free_target_y": 0.6
  },
  "bindingsString": {
    "nested_hand_model/hand_shape": "stopwatch"
  }
}
```

## Dynamic Updates

### Binding Updates
Update animation properties without recreating:

```json
{
  "zone": 4,
  "id": "clock",
  "bindings": {
    "start": "{task.startTime}",
    "end": "{task.deadlineTime}"
  }
}
```

### Status Changes
```json
{
  "zone": 4,
  "id": "achievement",
  "bindingsString": {
    "animation_status": "unlock",
    "content": "smarty pants"
  }
}
```

### Auto-Hide Trigger
```json
{
  "zone": 4,
  "id": "calendar",
  "autoHideMs": 1000
}
```

## Script Integration

### Data Action Trigger
```json
{
  "type": "trigger",
  "key": "fx",
  "event": "overlay_rive_update",
  "data": {
    "zone": 4,
    "bindings": {
      "start": "{task.deadlineTime}",
      "end": "{task.startTime}"
    }
  }
}
```

## Template Integration

Animations support full template syntax:
- `{task.startTime}` - Task timing variables
- `{session.mon_active}` - Session state variables
- `{task.remindersIntensity}` - User preference variables

## Nested Data Models

For complex animations with nested components:

```json
{
  "asset": "assets/animations/nesting.riv",
  "zone": 2,
  "artboard": "mom_artboard",
  "dataModel": "mom_model",
  "bindings": {
    "nested_child_model/opacity": 0.5,
    "nested_sibling_model/opacity": 0
  }
}
```

## Implementation Notes

- Use Rive version ^0.14.0-dev.5 (major prerelease)
- Zone layering: 1 (inline) < 3 (background) < 4 (interactive) < 2 (overlay)
- Interactive animations (Zone 4) respond to user parameter changes
- Overlay animations (Zone 2) triggered by script events
- All animations support template substitution and data binding