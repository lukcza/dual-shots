import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/camera_types.dart';
import '../../domain/entities/dual_shot_result.dart';
import '../../domain/entities/pip_layout_config.dart';
import '../widgets/draggable_pip_view.dart';
import 'dual_shot_result_preview_screen.dart';

/// Demo version of the camera screen using static images.
/// Used for taking promotional screenshots without a real camera.
class DemoCameraScreen extends StatefulWidget {
  const DemoCameraScreen({super.key});

  @override
  State<DemoCameraScreen> createState() => _DemoCameraScreenState();
}

class _DemoCameraScreenState extends State<DemoCameraScreen> {
  PiPLayoutConfig _layout = const PiPLayoutConfig(
    normalizedX: 0.62,
    normalizedY: 0.55,
    widthRatio: 0.32,
    aspectRatio: 3.0 / 4.0,
    borderRadius: 18,
    borderWidth: 3,
    isMirrored: false,
  );

  bool _isCapturing = false;

  Future<String> _assetToTempFile(String assetPath, String filename) async {
    final bytes = await rootBundle.load(assetPath);
    final temp = await getTemporaryDirectory();
    final file = File(p.join(temp.path, filename));
    await file.writeAsBytes(bytes.buffer.asUint8List());
    return file.path;
  }

  Future<void> _simulateCapture() async {
    HapticFeedback.heavyImpact();
    setState(() => _isCapturing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isCapturing = false);

    final stitchedPath =
        await _assetToTempFile('assets/demo/demo_shot_1.jpg', 'demo_stitched.jpg');
    final primaryPath =
        await _assetToTempFile('assets/demo/demo_shot_2.jpg', 'demo_primary.jpg');

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DualShotResultPreviewScreen(
          result: DualShotResult(
            id: 'demo',
            primaryImagePath: primaryPath,
            secondaryImagePath: primaryPath,
            stitchedImagePath: stitchedPath,
            timestamp: DateTime.now(),
            operatingMode: DualCameraOperatingMode.concurrentMultiCamera,
            primaryLens: CameraLens.back,
            secondaryLens: CameraLens.front,
            layoutConfig: _layout,
            stitchedWidth: 896,
            stitchedHeight: 1152,
          ),
          onRetake: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Rear camera static demo image
          Positioned.fill(
            child: Image.asset(
              'assets/demo/demo_camera_back.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Draggable PiP with selfie demo image
          DraggablePiPView(
            previewWidget: Image.asset(
              'assets/demo/demo_camera_front.jpg',
              fit: BoxFit.cover,
            ),
            layoutConfig: _layout,
            secondaryLens: CameraLens.front,
            operatingMode: DualCameraOperatingMode.concurrentMultiCamera,
            screenSize: screenSize,
            onLayoutChanged: (cfg) => setState(() => _layout = cfg),
            onFlipPressed: () {},
          ),

          // 3. Top bar (matches real app)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleIcon(
                      Icons.flash_off_rounded,
                      Colors.white,
                      () {},
                    ),
                    // Mode badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFFFB800).withOpacity(0.6)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_enhance_rounded,
                              color: Color(0xFFFFB800), size: 12),
                          SizedBox(width: 4),
                          Text(
                            'DUAL CAM',
                            style: TextStyle(
                              color: Color(0xFFFFB800),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _circleIcon(
                      Icons.help_outline_rounded,
                      Colors.white,
                      () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Bottom controls (matches real app)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  28, 20, 28, MediaQuery.of(context).padding.bottom + 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Gallery icon
                  _circleIcon(Icons.photo_library_outlined, Colors.white, () {}),

                  // Shutter button
                  GestureDetector(
                    onTap: _simulateCapture,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: _isCapturing ? 72 : 80,
                      height: _isCapturing ? 72 : 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCapturing
                            ? const Color(0xFFFFB800)
                            : Colors.transparent,
                        border: Border.all(
                          color: const Color(0xFFFFB800),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFB800)
                                .withOpacity(_isCapturing ? 0.6 : 0.3),
                            blurRadius: _isCapturing ? 24 : 12,
                            spreadRadius: _isCapturing ? 4 : 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Flip camera icon
                  _circleIcon(
                      Icons.flip_camera_ios_rounded, Colors.white, () {}),
                ],
              ),
            ),
          ),

          // 5. Capture flash overlay
          if (_isCapturing)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _isCapturing ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 100),
                child: Container(color: Colors.white.withOpacity(0.3)),
              ),
            ),

          // 6. Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white70, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E1E28).withOpacity(0.8),
          border: Border.all(color: Colors.white24, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}
