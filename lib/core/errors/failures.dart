import 'package:equatable/equatable.dart';

/// Base Failure class for Clean Architecture domain error handling
abstract class Failure extends Equatable {
  final String message;
  final String? details;

  const Failure({required this.message, this.details});

  @override
  List<Object?> get props => [message, details];
}

/// Returned when camera hardware cannot be accessed or fails initialization
class CameraFailure extends Failure {
  const CameraFailure({required super.message, super.details});
}

/// Returned when required runtime permissions (Camera, Microphone) are denied
class PermissionFailure extends Failure {
  final bool isPermanentlyDenied;

  const PermissionFailure({
    required super.message,
    this.isPermanentlyDenied = false,
    super.details,
  });

  @override
  List<Object?> get props => [message, details, isPermanentlyDenied];
}

/// Returned when the image stitching / post-processing pipeline fails in the isolate
class ImageStitchingFailure extends Failure {
  const ImageStitchingFailure({required super.message, super.details});
}

/// Returned when concurrent multi-camera is requested but hardware cannot satisfy it
class MultiCameraUnsupportedFailure extends Failure {
  const MultiCameraUnsupportedFailure({required super.message, super.details});
}

/// Returned when file system operations (save/read) fail
class StorageFailure extends Failure {
  const StorageFailure({required super.message, super.details});
}
