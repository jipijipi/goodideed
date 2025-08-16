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
import 'validators/type_rules_validator.dart';
import 'validators/image_message_validator.dart';
import 'validators/delay_hygiene_validator.dart';
import 'validators/route_syntax_validator.dart';
import 'validators/choice_ambiguity_validator.dart';

/// Main validator that coordinates all validation types
class SequenceValidator {
  final StructureValidator _structureValidator = StructureValidator();
  final ReferenceValidator _referenceValidator = ReferenceValidator();
  final FlowValidator _flowValidator = FlowValidator();
  final ChoiceValidator _choiceValidator = ChoiceValidator();
  final RouteValidator _routeValidator = RouteValidator();
  final TemplateValidator _templateValidator = TemplateValidator();
  final TypeRulesValidator _typeRulesValidator = TypeRulesValidator();
  final ImageMessageValidator _imageMessageValidator = ImageMessageValidator();
  final DelayHygieneValidator _delayHygieneValidator = DelayHygieneValidator();
  final RouteSyntaxValidator _routeSyntaxValidator = RouteSyntaxValidator();
  final ChoiceAmbiguityValidator _choiceAmbiguityValidator = ChoiceAmbiguityValidator();

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
    errors.addAll(
      flowIssues.where((e) => e.severity == ValidationConstants.severityError),
    );
    warnings.addAll(
      flowIssues.where(
        (e) => e.severity == ValidationConstants.severityWarning,
      ),
    );
    info.addAll(
      flowIssues.where((e) => e.severity == ValidationConstants.severityInfo),
    );

    // Choice validation
    errors.addAll(_choiceValidator.validate(sequence));

    // Route condition validation
    errors.addAll(_routeValidator.validate(sequence));

    // Template validation
    warnings.addAll(_templateValidator.validate(sequence));

    // Type-specific rules validation
    errors.addAll(_typeRulesValidator.validate(sequence));

    // Image message constraints (errors)
    errors.addAll(_imageMessageValidator.validate(sequence));

    // Delay hygiene (warnings only)
    warnings.addAll(_delayHygieneValidator.validate(sequence));

    // Route syntax (warnings)
    warnings.addAll(_routeSyntaxValidator.validate(sequence));

    // Choice ambiguity (warnings)
    warnings.addAll(_choiceAmbiguityValidator.validate(sequence));

    return ValidationResult(errors: errors, warnings: warnings, info: info);
  }
}
