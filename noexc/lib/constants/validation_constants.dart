/// Constants for validation error types and severity levels
class ValidationConstants {
  // Error types
  static const String missingSequenceId = 'MISSING_SEQUENCE_ID';
  static const String missingSequenceName = 'MISSING_SEQUENCE_NAME';
  static const String emptySequence = 'EMPTY_SEQUENCE';
  static const String duplicateMessageIds = 'DUPLICATE_MESSAGE_IDS';
  static const String invalidNextMessageId = 'INVALID_NEXT_MESSAGE_ID';
  static const String invalidChoiceNextMessageId =
      'INVALID_CHOICE_NEXT_MESSAGE_ID';
  static const String invalidRouteNextMessageId =
      'INVALID_ROUTE_NEXT_MESSAGE_ID';
  static const String unreachableMessage = 'UNREACHABLE_MESSAGE';
  static const String deadEnd = 'DEAD_END';
  static const String circularReference = 'CIRCULAR_REFERENCE';
  static const String missingChoices = 'MISSING_CHOICES';
  static const String choiceNoDestination = 'CHOICE_NO_DESTINATION';
  static const String missingRoutes = 'MISSING_ROUTES';
  static const String missingDefaultRoute = 'MISSING_DEFAULT_ROUTE';
  static const String routeNoDestination = 'ROUTE_NO_DESTINATION';
  static const String templateSyntaxWarning = 'TEMPLATE_SYNTAX_WARNING';

  // Severity levels
  static const String severityError = 'error';
  static const String severityWarning = 'warning';
  static const String severityInfo = 'info';

  // Private constructor to prevent instantiation
  ValidationConstants._();
}
