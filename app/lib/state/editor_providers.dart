import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generator/image_reference_importer.dart';
import '../generator/procedural_generator.dart';
import '../models/palette.dart';
import '../models/sprite.dart';

final editorProvider = NotifierProvider<EditorController, EditorState>(
  EditorController.new,
);

class EditorState {
  const EditorState({
    required this.document,
    required this.palette,
    required this.selectedColorIndex,
    required this.tool,
    required this.mirrorX,
    required this.mirrorY,
    required this.prompt,
    required this.seed,
    required this.generatorArchetype,
    required this.paletteMood,
    required this.generationMode,
    required this.includeOutline,
    required this.isPreviewPlaying,
    required this.previewFrameIndex,
    required this.isDrawing,
    required this.isDirty,
    this.currentFilePath,
    this.statusMessage,
    this.dragStart,
    this.dragEnd,
  });

  factory EditorState.initial() {
    return EditorState(
      document: SpriteDocument.blank(),
      palette: SpritePalette.pico8,
      selectedColorIndex: 3,
      tool: SpriteTool.pencil,
      mirrorX: false,
      mirrorY: false,
      prompt: 'dragon',
      seed: 1208,
      generatorArchetype: null,
      paletteMood: PaletteMood.auto,
      generationMode: GenerationMode.singleFrame,
      includeOutline: true,
      isPreviewPlaying: false,
      previewFrameIndex: 0,
      isDrawing: false,
      isDirty: false,
    );
  }

  final SpriteDocument document;
  final SpritePalette palette;
  final int selectedColorIndex;
  final SpriteTool tool;
  final bool mirrorX;
  final bool mirrorY;
  final String prompt;
  final int seed;
  final SpriteArchetype? generatorArchetype;
  final PaletteMood paletteMood;
  final GenerationMode generationMode;
  final bool includeOutline;
  final bool isPreviewPlaying;
  final int previewFrameIndex;
  final bool isDrawing;
  final bool isDirty;
  final String? currentFilePath;
  final String? statusMessage;
  final CanvasPoint? dragStart;
  final CanvasPoint? dragEnd;

  EditorState copyWith({
    SpriteDocument? document,
    SpritePalette? palette,
    int? selectedColorIndex,
    SpriteTool? tool,
    bool? mirrorX,
    bool? mirrorY,
    String? prompt,
    int? seed,
    SpriteArchetype? generatorArchetype,
    PaletteMood? paletteMood,
    GenerationMode? generationMode,
    bool? includeOutline,
    bool? isPreviewPlaying,
    int? previewFrameIndex,
    bool? isDrawing,
    bool? isDirty,
    String? currentFilePath,
    String? statusMessage,
    CanvasPoint? dragStart,
    CanvasPoint? dragEnd,
    bool clearCurrentFilePath = false,
    bool clearStatusMessage = false,
    bool clearGeneratorArchetype = false,
    bool clearDragStart = false,
  }) {
    final nextDocument = document ?? this.document;
    final nextPreviewFrameIndex = (previewFrameIndex ?? this.previewFrameIndex)
        .clamp(0, nextDocument.frames.length - 1);

    return EditorState(
      document: nextDocument,
      palette: palette ?? this.palette,
      selectedColorIndex: selectedColorIndex ?? this.selectedColorIndex,
      tool: tool ?? this.tool,
      mirrorX: mirrorX ?? this.mirrorX,
      mirrorY: mirrorY ?? this.mirrorY,
      prompt: prompt ?? this.prompt,
      seed: seed ?? this.seed,
      generatorArchetype: clearGeneratorArchetype
          ? null
          : generatorArchetype ?? this.generatorArchetype,
      paletteMood: paletteMood ?? this.paletteMood,
      generationMode: generationMode ?? this.generationMode,
      includeOutline: includeOutline ?? this.includeOutline,
      isPreviewPlaying: isPreviewPlaying ?? this.isPreviewPlaying,
      previewFrameIndex: nextPreviewFrameIndex,
      isDrawing: isDrawing ?? this.isDrawing,
      isDirty: isDirty ?? this.isDirty,
      currentFilePath: clearCurrentFilePath
          ? null
          : currentFilePath ?? this.currentFilePath,
      statusMessage: clearStatusMessage
          ? null
          : statusMessage ?? this.statusMessage,
      dragStart: clearDragStart ? null : dragStart ?? this.dragStart,
      dragEnd: clearDragStart ? null : dragEnd ?? this.dragEnd,
    );
  }
}

