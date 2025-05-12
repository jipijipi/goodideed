import 'package:flutter/material.dart';
import 'package:tristopher_app/constants/app_constants.dart';

/// A custom scaffold with paper texture background that scrolls with content
class PaperBackgroundScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final ScrollController? scrollController;
  final Widget? drawer; // Add drawer parameter

  const PaperBackgroundScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.scrollController,
    this.drawer, // Add to constructor
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      // The key change: we wrap the body in our custom scrolling background
      body: _ScrollingPaperBackground(
        controller: scrollController,
        backgroundColor: AppColors.backgroundColor,
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer, // Pass drawer to Scaffold
    );
  }
}

/// A simple widget that provides a paper texture background that scrolls perfectly with content
class _ScrollingPaperBackground extends StatefulWidget {
  final ScrollController? controller;
  final Color backgroundColor;
  final Widget child;

  const _ScrollingPaperBackground({
    this.controller,
    required this.backgroundColor,
    required this.child,
  });

  @override
  State<_ScrollingPaperBackground> createState() => _ScrollingPaperBackgroundState();
}

class _ScrollingPaperBackgroundState extends State<_ScrollingPaperBackground> {
  late ScrollController _effectiveController;
  double _scrollOffset = 0.0;
  
  @override
  void initState() {
    super.initState();
    _effectiveController = widget.controller ?? ScrollController();
    _effectiveController.addListener(_handleScroll);
  }
  
  @override
  void didUpdateWidget(_ScrollingPaperBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _effectiveController.removeListener(_handleScroll);
      _effectiveController = widget.controller ?? ScrollController();
      _effectiveController.addListener(_handleScroll);
    }
  }
  
  @override
  void dispose() {
    _effectiveController.removeListener(_handleScroll);
    // Only dispose if we created it
    if (widget.controller == null) {
      _effectiveController.dispose();
    }
    super.dispose();
  }
  
  void _handleScroll() {
    if (mounted) {
      setState(() {
        _scrollOffset = _effectiveController.offset;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background layer with texture
        Positioned.fill(
          child: _BackgroundLayer(
            scrollOffset: _scrollOffset,
            backgroundColor: widget.backgroundColor,
          ),
        ),
        
        // Content layer
        widget.child,
      ],
    );
  }
}

/// A simple stateless widget that renders the background with the correct offset
class _BackgroundLayer extends StatelessWidget {
  final double scrollOffset;
  final Color backgroundColor;

  const _BackgroundLayer({
    required this.scrollOffset,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate the effective offset for perfect repeating
    // We use modulo to ensure proper tiling no matter how far we scroll
    final textureHeight = 2048.0; // Adjust this value based on your actual texture height
    final offsetY = -(scrollOffset % textureHeight);
    
    return IgnorePointer(
      child: Container(
        color: backgroundColor,
        child: Stack(
          children: [
            // Primary texture positioned at the calculated offset
            Positioned(
              left: 0,
              right: 0,
              top: offsetY, 
              height: textureHeight,
              child: RepaintBoundary(
                child: Image.asset(
                  'assets/images/paper_texture.jpg',
                  fit: BoxFit.cover,
                  repeat: ImageRepeat.repeatX,
                  opacity: const AlwaysStoppedAnimation<double>(0.7),
                ),
              ),
            ),
            
            // Secondary texture positioned to continue seamlessly after primary
            Positioned(
              left: 0,
              right: 0,
              top: offsetY + textureHeight,
              height: textureHeight,
              child: RepaintBoundary(
                child: Image.asset(
                  'assets/images/paper_texture.jpg',
                  fit: BoxFit.cover,
                  repeat: ImageRepeat.repeatX,
                  opacity: const AlwaysStoppedAnimation<double>(0.7),
                ),
              ),
            ),
            
            // Add a third copy for extra safety during fast scrolling
            Positioned(
              left: 0,
              right: 0,
              top: offsetY - textureHeight,
              height: textureHeight,
              child: RepaintBoundary(
                child: Image.asset(
                  'assets/images/paper_texture.jpg',
                  fit: BoxFit.cover,
                  repeat: ImageRepeat.repeatX,
                  opacity: const AlwaysStoppedAnimation<double>(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
