import '../../models/chat_sequence.dart';
import '../chat_service/sequence_loader.dart';
import '../logger_service.dart';

/// Manages atomic sequence transitions with rollback capability
/// 
/// This class ensures that sequence changes are handled atomically:
/// - Either the transition fully succeeds
/// - Or it rolls back to the previous state
/// 
/// This prevents partial state issues that can cause message ordering problems.
class SequenceTransitionManager {
  final SequenceLoader _sequenceLoader;
  final logger = LoggerService.instance;
  
  /// Backup of the previous sequence for rollback
  ChatSequence? _previousSequence;
  String? _previousSequenceId;
  
  SequenceTransitionManager(this._sequenceLoader);

  /// Atomically transition to a new sequence
  /// 
  /// This method:
  /// 1. Validates the target sequence exists
  /// 2. Backs up the current sequence state
  /// 3. Loads the new sequence
  /// 4. Validates the transition succeeded
  /// 5. Rolls back if any step fails
  Future<void> transitionToSequence(String sequenceId) async {
    logger.info('Starting atomic sequence transition to: $sequenceId');
    
    // Backup current state for potential rollback
    _backupCurrentState();
    
    try {
      // Validate target sequence exists (this will throw if not found)
      await _validateSequenceExists(sequenceId);
      
      // Perform the actual transition
      await _sequenceLoader.loadSequence(sequenceId);
      
      // Validate the transition was successful
      _validateTransitionSuccess(sequenceId);
      
      logger.info('Sequence transition completed successfully to: $sequenceId');
      
      // Clear backup on successful transition
      _clearBackup();
      
    } catch (e) {
      logger.error('Sequence transition failed: $e');
      
      // Attempt rollback
      await _rollback();
      
      rethrow;
    }
  }

  /// Backup the current sequence state
  void _backupCurrentState() {
    _previousSequence = _sequenceLoader.currentSequence;
    _previousSequenceId = _previousSequence?.sequenceId;
    
    logger.debug('Backed up current sequence: $_previousSequenceId');
  }

  /// Validate that the target sequence exists and can be loaded
  Future<void> _validateSequenceExists(String sequenceId) async {
    try {
      // This will throw an exception if the sequence doesn't exist
      // We don't store the result here, just validate it can be loaded
      await _sequenceLoader.loadSequence(sequenceId);
    } catch (e) {
      throw Exception('Target sequence "$sequenceId" cannot be loaded: $e');
    }
  }

  /// Validate that the transition was successful
  void _validateTransitionSuccess(String expectedSequenceId) {
    final currentSequence = _sequenceLoader.currentSequence;
    
    if (currentSequence == null) {
      throw Exception('Transition failed: no sequence loaded');
    }
    
    if (currentSequence.sequenceId != expectedSequenceId) {
      throw Exception(
        'Transition failed: expected "$expectedSequenceId", got "${currentSequence.sequenceId}"'
      );
    }
    
    // Validate the sequence has messages
    if (currentSequence.messages.isEmpty) {
      throw Exception('Transition failed: sequence "$expectedSequenceId" has no messages');
    }
  }

  /// Rollback to the previous sequence state
  Future<void> _rollback() async {
    if (_previousSequence == null) {
      logger.warning('Cannot rollback: no previous sequence backed up');
      return;
    }
    
    try {
      logger.info('Rolling back to previous sequence: $_previousSequenceId');
      
      if (_previousSequenceId != null) {
        await _sequenceLoader.loadSequence(_previousSequenceId!);
      }
      
      logger.info('Rollback completed successfully');
    } catch (e) {
      logger.error('Rollback failed: $e');
      // At this point we're in an inconsistent state
      // The calling code will need to handle this
      rethrow;
    } finally {
      _clearBackup();
    }
  }

  /// Clear the backup state
  void _clearBackup() {
    _previousSequence = null;
    _previousSequenceId = null;
  }

  /// Get the current sequence ID (for debugging)
  String? get currentSequenceId => _sequenceLoader.currentSequence?.sequenceId;
  
  /// Check if we have a backup (for testing)
  bool get hasBackup => _previousSequence != null;
}