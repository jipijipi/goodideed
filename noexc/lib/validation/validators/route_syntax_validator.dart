/// Warns on suspicious route condition syntax (best-effort static check)
library;

import '../../models/chat_sequence.dart';
import '../../models/chat_message.dart';
import '../../constants/validation_constants.dart';
import '../models/validation_models.dart';

class RouteSyntaxValidator {
  List<ValidationError> validate(ChatSequence sequence) {
    final warnings = <ValidationError>[];

    for (final m in sequence.messages) {
      if (m.type != MessageType.autoroute || m.routes == null) continue;
      for (final r in m.routes!) {
        final c = r.condition?.trim();
        if (c == null || c.isEmpty) continue;
        // Simple static checks: balanced quotes and some operator presence
        final sqCount = _count(c, "'");
        final dqCount = _count(c, '"');
        final hasOp = c.contains('==') ||
            c.contains('!=') ||
            c.contains('>=') ||
            c.contains('<=') ||
            c.contains('>') ||
            c.contains('<') ||
            c.contains('&&') ||
            c.contains('||');
        if (sqCount % 2 != 0 || dqCount % 2 != 0 || !hasOp) {
          warnings.add(
            ValidationError(
              type: 'SUSPECT_ROUTE_CONDITION',
              message:
                  'Route condition may be malformed or unparseable: "$c"',
              messageId: m.id,
              sequenceId: sequence.sequenceId,
              severity: ValidationConstants.severityWarning,
            ),
          );
        }
      }
    }

    return warnings;
  }

  int _count(String s, String token) => s.split(token).length - 1;
}
