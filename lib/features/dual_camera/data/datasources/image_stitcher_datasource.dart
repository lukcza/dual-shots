import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/pip_layout_config.dart';

abstract class IImageStitcherDataSource {
  Future<String> stitchImages({
    required String primaryPath,
    required String secondaryPath,
    required PiPLayoutConfig layoutConfig,
    required Size previewViewportSize,
  });
}

class ImageStitcherParams {
  final String primaryPath;
  final String secondaryPath;
  final String outputPath;
  final double normalizedX;
  final double normalizedY;
  final double widthRatio;
  final double aspectRatio;
  final double borderRadius;
  final double borderWidth;
  final bool isMirrored;
  final double viewportWidth;
  final double viewportHeight;

  const ImageStitcherParams({
    required this.primaryPath,
    required this.secondaryPath,
    required this.outputPath,
    required this.normalizedX,
    required this.normalizedY,
    required this.widthRatio,
    required this.aspectRatio,
    required this.borderRadius,
    required this.borderWidth,
    required this.isMirrored,
    required this.viewportWidth,
    required this.viewportHeight,
  });
}

class ImageStitcherDataSource implements IImageStitcherDataSource {
  final Uuid _uuid = const Uuid();

  @override
  Future<String> stitchImages({
    required String primaryPath,
    required String secondaryPath,
    required PiPLayoutConfig layoutConfig,
    required Size previewViewportSize,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = p.join(
        tempDir.path,
        'dual_shot_${_uuid.v4()}.jpg',
      );

      final params = ImageStitcherParams(
        primaryPath: primaryPath,
        secondaryPath: secondaryPath,
        outputPath: outputPath,
        normalizedX: layoutConfig.normalizedX,
        normalizedY: layoutConfig.normalizedY,
        widthRatio: layoutConfig.widthRatio,
        aspectRatio: layoutConfig.aspectRatio,
        borderRadius: layoutConfig.borderRadius,
        borderWidth: layoutConfig.borderWidth,
        isMirrored: layoutConfig.isMirrored,
        viewportWidth: previewViewportSize.width > 0 ? previewViewportSize.width : 1080,
        viewportHeight: previewViewportSize.height > 0 ? previewViewportSize.height : 1920,
      );

      // Execute optimized image compositing in background Isolate
      final resultPath = await compute(_processImageStitchingInIsolate, params);
      return resultPath;
    } catch (e, stack) {
      throw StitchingException(
        'Failed to composite dual shot images in isolate',
        error: '$e\n$stack',
      );
    }
  }

  /// High-performance Isolate worker function for fast image composition
  static Future<String> _processImageStitchingInIsolate(
      ImageStitcherParams params) async {
    final primaryFile = File(params.primaryPath);
    final secondaryFile = File(params.secondaryPath);

    if (!primaryFile.existsSync() || !secondaryFile.existsSync()) {
      throw Exception('Source image files do not exist for stitching');
    }

    final primaryBytes = await primaryFile.readAsBytes();
    final secondaryBytes = await secondaryFile.readAsBytes();

    // 1. Fast decode
    img.Image? primaryImg = img.decodeImage(primaryBytes);
    img.Image? secondaryImg = img.decodeImage(secondaryBytes);

    if (primaryImg == null || secondaryImg == null) {
      throw Exception('Failed to decode image bytes');
    }

    // Orientations
    primaryImg = img.bakeOrientation(primaryImg);
    secondaryImg = img.bakeOrientation(secondaryImg);

    // 2. Downscale primary if ultra-high res (e.g. 48MP/12MP) to 1920p for instant processing
    if (primaryImg.height > 1920 || primaryImg.width > 1920) {
      if (primaryImg.height >= primaryImg.width) {
        primaryImg = img.copyResize(primaryImg, height: 1920);
      } else {
        primaryImg = img.copyResize(primaryImg, width: 1920);
      }
    }

    // 3. Mirror secondary image if requested (selfie camera)
    if (params.isMirrored) {
      secondaryImg = img.flipHorizontal(secondaryImg);
    }

    final mainWidth = primaryImg.width;
    final mainHeight = primaryImg.height;

    // PiP window width relative to main image
    final pipWidth = (mainWidth * params.widthRatio).round().clamp(100, mainWidth);
    final pipHeight = (pipWidth / params.aspectRatio).round().clamp(100, mainHeight);

    // Center crop & resize secondary image to match PiP dimensions
    final croppedSecondary = _cropAndResizeToCover(
      secondaryImg,
      targetWidth: pipWidth,
      targetHeight: pipHeight,
    );

    // 4. Style PiP with white border and rounded corners
    final int scaledRadius = (params.borderRadius * (pipWidth / 350.0))
        .clamp(4.0, (pipWidth / 4))
        .round();
    final int scaledBorder = (params.borderWidth * (pipWidth / 350.0))
        .clamp(2.0, 10.0)
        .round();

    final styledPip = _applyRoundedCornersFast(
      croppedSecondary,
      radius: scaledRadius,
      borderWidth: scaledBorder,
    );

    // 5. Destination coordinates on main image
    final int destX = (params.normalizedX * (mainWidth - styledPip.width))
        .round()
        .clamp(0, math.max(0, mainWidth - styledPip.width))
        .toInt();
    final int destY = (params.normalizedY * (mainHeight - styledPip.height))
        .round()
        .clamp(0, math.max(0, mainHeight - styledPip.height))
        .toInt();

    // 6. Alpha-blend PiP onto primary background
    img.compositeImage(
      primaryImg,
      styledPip,
      dstX: destX,
      dstY: destY,
      blend: img.BlendMode.alpha,
    );

    // 7. High speed JPEG encoding
    final encodedJpg = img.encodeJpg(primaryImg, quality: 92);

    final outputFile = File(params.outputPath);
    await outputFile.writeAsBytes(encodedJpg);

    return params.outputPath;
  }

