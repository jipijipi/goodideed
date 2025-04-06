import 'package:flutter/material.dart';
import 'package:tristopher_app/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StakeDisplay extends ConsumerStatefulWidget {
  final double? stakeAmount;
  final bool showFailureAnimation;
  final VoidCallback? onAnimationComplete;

  const StakeDisplay({
    Key? key,
    required this.stakeAmount,
    this.showFailureAnimation = false,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  ConsumerState<StakeDisplay> createState() => _StakeDisplayState();
}

class _StakeDisplayState extends ConsumerState<StakeDisplay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fireOpacityAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 2),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _fireOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
    ));

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
        });
        if (widget.onAnimationComplete != null) {
          widget.onAnimationComplete!();
        }
      }
    });

    if (widget.showFailureAnimation) {
      _triggerAnimation();
    }
  }

  @override
  void didUpdateWidget(StakeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showFailureAnimation && !_isAnimating && !oldWidget.showFailureAnimation) {
      _triggerAnimation();
    }
  }

  void _triggerAnimation() {
    setState(() {
      _isAnimating = true;
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedStake = widget.stakeAmount == null
        ? '\$0'
        : '\$${widget.stakeAmount!.toStringAsFixed(2)}';

    return Stack(
      alignment: Alignment.center,
      children: [
        // Fire pit
        Positioned(
          bottom: 0,
          child: FadeTransition(
            opacity: _fireOpacityAnimation,
            child: Image.asset(
              'assets/images/fire.png', // You'd need to create/add this
              width: 60,
              height: 50,
              // Use a placeholder fire image or icon
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_fire_department,
                      color: Colors.yellow,
                      size: 30,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        // Stake amount
        SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: Colors.black.withOpacity(0.2),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.attach_money,
                    size: 18.0,
                    color: AppColors.accentColor,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    'Stake: $formattedStake',
                    style: AppTextStyles.userText(
                      weight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
