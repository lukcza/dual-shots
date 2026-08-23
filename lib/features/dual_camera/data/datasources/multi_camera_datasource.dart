import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/camera_types.dart';
import 'i_camera_stream_datasource.dart';

class MultiCameraDataSource implements ICameraStreamDataSource {
  static const MethodChannel _channel =
      MethodChannel('com.example.dual_shots/native_dual_camera');

  CameraLens _currentPrimaryLens = CameraLens.back;
  CameraLens _currentSecondaryLens = CameraLens.front;
  bool _isInitialized = false;

  @override
  CameraLens get currentPrimaryLens => _currentPrimaryLens;

  @override
  CameraLens get currentSecondaryLens => _currentSecondaryLens;

  @override
  bool get isInitialized => _isInitialized;

  @override
  DualCameraOperatingMode get operatingMode =>
      DualCameraOperatingMode.concurrentMultiCamera;

  @override
  Future<void> initialize({required CameraLens primaryLens}) async {
    _currentPrimaryLens = primaryLens;
    _currentSecondaryLens = primaryLens == CameraLens.back
        ? CameraLens.front
        : CameraLens.back;
    _isInitialized = true;
  }

  @override
  Future<({String primaryPath, String secondaryPath})> captureDualShot() async {
    try {
      final dynamic response = await _channel.invokeMethod('takeDualShot');

      if (response is Map &&
          response['primaryPath'] != null &&
          response['secondaryPath'] != null) {
        return (
          primaryPath: response['primaryPath'] as String,
          secondaryPath: response['secondaryPath'] as String,
        );
      } else {
        throw CameraDeviceException('Failed to capture native dual camera photos');
      }
    } catch (e) {
      throw CameraDeviceException('Native dual snapshot failed: $e');
    }
  }

  @override
  Future<void> switchCameraRoles() async {
    final newPrimary = _currentSecondaryLens;
    final newSecondary = _currentPrimaryLens;

    _currentPrimaryLens = newPrimary;
    _currentSecondaryLens = newSecondary;

    try {
      await _channel.invokeMethod('switchCameraRoles');
    } catch (_) {}
  }

  @override
  Future<void> setFlashMode(DualCameraFlashMode mode) async {
    String modeString = 'off';
    switch (mode) {
      case DualCameraFlashMode.off:
        modeString = 'off';
        break;
      case DualCameraFlashMode.auto:
        modeString = 'auto';
        break;
      case DualCameraFlashMode.on:
        modeString = 'on';
        break;
      case DualCameraFlashMode.torch:
        modeString = 'torch';
        break;
    }
    try {
      await _channel.invokeMethod('setFlashMode', {'mode': modeString});
    } catch (_) {}
  }

  Future<void> openGallery() async {
    try {
      await _channel.invokeMethod('openGallery');
    } catch (_) {}
  }

  @override
  Widget? buildPrimaryPreviewWidget() {
    return const AndroidView(
      viewType: 'com.example.dual_shots/camera_view',
      creationParams: {'lens': 'primary'},
      creationParamsCodec: StandardMessageCodec(),
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{},
    );
  }

  @override
  Widget? buildSecondaryPreviewWidget() {
    return const AndroidView(
      viewType: 'com.example.dual_shots/camera_view',
      creationParams: {'lens': 'secondary'},
      creationParamsCodec: StandardMessageCodec(),
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{},
    );
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
    try {
      await _channel.invokeMethod('dispose');
    } catch (_) {}
  }
}