class EditorController extends Notifier<EditorState> {
  static const _generator = ProceduralGenerator();
  static const _referenceImporter = ImageReferenceImporter();

  @override
  EditorState build() => EditorState.initial();

  void selectTool(SpriteTool tool) {
    state = state.copyWith(tool: tool);
  }

  void selectColor(int index) {
    state = state.copyWith(selectedColorIndex: index, tool: SpriteTool.pencil);
  }

  void setPrompt(String prompt) {
    state = state.copyWith(prompt: prompt);
  }

  void rerollSeed() {
    state = state.copyWith(seed: math.Random().nextInt(999999));
  }

  void setGeneratorArchetype(SpriteArchetype? archetype) {
    state = state.copyWith(
      generatorArchetype: archetype,
      clearGeneratorArchetype: archetype == null,
    );
  }

  void setPaletteMood(PaletteMood mood) {
    state = state.copyWith(paletteMood: mood);
  }

  void setGenerationMode(GenerationMode mode) {
    state = state.copyWith(generationMode: mode);
  }

  void setIncludeOutline(bool includeOutline) {
    state = state.copyWith(includeOutline: includeOutline);
  }

  void playPreview() {
    if (state.document.frames.length <= 1) {
      state = state.copyWith(
        isPreviewPlaying: false,
        previewFrameIndex: state.document.activeFrameIndex,
      );
      return;
    }

    state = state.copyWith(
      isPreviewPlaying: true,
      previewFrameIndex: state.document.activeFrameIndex,
    );
  }

  void stopPreview() {
    state = state.copyWith(
      isPreviewPlaying: false,
      previewFrameIndex: state.document.activeFrameIndex,
    );
  }

  void advancePreview() {
    final frameCount = state.document.frames.length;
    if (!state.isPreviewPlaying || frameCount <= 1) {
      return;
    }
    state = state.copyWith(
      previewFrameIndex: (state.previewFrameIndex + 1) % frameCount,
    );
  }

  void setSize(int size) {
    state = state.copyWith(
      document: state.document.resized(size),
      isDirty: true,
      clearStatusMessage: true,
    );
  }

  void newDocument() {
    state = state.copyWith(
      document: SpriteDocument.blank(),
      isDirty: false,
      clearCurrentFilePath: true,
      isPreviewPlaying: false,
      previewFrameIndex: 0,
      statusMessage: 'New project ready',
    );
  }

  void openDocument(SpriteDocument document, {String? path}) {
    state = state.copyWith(
      document: document,
      isDirty: false,
      currentFilePath: path,
      clearCurrentFilePath: path == null,
      isPreviewPlaying: false,
      previewFrameIndex: 0,
      statusMessage: 'Opened ${document.name}',
    );
  }

  void markSaved({String? path, String? displayName}) {
    state = state.copyWith(
      isDirty: false,
      currentFilePath: path,
      clearCurrentFilePath: path == null,
      statusMessage: 'Saved ${displayName ?? state.document.name}',
    );
  }

  void addLayer() {
    state = state.copyWith(
      document: state.document.addLayer(),
      isDirty: true,
      clearStatusMessage: true,
    );
  }

  void duplicateLayer() {
    state = state.copyWith(
      document: state.document.duplicateLayer(),
      isDirty: true,
      clearStatusMessage: true,
    );
  }

  void deleteLayer() {
    state = state.copyWith(
      document: state.document.deleteLayer(),
      isDirty: true,
      clearStatusMessage: true,
    );
  }

  void moveLayerUp() {
    state = state.copyWith(
      document: state.document.moveLayerUp(),
      isDirty: true,
      clearStatusMessage: true,
    );
  }

  void moveLayerDown() {
    state = state.copyWith(
      document: state.document.moveLayerDown(),
      isDirty: true,
      clearStatusMessage: true,
    );
  }

  void mergeLayerDown() {
    state = state.copyWith(
      document: state.document.mergeLayerDown(),
      isDirty: true,
      clearStatusMessage: true,
    );
  }

  void selectLayer(int index) {
    state = state.copyWith(document: state.document.selectLayer(index));
  }

