import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/platform/camera_capability_checker.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/camera_types.dart';
import '../../domain/entities/dual_shot_result.dart';
import '../../domain/entities/pip_layout_config.dart';
import '../../domain/repositories/dual_camera_repository.dart';
import '../datasources/fallback_camera_datasource.dart';
import '../datasources/i_camera_stream_datasource.dart';
import '../datasources/image_stitcher_datasource.dart';
import '../datasources/multi_camera_datasource.dart';

class DualCameraRepositoryImpl implements IDualCameraRepository {
  final ICameraCapabilityChecker capabilityChecker;
  final MultiCameraDataSource multiCameraDataSource;
  final FallbackCameraDataSource fallbackCameraDataSource;
  final IImageStitcherDataSource imageStitcherDataSource;

  final Uuid _uuid = const Uuid();

  ICameraStreamDataSource? _activeDataSource;
  DualCameraOperatingMode _currentMode = DualCameraOperatingMode.concurrentMultiCamera;

  DualCameraRepositoryImpl({
    required this.capabilityChecker,
    required this.multiCameraDataSource,
    required this.fallbackCameraDataSource,
    required this.imageStitcherDataSource,
  });

  @override
  CameraLens get currentPrimaryLens =>
      _activeDataSource?.currentPrimaryLens ?? CameraLens.back;

  @override
  CameraLens get currentSecondaryLens =>
      _activeDataSource?.currentSecondaryLens ?? CameraLens.front;

  @override
  DualCameraOperatingMode get currentOperatingMode => _currentMode;

  @override
  bool get isInitialized => _activeDataSource?.isInitialized ?? false;

  @override
  Future<Either<Failure, DualCameraOperatingMode>> checkMultiCameraSupport() async {
    return const Right(DualCameraOperatingMode.concurrentMultiCamera);
  }

  @override
  Future<Either<Failure, DualCameraOperatingMode>> initializeCameras({
    required DualCameraOperatingMode preferredMode,
    required CameraLens primaryLens,
  }) async {
    try {
      await disposeCameras();

      // Initialize Concurrent Dual Camera PlatformView streams
      await multiCameraDataSource.initialize(primaryLens: primaryLens);
      _activeDataSource = multiCameraDataSource;
      _currentMode = DualCameraOperatingMode.concurrentMultiCamera;

      return Right(_currentMode);
    } on CameraDeviceException catch (e) {
      return Left(CameraFailure(message: e.message, details: e.code));
    } catch (e) {
      return Left(CameraFailure(message: 'Failed to initialize concurrent dual camera: $e'));
    }
  }

  @override
  Future<Either<Failure, DualShotResult>> takeDualShot({
    required PiPLayoutConfig layoutConfig,
    required Size screenSize,
  }) async {
    if (_activeDataSource == null || !_activeDataSource!.isInitialized) {
      return const Left(CameraFailure(message: 'Cameras are not initialized'));
    }

    try {
      final captureTimestamp = DateTime.now();
      final capturedPaths = await _activeDataSource!.captureDualShot();

      // Stitch images together via isolate post-processor in background thread
      final stitchedPath = await imageStitcherDataSource.stitchImages(
        primaryPath: capturedPaths.primaryPath,
        secondaryPath: capturedPaths.secondaryPath,
        layoutConfig: layoutConfig,
        previewViewportSize: screenSize,
      );

      final result = DualShotResult(
        id: _uuid.v4(),
        primaryImagePath: capturedPaths.primaryPath,
        secondaryImagePath: capturedPaths.secondaryPath,
        stitchedImagePath: stitchedPath,
        timestamp: captureTimestamp,
        operatingMode: _currentMode,
        primaryLens: currentPrimaryLens,
        secondaryLens: currentSecondaryLens,
        layoutConfig: layoutConfig,
        stitchedWidth: 1080,
        stitchedHeight: 1920,
      );

      return Right(result);
    } on CameraDeviceException catch (e) {
      return Left(CameraFailure(message: e.message, details: e.code));
    } on StitchingException catch (e) {
      return Left(ImageStitchingFailure(message: e.message, details: '${e.error}'));
    } catch (e) {
      return Left(CameraFailure(message: 'Failed to take dual shot: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> switchCameraRoles() async {
    if (_activeDataSource == null) {
      return const Left(CameraFailure(message: 'No active camera session'));
    }

    try {
      await _activeDataSource!.switchCameraRoles();
      return const Right(null);
    } catch (e) {
      return Left(CameraFailure(message: 'Failed to switch camera: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setFlashMode(DualCameraFlashMode mode) async {
    if (_activeDataSource == null) {
      return const Left(CameraFailure(message: 'No active camera session'));
    }

    try {
      await _activeDataSource!.setFlashMode(mode);
      return const Right(null);
    } catch (e) {
      return Left(CameraFailure(message: 'Failed to set flash: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> stitchImages({
    required String primaryPath,
    required String secondaryPath,
    required PiPLayoutConfig layoutConfig,
    required Size previewViewportSize,
  }) async {
    try {
      final stitchedPath = await imageStitcherDataSource.stitchImages(
        primaryPath: primaryPath,
        secondaryPath: secondaryPath,
        layoutConfig: layoutConfig,
        previewViewportSize: previewViewportSize,
      );
      return Right(stitchedPath);
    } catch (e) {
      return Left(ImageStitchingFailure(message: 'Error stitching images: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> disposeCameras() async {
    try {
      await _activeDataSource?.dispose();
      _activeDataSource = null;
      return const Right(null);
    } catch (e) {
      return Left(CameraFailure(message: 'Error disposing camera: $e'));
    }
  }

  @override
  Widget? getPrimaryPreviewWidget() {
    return _activeDataSource?.buildPrimaryPreviewWidget();
  }

  @override
  Widget? getSecondaryPreviewWidget() {
    return _activeDataSource?.buildSecondaryPreviewWidget();
  }
}
