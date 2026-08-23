import 'package:equatable/equatable.dart';

enum PiPCorner {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  custom,
}

class PiPLayoutConfig extends Equatable {
  /// Normalized X coordinate on screen (0.0 = left edge, 1.0 = right edge)
  final double normalizedX;

  /// Normalized Y coordinate on screen (0.0 = top edge, 1.0 = bottom edge)
  final double normalizedY;

  /// Width of the PiP viewport relative to the screen width (e.g. 0.28 = 28%)
  final double widthRatio;

  /// Aspect ratio of the PiP window (width / height) - standard 3/4 or 9/16
  final double aspectRatio;

  /// Corner radius in logical pixels for rounded borders
  final double borderRadius;

  /// Border width in logical pixels
  final double borderWidth;

  /// Whether the secondary stream/photo should be horizontally flipped (standard for front selfie camera)
  final bool isMirrored;

  const PiPLayoutConfig({
    this.normalizedX = 0.05,
    this.normalizedY = 0.12,
    this.widthRatio = 0.32,
    this.aspectRatio = 3.0 / 4.0,
    this.borderRadius = 16.0,
    this.borderWidth = 2.5,
    this.isMirrored = true,
  });

  PiPLayoutConfig copyWith({
    double? normalizedX,
    double? normalizedY,
    double? widthRatio,
    double? aspectRatio,
    double? borderRadius,
    double? borderWidth,
    bool? isMirrored,
  }) {
    return PiPLayoutConfig(
      normalizedX: normalizedX ?? this.normalizedX,
      normalizedY: normalizedY ?? this.normalizedY,
      widthRatio: widthRatio ?? this.widthRatio,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      isMirrored: isMirrored ?? this.isMirrored,
    );
  }

  @override
  List<Object?> get props => [
        normalizedX,
        normalizedY,
        widthRatio,
        aspectRatio,
        borderRadius,
        borderWidth,
        isMirrored,
      ];
}
