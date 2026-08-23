/// Exception thrown during low-level camera operations
class CameraDeviceException implements Exception {
  final String message;
  final String? code;

  CameraDeviceException(this.message, {this.code});

  @override
  String toString() => 'CameraDeviceException: $message (code: $code)';
}

/// Exception thrown when permissions are not granted
class PermissionDeniedException implements Exception {
  final String permissionName;
  final bool isPermanent;

  PermissionDeniedException(this.permissionName, {this.isPermanent = false});

  @override
  String toString() =>
      'PermissionDeniedException: $permissionName (permanent: $isPermanent)';
}

/// Exception thrown during image decoding, compositing, or encoding in isolate
class StitchingException implements Exception {
  final String message;
  final dynamic error;

  StitchingException(this.message, {this.error});

  @override
  String toString() => 'StitchingException: $message ($error)';
}
