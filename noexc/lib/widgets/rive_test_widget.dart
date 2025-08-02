/* import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveTestWidget extends StatefulWidget {
  const RiveTestWidget({super.key});

  @override
  State<RiveTestWidget> createState() => _RiveTestWidgetState();
}

class _RiveTestWidgetState extends State<RiveTestWidget> {
  Artboard? _riveArtboard;
  StateMachineController? _controller;
  bool _isPlaying = true;
  
  @override
  void initState() {
    super.initState();
    _loadRiveFile();
  }

  void _loadRiveFile() async {
    final file = await RiveFile.asset('assets/animations/arm_test_2.riv');
    final artboard = file.mainArtboard;
    
    var controller = StateMachineController.fromArtboard(artboard, 'State Machine 1');
    if (controller != null) {
      artboard.addController(controller);
      _controller = controller;
    }
    
    setState(() => _riveArtboard = artboard);
  }

  void _togglePlayback() {
    if (_controller != null) {
      setState(() {
        _isPlaying = !_isPlaying;
        _controller!.isActive = _isPlaying;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _riveArtboard == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Rive(
                  artboard: _riveArtboard!,
                  fit: BoxFit.contain,
                ),
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      onPressed: _togglePlayback,
                      backgroundColor: Colors.white.withOpacity(0.8),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
} */