import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum MultiCameraSupportType {
  /// Hardware supports true concurrent multi-camera capture (iOS AVCaptureMultiCamSession / Android FEATURE_CAMERA_CONCURRENT)
  hardwareConcurrent,

  /// Hardware does not support concurrent streams; system will use high-speed pseudo-dual fallback
  fallbackPseudoDual,

  /// Device has only a single camera sensor (e.g. some tablets or emulators)
  singleCameraOnly,
}

abstract class ICameraCapabilityChecker {
  Future<MultiCameraSupportType> detectMultiCameraSupport();
}

class CameraCapabilityChecker implements ICameraCapabilityChecker {
  static const MethodChannel _platformChannel =
      MethodChannel('com.example.dual_shots/camera_capabilities');

  @override
  Future<MultiCameraSupportType> detectMultiCameraSupport() async {
    try {
      if (kIsWeb) {
        return MultiCameraSupportType.fallbackPseudoDual;
      }

      if (Platform.isIOS) {
        // iOS 13+ on A12 Bionic and newer (iPhone XS, XR, 11, 12, 13, 14, 15, etc.) supports AVCaptureMultiCamSession
        final dynamic result =
            await _platformChannel.invokeMethod('isMultiCamSupported');
        if (result == true) {
          return MultiCameraSupportType.hardwareConcurrent;
        }
        return MultiCameraSupportType.fallbackPseudoDual;
      } else if (Platform.isAndroid) {
        // Android 9+ (API 28+) with PackageManager.FEATURE_CAMERA_CONCURRENT (Android 11+ API 30+)
        final dynamic result =
            await _platformChannel.invokeMethod('isConcurrentCameraSupported');
        if (result == true) {
          return MultiCameraSupportType.hardwareConcurrent;
        }
        return MultiCameraSupportType.fallbackPseudoDual;
      }
    } on PlatformException catch (_) {
      // If native channel is not implemented or fails, safely return fallback pseudo-dual mode
      return MultiCameraSupportType.fallbackPseudoDual;
    } catch (_) {
      return MultiCameraSupportType.fallbackPseudoDual;
    }

    return MultiCameraSupportType.fallbackPseudoDual;
  }
}
