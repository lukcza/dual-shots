import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/lifecycle_manager.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/camera_types.dart';
import '../../domain/entities/dual_shot_result.dart';
import '../../domain/entities/pip_layout_config.dart';
import '../../domain/repositories/dual_camera_repository.dart';
import '../bloc/dual_camera_bloc.dart';
import '../bloc/dual_camera_event.dart';
import '../bloc/dual_camera_state.dart';
import '../widgets/camera_overlay_controls.dart';
import '../widgets/dual_camera_preview_viewport.dart';
import '../widgets/dual_camera_tutorial_helper.dart';
import '../widgets/privacy_policy_sheet.dart';
import '../widgets/shutter_button.dart';
import 'dual_shot_result_preview_screen.dart';

class DualCameraScreen extends StatefulWidget {
  const DualCameraScreen({super.key});

  @override
  State<DualCameraScreen> createState() => _DualCameraScreenState();
}

class _DualCameraScreenState extends State<DualCameraScreen>
    implements AppLifecycleListenerDelegate {
  late final DualCameraBloc _cameraBloc;
  late final AppLifecycleManager _lifecycleManager;
  final IDualCameraRepository _cameraRepository = sl<IDualCameraRepository>();

  // GlobalKeys for Interactive Coachmark Tutorial Bubbles
  final GlobalKey _keyFlash = GlobalKey();
  final GlobalKey _keyHelp = GlobalKey();
  final GlobalKey _keyPiP = GlobalKey();
  final GlobalKey _keyShutter = GlobalKey();
  final GlobalKey _keyFlip = GlobalKey();
  final GlobalKey _keyGallery = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cameraBloc = sl<DualCameraBloc>();
    _lifecycleManager = sl<AppLifecycleManager>();
    _lifecycleManager.addDelegate(this);

    // Trigger initial permission check & camera initialization
    _cameraBloc.add(const RequestPermissionsAndInitEvent());
  }

  @override
  void dispose() {
    _lifecycleManager.removeDelegate(this);
    super.dispose();
  }

  @override
  void onAppPaused() {
    _cameraBloc.add(const AppPausedEvent());
  }

  @override
  void onAppResumed() {
    _cameraBloc.add(const AppResumedEvent());
  }

  @override
  void onAppInactive() {}

  void _showInfoMenu() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14141C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Help & Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Option 1: App Tutorial
                _buildInfoOptionTile(
                  icon: Icons.school_rounded,
                  iconColor: const Color(0xFFFFB800),
                  title: 'Interactive Tutorial',
                  subtitle: 'Learn how to drag, resize, and capture Dual Shots',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Future.delayed(const Duration(milliseconds: 250), () {
                      if (mounted) _showTutorialCoachMark();
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Option 2: Privacy Policy
                _buildInfoOptionTile(
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFF00E676),
                  title: 'Privacy Policy',
                  subtitle: '100% on-device processing • Zero data tracking',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Future.delayed(const Duration(milliseconds: 250), () {
                      if (mounted) PrivacyPolicySheet.show(context);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  void _showTutorialCoachMark() {
    HapticFeedback.mediumImpact();
    final tutorial = DualCameraTutorialHelper.createTutorial(
      context: context,
      flashKey: _keyFlash,
      helpKey: _keyHelp,
      pipKey: _keyPiP,
      shutterKey: _keyShutter,
      flipKey: _keyFlip,
      galleryKey: _keyGallery,
    );
    tutorial.show(context: context);
  }

  Future<void> _openSystemGallery() async {
    HapticFeedback.lightImpact();
    const channel = MethodChannel('com.example.dual_shots/native_dual_camera');
    try {
      await channel.invokeMethod('openGallery');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening photo gallery...'),
          backgroundColor: Color(0xFF1E222A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return BlocProvider.value(
      value: _cameraBloc,
      child: BlocConsumer<DualCameraBloc, DualCameraState>(
        listener: (context, state) {
          if (state.status == DualCameraStatus.capturedSuccess &&
              state.lastResult != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DualShotResultPreviewScreen(
                  result: state.lastResult!,
                  onRetake: () {
                    _cameraBloc.add(const ResetToCameraReadyEvent());
                  },
                ),
              ),
            );
          } else if (state.status == DualCameraStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: const Color(0xFFFF5252),
              ),
            );
          }
        },
        builder: (context, state) {
          // 1. Permission Denied View
          if (state.status == DualCameraStatus.permissionDenied) {
            return _buildPermissionDeniedView(context, state);
          }

          // 2. Main Live Viewport
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Dual Viewport (Main Camera Preview + Draggable PiP)
                DualCameraPreviewViewport(
                  pipKey: _keyPiP,
                  primaryPreviewWidget:
                      _cameraRepository.getPrimaryPreviewWidget(),
                  secondaryPreviewWidget:
                      _cameraRepository.getSecondaryPreviewWidget(),
                  primaryLens: state.primaryLens,
                  secondaryLens: state.secondaryLens,
                  operatingMode: state.operatingMode,
                  layoutConfig: state.pipLayoutConfig,
                  onLayoutChanged: (newConfig) {
                    _cameraBloc.add(UpdatePiPLayoutEvent(newConfig));
                  },
                  onFlipPressed: () {
                    _cameraBloc.add(const SwitchCameraRolesEvent());
                  },
                ),

                // 2. Top Controls Overlay (Flash, Help ?)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: CameraOverlayControls(
                    flashKey: _keyFlash,
                    helpKey: _keyHelp,
                    operatingMode: state.operatingMode,
                    flashMode: state.flashMode,
                    primaryLens: state.primaryLens,
                    onToggleFlash: () {
                      _cameraBloc.add(const ToggleFlashModeEvent());
                      final nextMode = switch (state.flashMode) {
                        DualCameraFlashMode.off => DualCameraFlashMode.auto,
                        DualCameraFlashMode.auto => DualCameraFlashMode.on,
                        DualCameraFlashMode.on => DualCameraFlashMode.torch,
                        DualCameraFlashMode.torch => DualCameraFlashMode.off,
                      };
                      _cameraRepository.setFlashMode(nextMode);
                    },
                    onSwitchRoles: () {
                      _cameraBloc.add(const SwitchCameraRolesEvent());
                    },
                    onInfoPressed: _showInfoMenu,
                  ),
                ),

                // 3. Bottom Camera Controls (Gallery, Shutter Button, Flip Camera)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 38),
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
                        // Left utility icon: System Photo Gallery Button
                        GestureDetector(
                          key: _keyGallery,
                          onTap: _openSystemGallery,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1E1E28).withOpacity(0.85),
                              border: Border.all(
                                  color: Colors.white30, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.photo_library_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        // Center: Animated Shutter Button with stitching progress
                        ShutterButton(
                          key: _keyShutter,
                          isProcessing: state.isProcessing,
                          isReady: state.isReady,
                          onTap: () {
                            _cameraBloc.add(
                              TakeDualShotEvent(screenSize: screenSize),
                            );
                          },
                        ),

                        // Right: Switch Primary Camera Role Button
                        GestureDetector(
                          key: _keyFlip,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _cameraBloc.add(const SwitchCameraRolesEvent());
                          },
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1E1E28).withOpacity(0.85),
                              border: Border.all(
                                  color: Colors.white30, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.flip_camera_ios_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Processing HUD Overlay
                if (state.isProcessing)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181820).withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFFB800).withOpacity(0.5),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFFFFB800),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                state.isCapturing
                                    ? 'Capturing frames...'
                                    : 'Stitching in background (Isolate)...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionDeniedView(
      BuildContext context, DualCameraState state) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.no_photography_rounded,
                  color: Color(0xFFFF5252),
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Camera Access Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ??
                    'DualShots requires camera and microphone permissions to capture dual sensor shots.',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () {
                  if (state.isPermissionPermanentlyDenied) {
                    _cameraBloc.add(const OpenAppSettingsEvent());
                  } else {
                    _cameraBloc.add(const RequestPermissionsAndInitEvent());
                  }
                },
                icon: const Icon(Icons.security_rounded),
                label: Text(state.isPermissionPermanentlyDenied
                    ? 'Open Settings'
                    : 'Grant Permissions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB800),
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
