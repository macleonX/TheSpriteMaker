import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sprite.dart';
import '../state/editor_providers.dart';

class PixelCanvas extends ConsumerWidget {
  const PixelCanvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final controller = ref.read(editorProvider.notifier);

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          CanvasPoint? pointFromPosition(Offset localPosition) {
            final side = math.min(constraints.maxWidth, constraints.maxHeight);
            final cellSize = side / editor.document.size;
            final x = (localPosition.dx / cellSize).floor();
            final y = (localPosition.dy / cellSize).floor();
            if (x < 0 ||
                y < 0 ||
                x >= editor.document.size ||
                y >= editor.document.size) {
              return null;
            }
            return CanvasPoint(x, y);
          }

          void handlePosition(
            Offset localPosition,
            void Function(CanvasPoint) action,
          ) {
            final point = pointFromPosition(localPosition);
            if (point != null) {
              action(point);
            }
          }

          return MouseRegion(
            cursor: SystemMouseCursors.precise,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) =>
                  handlePosition(details.localPosition, controller.startStroke),
              onPanUpdate: (details) => handlePosition(
                details.localPosition,
                controller.updateStroke,
              ),
              onPanEnd: (_) => controller.finishStroke(),
              onTapDown: (details) =>
                  handlePosition(details.localPosition, (point) {
                    controller.startStroke(point);
                    controller.endStroke(point);
                  }),
              child: CustomPaint(painter: PixelCanvasPainter(editor: editor)),
            ),
          );
        },
      ),
    );
  }
}

class PixelCanvasPainter extends CustomPainter {
  const PixelCanvasPainter({required this.editor});

  final EditorState editor;

  @override
  void paint(Canvas canvas, Size size) {
    final document = editor.document;
    final side = math.min(size.width, size.height);
    final origin = Offset((size.width - side) / 2, (size.height - side) / 2);
    final cellSize = side / document.size;
    final backgroundPaint = Paint()..color = const Color(0xff101819);
    final transparentPaint = Paint()..color = const Color(0xff152021);
    final gridPaint = Paint()
      ..color = const Color(0xff344344)
      ..strokeWidth = 1;

    canvas.drawRect(origin & Size.square(side), backgroundPaint);

    for (var y = 0; y < document.size; y++) {
      for (var x = 0; x < document.size; x++) {
        final rect = Rect.fromLTWH(
          origin.dx + x * cellSize,
          origin.dy + y * cellSize,
          cellSize,
          cellSize,
        );
        final pixel = document.pixelAt(x, y);
        if (pixel == null) {
          if ((x + y).isEven) {
            canvas.drawRect(rect, transparentPaint);
          }
        } else {
          canvas.drawRect(rect, Paint()..color = editor.palette.colors[pixel]);
        }
      }
    }

    for (var i = 0; i <= document.size; i++) {
      final offset = origin.dx + i * cellSize;
      canvas.drawLine(
        Offset(offset, origin.dy),
        Offset(offset, origin.dy + side),
        gridPaint,
      );
      final y = origin.dy + i * cellSize;
      canvas.drawLine(
        Offset(origin.dx, y),
        Offset(origin.dx + side, y),
        gridPaint,
      );
    }

    canvas.drawRect(
      origin & Size.square(side),
      Paint()
        ..color = const Color(0xff7e9295)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant PixelCanvasPainter oldDelegate) {
    return oldDelegate.editor != editor;
  }
}
