import 'package:flutter/widgets.dart';
import '../../domain/entities/camera_types.dart';

abstract class ICameraStreamDataSource {
  Future<void> initialize({required CameraLens primaryLens});

  /// Captures both photos and returns a record (primaryFilePath, secondaryFilePath)
  Future<({String primaryPath, String secondaryPath})> captureDualShot();

  Future<void> switchCameraRoles();
  Future<void> setFlashMode(DualCameraFlashMode mode);
  Future<void> dispose();

  Widget? buildPrimaryPreviewWidget();
  Widget? buildSecondaryPreviewWidget();

  CameraLens get currentPrimaryLens;
  CameraLens get currentSecondaryLens;
  bool get isInitialized;
  DualCameraOperatingMode get operatingMode;
}
