import 'package:flutter/material.dart';
import '../../domain/entities/camera_types.dart';
import '../../domain/entities/pip_layout_config.dart';

class DraggablePiPView extends StatefulWidget {
  final Widget? previewWidget;
  final PiPLayoutConfig layoutConfig;
  final CameraLens secondaryLens;
  final DualCameraOperatingMode operatingMode;
  final Size screenSize;
  final ValueChanged<PiPLayoutConfig> onLayoutChanged;
  final VoidCallback onFlipPressed;

  const DraggablePiPView({
    super.key,
    required this.previewWidget,
    required this.layoutConfig,
    required this.secondaryLens,
    required this.operatingMode,
    required this.screenSize,
    required this.onLayoutChanged,
    required this.onFlipPressed,
  });

  @override
  State<DraggablePiPView> createState() => _DraggablePiPViewState();
}

class _DraggablePiPViewState extends State<DraggablePiPView> {
  late double _normalizedX;
  late double _normalizedY;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _normalizedX = widget.layoutConfig.normalizedX;
    _normalizedY = widget.layoutConfig.normalizedY;
  }

  @override
  void didUpdateWidget(covariant DraggablePiPView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layoutConfig != widget.layoutConfig && !_isDragging) {
      _normalizedX = widget.layoutConfig.normalizedX;
      _normalizedY = widget.layoutConfig.normalizedY;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = widget.screenSize.width;
    final screenH = widget.screenSize.height;

    final pipW = screenW * widget.layoutConfig.widthRatio;
    final pipH = pipW / widget.layoutConfig.aspectRatio;

    final maxPosX = screenW - pipW - 16;
    final maxPosY = screenH - pipH - 120; // preserve bottom shutter area
    const minPosX = 16.0;
    const minPosY = 64.0; // preserve top status bar area

    final actualX = (_normalizedX * (screenW - pipW)).clamp(minPosX, maxPosX);
    final actualY = (_normalizedY * (screenH - pipH)).clamp(minPosY, maxPosY);

    return Positioned(
      left: actualX,
      top: actualY,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (details) {
          final newX = (actualX + details.delta.dx).clamp(minPosX, maxPosX);
          final newY = (actualY + details.delta.dy).clamp(minPosY, maxPosY);

          setState(() {
            _normalizedX = (newX / (screenW - pipW)).clamp(0.0, 1.0);
            _normalizedY = (newY / (screenH - pipH)).clamp(0.0, 1.0);
          });
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          _snapToNearestCorner(screenW, screenH, pipW, pipH, minPosX, maxPosX, minPosY, maxPosY);
        },
        child: AnimatedScale(
          scale: _isDragging ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: pipW,
            height: pipH,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(widget.layoutConfig.borderRadius),
              border: Border.all(
                color: Colors.white,
                width: widget.layoutConfig.borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isDragging ? 0.6 : 0.35),
                  blurRadius: _isDragging ? 18 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                widget.layoutConfig.borderRadius - widget.layoutConfig.borderWidth,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Secondary Camera Stream or Pseudo-Dual Fallback Indicator
                  if (widget.previewWidget != null)
                    Transform.flip(
                      flipX: widget.secondaryLens == CameraLens.front,
                      child: ClipRect(
                        child: widget.previewWidget!,
                      ),
                    )
                  else
                    _buildFallbackPipPlaceholder(),

                  // Lens Type & Flip Overlay Button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: widget.onFlipPressed,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white38, width: 1),
                        ),
                        child: const Icon(
                          Icons.flip_camera_ios_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),

                  // Lens label tag
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.secondaryLens == CameraLens.front ? 'FRONT' : 'BACK',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackPipPlaceholder() {
    final isFront = widget.secondaryLens == CameraLens.front;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onFlipPressed,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isFront
                  ? [
                      const Color(0xFF2A2A38),
                      const Color(0xFF161622),
                    ]
                  : [
                      const Color(0xFF1E2838),
                      const Color(0xFF101620),
                    ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(
                    color: const Color(0xFFFFB800).withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isFront ? Icons.face_rounded : Icons.camera_alt_rounded,
                  color: const Color(0xFFFFB800),
                  size: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isFront ? 'PRZÓD (SELFIE)' : 'TYŁ (GŁÓWNY)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      color: Colors.white70,
                      size: 9,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Dotknij by obrócić',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _snapToNearestCorner(
    double screenW,
    double screenH,
    double pipW,
    double pipH,
    double minX,
    double maxX,
    double minY,
    double maxY,
  ) {
    final currentCenterX = (_normalizedX * (screenW - pipW)) + (pipW / 2);
    final isLeft = currentCenterX < (screenW / 2);

    final targetX = isLeft ? minX : maxX;
    final normalizedTargetX = targetX / (screenW - pipW);

    final updated = widget.layoutConfig.copyWith(
      normalizedX: normalizedTargetX,
      normalizedY: _normalizedY,
    );

    widget.onLayoutChanged(updated);
  }
}
