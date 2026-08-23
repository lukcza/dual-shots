import 'package:equatable/equatable.dart';
import '../../domain/entities/camera_types.dart';
import '../../domain/entities/dual_shot_result.dart';
import '../../domain/entities/pip_layout_config.dart';

enum DualCameraStatus {
  initial,
  checkingPermissions,
  permissionDenied,
  initializing,
  ready,
  capturing,
  stitching,
  capturedSuccess,
  error,
}

class DualCameraState extends Equatable {
  final DualCameraStatus status;
  final DualCameraOperatingMode operatingMode;
  final CameraLens primaryLens;
  final CameraLens secondaryLens;
  final DualCameraFlashMode flashMode;
  final PiPLayoutConfig pipLayoutConfig;
  final DualShotResult? lastResult;
  final String? errorMessage;
  final bool isPermissionPermanentlyDenied;

  const DualCameraState({
    this.status = DualCameraStatus.initial,
    this.operatingMode = DualCameraOperatingMode.pseudoDualFallback,
    this.primaryLens = CameraLens.back,
    this.secondaryLens = CameraLens.front,
    this.flashMode = DualCameraFlashMode.off,
    this.pipLayoutConfig = const PiPLayoutConfig(),
    this.lastResult,
    this.errorMessage,
    this.isPermissionPermanentlyDenied = false,
  });

  bool get isReady => status == DualCameraStatus.ready;
  bool get isCapturing => status == DualCameraStatus.capturing;
  bool get isStitching => status == DualCameraStatus.stitching;
  bool get isProcessing => isCapturing || isStitching;

  DualCameraState copyWith({
    DualCameraStatus? status,
    DualCameraOperatingMode? operatingMode,
    CameraLens? primaryLens,
    CameraLens? secondaryLens,
    DualCameraFlashMode? flashMode,
    PiPLayoutConfig? pipLayoutConfig,
    DualShotResult? lastResult,
    String? errorMessage,
    bool? isPermissionPermanentlyDenied,
  }) {
    return DualCameraState(
      status: status ?? this.status,
      operatingMode: operatingMode ?? this.operatingMode,
      primaryLens: primaryLens ?? this.primaryLens,
      secondaryLens: secondaryLens ?? this.secondaryLens,
      flashMode: flashMode ?? this.flashMode,
      pipLayoutConfig: pipLayoutConfig ?? this.pipLayoutConfig,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: errorMessage,
      isPermissionPermanentlyDenied:
          isPermissionPermanentlyDenied ?? this.isPermissionPermanentlyDenied,
    );
  }

  @override
  List<Object?> get props => [
        status,
        operatingMode,
        primaryLens,
        secondaryLens,
        flashMode,
        pipLayoutConfig,
        lastResult,
        errorMessage,
        isPermissionPermanentlyDenied,
      ];
}
