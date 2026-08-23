import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:dual_shots/core/errors/failures.dart';
import 'package:dual_shots/core/usecase/usecase.dart';
import 'package:dual_shots/features/dual_camera/domain/entities/camera_types.dart';
import 'package:dual_shots/features/dual_camera/domain/entities/dual_shot_result.dart';
import 'package:dual_shots/features/dual_camera/domain/entities/pip_layout_config.dart';
import 'package:dual_shots/features/dual_camera/domain/repositories/dual_camera_repository.dart';
import 'package:dual_shots/features/dual_camera/domain/usecases/take_dual_shot_usecase.dart';

class MockDualCameraRepository extends Mock implements IDualCameraRepository {}

void main() {
  late TakeDualShotUseCase useCase;
  late MockDualCameraRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const PiPLayoutConfig());
    registerFallbackValue(const Size(1080, 1920));
  });

  setUp(() {
    mockRepository = MockDualCameraRepository();
    useCase = TakeDualShotUseCase(mockRepository);
  });

  const tLayoutConfig = PiPLayoutConfig(normalizedX: 0.1, normalizedY: 0.1);
  const tScreenSize = Size(1080, 1920);

  final tDualShotResult = DualShotResult(
    id: 'test-id-123',
    primaryImagePath: '/tmp/primary.jpg',
    secondaryImagePath: '/tmp/secondary.jpg',
    stitchedImagePath: '/tmp/stitched.jpg',
    timestamp: DateTime.now(),
    operatingMode: DualCameraOperatingMode.concurrentMultiCamera,
    primaryLens: CameraLens.back,
    secondaryLens: CameraLens.front,
    layoutConfig: tLayoutConfig,
    stitchedWidth: 1080,
    stitchedHeight: 1920,
  );

  test('should delegate takeDualShot call to repository and return DualShotResult', () async {
    // Arrange
    when(() => mockRepository.takeDualShot(
          layoutConfig: any(named: 'layoutConfig'),
          screenSize: any(named: 'screenSize'),
        )).thenAnswer((_) async => Right(tDualShotResult));

    // Act
    final result = await useCase(
      const TakeDualShotParams(
        layoutConfig: tLayoutConfig,
        screenSize: tScreenSize,
      ),
    );

    // Assert
    expect(result, Right<Failure, DualShotResult>(tDualShotResult));
    verify(() => mockRepository.takeDualShot(
          layoutConfig: tLayoutConfig,
          screenSize: tScreenSize,
        )).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
