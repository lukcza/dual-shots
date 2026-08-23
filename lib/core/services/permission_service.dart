import 'package:permission_handler/permission_handler.dart';
import '../errors/failures.dart';
import '../usecase/usecase.dart';

abstract class IPermissionService {
  Future<Either<PermissionFailure, bool>> checkAndRequestCameraPermissions();
  Future<bool> openAppSettingsPage();
}

class PermissionService implements IPermissionService {
  @override
  Future<Either<PermissionFailure, bool>>
      checkAndRequestCameraPermissions() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;

      if (cameraStatus.isGranted && micStatus.isGranted) {
        return const Right(true);
      }

      // Request both permissions in parallel
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      final cameraResult = statuses[Permission.camera];
      final micResult = statuses[Permission.microphone];

      if (cameraResult?.isGranted == true) {
        return const Right(true);
      }

      if (cameraResult?.isPermanentlyDenied == true ||
          micResult?.isPermanentlyDenied == true) {
        return const Left(
          PermissionFailure(
            message:
                'Uprawnienia do kamery zostały trwale zablokowane. Otwórz ustawienia, aby je włączyć.',
            isPermanentlyDenied: true,
          ),
        );
      }

      return const Left(
        PermissionFailure(
          message:
              'Aplikacja wymaga dostępu do kamery, aby móc wykonywać zdjęcia Dual Shot.',
          isPermanentlyDenied: false,
        ),
      );
    } catch (e) {
      return Left(
        PermissionFailure(
          message: 'Błąd podczas sprawdzania uprawnień: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<bool> openAppSettingsPage() async {
    return await openAppSettings();
  }
}
