import 'dart:math' as math;

enum SpriteTool { pencil, eraser, fill, eyedropper, line, rectangle }

class SpriteDocument {
  const SpriteDocument({
    required this.name,
    required this.size,
    required this.frames,
    required this.activeFrameIndex,
    required this.activeLayerIndex,
    required this.fps,
  });

  factory SpriteDocument.blank({
    int size = 16,
    String name = 'Untitled sprite',
  }) {
    return SpriteDocument(
      name: name,
      size: size,
      frames: [SpriteFrame.blank(size: size)],
      activeFrameIndex: 0,
      activeLayerIndex: 0,
      fps: 6,
    );
  }

  factory SpriteDocument.fromJson(Map<String, Object?> json) {
    final size = (json['size'] as num?)?.toInt() ?? 16;
    final rawFrames = json['frames'] as List<Object?>?;
    return SpriteDocument(
      name: json['name'] as String? ?? 'Untitled sprite',
      size: size,
      frames: rawFrames == null || rawFrames.isEmpty
          ? [SpriteFrame.blank(size: size)]
          : [
              for (final frame in rawFrames)
                SpriteFrame.fromJson(frame as Map<String, Object?>, size),
            ],
      activeFrameIndex: 0,
      activeLayerIndex: 0,
      fps: (json['fps'] as num?)?.toInt() ?? 6,
    );
  }

  final String name;
  final int size;
  final List<SpriteFrame> frames;
  final int activeFrameIndex;
  final int activeLayerIndex;
  final int fps;

  SpriteFrame get activeFrame => frames[activeFrameIndex];

  SpriteLayer get activeLayer => activeFrame.layers[activeLayerIndex];

  List<int?> get pixels => activeLayer.pixels;

  int? pixelAt(int x, int y) => activeLayer.pixelAt(x, y, size);

  int? compositePixelAt(int x, int y) =>
      activeFrame.compositePixelAt(x, y, size);

  List<int?> compositePixels() => activeFrame.compositePixels(size);

  SpriteDocument copyWith({
    String? name,
    int? size,
    List<SpriteFrame>? frames,
    int? activeFrameIndex,
    int? activeLayerIndex,
    int? fps,
  }) {
    final nextFrames = frames ?? this.frames;
    final nextFrameIndex = (activeFrameIndex ?? this.activeFrameIndex).clamp(
      0,
      nextFrames.length - 1,
    );
    final nextLayerCount = nextFrames[nextFrameIndex].layers.length;
    final nextLayerIndex = (activeLayerIndex ?? this.activeLayerIndex).clamp(
      0,
      nextLayerCount - 1,
    );

    return SpriteDocument(
      name: name ?? this.name,
      size: size ?? this.size,
      frames: List.unmodifiable(nextFrames),
      activeFrameIndex: nextFrameIndex,
      activeLayerIndex: nextLayerIndex,
      fps: fps ?? this.fps,
    );
  }

  SpriteDocument resized(int nextSize) {
    return copyWith(
      size: nextSize,
      frames: [for (final frame in frames) frame.resized(size, nextSize)],
    );
  }

  SpriteDocument withActiveLayer(SpriteLayer layer) {
    final layers = [...activeFrame.layers]..[activeLayerIndex] = layer;
    return withActiveFrame(activeFrame.copyWith(layers: layers));
  }

  SpriteDocument withActiveFrame(SpriteFrame frame) {
    final nextFrames = [...frames]..[activeFrameIndex] = frame;
    return copyWith(frames: nextFrames);
  }

  SpriteDocument withGeneratedFrame({
    required String name,
    required SpriteFrame frame,
  }) {
    final nextFrames = [...frames]..[activeFrameIndex] = frame;
    return copyWith(
      name: name,
      frames: nextFrames,
      activeLayerIndex: math.max(0, frame.layers.length - 1),
    );
  }

  SpriteDocument withGeneratedFrames({
    required String name,
    required List<SpriteFrame> frames,
  }) {
    return copyWith(
      name: name,
      frames: frames,
      activeFrameIndex: 0,
      activeLayerIndex: frames.first.layers.length - 1,
    );
  }

  SpriteDocument addLayer() {
    final nextIndex = activeFrame.layers.length;
    final layers = [
      ...activeFrame.layers,
      SpriteLayer.blank(name: 'Layer ${nextIndex + 1}', size: size),
    ];
    final nextFrames = [...frames]
      ..[activeFrameIndex] = activeFrame.copyWith(layers: layers);
    return copyWith(frames: nextFrames, activeLayerIndex: nextIndex);
  }

