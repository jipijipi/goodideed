#!/bin/bash

# Quick test summary script for compact failure analysis
echo "🧪 Quick Test Summary"
echo "===================="

# Run tests and capture failures
echo "Running tests with failures-only reporter..."
TEST_OUTPUT=$(flutter test --reporter failures-only 2>&1)
EXIT_CODE=$?

# Count totals
TOTAL_TESTS=$(echo "$TEST_OUTPUT" | grep -E "^\+[0-9]+" | tail -1 | sed 's/^+\([0-9]*\).*/\1/')
FAILED_TESTS=$(echo "$TEST_OUTPUT" | grep -E "^\+[0-9]+ -[0-9]+" | wc -l | tr -d ' ')

echo "Exit Code: $EXIT_CODE"
echo "Total Tests: $TOTAL_TESTS"
echo "Failed Tests: $FAILED_TESTS"

if [ "$FAILED_TESTS" -gt 0 ]; then
    echo ""
    echo "❌ FAILING TESTS:"
    echo "================="
    
    # Group failures by test file
    echo "$TEST_OUTPUT" | grep -E "^\+[0-9]+ -[0-9]+:" | while read line; do
        # Extract test file and test name
        TEST_FILE=$(echo "$line" | sed 's/.*\/Users\/jpl\/Dev\/Apps\/noexc\/test\/\([^:]*\):.*/\1/')
        TEST_NAME=$(echo "$line" | sed 's/.*: \(.*\) \[E\]/\1/' | sed 's/.*: \(.*\)/\1/')
        echo "📁 $TEST_FILE: $TEST_NAME"
    done | sort | uniq -c | sort -nr
    
    echo ""
    echo "📊 FAILURE CATEGORIES:"
    echo "====================="
    
    # Count by directory
    echo "$TEST_OUTPUT" | grep -E "^\+[0-9]+ -[0-9]+:" | sed 's/.*\/test\/\([^\/]*\)\/.*/\1/' | sort | uniq -c | sort -nr
    
    echo ""
    echo "🔍 SAMPLE FAILURES:"
    echo "=================="
    echo "$TEST_OUTPUT" | grep -A 5 -E "^\+[0-9]+ -[0-9]+:" | head -30
else
    echo "✅ All tests passed!"
fi

echo ""
echo "💡 Quick Commands:"
echo "  flutter test test/models/ --reporter failures-only"
echo "  flutter test test/services/ --reporter failures-only" 
echo "  flutter test test/widgets/ --reporter failures-only"
echo "  dart tool/test_analyzer.dart --category models"