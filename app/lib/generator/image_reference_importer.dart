import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../models/palette.dart';

class ImageReferenceImporter {
  const ImageReferenceImporter();

  List<int?> importPixels({
    required List<int> bytes,
    required int size,
    required SpritePalette palette,
  }) {
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) {
      throw const FormatException('Unsupported image format');
    }

    final square = _cropSquare(decoded);
    final resized = img.copyResize(
      square,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
    );

    return [
      for (var y = 0; y < size; y++)
        for (var x = 0; x < size; x++)
          _paletteIndexForPixel(resized.getPixel(x, y), palette),
    ];
  }

  img.Image _cropSquare(img.Image source) {
    final side = math.min(source.width, source.height);
    final x = ((source.width - side) / 2).floor();
    final y = ((source.height - side) / 2).floor();
    return img.copyCrop(source, x: x, y: y, width: side, height: side);
  }

  int? _paletteIndexForPixel(img.Pixel pixel, SpritePalette palette) {
    if (pixel.a < 32) {
      return null;
    }

    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < palette.colors.length; i++) {
      final color = palette.colors[i].toARGB32();
      final dr = pixel.r - ((color >> 16) & 0xff);
      final dg = pixel.g - ((color >> 8) & 0xff);
      final db = pixel.b - (color & 0xff);
      final distance = dr * dr + dg * dg + db * db;
      if (distance < bestDistance) {
        bestDistance = distance.toDouble();
        bestIndex = i;
      }
    }

    return bestIndex;
  }
}
