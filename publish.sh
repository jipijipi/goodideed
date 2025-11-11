#!/bin/bash

# Publish Website to goodideed Repository
# This script commits all changes in the goodideed/ directory and pushes to the remote repository

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Publishing goodideed Website${NC}"
echo -e "${GREEN}════════════════════════════════════════════════${NC}"
echo ""

# Validate we're in the correct directory
if [ ! -d "excuseyou" ]; then
    echo -e "${RED}Error: Must run from goodideed/ directory${NC}"
    echo -e "${YELLOW}Current directory: $(pwd)${NC}"
    exit 1
fi

# Check if there are changes to commit
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo -e "${YELLOW}📝 Changes detected, preparing to commit...${NC}"
    echo ""

    # Show status
    echo -e "${YELLOW}Current changes:${NC}"
    git status --short
    echo ""

    # Generate commit message with timestamp
    COMMIT_MSG="Update website content - $(date '+%Y-%m-%d %H:%M:%S')"

    # Add all changes
    echo -e "${GREEN}Adding all changes...${NC}"
    git add .

    # Commit with timestamp
    echo -e "${GREEN}Committing changes...${NC}"
    git commit -m "$COMMIT_MSG"
    echo ""

    # Push to goodideed remote
    echo -e "${GREEN}Pushing to goodideed remote...${NC}"
    git push goodideed main
    echo ""

    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ Successfully published to goodideed!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Changes will be live at https://goodideed.com shortly${NC}"
else
    echo -e "${YELLOW}⚠️  No changes to commit${NC}"
    echo ""
    echo -e "${YELLOW}All files are up to date. Nothing to publish.${NC}"
fi

echo ""
