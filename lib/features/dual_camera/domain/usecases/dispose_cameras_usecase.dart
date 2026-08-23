import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/dual_camera_repository.dart';

class DisposeCamerasUseCase implements UseCase<void, NoParams> {
  final IDualCameraRepository repository;

  DisposeCamerasUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.disposeCameras();
  }
}
