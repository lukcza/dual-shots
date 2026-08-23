import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/camera_types.dart';
import '../../domain/entities/dual_shot_result.dart';

class DualShotResultPreviewScreen extends StatefulWidget {
  final DualShotResult result;
  final VoidCallback onRetake;

  const DualShotResultPreviewScreen({
    super.key,
    required this.result,
    required this.onRetake,
  });

  @override
  State<DualShotResultPreviewScreen> createState() =>
      _DualShotResultPreviewScreenState();
}

class _DualShotResultPreviewScreenState
    extends State<DualShotResultPreviewScreen> {
  int _selectedViewIndex = 0; // 0: Stitched, 1: Primary, 2: Secondary
  bool _isSaving = false;
  bool _isSharing = false;
  String? _savedLocation;

  @override
  Widget build(BuildContext context) {
    final activeImagePath = switch (_selectedViewIndex) {
      0 => widget.result.stitchedImagePath,
      1 => widget.result.primaryImagePath,
      2 => widget.result.secondaryImagePath,
      _ => widget.result.stitchedImagePath,
    };

    final isConcurrent = widget.result.operatingMode ==
        DualCameraOperatingMode.concurrentMultiCamera;
    final dateFormatted =
        DateFormat('dd.MM.yyyy, HH:mm:ss').format(widget.result.timestamp);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Interactive High-Res Photo Display with Zoom & Double-Tap
          GestureDetector(
            onDoubleTap: () {},
            child: InteractiveViewer(
              minScale: 0.9,
              maxScale: 4.5,
              clipBehavior: Clip.none,
              child: Center(
                child: Hero(
                  tag: 'dual_shot_result_${widget.result.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Image.file(
                        File(activeImagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Premium Top Bar with Blur, Mode Badge & Back Button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 8,
                16,
                16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Back / Retake Icon
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onRetake();
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E28).withOpacity(0.8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title
                  const Expanded(
                    child: Text(
                      'DUAL SHOT RESULT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  // Info details button
                  InkWell(
                    onTap: () => _showPhotoInfoModal(context, dateFormatted),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E28).withOpacity(0.8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Modern Floating Bottom Control Deck
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                18,
                20,
                18,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF0A0A0E).withOpacity(0.98),
                    const Color(0xFF0A0A0E).withOpacity(0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Segmented Switcher for Perspectives (Responsive 3-column layout)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181822),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        _buildSegmentTab(
                          0,
                          'Dual PiP',
                          Icons.auto_awesome_rounded,
                        ),
                        _buildSegmentTab(
                          1,
                          'Rear Cam',
                          Icons.camera_alt_rounded,
                        ),
                        _buildSegmentTab(
                          2,
                          'Selfie',
                          Icons.face_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // File storage location preview
                  if (_savedLocation != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00E676).withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF00E676), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Saved: $_savedLocation',
                              style: const TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      // Retake IconButton
                      Tooltip(
                        message: 'Retake',
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onRetake();
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A24),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Save Photo Button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _savePhotoToGallery,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.download_done_rounded,
                                  color: Colors.black, size: 20),
                          label: Text(
                            _isSaving ? 'SAVING...' : 'SAVE PHOTO',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB800),
                            elevation: 8,
                            shadowColor:
                                const Color(0xFFFFB800).withOpacity(0.4),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Share IconButton (right of Save)
                      Tooltip(
                        message: 'Share',
                        child: InkWell(
                          onTap: (_isSharing || _isSaving)
                              ? null
                              : _sharePhoto,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF7B9FFF).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    const Color(0xFF7B9FFF).withOpacity(0.5),
                              ),
                            ),
                            child: _isSharing
                                ? const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF7B9FFF),
                                    ),
                                  )
                                : const Icon(
                                    Icons.share_rounded,
                                    color: Color(0xFF7B9FFF),
                                    size: 22,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentTab(int index, String label, IconData icon) {
    final isSelected = _selectedViewIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedViewIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFB800) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.black : Colors.white60,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sharePhoto() async {
    setState(() => _isSharing = true);
    HapticFeedback.lightImpact();

    final activeImagePath = switch (_selectedViewIndex) {
      0 => widget.result.stitchedImagePath,
      1 => widget.result.primaryImagePath,
      2 => widget.result.secondaryImagePath,
      _ => widget.result.stitchedImagePath,
    };

    try {
      final file = XFile(activeImagePath);
      await Share.shareXFiles([file]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF321A1A),
            content: Text('Share error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _savePhotoToGallery() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final activeImagePath = switch (_selectedViewIndex) {
      0 => widget.result.stitchedImagePath,
      1 => widget.result.primaryImagePath,
      2 => widget.result.secondaryImagePath,
      _ => widget.result.stitchedImagePath,
    };

    try {
      final sourceFile = File(activeImagePath);
      if (!sourceFile.existsSync()) {
        throw Exception('Source file does not exist');
      }

      // Save directly into Android MediaStore Gallery via native channel
      const channel =
          MethodChannel('com.example.dual_shots/native_dual_camera');
      final dynamic savedPath = await channel.invokeMethod('saveToGallery', {
        'path': activeImagePath,
      });

      setState(() {
        _isSaving = false;
        _savedLocation = (savedPath is String && savedPath.isNotEmpty)
            ? savedPath
            : 'Gallery -> Album DualShots';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E2A20),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF00E676), width: 1),
            ),
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Color(0xFF00E676), size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Photo saved to Gallery!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Check Gallery -> Album "DualShots"',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF321A1A),
            content: Text('Save error: $e'),
          ),
        );
      }
    }
  }

  void _showPhotoInfoModal(BuildContext context, String dateFormatted) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14141C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Shot Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Captured Date', dateFormatted),
              _buildInfoRow('Resolution',
                  '${widget.result.stitchedWidth} x ${widget.result.stitchedHeight} px'),
              _buildInfoRow(
                'Primary Camera',
                widget.result.primaryLens == CameraLens.back
                    ? 'Rear (Main)'
                    : 'Front (Selfie)',
              ),
              _buildInfoRow(
                'Secondary Camera',
                widget.result.secondaryLens == CameraLens.front
                    ? 'Front (Selfie)'
                    : 'Rear (Main)',
              ),
              _buildInfoRow(
                'Capture Mode',
                widget.result.operatingMode ==
                        DualCameraOperatingMode.concurrentMultiCamera
                    ? 'Native Dual-Stream'
                    : 'Pseudo-Dual Fallback',
              ),
              _buildInfoRow(
                'File Path',
                widget.result.stitchedImagePath,
                isSmall: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isSmall = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isSmall ? 10 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
