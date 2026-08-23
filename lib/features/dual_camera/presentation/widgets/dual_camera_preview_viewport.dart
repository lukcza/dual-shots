import 'package:flutter/material.dart';
import '../../domain/entities/camera_types.dart';
import '../../domain/entities/pip_layout_config.dart';
import 'draggable_pip_view.dart';

class DualCameraPreviewViewport extends StatelessWidget {
  final Widget? primaryPreviewWidget;
  final Widget? secondaryPreviewWidget;
  final CameraLens primaryLens;
  final CameraLens secondaryLens;
  final DualCameraOperatingMode operatingMode;
  final PiPLayoutConfig layoutConfig;
  final ValueChanged<PiPLayoutConfig> onLayoutChanged;
  final VoidCallback onFlipPressed;
  final GlobalKey? pipKey;

  const DualCameraPreviewViewport({
    super.key,
    required this.primaryPreviewWidget,
    required this.secondaryPreviewWidget,
    required this.primaryLens,
    required this.secondaryLens,
    required this.operatingMode,
    required this.layoutConfig,
    required this.onLayoutChanged,
    required this.onFlipPressed,
    this.pipKey,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Primary Fullscreen Viewport
        if (primaryPreviewWidget != null)
          Positioned.fill(
            child: ClipRect(
              child: Transform.flip(
                flipX: primaryLens == CameraLens.front,
                child: primaryPreviewWidget!,
              ),
            ),
          )
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFB800),
              ),
            ),
          ),

        // 2. Secondary Draggable PiP Overlay
        DraggablePiPView(
          key: pipKey,
          previewWidget: secondaryPreviewWidget,
          layoutConfig: layoutConfig,
          secondaryLens: secondaryLens,
          operatingMode: operatingMode,
          screenSize: screenSize,
          onLayoutChanged: onLayoutChanged,
          onFlipPressed: onFlipPressed,
        ),
      ],
    );
  }
}
