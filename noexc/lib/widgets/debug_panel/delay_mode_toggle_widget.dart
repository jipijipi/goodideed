import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../services/display_settings_service.dart';

class DelayModeToggleWidget extends StatefulWidget {
  const DelayModeToggleWidget({super.key});

  @override
  State<DelayModeToggleWidget> createState() => _DelayModeToggleWidgetState();
}

class _DelayModeToggleWidgetState extends State<DelayModeToggleWidget> {
  late final DisplaySettingsService _settings;

  @override
  void initState() {
    super.initState();
    _settings = ServiceLocator.instance.displaySettings;
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Instant display (test mode)'),
      subtitle: Text(
        _settings.instantDisplay
            ? 'Messages appear immediately'
            : 'Adaptive delays based on word count',
      ),
      value: _settings.instantDisplay,
      onChanged: (v) => _settings.instantDisplay = v,
    );
  }
}
