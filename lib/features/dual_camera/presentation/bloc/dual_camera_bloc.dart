import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/permission_service.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/camera_types.dart';
import '../../domain/usecases/check_multi_camera_support_usecase.dart';
import '../../domain/usecases/dispose_cameras_usecase.dart';
import '../../domain/usecases/init_dual_camera_usecase.dart';
import '../../domain/usecases/switch_camera_roles_usecase.dart';
import '../../domain/usecases/take_dual_shot_usecase.dart';
import 'dual_camera_event.dart';
import 'dual_camera_state.dart';

class DualCameraBloc extends Bloc<DualCameraEvent, DualCameraState> {
  final IPermissionService permissionService;
  final CheckMultiCameraSupportUseCase checkMultiCameraSupportUseCase;
  final InitDualCameraUseCase initDualCameraUseCase;
  final TakeDualShotUseCase takeDualShotUseCase;
  final SwitchCameraRolesUseCase switchCameraRolesUseCase;
  final DisposeCamerasUseCase disposeCamerasUseCase;

  DualCameraBloc({
    required this.permissionService,
    required this.checkMultiCameraSupportUseCase,
    required this.initDualCameraUseCase,
    required this.takeDualShotUseCase,
    required this.switchCameraRolesUseCase,
    required this.disposeCamerasUseCase,
  }) : super(const DualCameraState()) {
    on<RequestPermissionsAndInitEvent>(_onRequestPermissionsAndInit);
    on<InitializeCamerasEvent>(_onInitializeCameras);
    on<TakeDualShotEvent>(_onTakeDualShot);
    on<UpdatePiPLayoutEvent>(_onUpdatePiPLayout);
    on<SwitchCameraRolesEvent>(_onSwitchCameraRoles);
    on<ToggleFlashModeEvent>(_onToggleFlashMode);
    on<AppPausedEvent>(_onAppPaused);
    on<AppResumedEvent>(_onAppResumed);
    on<ResetToCameraReadyEvent>(_onResetToCameraReady);
    on<OpenAppSettingsEvent>((event, emit) async {
      await permissionService.openAppSettingsPage();
    });
  }

  Future<void> _onRequestPermissionsAndInit(
    RequestPermissionsAndInitEvent event,
    Emitter<DualCameraState> emit,
  ) async {
    emit(state.copyWith(status: DualCameraStatus.checkingPermissions));

    final permissionResult =
        await permissionService.checkAndRequestCameraPermissions();

    await permissionResult.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: DualCameraStatus.permissionDenied,
            errorMessage: failure.message,
            isPermissionPermanentlyDenied: failure.isPermanentlyDenied,
          ),
        );
      },
      (isGranted) async {
        // Detect multi-camera capability
        final capabilityResult =
            await checkMultiCameraSupportUseCase(const NoParams());

        final operatingMode = capabilityResult.fold(
          (_) => DualCameraOperatingMode.pseudoDualFallback,
          (mode) => mode,
        );

        add(InitializeCamerasEvent(
          preferredMode: operatingMode,
          primaryLens: event.initialLens,
        ));
      },
    );
  }

  Future<void> _onInitializeCameras(
    InitializeCamerasEvent event,
    Emitter<DualCameraState> emit,
  ) async {
    emit(state.copyWith(status: DualCameraStatus.initializing));

    final result = await initDualCameraUseCase(InitDualCameraParams(
      preferredMode: event.preferredMode,
      primaryLens: event.primaryLens,
    ));

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: DualCameraStatus.error,
          errorMessage: failure.message,
        ));
      },
      (actualMode) {
        final secondaryLens = event.primaryLens == CameraLens.back
            ? CameraLens.front
            : CameraLens.back;

        emit(state.copyWith(
          status: DualCameraStatus.ready,
          operatingMode: actualMode,
          primaryLens: event.primaryLens,
          secondaryLens: secondaryLens,
          errorMessage: null,
        ));
      },
    );
  }

  Future<void> _onTakeDualShot(
    TakeDualShotEvent event,
    Emitter<DualCameraState> emit,
  ) async {
    if (!state.isReady) return;

    emit(state.copyWith(status: DualCameraStatus.capturing));

    final result = await takeDualShotUseCase(TakeDualShotParams(
      layoutConfig: state.pipLayoutConfig,
      screenSize: event.screenSize,
    ));

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: DualCameraStatus.error,
          errorMessage: failure.message,
        ));
      },
      (dualShotResult) {
        emit(state.copyWith(
          status: DualCameraStatus.capturedSuccess,
          lastResult: dualShotResult,
        ));
      },
    );
  }

  void _onUpdatePiPLayout(
    UpdatePiPLayoutEvent event,
    Emitter<DualCameraState> emit,
  ) {
    emit(state.copyWith(pipLayoutConfig: event.layoutConfig));
  }

  Future<void> _onSwitchCameraRoles(
    SwitchCameraRolesEvent event,
    Emitter<DualCameraState> emit,
  ) async {
    if (!state.isReady) return;

    final newPrimary = state.secondaryLens;
    final newSecondary = state.primaryLens;

    emit(state.copyWith(
      primaryLens: newPrimary,
      secondaryLens: newSecondary,
      status: DualCameraStatus.initializing,
    ));

    final result = await switchCameraRolesUseCase(const NoParams());

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: DualCameraStatus.error,
          errorMessage: failure.message,
        ));
      },
      (_) {
        emit(state.copyWith(
          status: DualCameraStatus.ready,
          primaryLens: newPrimary,
          secondaryLens: newSecondary,
        ));
      },
    );
  }

  void _onToggleFlashMode(
    ToggleFlashModeEvent event,
    Emitter<DualCameraState> emit,
  ) {
    final nextFlash = switch (state.flashMode) {
      DualCameraFlashMode.off => DualCameraFlashMode.auto,
      DualCameraFlashMode.auto => DualCameraFlashMode.on,
      DualCameraFlashMode.on => DualCameraFlashMode.torch,
      DualCameraFlashMode.torch => DualCameraFlashMode.off,
    };

    emit(state.copyWith(flashMode: nextFlash));
  }

  Future<void> _onAppPaused(
    AppPausedEvent event,
    Emitter<DualCameraState> emit,
  ) async {
    await disposeCamerasUseCase(const NoParams());
    emit(state.copyWith(status: DualCameraStatus.initial));
  }

  Future<void> _onAppResumed(
    AppResumedEvent event,
    Emitter<DualCameraState> emit,
  ) async {
    add(RequestPermissionsAndInitEvent(initialLens: state.primaryLens));
  }

  void _onResetToCameraReady(
    ResetToCameraReadyEvent event,
    Emitter<DualCameraState> emit,
  ) {
    emit(state.copyWith(
      status: DualCameraStatus.ready,
      lastResult: null,
    ));
  }
}
