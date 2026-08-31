import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../models/palette.dart';
import '../models/sprite.dart';

class PngExporter {
  const PngExporter();

  Uint8List exportActiveFrame(
    SpriteDocument document,
    SpritePalette palette, {
    int scale = 8,
  }) {
    final image = _frameImage(document.activeFrame, document.size, palette);
    return img.encodePng(_scale(image, scale));
  }

  Uint8List exportSpriteSheet(
    SpriteDocument document,
    SpritePalette palette, {
    int scale = 8,
  }) {
    final sheet = img.Image(
      width: document.size * document.frames.length,
      height: document.size,
      numChannels: 4,
    );

    for (
      var frameIndex = 0;
      frameIndex < document.frames.length;
      frameIndex++
    ) {
      final pixels = document.frames[frameIndex].compositePixels(document.size);
      for (var y = 0; y < document.size; y++) {
        for (var x = 0; x < document.size; x++) {
          _setPixel(
            sheet,
            x + frameIndex * document.size,
            y,
            pixels[y * document.size + x],
            palette,
          );
        }
      }
    }

    return img.encodePng(_scale(sheet, scale));
  }

  img.Image _frameImage(SpriteFrame frame, int size, SpritePalette palette) {
    final image = img.Image(width: size, height: size, numChannels: 4);
    final pixels = frame.compositePixels(size);
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        _setPixel(image, x, y, pixels[y * size + x], palette);
      }
    }
    return image;
  }

  img.Image _scale(img.Image image, int scale) {
    final safeScale = scale.clamp(1, 64);
    if (safeScale == 1) {
      return image;
    }
    return img.copyResize(
      image,
      width: image.width * safeScale,
      height: image.height * safeScale,
      interpolation: img.Interpolation.nearest,
    );
  }

  void _setPixel(
    img.Image image,
    int x,
    int y,
    int? paletteIndex,
    SpritePalette palette,
  ) {
    if (paletteIndex == null) {
      image.setPixelRgba(x, y, 0, 0, 0, 0);
      return;
    }

    final color = palette.colors[paletteIndex].toARGB32();
    image.setPixelRgba(
      x,
      y,
      (color >> 16) & 0xff,
      (color >> 8) & 0xff,
      color & 0xff,
      255,
    );
  }
}