  void setLayerVisibility(int index, bool visible) {
    final document = state.document
        .selectLayer(index)
        .updateActiveLayer(visible: visible);
    state = state.copyWith(
      document: document,
      isDirty: true,
      clearStatusMessage: true,
    );
  }

  void setLayerOpacity(int index, double opacity) {
    final document = state.document
        .selectLayer(index)
        .updateActiveLayer(opacity: opacity);
    state = state.copyWith(
      document: document,
      isDirty: true,
      clearStatusMessage: true,
    );
  }

  void addFrame() {
    state = state.copyWith(
      document: state.document.addFrame(),
      isDirty: true,
      clearStatusMessage: true,
    );
  }

  void duplicateFrame() {
    state = state.copyWith(
      document: state.document.duplicateFrame(),
      isDirty: true,
      clearStatusMessage: true,
    );
  }

  void deleteFrame() {
    state = state.copyWith(
      document: state.document.deleteFrame(),
      isDirty: true,
      clearStatusMessage: true,
    );
  }

  void selectFrame(int index) {
    state = state.copyWith(
      document: state.document.selectFrame(index),
      previewFrameIndex: index,
      isPreviewPlaying: false,
    );
  }

  void setFps(int fps) {
    state = state.copyWith(
      document: state.document.setFps(fps),
      isDirty: true,
      clearStatusMessage: true,
    );
  }

  void toggleMirrorX() {
    state = state.copyWith(mirrorX: !state.mirrorX);
  }

  void toggleMirrorY() {
    state = state.copyWith(mirrorY: !state.mirrorY);
  }

  void clear() {
    state = state.copyWith(
      document: SpriteDocument.blank(size: state.document.size),
      isDirty: true,
      clearStatusMessage: true,
    );
  }

  void startStroke(CanvasPoint point) {
    switch (state.tool) {
      case SpriteTool.pencil:
      case SpriteTool.eraser:
        state = state.copyWith(isDrawing: true);
        _writePoint(
          point,
          state.tool == SpriteTool.eraser ? null : state.selectedColorIndex,
        );
      case SpriteTool.fill:
        _fill(point);
      case SpriteTool.eyedropper:
        final color = state.document.compositePixelAt(point.x, point.y);
        if (color != null) {
          state = state.copyWith(
            selectedColorIndex: color,
            tool: SpriteTool.pencil,
          );
        }
      case SpriteTool.line:
      case SpriteTool.rectangle:
        state = state.copyWith(
          isDrawing: true,
          dragStart: point,
          dragEnd: point,
        );
    }
  }

  void updateStroke(CanvasPoint point) {
    if (!state.isDrawing) {
      return;
    }

    switch (state.tool) {
      case SpriteTool.pencil:
        _writePoint(point, state.selectedColorIndex);
      case SpriteTool.eraser:
        _writePoint(point, null);
      case SpriteTool.fill:
      case SpriteTool.eyedropper:
      case SpriteTool.line:
      case SpriteTool.rectangle:
        state = state.copyWith(dragEnd: point);
    }
  }

  void finishStroke() {
    if (!state.isDrawing) {
      return;
    }

    final start = state.dragStart;
    final end = state.dragEnd ?? start;

    switch (state.tool) {
      case SpriteTool.line:
        if (start != null && end != null) {
          _writePoints(_linePoints(start, end), state.selectedColorIndex);
        }
      case SpriteTool.rectangle:
        if (start != null && end != null) {
          _writePoints(_rectanglePoints(start, end), state.selectedColorIndex);
        }
      case SpriteTool.pencil:
      case SpriteTool.eraser:
      case SpriteTool.fill:
      case SpriteTool.eyedropper:
        break;
    }

    state = state.copyWith(isDrawing: false, clearDragStart: true);
  }

  void endStroke(CanvasPoint point) {
    state = state.copyWith(dragEnd: point);
    finishStroke();
  }

  void generate() {
    final generated = _generator.generate(
      prompt: state.prompt,
      seed: state.seed,
      size: state.document.size,
      archetype: state.generatorArchetype,
      mood: state.paletteMood,
      mode: state.generationMode,
      includeOutline: state.includeOutline,
    );
    state = state.copyWith(
      document: state.document.withGeneratedFrames(
        name: generated.name,
        frames: generated.frames,
      ),
      previewFrameIndex: 0,
      isPreviewPlaying: generated.frames.length > 1,
      isDirty: true,
      clearStatusMessage: true,
    );
  }

