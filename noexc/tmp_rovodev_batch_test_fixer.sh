#!/bin/bash

# Batch Test Fixer - Automatically add test helpers to reduce debug log pollution
# This script identifies noisy tests and adds appropriate setupQuietTesting() calls

set -e

echo "🔧 Batch Test Fixer v1.0"
echo "========================="
echo "Automatically adding test helpers to reduce debug log pollution"
echo ""

# Configuration
DRY_RUN=false
BACKUP_DIR="test_backups_$(date +%Y%m%d_%H%M%S)"
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      echo "🔍 DRY RUN MODE - No files will be modified"
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --help)
      echo "Usage: $0 [--dry-run] [--verbose] [--help]"
      echo ""
      echo "Options:"
      echo "  --dry-run    Show what would be changed without modifying files"
      echo "  --verbose    Show detailed processing information"
      echo "  --help       Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Create backup directory if not dry run
if [ "$DRY_RUN" = false ]; then
  mkdir -p "$BACKUP_DIR"
  echo "📁 Backup directory created: $BACKUP_DIR"
fi

# Function to check if file needs test helpers
needs_test_helpers() {
  local file="$1"
  
  # Skip if already has test_helpers import
  if grep -q "import.*test_helpers" "$file"; then
    return 1
  fi
  
  # Skip if already has setupQuietTesting or setupSilentTesting
  if grep -q "setupQuietTesting\|setupSilentTesting" "$file"; then
    return 1
  fi
  
  return 0
}

# Function to determine appropriate test helper based on file path and content
get_test_helper_type() {
  local file="$1"
  
  # Silent testing for initialization and integration tests
  if [[ "$file" == *"initialization"* ]] || [[ "$file" == *"integration"* ]]; then
    echo "setupSilentTesting"
    return
  fi
  
  # Silent testing for error handling tests (they generate expected errors)
  if [[ "$file" == *"error"* ]] || grep -q "expect.*throw\|expect.*error" "$file"; then
    echo "setupSilentTesting"
    return
  fi
  
  # Quiet testing for service tests (most common case)
  if [[ "$file" == *"services/"* ]]; then
    echo "setupQuietTesting"
    return
  fi
  
  # Quiet testing for widget tests that likely initialize services
  if [[ "$file" == *"widgets/"* ]] || [[ "$file" == *"widget_test.dart" ]]; then
    echo "setupQuietTesting"
    return
  fi
  
  # Default to quiet testing
  echo "setupQuietTesting"
}

# Function to add test helpers to a file
add_test_helpers() {
  local file="$1"
  local helper_type="$2"
  local temp_file="${file}.tmp"
  
  if [ "$VERBOSE" = true ]; then
    echo "  Processing: $file"
    echo "  Helper type: $helper_type"
  fi
  
  # Create the modified content
  {
    # Add import after existing imports
    awk '
    BEGIN { import_added = 0 }
    /^import/ { 
      print $0
      if (!import_added && !/test_helpers/) {
        imports[++import_count] = $0
      }
    }
    /^$/ && !import_added && import_count > 0 {
      print "import '\''../test_helpers.dart'\'';"
      print ""
      import_added = 1
      next
    }
    !/^import/ {
      if (!import_added && import_count > 0) {
        print "import '\''../test_helpers.dart'\'';"
        print ""
        import_added = 1
      }
      print $0
    }
    ' "$file"
  } > "$temp_file"
  
  # Add setupQuietTesting/setupSilentTesting to setUp methods
  awk -v helper="$helper_type" '
  /setUp\(\) \{/ {
    print $0
    getline
    if ($0 ~ /^[ \t]*$/) {
      print "    " helper "();"
      print $0
    } else {
      print "    " helper "();"
      print $0
    }
    next
  }
  /setUp\(\) async \{/ {
    print $0
    getline
    if ($0 ~ /^[ \t]*$/) {
      print "    " helper "();"
      print $0
    } else {
      print "    " helper "();"
      print $0
    }
    next
  }
  { print $0 }
  ' "$temp_file" > "${temp_file}.2"
  
  mv "${temp_file}.2" "$temp_file"
  
  if [ "$DRY_RUN" = false ]; then
    # Backup original file
    cp "$file" "$BACKUP_DIR/$(basename "$file")"
    
    # Replace original with modified version
    mv "$temp_file" "$file"
    echo "  ✅ Modified: $file (added $helper_type)"
  else
    echo "  🔍 Would modify: $file (add $helper_type)"
    rm "$temp_file"
  fi
}

# Function to process files in a category
process_category() {
  local category="$1"
  local pattern="$2"
  local description="$3"
  
  echo ""
  echo "🎯 Processing $description"
  echo "$(printf '=%.0s' $(seq 1 $((${#description} + 15))))"
  
  local files_found=0
  local files_modified=0
  
  while IFS= read -r -d '' file; do
    files_found=$((files_found + 1))
    
    if needs_test_helpers "$file"; then
      helper_type=$(get_test_helper_type "$file")
      add_test_helpers "$file" "$helper_type"
      files_modified=$((files_modified + 1))
    else
      if [ "$VERBOSE" = true ]; then
        echo "  ⏭️  Skipped: $file (already has test helpers)"
      fi
    fi
  done < <(find test/ -name "$pattern" -print0)
  
  echo "  📊 Found: $files_found files, Modified: $files_modified files"
}

# Main processing
echo "🚀 Starting batch processing..."

# Process high-priority categories
process_category "services" "*service*_test.dart" "Service Tests (High Priority)"
process_category "initialization" "*initialization*_test.dart" "Initialization Tests"
process_category "integration" "*integration*_test.dart" "Integration Tests"
process_category "widgets" "*widget*_test.dart" "Widget Tests"
process_category "error_handling" "*error*_test.dart" "Error Handling Tests"

# Process remaining test files
echo ""
echo "🎯 Processing Remaining Test Files"
echo "=================================="

remaining_files=0
remaining_modified=0

while IFS= read -r -d '' file; do
  remaining_files=$((remaining_files + 1))
  
  if needs_test_helpers "$file"; then
    helper_type=$(get_test_helper_type "$file")
    add_test_helpers "$file" "$helper_type"
    remaining_modified=$((remaining_modified + 1))
  fi
done < <(find test/ -name "*_test.dart" -print0)

echo "  📊 Total remaining files processed: $remaining_files, Modified: $remaining_modified"

# Summary
echo ""
echo "✨ Batch Processing Complete!"
echo "============================"
if [ "$DRY_RUN" = false ]; then
  echo "📁 Backups saved to: $BACKUP_DIR"
  echo "🔧 Files have been modified to include test helpers"
  echo ""
  echo "🧪 Next steps:"
  echo "1. Run tests to verify changes: flutter test --reporter compact"
  echo "2. Check for any compilation errors"
  echo "3. Commit changes if everything looks good"
  echo ""
  echo "🔄 To restore from backup if needed:"
  echo "cp $BACKUP_DIR/* test/path/to/original/location/"
else
  echo "🔍 This was a dry run - no files were modified"
  echo "🚀 Run without --dry-run to apply changes"
fi

echo ""
echo "💡 Expected impact:"
echo "- Massive reduction in debug log output during testing"
echo "- Faster TDD cycles with cleaner test output"
echo "- Better context efficiency for AI-assisted development"