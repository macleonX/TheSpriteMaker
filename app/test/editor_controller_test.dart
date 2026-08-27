import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
      final first = container.read(editorProvider).document.pixels;

      container.dispose();
      container = ProviderContainer();
      controller = container.read(editorProvider.notifier);
      controller.setPrompt('fire dragon');
      controller.generate();

      expect(container.read(editorProvider).document.pixels, first);
    },
  );
}
