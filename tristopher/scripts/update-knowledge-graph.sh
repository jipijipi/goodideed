#!/bin/bash

# Tristopher Knowledge Graph Update Script
# This script helps maintain the project knowledge graph

set -e

echo "🧠 Tristopher Knowledge Graph Updater"
echo "======================================"

# Get project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS_DIR="$PROJECT_ROOT/docs"
KNOWLEDGE_GRAPH="$DOCS_DIR/knowledge_graph.json"

echo "📁 Project root: $PROJECT_ROOT"
echo "📚 Docs directory: $DOCS_DIR"

# Check if knowledge graph exists
if [ ! -f "$KNOWLEDGE_GRAPH" ]; then
    echo "❌ Knowledge graph not found at: $KNOWLEDGE_GRAPH"
    exit 1
fi

# Validate JSON format
echo "🔍 Validating knowledge graph JSON format..."
if command -v jq >/dev/null 2>&1; then
    if jq empty "$KNOWLEDGE_GRAPH" >/dev/null 2>&1; then
        echo "✅ Knowledge graph JSON is valid"
    else
        echo "❌ Invalid JSON format in knowledge graph"
        exit 1
    fi
else
    echo "⚠️  jq not found, skipping JSON validation"
fi

# Update metadata timestamp
echo "📅 Updating metadata timestamp..."
CURRENT_DATE=$(date +"%Y-%m-%d")
if command -v jq >/dev/null 2>&1; then
    # Create temporary file with updated timestamp
    jq --arg date "$CURRENT_DATE" '.metadata.generated = $date' "$KNOWLEDGE_GRAPH" > "${KNOWLEDGE_GRAPH}.tmp"
    mv "${KNOWLEDGE_GRAPH}.tmp" "$KNOWLEDGE_GRAPH"
    echo "✅ Updated timestamp to: $CURRENT_DATE"
else
    echo "⚠️  jq not found, manual timestamp update needed"
fi

# Get some statistics
if command -v jq >/dev/null 2>&1; then
    ENTITY_COUNT=$(jq '.entities | length' "$KNOWLEDGE_GRAPH")
    RELATION_COUNT=$(jq '.relations | length' "$KNOWLEDGE_GRAPH")
    echo ""
    echo "📊 Knowledge Graph Statistics:"
    echo "   • Entities: $ENTITY_COUNT"
    echo "   • Relations: $RELATION_COUNT"
    echo ""
fi

# Check if git is available and we're in a git repo
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo "🔧 Git repository detected"
    
    # Check if knowledge graph files have changes
    if git diff --quiet HEAD -- "$DOCS_DIR/knowledge_graph.json" "$DOCS_DIR/KNOWLEDGE_GRAPH.md" 2>/dev/null; then
        echo "✅ No changes detected in knowledge graph files"
    else
        echo "📝 Changes detected in knowledge graph files"
        echo ""
        echo "💡 To commit the updated knowledge graph:"
        echo "   git add docs/knowledge_graph.json docs/KNOWLEDGE_GRAPH.md"
        echo "   git commit -m \"docs: update knowledge graph\""
    fi
else
    echo "⚠️  Not in a git repository"
fi

echo ""
echo "🎉 Knowledge graph update complete!"
echo ""
echo "📖 Documentation files:"
echo "   • $DOCS_DIR/knowledge_graph.json"
echo "   • $DOCS_DIR/KNOWLEDGE_GRAPH.md"
echo ""
echo "🔗 To view the knowledge graph:"
echo "   • Open docs/KNOWLEDGE_GRAPH.md for human-readable format"
echo "   • Use docs/knowledge_graph.json for programmatic access"