  SpriteDocument duplicateLayer() {
    final source = activeLayer;
    final layers = [...activeFrame.layers]
      ..insert(
        activeLayerIndex + 1,
        source.copyWith(
          name: '${source.name} copy',
          pixels: [...source.pixels],
        ),
      );
    final nextFrames = [...frames]
      ..[activeFrameIndex] = activeFrame.copyWith(layers: layers);
    return copyWith(frames: nextFrames, activeLayerIndex: activeLayerIndex + 1);
  }

  SpriteDocument deleteLayer() {
    if (activeFrame.layers.length == 1) {
      return withActiveLayer(
        SpriteLayer.blank(name: activeLayer.name, size: size),
      );
    }
    final layers = [...activeFrame.layers]..removeAt(activeLayerIndex);
    final nextFrames = [...frames]
      ..[activeFrameIndex] = activeFrame.copyWith(layers: layers);
    return copyWith(
      frames: nextFrames,
      activeLayerIndex: math.max(0, activeLayerIndex - 1),
    );
  }

  SpriteDocument moveLayerUp() {
    if (activeLayerIndex >= activeFrame.layers.length - 1) {
      return this;
    }
    final layers = [...activeFrame.layers];
    final layer = layers.removeAt(activeLayerIndex);
    layers.insert(activeLayerIndex + 1, layer);
    final nextFrames = [...frames]
      ..[activeFrameIndex] = activeFrame.copyWith(layers: layers);
    return copyWith(frames: nextFrames, activeLayerIndex: activeLayerIndex + 1);
  }

  SpriteDocument moveLayerDown() {
    if (activeLayerIndex <= 0) {
      return this;
    }
    final layers = [...activeFrame.layers];
    final layer = layers.removeAt(activeLayerIndex);
    layers.insert(activeLayerIndex - 1, layer);
    final nextFrames = [...frames]
      ..[activeFrameIndex] = activeFrame.copyWith(layers: layers);
    return copyWith(frames: nextFrames, activeLayerIndex: activeLayerIndex - 1);
  }

  SpriteDocument mergeLayerDown() {
    if (activeLayerIndex <= 0) {
      return this;
    }

    final layers = [...activeFrame.layers];
    final upper = layers.removeAt(activeLayerIndex);
    final lower = layers[activeLayerIndex - 1];
    final mergedPixels = [...lower.pixels];
    if (upper.visible && upper.opacity > 0) {
      for (var i = 0; i < mergedPixels.length; i++) {
        final pixel = upper.pixels[i];
        if (pixel != null) {
          mergedPixels[i] = pixel;
        }
      }
    }
    layers[activeLayerIndex - 1] = lower.copyWith(pixels: mergedPixels);
    final nextFrames = [...frames]
      ..[activeFrameIndex] = activeFrame.copyWith(layers: layers);
    return copyWith(frames: nextFrames, activeLayerIndex: activeLayerIndex - 1);
  }

  SpriteDocument selectLayer(int index) {
    return copyWith(activeLayerIndex: index);
  }

  SpriteDocument updateActiveLayer({
    String? name,
    bool? visible,
    double? opacity,
  }) {
    return withActiveLayer(
      activeLayer.copyWith(name: name, visible: visible, opacity: opacity),
    );
  }

  SpriteDocument addFrame() {
    final frames = [...this.frames, SpriteFrame.blank(size: size)];
    return copyWith(
      frames: frames,
      activeFrameIndex: frames.length - 1,
      activeLayerIndex: 0,
    );
  }

  SpriteDocument duplicateFrame() {
    final frame = activeFrame.copyWith(
      layers: [
        for (final layer in activeFrame.layers)
          layer.copyWith(pixels: [...layer.pixels]),
      ],
    );
    final nextFrames = [...frames]..insert(activeFrameIndex + 1, frame);
    return copyWith(
      frames: nextFrames,
      activeFrameIndex: activeFrameIndex + 1,
      activeLayerIndex: activeLayerIndex,
    );
  }

  SpriteDocument deleteFrame() {
    if (frames.length == 1) {
      return copyWith(
        frames: [SpriteFrame.blank(size: size)],
        activeFrameIndex: 0,
        activeLayerIndex: 0,
      );
    }

    final nextFrames = [...frames]..removeAt(activeFrameIndex);
    return copyWith(
      frames: nextFrames,
      activeFrameIndex: math.max(0, activeFrameIndex - 1),
      activeLayerIndex: 0,
    );
  }

