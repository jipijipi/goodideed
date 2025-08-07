#!/bin/bash

# Comprehensive Test Noise Analysis
echo "🔍 Comprehensive Test Noise Analysis"
echo "===================================="

# Count total tests and those using helpers
TOTAL_TESTS=$(find test/ -name "*_test.dart" | wc -l | tr -d ' ')
USING_HELPERS=$(grep -l "import.*test_helpers" test/**/*.dart 2>/dev/null | wc -l | tr -d ' ')
NOT_USING_HELPERS=$((TOTAL_TESTS - USING_HELPERS))

echo "📊 Test Helper Usage Summary:"
echo "Total test files: $TOTAL_TESTS"
echo "Using test_helpers: $USING_HELPERS"
echo "NOT using test_helpers: $NOT_USING_HELPERS"
echo "Coverage: $((USING_HELPERS * 100 / TOTAL_TESTS))%"
echo ""

# Quick noise check on high-impact test categories
echo "🎯 High-Impact Test Categories (Quick Noise Check):"
echo "=================================================="

# Services tests (most likely to have noise)
echo "Services tests:"
SERVICES_NOISY=$(find test/services/ -name "*_test.dart" -exec grep -L "import.*test_helpers" {} \; | wc -l | tr -d ' ')
SERVICES_TOTAL=$(find test/services/ -name "*_test.dart" | wc -l | tr -d ' ')
echo "  - $SERVICES_NOISY/$SERVICES_TOTAL likely noisy (no test_helpers)"

# Integration tests
echo "Integration tests:"
INTEGRATION_NOISY=$(find test/integration/ -name "*_test.dart" -exec grep -L "import.*test_helpers" {} \; 2>/dev/null | wc -l | tr -d ' ')
INTEGRATION_TOTAL=$(find test/integration/ -name "*_test.dart" 2>/dev/null | wc -l | tr -d ' ')
echo "  - $INTEGRATION_NOISY/$INTEGRATION_TOTAL likely noisy (no test_helpers)"

# Widget tests
echo "Widget tests:"
WIDGET_NOISY=$(find test/widgets/ -name "*_test.dart" -exec grep -L "import.*test_helpers" {} \; 2>/dev/null | wc -l | tr -d ' ')
WIDGET_TOTAL=$(find test/widgets/ -name "*_test.dart" 2>/dev/null | wc -l | tr -d ' ')
echo "  - $WIDGET_NOISY/$WIDGET_TOTAL likely noisy (no test_helpers)"

echo ""
echo "🔥 High-Priority Candidates for Noise (Services without test_helpers):"
echo "====================================================================="
find test/services/ -name "*_test.dart" -exec grep -L "import.*test_helpers" {} \; | head -10

echo ""
echo "💡 Quick Fix Strategy:"
echo "====================="
echo "1. Add setupQuietTesting() to $SERVICES_NOISY service tests"
echo "2. Add setupSilentTesting() to initialization/integration tests"
echo "3. Estimated time: $((SERVICES_NOISY * 2)) minutes (2 min per test file)"
echo ""
echo "🚀 Batch Fix Command (for services):"
echo "find test/services/ -name '*_test.dart' -exec grep -L 'import.*test_helpers' {} \\;"