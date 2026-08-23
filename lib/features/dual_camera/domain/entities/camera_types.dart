enum CameraRole {
  /// The main full-screen camera (default is Back/Main lens)
  primary,

  /// The small Picture-in-Picture window camera (default is Front/Selfie lens)
  secondary,
}

enum CameraLens {
  back,
  front,
  external,
}

enum DualCameraOperatingMode {
  /// Both sensors active concurrently with real-time synchronized streams
  concurrentMultiCamera,

  /// Fallback mode: rapid sequential capture (Primary -> instant switch -> Secondary)
  pseudoDualFallback,
}

enum DualCameraFlashMode {
  off,
  auto,
  on,
  torch,
}

enum DualCameraAspectRatio {
  ratio4_3,
  ratio16_9,
  ratio1_1,
}
