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
    1: 'Morning (before noon)',
    2: 'Afternoon (noon to 5pm)', 
    3: 'Evening (5pm to 9pm)',
    4: 'Night (9pm to midnight)',
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentValues();
  }

  Future<void> _loadCurrentValues() async {
    final taskDate = await widget.userDataService.getValue<String>(StorageKeys.taskCurrentDate);
    final deadlineOption = await widget.userDataService.getValue<int>(StorageKeys.taskDeadlineTime);
    final isActiveDay = await widget.userDataService.getValue<bool>(StorageKeys.taskIsActiveDay);
    final isPastDeadline = await widget.userDataService.getValue<bool>(StorageKeys.taskIsPastDeadline);
    
    setState(() {
      _currentTaskDate = taskDate ?? 'Not set';
      _selectedDeadlineOption = deadlineOption;
      _currentDeadlineTime = deadlineOption != null 
          ? deadlineOptions[deadlineOption] ?? 'Unknown option'
          : 'Not set';
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


  Future<void> _setTaskDate() async {
    final dateString = _formatDate(_selectedDate);
    await widget.userDataService.storeValue(StorageKeys.taskCurrentDate, dateString);
    
    setState(() {
      _currentTaskDate = dateString;
    });
    
    widget.onDataChanged?.call();
    
    widget.statusController?.addSuccess('Task date set to $dateString');
  }


  Future<void> _setDeadlineOption(int option) async {
    await widget.userDataService.storeValue(StorageKeys.taskDeadlineTime, option);
    
    setState(() {
      _selectedDeadlineOption = option;
      _currentDeadlineTime = deadlineOptions[option] ?? 'Unknown option';
    });
    
    widget.onDataChanged?.call();
    
    widget.statusController?.addSuccess('Deadline set to ${deadlineOptions[option]}');
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
    
    widget.statusController?.addSuccess('Task date reset to today');
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
                'Set Deadline Option',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...deadlineOptions.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _setDeadlineOption(entry.key),
                    icon: Icon(
                      _selectedDeadlineOption == entry.key 
                          ? Icons.check_circle 
                          : Icons.radio_button_unchecked,
                      size: 16,
                    ),
                    label: Text(entry.value),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedDeadlineOption == entry.key
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: _selectedDeadlineOption == entry.key
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        ],
      ),
    );
  }
}