#!/bin/bash

# Compact Test Command Aliases
# Source this file: source tool/test_aliases.sh

# Quick test aliases
alias tf='flutter test --reporter failures-only'
alias tc='flutter test --reporter compact' 
alias tq='dart tool/tdd_runner.dart --quiet'
alias ts='./tool/quick_test_summary.sh'
alias ta='dart tool/test_analyzer.dart'

# Category aliases
alias tf-services='flutter test test/services/ --reporter failures-only'
alias tf-models='flutter test test/models/ --reporter failures-only'
alias tf-widgets='flutter test test/widgets/ --reporter failures-only'
alias tf-cli='flutter test test/cli/ --reporter failures-only'
alias tf-validation='flutter test test/validation/ --reporter failures-only'

# Quick fix commands
alias fix-models='flutter test test/models/chat_message_test.dart --reporter expanded'
alias fix-widgets='flutter test test/widgets/ --reporter expanded'

# Analysis commands
alias ta-services='dart tool/test_analyzer.dart --category services'
alias ta-quick='dart tool/test_analyzer.dart --quick --failures-only'

echo "🧪 Test aliases loaded:"
echo "  tf          - failures only"
echo "  tc          - compact format"  
echo "  tq          - TDD quiet mode"
echo "  ts          - quick summary"
echo "  ta          - full analyzer"
echo "  tf-services - service failures"
echo "  tf-models   - model failures"
echo "  ta-quick    - quick analysis"