import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'features/dual_camera/presentation/pages/dual_camera_screen.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for optimal camera layout
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set immersive dark UI overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F0F12),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Clean Architecture Service Locator (GetIt)
  await initServiceLocator();

  runApp(const DualShotsApp());
}

class DualShotsApp extends StatelessWidget {
  const DualShotsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dual Shots',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DualCameraScreen(),
    );
  }
}
