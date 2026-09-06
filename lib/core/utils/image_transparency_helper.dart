import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

/// Helper to automatically remove white or near-white opaque backgrounds from
/// uploaded logos, converting them into transparent PNGs so they look seamless
/// in both Dark Mode and Light Mode.
class ImageTransparencyHelper {
  /// Checks whether a color is considered "neutral light/white background".
  /// Neutral white/light colors have high R, G, B channels and low saturation/variance.
  static bool isLightBackground(
    int r,
    int g,
    int b,
    int a, {
    int threshold = 215,
    int maxColorDiff = 25,
  }) {
    // If already transparent or semi-transparent, treat as background
    if (a < 30) return true;

    // Must be bright enough
    if (r < threshold || g < threshold || b < threshold) return false;

    // Must be near-neutral (low color difference between channels)
    final rg = (r - g).abs();
    final gb = (g - b).abs();
    final rb = (r - b).abs();
    return rg <= maxColorDiff && gb <= maxColorDiff && rb <= maxColorDiff;
  }

  /// Processes [rawBytes] of an image (PNG, JPEG, WebP) and removes any
  /// outer contiguous white/light background using a boundary flood-fill (BFS).
  ///
  /// Returns transparent PNG byte data.
  static Future<Uint8List> makeBackgroundTransparent(
    Uint8List rawBytes, {
    int whiteThreshold = 215,
    int maxColorDiff = 25,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(rawBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final int width = image.width;
      final int height = image.height;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return rawBytes;

      final Uint8List pixels = byteData.buffer.asUint8List();
      final int totalPixels = width * height;

      // Check if corners are light background. If none are light, the image doesn't
      // have a light background (e.g. it's already dark or a full photo), so preserve it.
      int lightCorners = 0;
      final cornerIndices = [
        0, // top-left
        (width - 1), // top-right
        (height - 1) * width, // bottom-left
        (height - 1) * width + (width - 1), // bottom-right
      ];

      for (final idx in cornerIndices) {
        final pi = idx * 4;
        if (isLightBackground(
          pixels[pi],
          pixels[pi + 1],
          pixels[pi + 2],
          pixels[pi + 3],
          threshold: whiteThreshold,
          maxColorDiff: maxColorDiff,
        )) {
          lightCorners++;
        }
      }

      // If less than 2 corners are light background, do not modify
      if (lightCorners < 2) {
        return rawBytes;
      }

      // Track visited pixels for BFS flood fill
      final Uint8List visited = Uint8List(totalPixels);
      final Queue<int> queue = Queue<int>();

      void enqueueIfLight(int x, int y) {
        if (x < 0 || x >= width || y < 0 || y >= height) return;
        final int idx = y * width + x;
        if (visited[idx] == 1) return;

        final int pi = idx * 4;
        if (isLightBackground(
          pixels[pi],
          pixels[pi + 1],
          pixels[pi + 2],
          pixels[pi + 3],
          threshold: whiteThreshold,
          maxColorDiff: maxColorDiff,
        )) {
          visited[idx] = 1;
          queue.add(idx);
        }
      }

      // Initialize flood fill queue from all outer boundaries (edges of the image)
      for (int x = 0; x < width; x++) {
        enqueueIfLight(x, 0); // top row
        enqueueIfLight(x, height - 1); // bottom row
      }
      for (int y = 0; y < height; y++) {
        enqueueIfLight(0, y); // left column
        enqueueIfLight(width - 1, y); // right column
      }

      // BFS flood fill: only erase pixels that are connected to the outside boundary!
      // This protects any white elements or white text inside the logo from being erased.
      while (queue.isNotEmpty) {
        final int current = queue.removeFirst();
        final int x = current % width;
        final int y = current ~/ width;

        // Make current pixel 100% transparent
        final int pi = current * 4;
        pixels[pi + 3] = 0; // Alpha = 0

        // Check 4-connected neighbors
        enqueueIfLight(x + 1, y);
        enqueueIfLight(x - 1, y);
        enqueueIfLight(x, y + 1);
        enqueueIfLight(x, y - 1);
      }

      // Optional edge antialiasing: feather pixels adjacent to transparent pixels
      for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
          final int idx = y * width + x;
          final int pi = idx * 4;

          // If current pixel is not transparent, check if it's near an erased background pixel
          if (pixels[pi + 3] > 0) {
            final int r = pixels[pi];
            final int g = pixels[pi + 1];
            final int b = pixels[pi + 2];
            final int luminance = (0.299 * r + 0.587 * g + 0.114 * b).round();

            // If it's a bright transition pixel adjacent to transparent
            if (luminance > 200) {
              final bool hasTransparentNeighbor =
                  pixels[((y - 1) * width + x) * 4 + 3] == 0 ||
                  pixels[((y + 1) * width + x) * 4 + 3] == 0 ||
                  pixels[(y * width + (x - 1)) * 4 + 3] == 0 ||
                  pixels[(y * width + (x + 1)) * 4 + 3] == 0;

              if (hasTransparentNeighbor) {
                // Smoothly attenuate alpha based on how close it is to white
                final double t = ((255 - luminance) / 55.0).clamp(0.0, 1.0);
                pixels[pi + 3] = (pixels[pi + 3] * t).round();
              }
            }
          }
        }
      }

      // Decode modified pixels back into ui.Image
      final Completer<ui.Image> completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        pixels,
        width,
        height,
        ui.PixelFormat.rgba8888,
        (ui.Image result) => completer.complete(result),
      );

      final ui.Image newImage = await completer.future;
      final ByteData? pngByteData =
          await newImage.toByteData(format: ui.ImageByteFormat.png);

      if (pngByteData == null) return rawBytes;
      return pngByteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error making background transparent: $e');
      return rawBytes;
    }
  }

  /// Takes raw image bytes from picker, makes the background transparent,
  /// and returns a web-and-mobile safe Data URL (`data:image/png;base64,...`).
  static Future<String> processLogoToDataUrl(Uint8List rawBytes) async {
    final transparentBytes = await makeBackgroundTransparent(rawBytes);
    final base64String = base64Encode(transparentBytes);
    return 'data:image/png;base64,$base64String';
  }
}
