import 'package:flutter/widgets.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/camera_types.dart';
import '../entities/dual_shot_result.dart';
import '../entities/pip_layout_config.dart';

abstract class IDualCameraRepository {
  /// Checks whether device supports concurrent multi-camera hardware capture
  Future<Either<Failure, DualCameraOperatingMode>> checkMultiCameraSupport();

  /// Initializes camera sensors according to desired operating mode and primary lens
  Future<Either<Failure, DualCameraOperatingMode>> initializeCameras({
    required DualCameraOperatingMode preferredMode,
    required CameraLens primaryLens,
  });

  /// Captures both primary and secondary images according to active operating mode
  Future<Either<Failure, DualShotResult>> takeDualShot({
    required PiPLayoutConfig layoutConfig,
    required Size screenSize,
  });

  /// Inverts the role of lenses (e.g. Front becomes Primary, Back becomes PiP)
  Future<Either<Failure, void>> switchCameraRoles();

  /// Sets the flash mode on primary camera if available
  Future<Either<Failure, void>> setFlashMode(DualCameraFlashMode mode);

  /// Stitches two captured image files into a single composite image using PiP layout
  Future<Either<Failure, String>> stitchImages({
    required String primaryPath,
    required String secondaryPath,
    required PiPLayoutConfig layoutConfig,
    required Size previewViewportSize,
  });

  /// Releases all camera streams and hardware resources
  Future<Either<Failure, void>> disposeCameras();

  /// Widget building helper or controller getter for UI display
  Widget? getPrimaryPreviewWidget();
  Widget? getSecondaryPreviewWidget();

  CameraLens get currentPrimaryLens;
  CameraLens get currentSecondaryLens;
  DualCameraOperatingMode get currentOperatingMode;
  bool get isInitialized;
}
