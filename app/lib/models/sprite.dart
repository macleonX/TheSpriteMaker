import 'dart:math' as math;

enum SpriteTool { pencil, eraser, fill, eyedropper, line, rectangle }

class SpriteDocument {
  const SpriteDocument({
    required this.name,
    required this.size,
    required this.pixels,
  });

  factory SpriteDocument.blank({int size = 16}) {
    return SpriteDocument(
      name: 'Untitled sprite',
      size: size,
      pixels: List<int?>.filled(size * size, null),
    );
  }

  final String name;
  final int size;
  final List<int?> pixels;

  int? pixelAt(int x, int y) => pixels[y * size + x];

  SpriteDocument copyWith({String? name, int? size, List<int?>? pixels}) {
    return SpriteDocument(
      name: name ?? this.name,
      size: size ?? this.size,
      pixels: pixels ?? this.pixels,
    );
  }

  SpriteDocument resized(int nextSize) {
    final nextPixels = List<int?>.filled(nextSize * nextSize, null);
    final copySize = math.min(size, nextSize);

    for (var y = 0; y < copySize; y++) {
      for (var x = 0; x < copySize; x++) {
        nextPixels[y * nextSize + x] = pixelAt(x, y);
      }
    }

    return copyWith(size: nextSize, pixels: nextPixels);
  }
}

class CanvasPoint {
  const CanvasPoint(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) {
    return other is CanvasPoint && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}
