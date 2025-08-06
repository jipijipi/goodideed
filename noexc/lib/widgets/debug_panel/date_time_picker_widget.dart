import 'package:flutter/material.dart';
import '../../constants/design_tokens.dart';
import '../../constants/storage_keys.dart';
import '../../services/user_data_service.dart';
import 'debug_status_area.dart';

/// Widget for picking date and time to test day tracking functionality
class DateTimePickerWidget extends StatefulWidget {
  final UserDataService userDataService;
  final VoidCallback? onDataChanged;
  final DebugStatusController? statusController;

  const DateTimePickerWidget({
    super.key,
    required this.userDataService,
    this.onDataChanged,
    this.statusController,
  });

  @override
  State<DateTimePickerWidget> createState() => _DateTimePickerWidgetState();
}

class _DateTimePickerWidgetState extends State<DateTimePickerWidget> {
  DateTime _selectedDate = DateTime.now();
  String _currentTaskDate = '';
  String _currentDeadlineTime = '';
  String _currentIsActiveDay = '';
  String _currentIsPastDeadline = '';
  int? _selectedDeadlineOption;

  // Deadline options matching the JSON sequence choices
  static const Map<int, String> deadlineOptions = {
    1: 'Morning (10:00)',
    2: 'Afternoon (14:00)', 
    3: 'Evening (18:00)',
    4: 'Night (23:00)',
  };

  // Time string to option number mapping
  static const Map<String, int> timeStringToOption = {
    '10:00': 1,
    '14:00': 2,
    '18:00': 3,
    '23:00': 4,
  };

  // Option number to time string mapping
  static const Map<int, String> optionToTimeString = {
    1: '10:00',
    2: '14:00',
    3: '18:00',
    4: '23:00',
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentValues();
  }

  Future<void> _loadCurrentValues() async {
    final taskDate = await widget.userDataService.getValue<String>(StorageKeys.taskCurrentDate);
    final isActiveDay = await widget.userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
    final isPastDeadline = await widget.userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
    
    // Handle both string and integer deadline formats
    String deadlineDisplay = 'Not set';
    int? selectedOption;
    
    // Try string format first (new format)
    final deadlineString = await widget.userDataService.getValue<String>(StorageKeys.taskDeadlineTime);
    if (deadlineString != null) {
      deadlineDisplay = deadlineString;
      // Convert string time to option number for UI selection
      selectedOption = _timeStringToOption(deadlineString);
    } else {
      // Try integer format (legacy format)  
      final deadlineOption = await widget.userDataService.getValue<int>(StorageKeys.taskDeadlineTime);
      if (deadlineOption != null) {
        selectedOption = deadlineOption;
        deadlineDisplay = deadlineOptions[deadlineOption] ?? 'Unknown option';
      }
    }
    
    setState(() {
      _currentTaskDate = taskDate ?? 'Not set';
      _selectedDeadlineOption = selectedOption;
      _currentDeadlineTime = deadlineDisplay;
      _currentIsActiveDay = isActiveDay?.toString() ?? 'Not computed';
      _currentIsPastDeadline = isPastDeadline?.toString() ?? 'Not computed';
    });

    // Parse current task date if it exists
    if (taskDate != null) {
      try {
        final parts = taskDate.split('-');
        if (parts.length == 3) {
          _selectedDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      } catch (e) {
        // Use current date if parsing fails
        _selectedDate = DateTime.now();
      }
    }

  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Convert time string to option number for UI selection
  int? _timeStringToOption(String timeString) {
    return timeStringToOption[timeString];
  }


  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCurrentValueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(DesignTokens.debugButtonRadius),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }


  Future<void> _setTaskDate() async {
    final dateString = _formatDate(_selectedDate);
    
    // Validate date format before storing
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateString)) {
      widget.statusController?.addError('Error: Invalid date format');
      return;
    }
    
    await widget.userDataService.storeValue(StorageKeys.taskCurrentDate, dateString);
    
    // Note: isActiveDay will be recalculated on next session initialization
    // The inline computation in _checkCurrentDayDeadline prevents race conditions
    
    setState(() {
      _currentTaskDate = dateString;
    });
    
    widget.onDataChanged?.call();
    
    widget.statusController?.addSuccess('Task date set to $dateString');
  }


  Future<void> _setDeadlineOption(int option) async {
    // Store as string format (new format)
    final timeString = optionToTimeString[option];
    if (timeString != null) {
      await widget.userDataService.storeValue(StorageKeys.taskDeadlineTime, timeString);
      
      setState(() {
        _selectedDeadlineOption = option;
        _currentDeadlineTime = timeString;
      });
      
      widget.onDataChanged?.call();
      
      widget.statusController?.addSuccess('Deadline set to ${deadlineOptions[option]} ($timeString)');
    }
  }

  Future<void> _setToToday() async {
    final today = DateTime.now();
    final todayString = _formatDate(today);
    
    // Date validation (should always pass for DateTime.now())
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(todayString)) {
      widget.statusController?.addError('Error: Invalid date format');
      return;
    }
    
    await widget.userDataService.storeValue(StorageKeys.taskCurrentDate, todayString);
    
    setState(() {
      _selectedDate = today;
      _currentTaskDate = todayString;
    });
    
    widget.onDataChanged?.call();
    
    widget.statusController?.addSuccess('Task date reset to today');
  }

  Future<void> _setToYesterday() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayString = _formatDate(yesterday);
    
    // Date validation (should always pass for DateTime operations)
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(yesterdayString)) {
      widget.statusController?.addError('Error: Invalid date format');
      return;
    }
    
    await widget.userDataService.storeValue(StorageKeys.taskCurrentDate, yesterdayString);
    
    setState(() {
      _selectedDate = yesterday;
      _currentTaskDate = yesterdayString;
    });
    
    widget.onDataChanged?.call();
    
    widget.statusController?.addSuccess('Task date set to yesterday (for testing)');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        _buildSectionHeader(context, 'Date & Time Testing'),
        
        // Current Values Display
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(DesignTokens.debugCardRadius),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Values',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildCurrentValueRow('Task Date:', _currentTaskDate),
              _buildCurrentValueRow('Deadline Time:', _currentDeadlineTime),
              _buildCurrentValueRow('Is Active Day:', _currentIsActiveDay),
              _buildCurrentValueRow('Is Past Deadline:', _currentIsPastDeadline),
            ],
          ),
        ),
        
        // Date Picker Section
        Padding(
          padding: DesignTokens.variableItemPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Task Date',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_formatDate(_selectedDate)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _setTaskDate,
                    child: const Text('Set'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Quick date buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _setToToday,
                      icon: const Icon(Icons.today, size: 16),
                      label: const Text('Today'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _setToYesterday,
                      icon: const Icon(Icons.history, size: 16),
                      label: const Text('Yesterday'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Deadline Options Section
        Padding(
          padding: DesignTokens.variableItemPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Deadline Time',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedDeadlineOption,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        hintText: 'Select deadline time',
                      ),
                      items: deadlineOptions.entries.map((entry) => DropdownMenuItem<int>(
                        value: entry.key,
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      )).toList(),
                      onChanged: (int? value) {
                        if (value != null) {
                          _setDeadlineOption(value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        ],
      ),
    );
  }
}