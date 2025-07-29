import 'package:flutter/material.dart';
import '../../services/logger_service.dart';
import '../../constants/design_tokens.dart';

/// Logger controls widget for the debug panel
class LoggerControlsWidget extends StatefulWidget {
  const LoggerControlsWidget({super.key});

  @override
  State<LoggerControlsWidget> createState() => _LoggerControlsWidgetState();
}

class _LoggerControlsWidgetState extends State<LoggerControlsWidget> {
  LogLevel _selectedLevel = LogLevel.debug;
  Set<LogComponent> _enabledComponents = {};
  bool _showTimestamps = false;
  bool _allComponentsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfiguration();
  }

  void _loadCurrentConfiguration() {
    final config = logger.getConfiguration();
    setState(() {
      _selectedLevel = LogLevel.values.firstWhere(
        (level) => level.name == config['minLevel'],
        orElse: () => LogLevel.debug,
      );
      _showTimestamps = config['showTimestamps'] ?? false;
      _allComponentsEnabled = config['allComponentsEnabled'] ?? true;
      
      if (!_allComponentsEnabled) {
        final enabledComponentNames = List<String>.from(config['enabledComponents'] ?? []);
        _enabledComponents = LogComponent.values
            .where((comp) => enabledComponentNames.contains(comp.name))
            .toSet();
      }
    });
  }

  void _applyConfiguration() {
    logger.configure(
      minLevel: _selectedLevel,
      enabledComponents: _allComponentsEnabled ? null : _enabledComponents,
      showTimestamps: _showTimestamps,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logger configuration applied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: DesignTokens.debugCardMargin,
      child: Padding(
        padding: DesignTokens.debugCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, size: 16),
                SizedBox(width: 8),
                Text(
                  'Logger Controls',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.mediumSpacing),
            
            // Log Level Selection
            Text(
              'Log Level',
              style: TextStyle(
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.getDebugTextSecondary(context),
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<LogLevel>(
              value: _selectedLevel,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: DesignTokens.debugCardContentPadding,
                border: OutlineInputBorder(),
              ),
              items: LogLevel.values.map((level) {
                return DropdownMenuItem<LogLevel>(
                  value: level,
                  child: Row(
                    children: [
                      Text(level.emoji),
                      const SizedBox(width: 8),
                      Text(level.name.toUpperCase()),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (LogLevel? newLevel) {
                if (newLevel != null) {
                  setState(() {
                    _selectedLevel = newLevel;
                  });
                }
              },
            ),
            const SizedBox(height: DesignTokens.mediumSpacing),
            
            // Timestamps Toggle
            CheckboxListTile(
              title: const Text('Show Timestamps'),
              value: _showTimestamps,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (bool? value) {
                setState(() {
                  _showTimestamps = value ?? false;
                });
              },
            ),
            
            // All Components Toggle
            CheckboxListTile(
              title: const Text('Enable All Components'),
              value: _allComponentsEnabled,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (bool? value) {
                setState(() {
                  _allComponentsEnabled = value ?? true;
                  if (_allComponentsEnabled) {
                    _enabledComponents.clear();
                  }
                });
              },
            ),
            
            // Component Selection (only if not all enabled)
            if (!_allComponentsEnabled) ...[
              const SizedBox(height: DesignTokens.smallSpacing),
              Text(
                'Enabled Components',
                style: TextStyle(
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: DesignTokens.getDebugTextSecondary(context),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: DesignTokens.getDebugCardBorder(context)),
                  borderRadius: BorderRadius.circular(DesignTokens.debugCardRadius),
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: LogComponent.values.map((component) {
                    return CheckboxListTile(
                      title: Text(component.tag, style: TextStyle(fontSize: DesignTokens.fontSizeXS)),
                      value: _enabledComponents.contains(component),
                      dense: true,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _enabledComponents.add(component);
                          } else {
                            _enabledComponents.remove(component);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
            
            const SizedBox(height: DesignTokens.mediumSpacing),
            
            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyConfiguration,
                style: ElevatedButton.styleFrom(
                  padding: DesignTokens.debugButtonPadding,
                ),
                child: const Text('Apply Configuration'),
              ),
            ),
            
            const SizedBox(height: DesignTokens.smallSpacing),
            
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedLevel = LogLevel.debug;
                        _allComponentsEnabled = true;
                        _enabledComponents.clear();
                        _showTimestamps = false;
                      });
                      _applyConfiguration();
                    },
                    child: Text('Debug All', style: TextStyle(fontSize: DesignTokens.fontSizeXS)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedLevel = LogLevel.error;
                        _allComponentsEnabled = true;
                        _enabledComponents.clear();
                        _showTimestamps = false;
                      });
                      _applyConfiguration();
                    },
                    child: Text('Errors Only', style: TextStyle(fontSize: DesignTokens.fontSizeXS)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}