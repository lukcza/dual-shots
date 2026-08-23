import 'package:get_it/get_it.dart';

import 'core/platform/camera_capability_checker.dart';
import 'core/services/lifecycle_manager.dart';
import 'core/services/permission_service.dart';
import 'features/dual_camera/data/datasources/fallback_camera_datasource.dart';
import 'features/dual_camera/data/datasources/image_stitcher_datasource.dart';
import 'features/dual_camera/data/datasources/multi_camera_datasource.dart';
import 'features/dual_camera/data/repositories/dual_camera_repository_impl.dart';
import 'features/dual_camera/domain/repositories/dual_camera_repository.dart';
import 'features/dual_camera/domain/usecases/check_multi_camera_support_usecase.dart';
import 'features/dual_camera/domain/usecases/dispose_cameras_usecase.dart';
import 'features/dual_camera/domain/usecases/init_dual_camera_usecase.dart';
import 'features/dual_camera/domain/usecases/stitch_dual_shot_usecase.dart';
import 'features/dual_camera/domain/usecases/switch_camera_roles_usecase.dart';
import 'features/dual_camera/domain/usecases/take_dual_shot_usecase.dart';
import 'features/dual_camera/presentation/bloc/dual_camera_bloc.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  //! Presentation - BLoC
  sl.registerFactory(
    () => DualCameraBloc(
      permissionService: sl(),
      checkMultiCameraSupportUseCase: sl(),
      initDualCameraUseCase: sl(),
      takeDualShotUseCase: sl(),
      switchCameraRolesUseCase: sl(),
      disposeCamerasUseCase: sl(),
    ),
  );

  //! Domain - Use Cases
  sl.registerLazySingleton(() => CheckMultiCameraSupportUseCase(sl()));
  sl.registerLazySingleton(() => InitDualCameraUseCase(sl()));
  sl.registerLazySingleton(() => TakeDualShotUseCase(sl()));
  sl.registerLazySingleton(() => StitchDualShotUseCase(sl()));
  sl.registerLazySingleton(() => SwitchCameraRolesUseCase(sl()));
  sl.registerLazySingleton(() => DisposeCamerasUseCase(sl()));

  //! Data - Repository
  sl.registerLazySingleton<IDualCameraRepository>(
    () => DualCameraRepositoryImpl(
      capabilityChecker: sl(),
      multiCameraDataSource: sl(),
      fallbackCameraDataSource: sl(),
      imageStitcherDataSource: sl(),
    ),
  );

  //! Data - Data Sources
  sl.registerLazySingleton(() => MultiCameraDataSource());
  sl.registerLazySingleton(() => FallbackCameraDataSource());
  sl.registerLazySingleton<IImageStitcherDataSource>(
    () => ImageStitcherDataSource(),
  );

  //! Core Services & Platform
  sl.registerLazySingleton<ICameraCapabilityChecker>(
    () => CameraCapabilityChecker(),
  );
  sl.registerLazySingleton<IPermissionService>(
    () => PermissionService(),
  );
  sl.registerLazySingleton(() {
    final manager = AppLifecycleManager();
    manager.init();
    return manager;
  });
}
