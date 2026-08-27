import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    required this.isDrawing,
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
      isDrawing: false,
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
  final bool isDrawing;
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
    bool? isDrawing,
    CanvasPoint? dragStart,
    CanvasPoint? dragEnd,
    bool clearDragStart = false,
  }) {
    return EditorState(
      document: document ?? this.document,
      palette: palette ?? this.palette,
      selectedColorIndex: selectedColorIndex ?? this.selectedColorIndex,
      tool: tool ?? this.tool,
      mirrorX: mirrorX ?? this.mirrorX,
      mirrorY: mirrorY ?? this.mirrorY,
      prompt: prompt ?? this.prompt,
      seed: seed ?? this.seed,
      isDrawing: isDrawing ?? this.isDrawing,
      dragStart: clearDragStart ? null : dragStart ?? this.dragStart,
      dragEnd: clearDragStart ? null : dragEnd ?? this.dragEnd,
    );
  }
}

class EditorController extends Notifier<EditorState> {
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

  void setSize(int size) {
    state = state.copyWith(document: state.document.resized(size));
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
        final color = state.document.pixelAt(point.x, point.y);
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
    final prompt = state.prompt.toLowerCase();
    final random = math.Random(
      state.seed + prompt.codeUnits.fold(0, (a, b) => a + b),
    );
    final pixels = List<int?>.filled(
      state.document.size * state.document.size,
      null,
    );
    final size = state.document.size;
    final center = (size - 1) / 2;

    final palette = _paletteForPrompt(prompt);
    final body = palette.$1;
    final shade = palette.$2;
    final accent = palette.$3;

    for (var y = 2; y < size - 1; y++) {
      final t = y / (size - 1);
      final widthCurve = prompt.contains('ship') || prompt.contains('car')
          ? math.sin(t * math.pi) * 0.45 + 0.18
          : math.sin(t * math.pi) * 0.34 + 0.12;
      final halfWidth = (size * widthCurve + random.nextDouble() * 1.5).round();

      for (var x = 0; x < size; x++) {
        if ((x - center).abs() <= halfWidth) {
          pixels[y * size + x] = y > size * 0.62 ? shade : body;
        }
      }
    }

    for (var y = 1; y < size - 1; y++) {
      for (var x = 1; x < size - 1; x++) {
        final index = y * size + x;
        if (pixels[index] != null) {
          continue;
        }
        final touchesBody = [
          pixels[(y - 1) * size + x],
          pixels[(y + 1) * size + x],
          pixels[y * size + x - 1],
          pixels[y * size + x + 1],
        ].any((value) => value != null);
        if (touchesBody) {
          pixels[index] = 0;
        }
      }
    }

    if (!prompt.contains('ship') && !prompt.contains('car') && size >= 16) {
      final eyeY = (size * 0.36).round();
      pixels[eyeY * size + (center - 2).round()] = accent;
      pixels[eyeY * size + (center + 2).round()] = accent;
    }

    state = state.copyWith(
      document: state.document.copyWith(
        name: prompt.isEmpty ? 'Generated sprite' : prompt,
        pixels: pixels,
      ),
    );
  }

  (int, int, int) _paletteForPrompt(String prompt) {
    if (prompt.contains('fire') || prompt.contains('dragon')) {
      return (3, 2, 4);
    }
    if (prompt.contains('water') || prompt.contains('ice')) {
      return (10, 9, 11);
    }
    if (prompt.contains('toxic') || prompt.contains('slime')) {
      return (6, 7, 5);
    }
    if (prompt.contains('shadow') || prompt.contains('ghost')) {
      return (8, 1, 12);
    }
    return (6, 14, 12);
  }

  void _writePoint(CanvasPoint point, int? value) {
    _writePoints(_mirroredPoints(point), value);
  }

  void _writePoints(Iterable<CanvasPoint> points, int? value) {
    final document = state.document;
    final pixels = [...document.pixels];

    for (final point in points) {
      if (_isInBounds(point)) {
        pixels[point.y * document.size + point.x] = value;
      }
    }

    state = state.copyWith(document: document.copyWith(pixels: pixels));
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
    final target = document.pixelAt(point.x, point.y);
    final replacement = state.selectedColorIndex;

    if (target == replacement) {
      return;
    }

    final pixels = [...document.pixels];
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

    state = state.copyWith(document: document.copyWith(pixels: pixels));
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
