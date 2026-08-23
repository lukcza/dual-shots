import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/camera_types.dart';
import 'i_camera_stream_datasource.dart';

class FallbackCameraDataSource implements ICameraStreamDataSource {
  CameraController? _primaryController;
  List<CameraDescription> _availableCameras = [];

  CameraLens _currentPrimaryLens = CameraLens.back;
  CameraLens _currentSecondaryLens = CameraLens.front;
  bool _isInitialized = false;

  @override
  CameraLens get currentPrimaryLens => _currentPrimaryLens;

  @override
  CameraLens get currentSecondaryLens => _currentSecondaryLens;

  @override
  bool get isInitialized =>
      _isInitialized &&
      _primaryController != null &&
      _primaryController!.value.isInitialized;

  @override
  DualCameraOperatingMode get operatingMode =>
      DualCameraOperatingMode.pseudoDualFallback;

  @override
  Future<void> initialize({required CameraLens primaryLens}) async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        throw CameraDeviceException('No camera sensors found on this device');
      }

      _currentPrimaryLens = primaryLens;
      _currentSecondaryLens = primaryLens == CameraLens.back
          ? CameraLens.front
          : CameraLens.back;

      await _initPrimaryController();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      throw CameraDeviceException('Failed to initialize fallback camera: $e');
    }
  }

  Future<void> _initPrimaryController() async {
    final cameraDescription = _getCameraForLens(_currentPrimaryLens);
    if (cameraDescription == null) {
      throw CameraDeviceException(
          'Target camera lens $_currentPrimaryLens not found');
    }

    if (_primaryController != null) {
      await _primaryController?.dispose();
      _primaryController = null;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _primaryController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _primaryController!.initialize();
  }

  CameraDescription? _getCameraForLens(CameraLens lens) {
    final targetDirection = lens == CameraLens.back
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    try {
      return _availableCameras.firstWhere(
        (cam) => cam.lensDirection == targetDirection,
      );
    } catch (_) {
      return _availableCameras.isNotEmpty ? _availableCameras.first : null;
    }
  }

  @override
  Future<({String primaryPath, String secondaryPath})> captureDualShot() async {
    if (!isInitialized || _primaryController == null) {
      throw CameraDeviceException('Camera is not initialized');
    }

    try {
      // 1. Capture primary shot instantly
      final XFile primaryPhoto = await _primaryController!.takePicture();
      await Future.delayed(const Duration(milliseconds: 80));

      // 2. Fast switch sensor to secondary lens
      final secondaryCameraDescription =
          _getCameraForLens(_currentSecondaryLens);
      if (secondaryCameraDescription == null) {
        throw CameraDeviceException('Secondary camera lens not available');
      }

      // Dispose primary controller to release hardware Camera HAL lock
      await _primaryController!.dispose();
      _primaryController = null;
      await Future.delayed(const Duration(milliseconds: 250));

      // Initialize secondary camera with resilience retry
      CameraController? secondaryController;
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          final tempController = CameraController(
            secondaryCameraDescription,
            ResolutionPreset.medium,
            enableAudio: false,
          );
          await tempController.initialize();
          secondaryController = tempController;
          break;
        } catch (_) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      if (secondaryController == null) {
        throw CameraDeviceException(
            'Could not access secondary camera sensor from Camera HAL');
      }

      // Allow auto-exposure a fraction of a second to calibrate
      await Future.delayed(const Duration(milliseconds: 150));

      final XFile secondaryPhoto = await secondaryController.takePicture();
      await Future.delayed(const Duration(milliseconds: 80));

      // 3. Dispose secondary and restore primary sensor preview
      await secondaryController.dispose();
      await Future.delayed(const Duration(milliseconds: 250));
      await _initPrimaryController();

      return (
        primaryPath: primaryPhoto.path,
        secondaryPath: secondaryPhoto.path,
      );
    } catch (e) {
      // Ensure primary camera is restored even on error
      if (_primaryController == null ||
          !_primaryController!.value.isInitialized) {
        await _initPrimaryController().catchError((_) {});
      }
      throw CameraDeviceException('Pseudo-dual capture failed: $e');
    }
  }

  @override
  Future<void> switchCameraRoles() async {
    final newPrimary = _currentSecondaryLens;
    final newSecondary = _currentPrimaryLens;

    _currentPrimaryLens = newPrimary;
    _currentSecondaryLens = newSecondary;

    await _initPrimaryController();
  }

  @override
  Future<void> setFlashMode(DualCameraFlashMode mode) async {
    if (_primaryController == null ||
        !_primaryController!.value.isInitialized) {
      return;
    }

    try {
      FlashMode flashMode;
      switch (mode) {
        case DualCameraFlashMode.off:
          flashMode = FlashMode.off;
          break;
        case DualCameraFlashMode.auto:
          flashMode = FlashMode.auto;
          break;
        case DualCameraFlashMode.on:
          flashMode = FlashMode.always;
          break;
        case DualCameraFlashMode.torch:
          flashMode = FlashMode.torch;
          break;
      }
      await _primaryController!.setFlashMode(flashMode);
    } catch (_) {}
  }

  @override
  Widget? buildPrimaryPreviewWidget() {
    if (_primaryController == null ||
        !_primaryController!.value.isInitialized) {
      return null;
    }
    return CameraPreview(_primaryController!);
  }

  @override
  Widget? buildSecondaryPreviewWidget() {
    return null;
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
    await _primaryController?.dispose();
    _primaryController = null;
  }
}
