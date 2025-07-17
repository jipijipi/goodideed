/// Constants for data action operations
class DataActionConstants {
  // Default values for data actions
  static const int defaultIncrementValue = 1;
  static const int defaultDecrementValue = 1;
  static const int defaultResetValue = 0;
  static const int defaultNumericValue = 0;
  
  // Common data action operations
  static const String operationSet = 'set';
  static const String operationIncrement = 'increment';
  static const String operationDecrement = 'decrement';
  static const String operationReset = 'reset';
  static const String operationTrigger = 'trigger';
  
  // Private constructor to prevent instantiation
  DataActionConstants._();
}