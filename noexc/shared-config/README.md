# Shared Configuration

This directory contains shared configuration files used by both the Flutter app and the React Flow authoring tool.

## Structure

```
shared-config/
├── variables.json          # Variable definitions shared between projects
├── environments.json       # Environment-specific configurations  
├── sequences/              # Exported conversation sequences
├── backups/                # Automatic backups
└── README.md               # This file
```

## Files

### variables.json
Contains all variable definitions used in conversation flows:
- Variable keys, types, and default values
- Descriptions and categories
- Environment availability
- Source tracking

### environments.json
Defines different deployment environments:
- Development, staging, production configs
- Environment-specific variable overrides
- Deployment settings

### sequences/
Directory for exported conversation sequences from the authoring tool:
- JSON files compatible with Flutter app
- Organized by sequence ID
- Version controlled

### backups/
Automatic backups of configuration files:
- Timestamped snapshots
- Recovery from accidental changes
- Version history

## Usage

### From Authoring Tool
1. Variables are automatically synced to/from variables.json
2. Export sequences to sequences/ directory
3. Import shared variables on startup

### From Flutter App
1. Read variables.json for available variables
2. Load sequences from sequences/ directory
3. Use environment configs for deployment

## Version Control

All files in this directory should be committed to version control to ensure consistency across team members and deployments.