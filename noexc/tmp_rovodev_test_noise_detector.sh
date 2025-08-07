#!/bin/bash

# Test Noise Detector - Find tests with debug log pollution
echo "🔍 Scanning for tests with debug log pollution..."
echo "=================================================="

# Find all test files
TEST_FILES=$(find test/ -name "*_test.dart" | head -10)  # Limit to first 10 for quick scan

echo "📊 Debug Log Count by Test File:"
echo "================================"

for test_file in $TEST_FILES; do
    echo -n "Testing $test_file... "
    
    # Run test and count debug logs (🔍)
    DEBUG_COUNT=$(timeout 30s flutter test "$test_file" 2>&1 | grep -c "🔍" || echo "0")
    
    if [ "$DEBUG_COUNT" -gt 0 ]; then
        echo "❌ $DEBUG_COUNT debug logs"
    else
        echo "✅ Clean"
    fi
done

echo ""
echo "🎯 Tests needing setupQuietTesting():"
echo "====================================="

# Check which tests already use test helpers
echo "Tests already using test_helpers:"
grep -l "import.*test_helpers" test/**/*.dart 2>/dev/null || echo "None found"

echo ""
echo "Tests NOT using test_helpers:"
find test/ -name "*.dart" -exec grep -L "import.*test_helpers" {} \; | head -10