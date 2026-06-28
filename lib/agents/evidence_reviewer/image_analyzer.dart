import 'dart:io';
import 'dart:ui' as ui;

/// Flags raised during image analysis.
enum ImageFlag {
  tooLarge,
  mayNotBeScreenshot,
  unusuallySmallForDimensions,
}

/// Result of analyzing an uploaded image.
class ImageAnalysisResult {
  double fileSizeKB = 0;
  int width = 0;
  int height = 0;
  bool looksLikeScreenshot = false;
  List<ImageFlag> flags = [];
}

/// Analyzes uploaded screenshots for evidence quality.
///
/// Checks dimensions, file size, and aspect ratio to determine if
/// the image looks like a genuine phone screenshot.
class ImageAnalyzer {
  /// Analyze an image file and return quality assessment.
  Future<ImageAnalysisResult> analyzeImage(File imageFile) async {
    final result = ImageAnalysisResult();

    // Step 1: Check file size
    final bytes = await imageFile.length();
    result.fileSizeKB = bytes / 1024;

    if (result.fileSizeKB > 5120) {
      result.flags.add(ImageFlag.tooLarge);
    }

    // Step 2: Decode image to check dimensions
    final imageBytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    result.width = frame.image.width;
    result.height = frame.image.height;
    frame.image.dispose();

    // Step 3: Check for screenshot characteristics
    final isPortrait = result.height > result.width;
    final aspectRatio =
        result.width > 0 ? result.height / result.width : 0.0;

    // Common phone screenshot ratios: 16:9 (1.78), 19.5:9 (2.17), 20:9 (2.22)
    final isTypicalPhoneRatio = aspectRatio > 1.5 && aspectRatio < 2.5;
    result.looksLikeScreenshot = isPortrait && isTypicalPhoneRatio;

    if (!result.looksLikeScreenshot) {
      result.flags.add(ImageFlag.mayNotBeScreenshot);
    }

    // Step 4: Check for heavy compression (potentially edited)
    if (result.fileSizeKB < 20 && result.width > 500) {
      result.flags.add(ImageFlag.unusuallySmallForDimensions);
    }

    return result;
  }
}
