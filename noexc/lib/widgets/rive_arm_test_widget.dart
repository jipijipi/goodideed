import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// Example widget demonstrating Rive 0.14.0+ Data Binding with arm_test_3.riv
/// 
/// This widget shows how to:
/// - Load a Rive file with arm animation and data binding
/// - Access and control arm animation properties
/// - Update Rive animations via data binding in real-time
/// - Handle arm-specific controls and interactions
/// 
/// Required setup in main.dart:
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await RiveNative.init(); // Required for Rive 0.14.0+
///   runApp(const MyApp());
/// }
/// ```
class RiveArmTestWidget extends StatefulWidget {
  const RiveArmTestWidget({super.key});

  @override
  State<RiveArmTestWidget> createState() => _RiveArmTestWidgetState();
}

class _RiveArmTestWidgetState extends State<RiveArmTestWidget> {
  // Core Rive components
  File? file;
  RiveWidgetController? controller;
  
  // Data binding components
  ViewModelInstance? viewModelInstance;
  
  // Common arm control properties (will be populated based on what's available in the file)
  List<ViewModelInstanceNumber> armProperties = [];
  List<String> armPropertyNames = [];
  List<double> armPropertyValues = [];

  @override
  void initState() {
    super.initState();
    _initRive();
  }

  /// Initialize Rive file and set up data binding
  Future<void> _initRive() async {
    // Step 1: Load the Rive file
    file = await File.asset(
      'assets/animations/arm_test_3.riv',
      riveFactory: Factory.rive, // Use Factory.rive for Rive renderer
    );
    
    // Step 2: Create controller
    controller = RiveWidgetController(file!);
    
    // Step 3: Set up data binding
    _initDataBinding();
    
    // Step 4: Update UI
    setState(() {});
  }

  /// Set up data binding with view model properties
  void _initDataBinding() {
    // Create view model instance using auto-binding
    viewModelInstance = controller!.dataBind(DataBind.auto());
    
    if (viewModelInstance != null) {
      // Discover available number properties in the view model
      // Common arm animation properties might include position, rotation, scale, etc.
      _discoverArmProperties();
    }
  }

  /// Discover and initialize arm control properties from the view model
  void _discoverArmProperties() {
    // Common property names that might exist in arm animations
    final possibleProperties = [
      'elbow_rotation',
      'shoulder_rotation',
      'pince_pos_x',
      'pince_pos_y',
      'pince_rotation',
/*       'hand_controller_y', 
      'hand_controller_x',
      'hand_rotation', */
    ];
    
    for (String propertyName in possibleProperties) {
      final property = viewModelInstance!.number(propertyName);
      if (property != null) {
        armProperties.add(property);
        armPropertyNames.add(propertyName);
        armPropertyValues.add(property.value);
      }
    }
  }

  /// Update specific arm property when slider value changes
  void _updateArmProperty(int index, double value) {
    if (index < armProperties.length) {
      armProperties[index].value = value;
      armPropertyValues[index] = value;
      
      // Data binding automatically updates the animation - no manual advancement needed
    }
  }

  @override
  void dispose() {
    // Dispose of all resources in reverse order of creation
    for (var property in armProperties) {
      property.dispose();
    }
    viewModelInstance?.dispose();
    controller?.dispose();
    file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Rive animation display area
          Expanded(
            child: controller == null
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : RiveWidget(
                    controller: controller,
                    fit: Fit.contain,
                  ),
          ),
          
          // Control panel
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (armProperties.isEmpty)
                  const Text(
                    'No controllable properties found in this Rive file',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  )
                else
                  ...List.generate(armProperties.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          Text(
                            '${armPropertyNames[index]}: ${armPropertyValues[index].toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Slider(
                            value: armPropertyValues[index],
                            min: -200,
                            max: 200,
                            activeColor: _getSliderColor(index),
                            inactiveColor: _getSliderColor(index).withValues(alpha: 0.3),
                            onChanged: (value) {
                              setState(() {
                                armPropertyValues[index] = value;
                              });
                              _updateArmProperty(index, value);
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get a unique color for each slider
  Color _getSliderColor(int index) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.pink,
      Colors.amber,
    ];
    return colors[index % colors.length];
  }
}
