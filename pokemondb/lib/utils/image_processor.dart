import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Processes Pokemon images to remove white/near-white backgrounds and trim
/// transparent margins, producing clean icon-like artwork.
class ImageProcessor {
  static final Map<String, Uint8List> _processedCache = {};
  static final Map<String, Future<Uint8List?>> _pending = {};
  static const int _maxCacheSize = 300;

  /// Returns processed PNG bytes for the given image URL.
  /// Results are cached in memory. Returns null on failure.
  static Future<Uint8List?> getProcessedImage(String url) async {
    if (_processedCache.containsKey(url)) {
      return _processedCache[url]!;
    }

    // Deduplicate concurrent requests for the same URL
    if (_pending.containsKey(url)) {
      return _pending[url];
    }

    final future = _processImageFromUrl(url);
    _pending[url] = future;
    try {
      final result = await future;
      if (result != null) {
        // Evict oldest entries if cache is full
        if (_processedCache.length >= _maxCacheSize) {
          final keysToRemove = _processedCache.keys
              .take(_processedCache.length - _maxCacheSize + 50)
              .toList();
          for (final key in keysToRemove) {
            _processedCache.remove(key);
          }
        }
        _processedCache[url] = result;
      }
      return result;
    } finally {
      _pending.remove(url);
    }
  }

  static Future<Uint8List?> _processImageFromUrl(String url) async {
    try {
      // Download image
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      // Decode image to get raw pixels
      final codec = await ui.instantiateImageCodec(response.bodyBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;

      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;

      final pixels = byteData.buffer.asUint8List();

      // Run pixel processing in a separate isolate
      final result = await compute(_processPixels, _ProcessingInput(
        pixels: Uint8List.fromList(pixels),
        width: width,
        height: height,
      ));

      if (result == null) return null;

      // Reconstruct a dart:ui Image from the processed pixels
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        result.pixels,
        result.width,
        result.height,
        ui.PixelFormat.rgba8888,
        completer.complete,
      );
      final processedImage = await completer.future;

      // Encode back to PNG
      final pngData =
          await processedImage.toByteData(format: ui.ImageByteFormat.png);
      if (pngData == null) return null;

      return pngData.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  /// Pure pixel-processing function that runs in an isolate.
  /// Removes white/near-white backgrounds and trims transparent margins.
  static _ProcessingOutput? _processPixels(_ProcessingInput input) {
    final pixels = input.pixels;
    final width = input.width;
    final height = input.height;
    const int whiteThreshold = 230;
    const int alphaThreshold = 10;
    const int margin = 2;

    // Step 1: Remove white/near-white background pixels.
    // Use a soft fade so edges don't look harsh.
    for (int i = 0; i < pixels.length; i += 4) {
      final r = pixels[i];
      final g = pixels[i + 1];
      final b = pixels[i + 2];
      final a = pixels[i + 3];

      if (a == 0) continue; // Already transparent

      final avg = (r + g + b) ~/ 3;
      // Check if pixel is near-white (all channels above threshold)
      if (r >= whiteThreshold && g >= whiteThreshold && b >= whiteThreshold) {
        // Smoothly fade: the whiter it is, the more transparent it becomes
        final whiteness = avg / 255.0;
        // Map whiteness from [threshold/255..1] to alpha [original..0]
        final t = ((whiteness - whiteThreshold / 255.0) /
                (1.0 - whiteThreshold / 255.0))
            .clamp(0.0, 1.0);
        final newAlpha = (a * (1.0 - t)).round().clamp(0, 255);
        pixels[i + 3] = newAlpha;
      }
    }

    // Step 2: Find bounding box of non-transparent pixels
    int minX = width, minY = height, maxX = 0, maxY = 0;
    bool hasContent = false;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = (y * width + x) * 4;
        if (pixels[idx + 3] > alphaThreshold) {
          hasContent = true;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (!hasContent) return null;

    // Step 3: Crop to bounding box with a small margin
    minX = (minX - margin).clamp(0, width - 1);
    minY = (minY - margin).clamp(0, height - 1);
    maxX = (maxX + margin).clamp(0, width - 1);
    maxY = (maxY + margin).clamp(0, height - 1);

    final cropWidth = maxX - minX + 1;
    final cropHeight = maxY - minY + 1;
    final cropped = Uint8List(cropWidth * cropHeight * 4);

    for (int y = 0; y < cropHeight; y++) {
      final srcStart = ((minY + y) * width + minX) * 4;
      final dstStart = y * cropWidth * 4;
      cropped.setRange(dstStart, dstStart + cropWidth * 4, pixels, srcStart);
    }

    return _ProcessingOutput(
      pixels: cropped,
      width: cropWidth,
      height: cropHeight,
    );
  }

  static void clearCache() {
    _processedCache.clear();
  }
}

class _ProcessingInput {
  final Uint8List pixels;
  final int width;
  final int height;

  const _ProcessingInput({
    required this.pixels,
    required this.width,
    required this.height,
  });
}

class _ProcessingOutput {
  final Uint8List pixels;
  final int width;
  final int height;

  const _ProcessingOutput({
    required this.pixels,
    required this.width,
    required this.height,
  });
}