  void importReferenceImage(List<int> bytes, {String? displayName}) {
    final pixels = _referenceImporter.importPixels(
      bytes: bytes,
      size: state.document.size,
      palette: state.palette,
    );
    final layerName = displayName == null
        ? 'reference'
        : displayName.replaceAll(RegExp(r'\.[^.]+$'), '');
    final layer = state.document.activeLayer.copyWith(
      name: layerName,
      pixels: pixels,
    );
    state = state.copyWith(
      document: state.document.withActiveLayer(layer),
      isDirty: true,
      statusMessage: 'Imported image reference',
    );
  }

  void _writePoint(CanvasPoint point, int? value) {
    _writePoints(_mirroredPoints(point), value);
  }

  void _writePoints(Iterable<CanvasPoint> points, int? value) {
    final document = state.document;
    final layer = document.activeLayer;
    final pixels = [...layer.pixels];

    for (final point in points) {
      if (_isInBounds(point)) {
        pixels[point.y * document.size + point.x] = value;
      }
    }

    state = state.copyWith(
      document: document.withActiveLayer(layer.copyWith(pixels: pixels)),
      isDirty: true,
      clearStatusMessage: true,
    );
  }

  Iterable<CanvasPoint> _mirroredPoints(CanvasPoint point) {
    final size = state.document.size;
    return {
      point,
      if (state.mirrorX) CanvasPoint(size - point.x - 1, point.y),
      if (state.mirrorY) CanvasPoint(point.x, size - point.y - 1),
      if (state.mirrorX && state.mirrorY)
        CanvasPoint(size - point.x - 1, size - point.y - 1),
    };
  }

  void _fill(CanvasPoint point) {
    final document = state.document;
    final layer = document.activeLayer;
    final target = layer.pixelAt(point.x, point.y, document.size);
    final replacement = state.selectedColorIndex;

    if (target == replacement) {
      return;
    }

    final pixels = [...layer.pixels];
    final queue = Queue<CanvasPoint>()..add(point);
    final visited = <CanvasPoint>{};

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (!_isInBounds(current) || visited.contains(current)) {
        continue;
      }
      visited.add(current);

      final index = current.y * document.size + current.x;
      if (pixels[index] != target) {
        continue;
      }

      pixels[index] = replacement;
      queue
        ..add(CanvasPoint(current.x + 1, current.y))
        ..add(CanvasPoint(current.x - 1, current.y))
        ..add(CanvasPoint(current.x, current.y + 1))
        ..add(CanvasPoint(current.x, current.y - 1));
    }

    state = state.copyWith(
      document: document.withActiveLayer(layer.copyWith(pixels: pixels)),
      isDirty: true,
      clearStatusMessage: true,
    );
  }

  bool _isInBounds(CanvasPoint point) {
    final size = state.document.size;
    return point.x >= 0 && point.x < size && point.y >= 0 && point.y < size;
  }

  Iterable<CanvasPoint> _linePoints(CanvasPoint start, CanvasPoint end) sync* {
    var x0 = start.x;
    var y0 = start.y;
    final x1 = end.x;
    final y1 = end.y;
    final dx = (x1 - x0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final dy = -(y1 - y0).abs();
    final sy = y0 < y1 ? 1 : -1;
    var error = dx + dy;

    while (true) {
      yield CanvasPoint(x0, y0);
      if (x0 == x1 && y0 == y1) {
        break;
      }
      final doubledError = 2 * error;
      if (doubledError >= dy) {
        error += dy;
        x0 += sx;
      }
      if (doubledError <= dx) {
        error += dx;
        y0 += sy;
      }
    }
  }

  Iterable<CanvasPoint> _rectanglePoints(
    CanvasPoint start,
    CanvasPoint end,
  ) sync* {
    final left = math.min(start.x, end.x);
    final right = math.max(start.x, end.x);
    final top = math.min(start.y, end.y);
    final bottom = math.max(start.y, end.y);

    for (var x = left; x <= right; x++) {
      yield CanvasPoint(x, top);
      yield CanvasPoint(x, bottom);
    }
    for (var y = top; y <= bottom; y++) {
      yield CanvasPoint(left, y);
      yield CanvasPoint(right, y);
    }
  }
}
