# Authoring Tool - Git-Based State Management

The authoring tool now uses git-tracked state management instead of browser localStorage.

## What Changed

### Before
- Master flow stored in browser localStorage (`react-flow-data`)
- Lost when switching branches, clearing browser data, or using different devices
- No version tracking or compatibility warnings

### After  
- Master flow stored in **git-tracked file**: `master-flow/authoring-tool-master-flow.json`
- Includes git branch/commit metadata for version compatibility
- Automatic warnings when loading flows from different branches
- Never lose work when switching branches or devices

## New Features

### Auto-Load on Startup
- Tool automatically loads `master-flow/authoring-tool-master-flow.json` on startup
- Shows branch compatibility warnings if needed
- Falls back to default flow if no master flow exists

### Git-Tracked Persistence
- **Save**: Updates `master-flow/authoring-tool-master-flow.json` with current git info
- **Restore**: Loads from `master-flow/authoring-tool-master-flow.json` with version warnings
- **Import Master Flow**: Import `.json` files from other branches/collaborators  
- **Export Master Flow**: Export timestamped `.json` files for sharing

### Version Compatibility
- Shows warnings when master flow is from different git branch
- Includes commit hash for detailed tracking
- Helps prevent export compatibility issues

## Usage

### Development Workflow
```bash
# Start authoring tool (auto-loads current master flow)
npm start

# Update git info before building
npm run git-info

# Build (automatically runs git-info first)  
npm run build
```

### Button Reference
- **💾 Save**: 
  - When Flutter project connected: Directly saves to `master-flow/authoring-tool-master-flow.json` (no dialog, no page reload)
  - When not connected: Shows file picker or downloads file
- **📂 Restore**: Load from `master-flow/authoring-tool-master-flow.json`  
- **📄 Import Master Flow**: Import master flow from file
- **📤 Export Master Flow**: Export master flow for sharing (always downloads)

### File Locations
- **Master Flow**: `/noexc-authoring-tool/master-flow/authoring-tool-master-flow.json` (git-tracked)
- **Git Info**: `/noexc-authoring-tool/public/git-info.json` (auto-generated)
- **Scripts**: `/noexc-authoring-tool/scripts/generate-git-info.js`

## Benefits

✅ **Never lose work** - Master flow is git-tracked  
✅ **Branch compatibility** - Automatic warnings prevent issues  
✅ **Team collaboration** - Share master flows via git  
✅ **Version tracking** - Know exactly which commit/branch a flow is from  
✅ **No file picker dialogs** - Direct save when Flutter project connected  
✅ **No page reloads** - Uses File System Access API to avoid React dev server reloads  
✅ **Prevents empty files** - Built-in data validation before save  
✅ **Zero setup** - Works automatically with existing workflow

## Migration

Existing localStorage data can be restored one last time with the **📂 Restore** button, then save it to the new git-tracked system. The old localStorage system continues to work during transition.