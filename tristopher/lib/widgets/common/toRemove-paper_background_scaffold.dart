import 'package:flutter/material.dart';
import 'package:tristopher_app/constants/app_constants.dart';

/// A custom scaffold with paper texture background that scrolls with content
class PaperBackgroundScaffold extends StatefulWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final ScrollController? scrollController;

  const PaperBackgroundScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.scrollController,
  });

  @override
  State<PaperBackgroundScaffold> createState() => _PaperBackgroundScaffoldState();
}

class _PaperBackgroundScaffoldState extends State<PaperBackgroundScaffold> {
  ScrollController? _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    
    // Listen to scroll changes
    _scrollController?.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController?.offset ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    // Only dispose if we created the controller
    if (widget.scrollController == null) {
      _scrollController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      body: Container(
        color: AppColors.backgroundColor,
        child: Stack(
          children: [
            // Paper texture background that scrolls with content
            AnimatedBuilder(
              animation: _scrollController ?? ScrollController(),
              builder: (context, child) {
                return Container(
                  // Set a large fixed height to ensure it covers the entire scrollable area
                  height: 10000, // Large enough to cover any reasonable scroll area
                  decoration: BoxDecoration(
                    // Using a repeating image as a pattern in the decoration
                    image: DecorationImage(
                      image: const AssetImage('assets/images/paper_texture.png'),
                      repeat: ImageRepeat.repeat,
                      fit: BoxFit.none,
                      // Position the background based on scroll offset - exact 1:1 ratio
                      alignment: Alignment(0, (_scrollOffset / 1000.0) % 1.0),
                      opacity: 0.7,
                    ),
                  ),
                );
              },
            ),
            
            // Actual content
            widget.body,
          ],
        ),
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}
