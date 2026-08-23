import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicySheet extends StatelessWidget {
  const PrivacyPolicySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12121A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const PrivacyPolicySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, mediaQuery.padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFFB800).withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFFFFB800),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'DualShots • Last Updated: August 2026',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),

          // Scrollable privacy content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key Highlight Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00E676).withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF00E676),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '100% On-Device & Zero Data Collection',
                                style: TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'DualShots operates entirely offline. None of your photos, camera feeds, audio, or personal information are ever collected, transmitted, or stored on external servers.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  _buildSection(
                    icon: Icons.camera_alt_outlined,
                    title: '1. Camera & Microphone Permissions',
                    body:
                        '• Camera Access (android.permission.CAMERA):\nRequired strictly to display live viewfinders and capture pictures from the front and rear lenses simultaneously. All frame processing occurs in device memory.\n\n• Microphone Access (android.permission.RECORD_AUDIO):\nMay be requested by low-level Android camera framework APIs. DualShots does not record, listen to, or transmit any audio.',
                  ),

                  _buildSection(
                    icon: Icons.photo_library_outlined,
                    title: '2. Storage & Gallery Access',
                    body:
                        '• Photos & Media (READ_MEDIA_IMAGES / WRITE_EXTERNAL_STORAGE):\nUsed solely to save your composited Dual Shot pictures directly into your device\'s local gallery under the "DualShots" album. The app does not scan or upload your existing private photo library.',
                  ),

                  _buildSection(
                    icon: Icons.memory_rounded,
                    title: '3. Image Processing & Stitching',
                    body:
                        'All image composition, Picture-in-Picture blending, and EXIF tagging are executed locally on your phone hardware inside an isolated background thread. No third-party cloud processing or artificial intelligence API endpoints are utilized.',
                  ),

                  _buildSection(
                    icon: Icons.block_flipped,
                    title: '4. Third-Party Services & Analytics',
                    body:
                        'DualShots does NOT integrate any third-party tracking SDKs, telemetry libraries, advertising networks, or analytics tools (such as Google Analytics, Firebase Analytics, or Facebook SDK).',
                  ),

                  _buildSection(
                    icon: Icons.child_care_rounded,
                    title: '5. Children\'s Privacy & COPPA Compliance',
                    body:
                        'Because DualShots does not collect, retain, or transmit any personal identifiable information, it complies fully with COPPA (Children\'s Online Privacy Protection Act) and the Google Play Families Policy.',
                  ),

                  _buildSection(
                    icon: Icons.delete_outline_rounded,
                    title: '6. Data Control & Deletion',
                    body:
                        'You retain complete ownership over all created photos. You may delete any saved photos at any time through your phone\'s Gallery application or file manager.',
                  ),

                  _buildSection(
                    icon: Icons.mail_outline_rounded,
                    title: '7. Developer Contact',
                    body:
                        'If you have any questions or feedback regarding this Privacy Policy or your data security, please contact us at:\nsupport@dualshots.app',
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSection({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFFB800), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