  SpriteDocument selectFrame(int index) {
    return copyWith(activeFrameIndex: index, activeLayerIndex: 0);
  }

  SpriteDocument setFps(int fps) {
    return copyWith(fps: fps.clamp(1, 60));
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'size': size,
      'fps': fps,
      'frames': [for (final frame in frames) frame.toJson()],
    };
  }
}

class SpriteFrame {
  const SpriteFrame({required this.layers});

  factory SpriteFrame.blank({required int size}) {
    return SpriteFrame(
      layers: [SpriteLayer.blank(name: 'base', size: size)],
    );
  }

  factory SpriteFrame.fromJson(Map<String, Object?> json, int size) {
    final rawLayers = json['layers'] as List<Object?>?;
    return SpriteFrame(
      layers: rawLayers == null || rawLayers.isEmpty
          ? [SpriteLayer.blank(name: 'base', size: size)]
          : [
              for (final layer in rawLayers)
                SpriteLayer.fromJson(layer as Map<String, Object?>, size),
            ],
    );
  }

  final List<SpriteLayer> layers;

  SpriteFrame copyWith({List<SpriteLayer>? layers}) {
    return SpriteFrame(layers: List.unmodifiable(layers ?? this.layers));
  }

  SpriteFrame resized(int oldSize, int nextSize) {
    return copyWith(
      layers: [for (final layer in layers) layer.resized(oldSize, nextSize)],
    );
  }

  int? compositePixelAt(int x, int y, int size) {
    for (var i = layers.length - 1; i >= 0; i--) {
      final layer = layers[i];
      if (!layer.visible || layer.opacity <= 0) {
        continue;
      }
      final pixel = layer.pixelAt(x, y, size);
      if (pixel != null) {
        return pixel;
      }
    }
    return null;
  }

  List<int?> compositePixels(int size) {
    return [
      for (var y = 0; y < size; y++)
        for (var x = 0; x < size; x++) compositePixelAt(x, y, size),
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'layers': [for (final layer in layers) layer.toJson()],
    };
  }
}

class SpriteLayer {
  const SpriteLayer({
    required this.name,
    required this.visible,
    required this.opacity,
    required this.pixels,
  });

  factory SpriteLayer.blank({required String name, required int size}) {
    return SpriteLayer(
      name: name,
      visible: true,
      opacity: 1,
      pixels: List<int?>.filled(size * size, null),
    );
  }

  factory SpriteLayer.fromJson(Map<String, Object?> json, int size) {
    final encoded = json['pixels'] as String?;
    return SpriteLayer(
      name: json['name'] as String? ?? 'Layer',
      visible: json['visible'] as bool? ?? true,
      opacity: ((json['opacity'] as num?)?.toDouble() ?? 1).clamp(0, 1),
      pixels: encoded == null
          ? List<int?>.filled(size * size, null)
          : _decodePixels(encoded, size * size),
    );
  }

  final String name;
  final bool visible;
  final double opacity;
  final List<int?> pixels;

  int? pixelAt(int x, int y, int size) => pixels[y * size + x];

  SpriteLayer copyWith({
    String? name,
    bool? visible,
    double? opacity,
    List<int?>? pixels,
  }) {
    return SpriteLayer(
      name: name ?? this.name,
      visible: visible ?? this.visible,
      opacity: opacity ?? this.opacity,
      pixels: List.unmodifiable(pixels ?? this.pixels),
    );
  }

  SpriteLayer resized(int oldSize, int nextSize) {
    final nextPixels = List<int?>.filled(nextSize * nextSize, null);
    final copySize = math.min(oldSize, nextSize);

    for (var y = 0; y < copySize; y++) {
      for (var x = 0; x < copySize; x++) {
        nextPixels[y * nextSize + x] = pixels[y * oldSize + x];
      }
    }

    return copyWith(pixels: nextPixels);
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'visible': visible,
      'opacity': opacity,
      'pixels': _encodePixels(pixels),
    };
  }

  static String _encodePixels(List<int?> pixels) {
    return pixels
        .map((pixel) => pixel == null ? '.' : pixel.toRadixString(16))
        .join();
  }

  static List<int?> _decodePixels(String encoded, int length) {
    final pixels = List<int?>.filled(length, null);
    for (var i = 0; i < math.min(encoded.length, length); i++) {
      final value = encoded[i];
      pixels[i] = value == '.' ? null : int.tryParse(value, radix: 16);
    }
    return pixels;
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
