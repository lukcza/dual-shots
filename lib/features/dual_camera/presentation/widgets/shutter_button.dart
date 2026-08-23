import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShutterButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isProcessing;
  final bool isReady;

  const ShutterButton({
    super.key,
    required this.onTap,
    this.isProcessing = false,
    this.isReady = true,
  });

  @override
  State<ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<ShutterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerShutter() {
    if (widget.isReady && !widget.isProcessing) {
      HapticFeedback.mediumImpact();
      _animController.forward().then((_) => _animController.reverse());
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: _triggerShutter,
      radius: 44,
      highlightColor: Colors.transparent,
      splashColor: Colors.white24,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isProcessing
                            ? const Color(0xFFFFB800)
                            : Colors.white,
                        width: 4,
                      ),
                    ),
                  ),

                  // Progress ring when stitching
                  if (widget.isProcessing)
                    const SizedBox(
                      width: 82,
                      height: 82,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF00E5FF),
                        ),
                      ),
                    ),

                  // Inner Solid Shutter Circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: widget.isProcessing ? 38 : 68,
                    height: widget.isProcessing ? 38 : 68,
                    decoration: BoxDecoration(
                      color: widget.isProcessing
                          ? const Color(0xFFFFB800)
                          : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: widget.isProcessing
                        ? const Icon(
                            Icons.auto_awesome,
                            color: Colors.black,
                            size: 18,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
