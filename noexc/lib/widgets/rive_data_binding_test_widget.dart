import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveDataBindingTestWidget extends StatefulWidget {
  const RiveDataBindingTestWidget({super.key});

  @override
  State<RiveDataBindingTestWidget> createState() => _RiveDataBindingTestWidgetState();
}

class _RiveDataBindingTestWidgetState extends State<RiveDataBindingTestWidget> {
  File? file;
  RiveWidgetController? controller;
  ViewModelInstance? viewModelInstance;
  ViewModelInstanceNumber? posXProperty;
  ViewModelInstanceNumber? posYProperty;
  
  double posX = 0.0;
  double posY = 0.0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    file = await File.asset(
      'assets/animations/test-spere.riv',
      riveFactory: Factory.rive,
    );
    controller = RiveWidgetController(file!);
    _initViewModel();
    setState(() {});
  }

  void _initViewModel() {
    try {
      print('Initializing view model...');
      
      // Use DataBind.auto() like the Rive example
      viewModelInstance = controller!.dataBind(DataBind.auto());
      print('View model instance: $viewModelInstance');
      
      if (viewModelInstance != null) {
        // Get references to the position properties
        posXProperty = viewModelInstance!.number('posx');
        posYProperty = viewModelInstance!.number('posy');
        print('Got properties - posX: $posXProperty, posY: $posYProperty');
        
        // Set initial values
        if (posXProperty != null) {
          posX = posXProperty!.value;
          print('Initial posX: $posX');
        }
        if (posYProperty != null) {
          posY = posYProperty!.value;
          print('Initial posY: $posY');
        }
      } else {
        print('No view model instance created');
      }
    } catch (e) {
      print('Error in view model setup: $e');
    }
  }

  void _updatePosition() {
    if (posXProperty != null && posYProperty != null) {
      print('Updating position - posX: $posX, posY: $posY');
      print('Before update - Property posX: ${posXProperty!.value}, Property posY: ${posYProperty!.value}');
      
      posXProperty!.value = posX;
      posYProperty!.value = posY;
      
      print('After setting - Property posX: ${posXProperty!.value}, Property posY: ${posYProperty!.value}');
      
      // Data binding should handle updates automatically, no manual advancement needed
      print('Properties updated - data binding should handle the rest');
    } else {
      print('Properties are null - posX: $posXProperty, posY: $posYProperty');
    }
  }

  @override
  void dispose() {
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
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: controller == null
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : RiveWidget(
                    controller: controller,
                    fit: Fit.contain,
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Position X: ${posX.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Slider(
                  value: posX,
                  min: -200,
                  max: 200,
                  activeColor: Colors.blue,
                  inactiveColor: Colors.blue.withOpacity(0.3),
                  onChanged: (value) {
                    print('Slider X changed to: $value');
                    setState(() {
                      posX = value;
                    });
                    _updatePosition();
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Position Y: ${posY.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Slider(
                  value: posY,
                  min: -200,
                  max: 200,
                  activeColor: Colors.red,
                  inactiveColor: Colors.red.withOpacity(0.3),
                  onChanged: (value) {
                    print('Slider Y changed to: $value');
                    setState(() {
                      posY = value;
                    });
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