  /// Crops image to target aspect ratio and resizes
  static img.Image _cropAndResizeToCover(
    img.Image src, {
    required int targetWidth,
    required int targetHeight,
  }) {
    final srcRatio = src.width / src.height;
    final targetRatio = targetWidth / targetHeight;

    int cropX = 0;
    int cropY = 0;
    int cropW = src.width;
    int cropH = src.height;

    if (srcRatio > targetRatio) {
      cropW = (src.height * targetRatio).round();
      cropX = ((src.width - cropW) / 2).round();
    } else {
      cropH = (src.width / targetRatio).round();
      cropY = ((src.height - cropH) / 2).round();
    }

    final cropped = img.copyCrop(
      src,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    return img.copyResize(
      cropped,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  /// Ultra-fast rounded corners and border algorithm (operates only on corner bounds)
  static img.Image _applyRoundedCornersFast(
    img.Image source, {
    required int radius,
    required int borderWidth,
  }) {
    final width = source.width;
    final height = source.height;

    final output = img.Image(
      width: width,
      height: height,
      numChannels: 4,
    );

    // Copy source buffer directly (O(1) block copy)
    img.compositeImage(output, source);

    final whiteColor = img.ColorRgba8(255, 255, 255, 255);
    final transparentColor = img.ColorRgba8(0, 0, 0, 0);

    // 1. Draw outer 4 border strips
    img.fillRect(output, x1: 0, y1: 0, x2: width, y2: borderWidth, color: whiteColor);
    img.fillRect(output, x1: 0, y1: height - borderWidth, x2: width, y2: height, color: whiteColor);
    img.fillRect(output, x1: 0, y1: 0, x2: borderWidth, y2: height, color: whiteColor);
    img.fillRect(output, x1: width - borderWidth, y1: 0, x2: width, y2: height, color: whiteColor);

    // 2. Clear only the 4 corner zones with smooth circular arc
    if (radius > 0) {
      final rSquared = radius * radius;
      for (int dy = 0; dy < radius; dy++) {
        for (int dx = 0; dx < radius; dx++) {
          final distSq = (radius - dx) * (radius - dx) + (radius - dy) * (radius - dy);
          if (distSq > rSquared) {
            // Top-Left corner
            output.setPixel(dx, dy, transparentColor);
            // Top-Right corner
            output.setPixel(width - 1 - dx, dy, transparentColor);
            // Bottom-Left corner
            output.setPixel(dx, height - 1 - dy, transparentColor);
            // Bottom-Right corner
            output.setPixel(width - 1 - dx, height - 1 - dy, transparentColor);
          } else if (distSq > (radius - borderWidth) * (radius - borderWidth)) {
            // Rounded border stroke
            output.setPixel(dx, dy, whiteColor);
            output.setPixel(width - 1 - dx, dy, whiteColor);
            output.setPixel(dx, height - 1 - dy, whiteColor);
            output.setPixel(width - 1 - dx, height - 1 - dy, whiteColor);
          }
        }
      }
    }

    return output;
  }
}
