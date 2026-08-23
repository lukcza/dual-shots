import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/camera_types.dart';
import '../repositories/dual_camera_repository.dart';

class CheckMultiCameraSupportUseCase
    implements UseCase<DualCameraOperatingMode, NoParams> {
  final IDualCameraRepository repository;

  CheckMultiCameraSupportUseCase(this.repository);

  @override
  Future<Either<Failure, DualCameraOperatingMode>> call(NoParams params) async {
    return await repository.checkMultiCameraSupport();
  }
}
