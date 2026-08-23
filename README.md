# Dual Shots - Flutter Clean Architecture

Profesjonalna aplikacja mobilna typu **Dual Shot** (jednoczesne zdjęcie z przedniej i tylnej kamery) stworzona we Flutterze z wykorzystaniem zasad **Clean Architecture**, wzorca **BLoC**, sprzętowego wsparcia **Multi-Camera API** oraz zaawansowanego algorytmu **Pseudo-Dual Fallback**.

---

## 📸 Główne Funkcjonalności

1. **Wsparcie Multi-Camera & Inteligentny Fallback:**
   - **Hardware Concurrent Mode:** Obsługa sprzętowa na iOS 13+ (A12 Bionic+) oraz Android 9/11+ (`FEATURE_CAMERA_CONCURRENT`).
   - **Fast Pseudo-Dual Fallback:** Automatyczny, niewidoczny dla użytkownika fallback na starszych urządzeniach – błyskawiczne sekwencyjne ujęcie (tył -> sensor switch -> przód).
2. **Dynamiczny Picture-in-Picture (PiP):**
   - Pływające okienko PiP z płynnym gestem przeciągania (`Draggable`), automatycznym przyciąganiem do rogów ekranu oraz zaokrąglonymi rogami i obramowaniem.
   - Szybka zamiana ról kamer (Front na pełny ekran, Back w okienku) jednym dotknięciem.
3. **Przetwarzanie obrazu w tle (Isolate):**
   - Skalowanie, przycinanie z dopasowaniem aspect ratio, odbicie lustrzane dla kamery przedniej oraz kompozycja bitowa wykonywana w osobnym wątku (`Isolate.run` / `compute`), eliminując jakiekolwiek zamrożenie UI.
4. **Odporność na przerwania i cykl życia:**
   - Automatyczne zwalnianie kontrolerów kamer w tle (np. przy połączeniu telefonicznym lub minimalizacji aplikacji) oraz bezpieczna reinicjalizacja.

---

## 🏛️ Architektura Projektu (Clean Architecture)

```
lib/
├── core/
│   ├── errors/                 # Failures (CameraFailure, PermissionFailure, ImageStitchingFailure)
│   ├── platform/               # Wykrywanie wsparcia Multi-Camera (ICameraCapabilityChecker)
│   ├── services/               # Uprawnienia (PermissionService), Cykl życia (AppLifecycleManager)
│   ├── theme/                  # Stylistyka (AppTheme - Dark Camera UI)
│   ├── usecase/                # Bazowe abstrakcje UseCase oraz Either<Failure, Type>
│   └── utils/                  # Narzędzia i parametry obliczeniowe
│
├── features/
│   └── dual_camera/
│       ├── domain/             # WARSTWA BIZNESOWA (Czysty Dart, niezależny od frameworków)
│       │   ├── entities/       # DualShotResult, PiPLayoutConfig, CameraTypes
│       │   ├── repositories/   # IDualCameraRepository
│       │   └── usecases/       # CheckMultiCameraSupport, InitDualCamera, TakeDualShot, StitchDualShot, SwitchCameraRoles, DisposeCameras
│       │
│       ├── data/               # WARSTWA DANYCH
│       │   ├── datasources/    # MultiCameraDataSource, FallbackCameraDataSource, ImageStitcherDataSource
│       │   ├── models/         # DualShotModel
│       │   └── repositories/   # DualCameraRepositoryImpl
│       │
│       └── presentation/       # WARSTWA PREZENTACJI
│           ├── bloc/           # DualCameraBloc, DualCameraEvent, DualCameraState
│           ├── widgets/        # DraggablePiPView, ShutterButton, CameraOverlayControls, DualCameraPreviewViewport
│           └── pages/          # DualCameraScreen, DualShotResultPreviewScreen
│
├── injection_container.dart    # Service Locator (GetIt)
└── main.dart                   # Punkt startowy aplikacji
```

---

## 🚀 Jak Uruchomić Projekt

Wszystkie komendy wykonaj w swoim terminalu PowerShell:

### 1. Pobranie zależności
```powershell
flutter pub get
```

### 2. Uruchomienie testów jednostkowych
```powershell
flutter test
```

### 3. Uruchomienie aplikacji na urządzeniu / emulatorze
```powershell
flutter run
```
