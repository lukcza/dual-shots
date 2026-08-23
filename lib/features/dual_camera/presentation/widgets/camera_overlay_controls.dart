import 'package:flutter/material.dart';
import '../../domain/entities/camera_types.dart';

class CameraOverlayControls extends StatelessWidget {
  final DualCameraOperatingMode operatingMode;
  final DualCameraFlashMode flashMode;
  final CameraLens primaryLens;
  final VoidCallback onToggleFlash;
  final VoidCallback onSwitchRoles;
  final VoidCallback onInfoPressed;
  final GlobalKey? flashKey;
  final GlobalKey? helpKey;

  const CameraOverlayControls({
    super.key,
    required this.operatingMode,
    required this.flashMode,
    required this.primaryLens,
    required this.onToggleFlash,
    required this.onSwitchRoles,
    required this.onInfoPressed,
    this.flashKey,
    this.helpKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top status and controls bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flash button
                _buildCircleIconButton(
                  key: flashKey,
                  icon: _getFlashIcon(flashMode),
                  color: flashMode != DualCameraFlashMode.off
                      ? const Color(0xFFFFB800)
                      : Colors.white,
                  onTap: onToggleFlash,
                ),

                // Tutorial / Help button
                _buildCircleIconButton(
                  key: helpKey,
                  icon: Icons.help_outline_rounded,
                  color: Colors.white,
                  onTap: onInfoPressed,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleIconButton({
    Key? key,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  IconData _getFlashIcon(DualCameraFlashMode mode) {
    switch (mode) {
      case DualCameraFlashMode.off:
        return Icons.flash_off_rounded;
      case DualCameraFlashMode.auto:
        return Icons.flash_auto_rounded;
      case DualCameraFlashMode.on:
        return Icons.flash_on_rounded;
      case DualCameraFlashMode.torch:
        return Icons.highlight_rounded;
    }
  }
}
