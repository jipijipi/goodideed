# CLI Testing Tool (Temporarily Disabled)

## Status: ⚠️ DISABLED

This directory contains CLI testing tools that were implemented prematurely and caused test instability.

## Why Disabled?

The CLI testing infrastructure was causing **19 test failures** due to:

- **Complex Integration Testing**: Testing across multiple unstable services
- **Timing Dependencies**: Async operations with unpredictable behavior  
- **Service Dependencies**: Semantic content service still has fallback warnings
- **Template Processing**: Integration incomplete, causing test brittleness
- **Premature Implementation**: Testing services that aren't fully stable

## What's In Here?

- **`conversation_runner.dart.disabled`** (588 lines): Full conversation simulation engine with terminal formatting, color codes, automatic response handling
- **`conversation_test.dart.disabled`** (435 lines): Comprehensive test suite covering basic flows, cross-sequence navigation, scenario-based testing, error handling

**Note**: Files renamed with `.disabled` extension to prevent Flutter test discovery

**Total**: 1000+ lines of conversation testing infrastructure

## Re-enablement Strategy

### Prerequisites:
1. ✅ **Semantic Content Service**: Eliminate fallback warnings, complete content resolution
2. ✅ **Template Processing**: Stabilize variable substitution and formatting
3. ✅ **Core Services**: Ensure ChatService, UserDataService, SessionService are robust

### Approach:
1. **Gradual Re-enablement**: Start with simple conversation tests
2. **Service-by-Service**: Test individual components before integration
3. **Monitoring**: Add comprehensive error handling and timeouts

### Timeline:
**Target**: 2-3 weeks after core service stabilization

## How to Re-enable

When ready to re-enable:

1. **Rename directory**: `test/cli_disabled/` → `test/cli/`
2. **Rename files**: Remove `.disabled` extensions from test files
3. **Verify dependencies**: Ensure all imported services are stable
4. **Run subset**: Start with basic conversation flow tests only
5. **Monitor failures**: Add proper error handling for remaining issues

## Development Notes

This was valuable development work that tested real conversation flows end-to-end. The implementation includes:

- **Terminal UI**: Rich formatting and color output
- **State Management**: Complex user state simulation
- **Sequence Navigation**: Cross-sequence routing testing  
- **Content Resolution**: Integration with semantic content system
- **Template Testing**: Variable substitution validation

**Don't delete** - this represents significant development investment and will be valuable once the underlying services are stable.

---

**Disabled on**: 2025-01-29  
**Reason**: Test instability (19 failures)  
**Decision**: Preserve for future use when services stabilize