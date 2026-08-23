import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dual_shots/core/errors/failures.dart';
import 'package:dual_shots/core/services/permission_service.dart';
import 'package:dual_shots/core/usecase/usecase.dart';
import 'package:dual_shots/features/dual_camera/domain/entities/camera_types.dart';
import 'package:dual_shots/features/dual_camera/domain/usecases/check_multi_camera_support_usecase.dart';
import 'package:dual_shots/features/dual_camera/domain/usecases/dispose_cameras_usecase.dart';
import 'package:dual_shots/features/dual_camera/domain/usecases/init_dual_camera_usecase.dart';
import 'package:dual_shots/features/dual_camera/domain/usecases/switch_camera_roles_usecase.dart';
import 'package:dual_shots/features/dual_camera/domain/usecases/take_dual_shot_usecase.dart';
import 'package:dual_shots/features/dual_camera/presentation/bloc/dual_camera_bloc.dart';
import 'package:dual_shots/features/dual_camera/presentation/bloc/dual_camera_event.dart';
import 'package:dual_shots/features/dual_camera/presentation/bloc/dual_camera_state.dart';

class MockPermissionService extends Mock implements IPermissionService {}
class MockCheckMultiCameraSupportUseCase extends Mock
    implements CheckMultiCameraSupportUseCase {}
class MockInitDualCameraUseCase extends Mock implements InitDualCameraUseCase {}
class MockTakeDualShotUseCase extends Mock implements TakeDualShotUseCase {}
class MockSwitchCameraRolesUseCase extends Mock
    implements SwitchCameraRolesUseCase {}
class MockDisposeCamerasUseCase extends Mock implements DisposeCamerasUseCase {}

void main() {
  late DualCameraBloc bloc;
  late MockPermissionService mockPermissionService;
  late MockCheckMultiCameraSupportUseCase mockCheckMultiCameraSupportUseCase;
  late MockInitDualCameraUseCase mockInitDualCameraUseCase;
  late MockTakeDualShotUseCase mockTakeDualShotUseCase;
  late MockSwitchCameraRolesUseCase mockSwitchCameraRolesUseCase;
  late MockDisposeCamerasUseCase mockDisposeCamerasUseCase;

  setUp(() {
    mockPermissionService = MockPermissionService();
    mockCheckMultiCameraSupportUseCase = MockCheckMultiCameraSupportUseCase();
    mockInitDualCameraUseCase = MockInitDualCameraUseCase();
    mockTakeDualShotUseCase = MockTakeDualShotUseCase();
    mockSwitchCameraRolesUseCase = MockSwitchCameraRolesUseCase();
    mockDisposeCamerasUseCase = MockDisposeCamerasUseCase();

    registerFallbackValue(const NoParams());
    registerFallbackValue(const InitDualCameraParams());

    bloc = DualCameraBloc(
      permissionService: mockPermissionService,
      checkMultiCameraSupportUseCase: mockCheckMultiCameraSupportUseCase,
      initDualCameraUseCase: mockInitDualCameraUseCase,
      takeDualShotUseCase: mockTakeDualShotUseCase,
      switchCameraRolesUseCase: mockSwitchCameraRolesUseCase,
      disposeCamerasUseCase: mockDisposeCamerasUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be DualCameraStatus.initial', () {
    expect(bloc.state.status, equals(DualCameraStatus.initial));
  });

  blocTest<DualCameraBloc, DualCameraState>(
    'emits [initializing, ready] when InitializeCamerasEvent succeeds',
    build: () {
      when(() => mockInitDualCameraUseCase(any())).thenAnswer(
        (_) async => const Right<Failure, DualCameraOperatingMode>(
            DualCameraOperatingMode.concurrentMultiCamera),
      );
      return bloc;
    },
    act: (bloc) => bloc.add(const InitializeCamerasEvent(
      preferredMode: DualCameraOperatingMode.concurrentMultiCamera,
      primaryLens: CameraLens.back,
    )),
    expect: () => [
      const DualCameraState(status: DualCameraStatus.initializing),
      const DualCameraState(
        status: DualCameraStatus.ready,
        operatingMode: DualCameraOperatingMode.concurrentMultiCamera,
        primaryLens: CameraLens.back,
        secondaryLens: CameraLens.front,
      ),
    ],
  );
}
