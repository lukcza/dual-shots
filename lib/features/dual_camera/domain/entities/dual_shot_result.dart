import 'package:equatable/equatable.dart';
import 'camera_types.dart';
import 'pip_layout_config.dart';

class DualShotResult extends Equatable {
  final String id;
  final String primaryImagePath;
  final String secondaryImagePath;
  final String stitchedImagePath;
  final DateTime timestamp;
  final DualCameraOperatingMode operatingMode;
  final CameraLens primaryLens;
  final CameraLens secondaryLens;
  final PiPLayoutConfig layoutConfig;
  final int stitchedWidth;
  final int stitchedHeight;

  const DualShotResult({
    required this.id,
    required this.primaryImagePath,
    required this.secondaryImagePath,
    required this.stitchedImagePath,
    required this.timestamp,
    required this.operatingMode,
    required this.primaryLens,
    required this.secondaryLens,
    required this.layoutConfig,
    required this.stitchedWidth,
    required this.stitchedHeight,
  });

  @override
  List<Object?> get props => [
        id,
        primaryImagePath,
        secondaryImagePath,
        stitchedImagePath,
        timestamp,
        operatingMode,
        primaryLens,
        secondaryLens,
        layoutConfig,
        stitchedWidth,
        stitchedHeight,
      ];
}
