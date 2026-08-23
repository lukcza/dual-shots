import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import '../../domain/entities/camera_types.dart';
import '../../domain/entities/pip_layout_config.dart';

abstract class DualCameraEvent extends Equatable {
  const DualCameraEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched on page entry to check permissions and hardware capabilities
class RequestPermissionsAndInitEvent extends DualCameraEvent {
  final CameraLens initialLens;

  const RequestPermissionsAndInitEvent({this.initialLens = CameraLens.back});

  @override
  List<Object?> get props => [initialLens];
}

/// Dispatched to initialize or re-initialize camera sessions
class InitializeCamerasEvent extends DualCameraEvent {
  final DualCameraOperatingMode preferredMode;
  final CameraLens primaryLens;

  const InitializeCamerasEvent({
    this.preferredMode = DualCameraOperatingMode.concurrentMultiCamera,
    this.primaryLens = CameraLens.back,
  });

  @override
  List<Object?> get props => [preferredMode, primaryLens];
}

/// Dispatched when user taps the shutter button to take a dual shot
class TakeDualShotEvent extends DualCameraEvent {
  final Size screenSize;

  const TakeDualShotEvent({required this.screenSize});

  @override
  List<Object?> get props => [screenSize];
}

/// Dispatched when user changes PiP position, size, or mirroring
class UpdatePiPLayoutEvent extends DualCameraEvent {
  final PiPLayoutConfig layoutConfig;

  const UpdatePiPLayoutEvent(this.layoutConfig);

  @override
  List<Object?> get props => [layoutConfig];
}

/// Dispatched to invert camera roles (Front becomes full screen, Back becomes PiP)
class SwitchCameraRolesEvent extends DualCameraEvent {
  const SwitchCameraRolesEvent();
}

/// Dispatched to cycle flash mode (off -> auto -> on -> torch)
class ToggleFlashModeEvent extends DualCameraEvent {
  const ToggleFlashModeEvent();
}

/// Dispatched when app goes to background (pause streams to save battery)
class AppPausedEvent extends DualCameraEvent {
  const AppPausedEvent();
}

/// Dispatched when app returns to foreground (re-initialize streams)
class AppResumedEvent extends DualCameraEvent {
  const AppResumedEvent();
}

/// Dispatched to reset to ready state after previewing shot
class ResetToCameraReadyEvent extends DualCameraEvent {
  const ResetToCameraReadyEvent();
}

/// Dispatched to open app settings when permissions are denied
class OpenAppSettingsEvent extends DualCameraEvent {
  const OpenAppSettingsEvent();
}
