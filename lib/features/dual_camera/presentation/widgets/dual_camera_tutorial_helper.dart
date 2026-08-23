import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class DualCameraTutorialHelper {
  static TutorialCoachMark createTutorial({
    required BuildContext context,
    required GlobalKey flashKey,
    required GlobalKey helpKey,
    required GlobalKey pipKey,
    required GlobalKey shutterKey,
    required GlobalKey flipKey,
    required GlobalKey galleryKey,
    VoidCallback? onFinish,
  }) {
    final targets = <TargetFocus>[
      // 1. Flash Control
      TargetFocus(
        identify: "flash_target",
        keyTarget: flashKey,
        alignSkip: Alignment.bottomRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildSpeechBubble(
                title: "⚡ Flash Control",
                description:
                    "Select flash mode: Off, Auto, On, or Torch.",
                stepNumber: 1,
                totalSteps: 5,
                onNext: () => controller.next(),
                onSkip: () => controller.skip(),
              );
            },
          ),
        ],
      ),

      // 2. Draggable PiP Window
      TargetFocus(
        identify: "pip_target",
        keyTarget: pipKey,
        alignSkip: Alignment.bottomRight,
        enableOverlayTab: true,
        shape: ShapeLightFocus.RRect,
        radius: 20,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildSpeechBubble(
                title: "🤳 Draggable PiP Window",
                description:
                    "Drag the window anywhere on screen! Tap it to quickly swap cameras.",
                stepNumber: 2,
                totalSteps: 5,
                onNext: () => controller.next(),
                onSkip: () => controller.skip(),
              );
            },
          ),
        ],
      ),

      // 3. Shutter Button
      TargetFocus(
        identify: "shutter_target",
        keyTarget: shutterKey,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildSpeechBubble(
                title: "📸 Shutter Button",
                description:
                    "Tap to capture from both cameras simultaneously and merge into one shot!",
                stepNumber: 3,
                totalSteps: 5,
                onNext: () => controller.next(),
                onSkip: () => controller.skip(),
              );
            },
          ),
        ],
      ),

      // 4. Flip Cameras
      TargetFocus(
        identify: "flip_target",
        keyTarget: flipKey,
        alignSkip: Alignment.topLeft,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildSpeechBubble(
                title: "🔄 Flip Cameras",
                description:
                    "Swap the main and front selfie cameras with a single tap.",
                stepNumber: 4,
                totalSteps: 5,
                onNext: () => controller.next(),
                onSkip: () => controller.skip(),
              );
            },
          ),
        ],
      ),

      // 5. Gallery
      TargetFocus(
        identify: "gallery_target",
        keyTarget: galleryKey,
        alignSkip: Alignment.topRight,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildSpeechBubble(
                title: "🖼️ Photo Gallery",
                description:
                    "Open your device gallery to browse your saved Dual Shot photos.",
                stepNumber: 5,
                totalSteps: 5,
                isLast: true,
                onNext: () => controller.next(),
                onSkip: () => controller.skip(),
              );
            },
          ),
        ],
      ),
    ];

    return TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black.withOpacity(0.85),
      paddingFocus: 10,
      opacityShadow: 0.88,
      textSkip: "CLOSE",
      textStyleSkip: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      onFinish: onFinish,
    );
  }

  static Widget _buildSpeechBubble({
    required String title,
    required String description,
    required int stepNumber,
    required int totalSteps,
    required VoidCallback onNext,
    required VoidCallback onSkip,
    bool isLast = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFB800).withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$stepNumber / $totalSteps',
                  style: const TextStyle(
                    color: Color(0xFFFFB800),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Close / Skip Button
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white60,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                child: const Text(
                  'CLOSE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Next Button
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB800),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isLast ? 'GET STARTED!' : 'NEXT',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
