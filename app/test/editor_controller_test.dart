import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:the_sprite_maker/export/png_exporter.dart';
import 'package:the_sprite_maker/generator/procedural_generator.dart';
import 'package:the_sprite_maker/io/project_file.dart';
import 'package:the_sprite_maker/models/palette.dart';
import 'package:the_sprite_maker/models/sprite.dart';
import 'package:the_sprite_maker/state/editor_providers.dart';

void main() {
  late ProviderContainer container;
  late EditorController controller;

  setUp(() {
    container = ProviderContainer();
    controller = container.read(editorProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  test('pencil draws the selected color', () {
    controller.selectColor(4);
    controller.startStroke(const CanvasPoint(1, 1));

    expect(container.read(editorProvider).document.pixelAt(1, 1), 4);
  });

  test('mirror toggles draw reflected pixels', () {
    controller.toggleMirrorX();
    controller.toggleMirrorY();
    controller.startStroke(const CanvasPoint(2, 3));

    final document = container.read(editorProvider).document;
    expect(document.pixelAt(2, 3), isNotNull);
    expect(document.pixelAt(13, 3), isNotNull);
    expect(document.pixelAt(2, 12), isNotNull);
    expect(document.pixelAt(13, 12), isNotNull);
  });

  test('fill paints a contiguous region', () {
    controller.selectTool(SpriteTool.fill);
    controller.startStroke(const CanvasPoint(0, 0));

    final document = container.read(editorProvider).document;
    expect(document.pixels.whereType<int>().length, 256);
  });

  test('line tool commits the drag path', () {
    controller.selectTool(SpriteTool.line);
    controller.startStroke(const CanvasPoint(0, 0));
    controller.updateStroke(const CanvasPoint(3, 0));
    controller.finishStroke();

    final document = container.read(editorProvider).document;
    expect(document.pixelAt(0, 0), isNotNull);
    expect(document.pixelAt(1, 0), isNotNull);
    expect(document.pixelAt(2, 0), isNotNull);
    expect(document.pixelAt(3, 0), isNotNull);
  });

  test('resize keeps existing pixels inside the new canvas', () {
    controller.startStroke(const CanvasPoint(1, 1));
    controller.setSize(8);

    final document = container.read(editorProvider).document;
    expect(document.size, 8);
    expect(document.pixelAt(1, 1), isNotNull);
    expect(document.pixels.length, 64);
  });

  test(
    'generator creates deterministic pixels for the same prompt and seed',
    () {
      controller.setPrompt('fire dragon');
      controller.generate();
      final first = container.read(editorProvider).document.activeFrame.layers;

      container.dispose();
      container = ProviderContainer();
      controller = container.read(editorProvider.notifier);
      controller.setPrompt('fire dragon');
      controller.generate();

      final second = container.read(editorProvider).document.activeFrame.layers;
      expect(
        second.map((layer) => layer.pixels),
        first.map((layer) => layer.pixels),
      );
    },
  );

  test('generator creates editable named layers', () {
    controller.setPrompt('blue robot');
    controller.generate();

    final document = container.read(editorProvider).document;
    expect(document.name, 'blue robot');
    expect(document.activeFrame.layers.map((layer) => layer.name), [
      'outline',
      'base',
      'shading',
      'accent',
    ]);
    expect(document.compositePixels().whereType<int>(), isNotEmpty);
  });

  test('generator settings can force type, mood, and no outline', () {
    controller.setPrompt('plain thing');
    controller.setGeneratorArchetype(SpriteArchetype.weapon);
    controller.setPaletteMood(PaletteMood.metal);
    controller.setIncludeOutline(false);
    controller.generate();

    final document = container.read(editorProvider).document;
    final outline = document.activeFrame.layers.first;
    expect(outline.name, 'outline');
    expect(outline.pixels.whereType<int>(), isEmpty);
    expect(
      document.activeFrame.layers[1].pixels.whereType<int>(),
      contains(13),
    );
  });

  test('idle animation generation creates four editable frames', () {
    controller.setPrompt('blue robot');
    controller.setGenerationMode(GenerationMode.idleAnimation);
    controller.generate();

    final document = container.read(editorProvider).document;
    expect(document.frames, hasLength(4));
    expect(document.frames.every((frame) => frame.layers.length == 4), isTrue);
    expect(
      document.frames[0].compositePixels(document.size),
      isNot(document.frames[1].compositePixels(document.size)),
    );
  });

  test('preview playback advances without changing active frame', () {
    controller.addFrame();
    controller.addFrame();
    controller.selectFrame(1);
    controller.playPreview();
    controller.advancePreview();

    var editor = container.read(editorProvider);
    expect(editor.isPreviewPlaying, isTrue);
    expect(editor.document.activeFrameIndex, 1);
    expect(editor.previewFrameIndex, 2);

    controller.advancePreview();
    controller.stopPreview();
    editor = container.read(editorProvider);
    expect(editor.isPreviewPlaying, isFalse);
    expect(editor.previewFrameIndex, 1);
    expect(editor.document.activeFrameIndex, 1);
  });

  test('preview playback stays stopped for a single-frame document', () {
    controller.playPreview();
    controller.advancePreview();

    final editor = container.read(editorProvider);
    expect(editor.isPreviewPlaying, isFalse);
    expect(editor.previewFrameIndex, 0);
  });

  test('drawing writes to the active layer only', () {
    controller.selectColor(4);
    controller.startStroke(const CanvasPoint(1, 1));
    controller.addLayer();
    controller.selectColor(10);
    controller.startStroke(const CanvasPoint(2, 2));

    final document = container.read(editorProvider).document;
    expect(document.activeFrame.layers, hasLength(2));
    expect(document.activeFrame.layers[0].pixelAt(1, 1, document.size), 4);
    expect(document.activeFrame.layers[0].pixelAt(2, 2, document.size), isNull);
    expect(document.activeFrame.layers[1].pixelAt(2, 2, document.size), 10);
    expect(document.compositePixelAt(1, 1), 4);
    expect(document.compositePixelAt(2, 2), 10);
  });

  test('hidden layers are skipped by the composite', () {
    controller.selectColor(4);
    controller.startStroke(const CanvasPoint(1, 1));
    controller.addLayer();
    controller.selectColor(10);
    controller.startStroke(const CanvasPoint(1, 1));
    controller.setLayerVisibility(1, false);

    final document = container.read(editorProvider).document;
    expect(document.pixelAt(1, 1), 10);
    expect(document.compositePixelAt(1, 1), 4);
  });

  test('layers can move up and down in the stack', () {
    controller.addLayer();
    controller.addLayer();

    controller.selectLayer(1);
    controller.moveLayerUp();
    var document = container.read(editorProvider).document;
    expect(document.activeLayerIndex, 2);
    expect(document.activeFrame.layers[2].name, 'Layer 2');

    controller.moveLayerDown();
    document = container.read(editorProvider).document;
    expect(document.activeLayerIndex, 1);
    expect(document.activeFrame.layers[1].name, 'Layer 2');
  });

  test('merge layer down flattens active pixels into the layer below', () {
    controller.selectColor(4);
    controller.startStroke(const CanvasPoint(1, 1));
    controller.addLayer();
    controller.selectColor(10);
    controller.startStroke(const CanvasPoint(2, 2));

    controller.mergeLayerDown();

    final document = container.read(editorProvider).document;
    expect(document.activeFrame.layers, hasLength(1));
    expect(document.activeLayerIndex, 0);
    expect(document.pixelAt(1, 1), 4);
    expect(document.pixelAt(2, 2), 10);
  });

  test('duplicating a frame copies the whole layer stack', () {
    controller.startStroke(const CanvasPoint(1, 1));
    controller.addLayer();
    controller.startStroke(const CanvasPoint(2, 2));
    controller.duplicateFrame();

    final document = container.read(editorProvider).document;
    expect(document.frames, hasLength(2));
    expect(document.activeFrame.layers, hasLength(2));
    expect(document.compositePixelAt(1, 1), isNotNull);
    expect(document.compositePixelAt(2, 2), isNotNull);
  });

  test('delete frame keeps at least one editable frame', () {
    controller.addFrame();
    controller.deleteFrame();
    controller.deleteFrame();

    final document = container.read(editorProvider).document;
    expect(document.frames, hasLength(1));
    expect(document.activeFrameIndex, 0);
  });

  test('fps updates the document timing', () {
    controller.setFps(12);

    final editor = container.read(editorProvider);
    expect(editor.document.fps, 12);
    expect(editor.isDirty, isTrue);
  });

  test('project files round-trip layered sprites', () {
    controller.selectColor(4);
    controller.startStroke(const CanvasPoint(1, 1));
    controller.addLayer();
    controller.selectColor(10);
    controller.startStroke(const CanvasPoint(2, 2));

    const codec = ProjectFileCodec();
    final encoded = codec.encode(
      container.read(editorProvider).document,
      SpritePalette.pico8,
    );
    final decoded = codec.decode(encoded);

    expect(decoded.frames, hasLength(1));
    expect(decoded.activeFrame.layers, hasLength(2));
    expect(decoded.activeFrame.layers[0].pixelAt(1, 1, decoded.size), 4);
    expect(decoded.activeFrame.layers[1].pixelAt(2, 2, decoded.size), 10);
  });

  test('document edits mark the project dirty', () {
    expect(container.read(editorProvider).isDirty, isFalse);

    controller.startStroke(const CanvasPoint(1, 1));

    expect(container.read(editorProvider).isDirty, isTrue);
  });

  test('open and save metadata keeps dirty state honest', () {
    final loaded = SpriteDocument.blank(name: 'loaded');
    controller.openDocument(loaded, path: '/tmp/loaded.sprf');

    var editor = container.read(editorProvider);
    expect(editor.document.name, 'loaded');
    expect(editor.currentFilePath, '/tmp/loaded.sprf');
    expect(editor.isDirty, isFalse);

    controller.startStroke(const CanvasPoint(1, 1));
    expect(container.read(editorProvider).isDirty, isTrue);

    controller.markSaved(path: '/tmp/loaded.sprf', displayName: 'loaded.sprf');
    editor = container.read(editorProvider);
    expect(editor.currentFilePath, '/tmp/loaded.sprf');
    expect(editor.isDirty, isFalse);
  });

  test('png exporter writes active frame at nearest-neighbor scale', () {
    controller.selectColor(4);
    controller.startStroke(const CanvasPoint(1, 1));

    const exporter = PngExporter();
    final bytes = exporter.exportActiveFrame(
      container.read(editorProvider).document,
      SpritePalette.pico8,
      scale: 4,
    );
    final decoded = image.decodePng(bytes);

    expect(decoded, isNotNull);
    expect(decoded!.width, 64);
    expect(decoded.height, 64);
  });

  test('png exporter writes a horizontal sprite sheet for multiple frames', () {
    controller.startStroke(const CanvasPoint(1, 1));
    controller.addFrame();
    controller.startStroke(const CanvasPoint(2, 2));

    const exporter = PngExporter();
    final bytes = exporter.exportSpriteSheet(
      container.read(editorProvider).document,
      SpritePalette.pico8,
      scale: 2,
    );
    final decoded = image.decodePng(bytes);

    expect(decoded, isNotNull);
    expect(decoded!.width, 64);
    expect(decoded.height, 32);
  });

  test('image reference import quantizes image bytes to the active layer', () {
    final source = image.Image(width: 2, height: 2, numChannels: 4)
      ..setPixelRgba(0, 0, 255, 0, 0, 255)
      ..setPixelRgba(1, 0, 0, 0, 255, 255)
      ..setPixelRgba(0, 1, 0, 255, 0, 255)
      ..setPixelRgba(1, 1, 0, 0, 0, 0);

    controller.importReferenceImage(
      image.encodePng(source),
      displayName: 'reference.png',
    );

    final editor = container.read(editorProvider);
    expect(editor.document.activeLayer.name, 'reference');
    expect(editor.document.pixels, hasLength(256));
    expect(editor.document.pixels.whereType<int>(), isNotEmpty);
    expect(editor.isDirty, isTrue);
  });
}
