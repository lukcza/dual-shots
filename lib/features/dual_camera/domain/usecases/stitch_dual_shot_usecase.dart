import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/pip_layout_config.dart';
import '../repositories/dual_camera_repository.dart';

class StitchDualShotParams extends Equatable {
  final String primaryPath;
  final String secondaryPath;
  final PiPLayoutConfig layoutConfig;
  final Size previewViewportSize;

  const StitchDualShotParams({
    required this.primaryPath,
    required this.secondaryPath,
    required this.layoutConfig,
    required this.previewViewportSize,
  });

  @override
  List<Object?> get props => [
        primaryPath,
        secondaryPath,
        layoutConfig,
        previewViewportSize,
      ];
}

class StitchDualShotUseCase implements UseCase<String, StitchDualShotParams> {
  final IDualCameraRepository repository;

  StitchDualShotUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(StitchDualShotParams params) async {
    return await repository.stitchImages(
      primaryPath: params.primaryPath,
      secondaryPath: params.secondaryPath,
      layoutConfig: params.layoutConfig,
      previewViewportSize: params.previewViewportSize,
    );
  }
}
