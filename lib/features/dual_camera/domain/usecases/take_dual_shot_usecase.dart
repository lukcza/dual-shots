import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/dual_shot_result.dart';
import '../entities/pip_layout_config.dart';
import '../repositories/dual_camera_repository.dart';

class TakeDualShotParams extends Equatable {
  final PiPLayoutConfig layoutConfig;
  final Size screenSize;

  const TakeDualShotParams({
    required this.layoutConfig,
    required this.screenSize,
  });

  @override
  List<Object?> get props => [layoutConfig, screenSize];
}

class TakeDualShotUseCase implements UseCase<DualShotResult, TakeDualShotParams> {
  final IDualCameraRepository repository;

  TakeDualShotUseCase(this.repository);

  @override
  Future<Either<Failure, DualShotResult>> call(TakeDualShotParams params) async {
    return await repository.takeDualShot(
      layoutConfig: params.layoutConfig,
      screenSize: params.screenSize,
    );
  }
}
