import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// Example widget demonstrating Rive 0.14.0+ Data Binding
/// 
/// This widget shows how to:
/// - Load a Rive file with data binding capabilities
/// - Access view model properties (number properties)
/// - Update Rive animations via data binding in real-time
/// - Properly dispose of resources
/// 
/// Required setup in main.dart:
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await RiveNative.init(); // Required for Rive 0.14.0+
///   runApp(const MyApp());
/// }
/// ```
class RiveDataBindingTestWidget extends StatefulWidget {
  const RiveDataBindingTestWidget({super.key});

  @override
  State<RiveDataBindingTestWidget> createState() => _RiveDataBindingTestWidgetState();
}

class _RiveDataBindingTestWidgetState extends State<RiveDataBindingTestWidget> {
  // Core Rive components
  File? file;
  RiveWidgetController? controller;
  
  // Data binding components
  ViewModelInstance? viewModelInstance;
  ViewModelInstanceNumber? posXProperty;
  ViewModelInstanceNumber? posYProperty;
  
  // UI state
  double posX = 0.0;
  double posY = 0.0;

  @override
  void initState() {
    super.initState();
    _initRive();
  }

  /// Initialize Rive file and set up data binding
  Future<void> _initRive() async {
    // Step 1: Load the Rive file
    file = await File.asset(
      'assets/animations/test-spere.riv',
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
      // Access number properties from the view model
      // These correspond to properties defined in the Rive file
      posXProperty = viewModelInstance!.number('posx');
      posYProperty = viewModelInstance!.number('posy');
      
      // Set initial UI values from Rive properties
      if (posXProperty != null) posX = posXProperty!.value;
      if (posYProperty != null) posY = posYProperty!.value;
    }
  }

  /// Update Rive animation properties when slider values change
  void _updatePosition() {
    if (posXProperty != null && posYProperty != null) {
      // Set new values on the data binding properties
      posXProperty!.value = posX;
      posYProperty!.value = posY;
      
      // Data binding automatically updates the animation - no manual advancement needed
    }
  }

  @override
  void dispose() {
    // Dispose of all resources in reverse order of creation
    posXProperty?.dispose();
    posYProperty?.dispose();
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
                // X Position Slider
                Text(
                  'Position X: ${posX.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Slider(
                  value: posX,
                  min: 0,
                  max: 500,
                  activeColor: Colors.blue,
                  inactiveColor: Colors.blue.withValues(alpha: 0.3),
                  onChanged: (value) {
                    setState(() => posX = value);
                    _updatePosition();
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Y Position Slider
                Text(
                  'Position Y: ${posY.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Slider(
                  value: posY,
                  min: 0,
                  max: 500,
                  activeColor: Colors.red,
                  inactiveColor: Colors.red.withValues(alpha: 0.3),
                  onChanged: (value) {
                    setState(() => posY = value);
                    _updatePosition();
                  },
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
