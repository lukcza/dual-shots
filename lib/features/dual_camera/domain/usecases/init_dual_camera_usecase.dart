import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/camera_types.dart';
import '../repositories/dual_camera_repository.dart';

class InitDualCameraParams extends Equatable {
  final DualCameraOperatingMode preferredMode;
  final CameraLens primaryLens;

  const InitDualCameraParams({
    this.preferredMode = DualCameraOperatingMode.concurrentMultiCamera,
    this.primaryLens = CameraLens.back,
  });

  @override
  List<Object?> get props => [preferredMode, primaryLens];
}

class InitDualCameraUseCase
    implements UseCase<DualCameraOperatingMode, InitDualCameraParams> {
  final IDualCameraRepository repository;

  InitDualCameraUseCase(this.repository);

  @override
  Future<Either<Failure, DualCameraOperatingMode>> call(
      InitDualCameraParams params) async {
    return await repository.initializeCameras(
      preferredMode: params.preferredMode,
      primaryLens: params.primaryLens,
    );
  }
}
