/// Main sequence validator that orchestrates all validation types
library;
import '../models/chat_sequence.dart';
import '../constants/validation_constants.dart';
import 'models/validation_models.dart';
import 'validators/structure_validator.dart';
import 'validators/reference_validator.dart';
import 'validators/flow_validator.dart';
import 'validators/choice_validator.dart';
import 'validators/route_validator.dart';
import 'validators/template_validator.dart';

/// Main validator that coordinates all validation types
class SequenceValidator {
  final StructureValidator _structureValidator = StructureValidator();
  final ReferenceValidator _referenceValidator = ReferenceValidator();
  final FlowValidator _flowValidator = FlowValidator();
  final ChoiceValidator _choiceValidator = ChoiceValidator();
  final RouteValidator _routeValidator = RouteValidator();
  final TemplateValidator _templateValidator = TemplateValidator();

  /// Validates a complete chat sequence
  ValidationResult validateSequence(ChatSequence sequence) {
    final errors = <ValidationError>[];
    final warnings = <ValidationError>[];
    final info = <ValidationError>[];
    
    // Basic structure validation
    errors.addAll(_structureValidator.validate(sequence));
    
    // Message reference validation
    errors.addAll(_referenceValidator.validate(sequence));
    
    // Flow analysis
    final flowIssues = _flowValidator.validate(sequence);
    errors.addAll(flowIssues.where((e) => e.severity == ValidationConstants.severityError));
    warnings.addAll(flowIssues.where((e) => e.severity == ValidationConstants.severityWarning));
    info.addAll(flowIssues.where((e) => e.severity == ValidationConstants.severityInfo));
    
    // Choice validation
    errors.addAll(_choiceValidator.validate(sequence));
    
    // Route condition validation
    errors.addAll(_routeValidator.validate(sequence));
    
    // Template validation
    warnings.addAll(_templateValidator.validate(sequence));
    
    return ValidationResult(
      errors: errors,
      warnings: warnings,
      info: info,
    );
  }
}