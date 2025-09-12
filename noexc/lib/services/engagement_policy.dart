/// Simple engagement policy that decides whether the app should re-engage
/// on resume using existing guards only.
class EngagementPolicy {
  /// Returns true if it's safe to re-engage (append/start a sequence).
  /// Guards:
  /// - panelOpen: user debug/menu panel is visible
  /// - hasTextInput: a text input bubble is currently active
  /// - hasUnansweredChoice: a choice bubble is visible and not answered
  static bool shouldReengage({
    required bool panelOpen,
    required bool hasTextInput,
    required bool hasUnansweredChoice,
  }) {
    if (panelOpen) return false;
    if (hasTextInput) return false;
    if (hasUnansweredChoice) return false;
    return true;
  }
}

