import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveTestWidget extends StatefulWidget {
  const RiveTestWidget({super.key});

  @override
  State<RiveTestWidget> createState() => _RiveTestWidgetState();
}

class _RiveTestWidgetState extends State<RiveTestWidget> {
  Artboard? _riveArtboard;
  StateMachineController? _controller;
  
  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  void _loadRiveFile() async {
    final file = await RiveFile.asset('assets/animations/arm_test.riv');
    final artboard = file.mainArtboard;
    
    var controller = StateMachineController.fromArtboard(artboard, 'State Machine 1');
    if (controller != null) {
      artboard.addController(controller);
      _controller = controller;
    }
    
    setState(() => _riveArtboard = artboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rive Animation Test'),
        backgroundColor: Colors.blue,
      ),
      body: _riveArtboard == null
          ? const Center(child: CircularProgressIndicator())
          : Rive(
              artboard: _riveArtboard!,
              fit: BoxFit.contain,
            ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}