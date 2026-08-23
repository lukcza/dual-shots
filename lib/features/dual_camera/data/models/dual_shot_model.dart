import '../../domain/entities/camera_types.dart';
import '../../domain/entities/dual_shot_result.dart';
import '../../domain/entities/pip_layout_config.dart';

class DualShotModel extends DualShotResult {
  const DualShotModel({
    required super.id,
    required super.primaryImagePath,
    required super.secondaryImagePath,
    required super.stitchedImagePath,
    required super.timestamp,
    required super.operatingMode,
    required super.primaryLens,
    required super.secondaryLens,
    required super.layoutConfig,
    required super.stitchedWidth,
    required super.stitchedHeight,
  });

  factory DualShotModel.fromEntity(DualShotResult entity) {
    return DualShotModel(
      id: entity.id,
      primaryImagePath: entity.primaryImagePath,
      secondaryImagePath: entity.secondaryImagePath,
      stitchedImagePath: entity.stitchedImagePath,
      timestamp: entity.timestamp,
      operatingMode: entity.operatingMode,
      primaryLens: entity.primaryLens,
      secondaryLens: entity.secondaryLens,
      layoutConfig: entity.layoutConfig,
      stitchedWidth: entity.stitchedWidth,
      stitchedHeight: entity.stitchedHeight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'primaryImagePath': primaryImagePath,
      'secondaryImagePath': secondaryImagePath,
      'stitchedImagePath': stitchedImagePath,
      'timestamp': timestamp.toIso8601String(),
      'operatingMode': operatingMode.name,
      'primaryLens': primaryLens.name,
      'secondaryLens': secondaryLens.name,
      'stitchedWidth': stitchedWidth,
      'stitchedHeight': stitchedHeight,
    };
  }
}
