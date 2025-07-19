import 'package:flutter/material.dart';
import '../../constants/ui_constants.dart';
import '../../constants/storage_keys.dart';
import '../../services/user_data_service.dart';

/// Widget for picking date and time to test day tracking functionality
class DateTimePickerWidget extends StatefulWidget {
  final UserDataService userDataService;
  final VoidCallback? onDataChanged;

  const DateTimePickerWidget({
    super.key,
    required this.userDataService,
    this.onDataChanged,
  });

  @override
  State<DateTimePickerWidget> createState() => _DateTimePickerWidgetState();
}

class _DateTimePickerWidgetState extends State<DateTimePickerWidget> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _currentTaskDate = '';
  String _currentDeadlineTime = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentValues();
  }

  Future<void> _loadCurrentValues() async {
    final taskDate = await widget.userDataService.getValue<String>(StorageKeys.taskCurrentDate);
    final deadlineTimeString = await _getDeadlineTimeAsString();
    
    setState(() {
      _currentTaskDate = taskDate ?? 'Not set';
      _currentDeadlineTime = deadlineTimeString;
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

    // Parse current deadline time
    try {
      final timeParts = _currentDeadlineTime.split(':');
      if (timeParts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }
    } catch (e) {
      _selectedTime = const TimeOfDay(hour: 21, minute: 0);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
              borderRadius: BorderRadius.circular(4),
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

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _setTaskDate() async {
    final dateString = _formatDate(_selectedDate);
    await widget.userDataService.storeValue(StorageKeys.taskCurrentDate, dateString);
    
    setState(() {
      _currentTaskDate = dateString;
    });
    
    widget.onDataChanged?.call();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task date set to $dateString')),
      );
    }
  }

  /// Get deadline time as string, handling both integer and string storage formats
  Future<String> _getDeadlineTimeAsString() async {
    // Try to get as string first (new format)
    try {
      final stringValue = await widget.userDataService.getValue<String>(StorageKeys.taskDeadlineTime);
      if (stringValue != null) {
        return stringValue;
      }
    } catch (e) {
      // Type cast failed, value is probably an integer
    }
    
    // Try to get as integer (legacy format from JSON sequences)
    try {
      final intValue = await widget.userDataService.getValue<int>(StorageKeys.taskDeadlineTime);
      if (intValue != null) {
        // Convert integer to time string based on task config sequence format
        switch (intValue) {
          case 1: return '11:00'; // Morning (before noon)
          case 2: return '17:00'; // Afternoon (noon to 5pm) 
          case 3: return '21:00'; // Evening (5pm to 9pm)
          case 4: return '06:00'; // Night (9pm to 6am) - use 6am as reasonable night deadline
          default: return '21:00'; // Default to evening
        }
      }
    } catch (e) {
      // Type cast failed, value is probably a string or doesn't exist
    }
    
    // Default if neither format found
    return '21:00';
  }

  Future<void> _setDeadlineTime() async {
    final timeString = _formatTime(_selectedTime);
    await widget.userDataService.storeValue(StorageKeys.taskDeadlineTime, timeString);
    
    setState(() {
      _currentDeadlineTime = timeString;
    });
    
    widget.onDataChanged?.call();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deadline time set to $timeString')),
      );
    }
  }

  Future<void> _setToToday() async {
    final today = DateTime.now();
    final todayString = _formatDate(today);
    
    await widget.userDataService.storeValue(StorageKeys.taskCurrentDate, todayString);
    
    setState(() {
      _selectedDate = today;
      _currentTaskDate = todayString;
    });
    
    widget.onDataChanged?.call();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task date reset to today')),
      );
    }
  }

  Future<void> _setToYesterday() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayString = _formatDate(yesterday);
    
    await widget.userDataService.storeValue(StorageKeys.taskCurrentDate, yesterdayString);
    
    setState(() {
      _selectedDate = yesterday;
      _currentTaskDate = yesterdayString;
    });
    
    widget.onDataChanged?.call();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task date set to yesterday (for testing)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Date & Time Testing'),
        
        // Current Values Display
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
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
            ],
          ),
        ),
        
        // Date Picker Section
        Padding(
          padding: UIConstants.variableItemPadding,
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
        
        // Time Picker Section
        Padding(
          padding: UIConstants.variableItemPadding,
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
                    child: OutlinedButton.icon(
                      onPressed: _selectTime,
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(_formatTime(_selectedTime)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _setDeadlineTime,
                    child: const Text('Set'),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
      ],
    );
  }
}