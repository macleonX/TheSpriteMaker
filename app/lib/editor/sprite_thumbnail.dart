import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/palette.dart';

class SpriteThumbnail extends StatelessWidget {
  const SpriteThumbnail({
    super.key,
    required this.size,
    required this.pixels,
    required this.palette,
    this.showCheckerboard = true,
    this.padding = 8,
  });

  final int size;
  final List<int?> pixels;
  final SpritePalette palette;
  final bool showCheckerboard;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SpriteThumbnailPainter(
        size: size,
        pixels: pixels,
        palette: palette,
        showCheckerboard: showCheckerboard,
        padding: padding,
      ),
    );
  }
}

class SpriteThumbnailPainter extends CustomPainter {
  const SpriteThumbnailPainter({
    required this.size,
    required this.pixels,
    required this.palette,
    required this.showCheckerboard,
    required this.padding,
  });

  final int size;
  final List<int?> pixels;
  final SpritePalette palette;
  final bool showCheckerboard;
  final double padding;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final side = math.min(
      canvasSize.width - padding * 2,
      canvasSize.height - padding * 2,
    );
    if (side <= 0) {
      return;
    }

    final origin = Offset(
      (canvasSize.width - side) / 2,
      (canvasSize.height - side) / 2,
    );
    final cellSize = side / size;

    canvas.drawRect(
      origin & Size.square(side),
      Paint()..color = const Color(0xff101827),
    );

    if (showCheckerboard) {
      final checkerPaint = Paint()..color = const Color(0xff172033);
      for (var y = 0; y < size; y++) {
        for (var x = 0; x < size; x++) {
          if ((x + y).isEven) {
            canvas.drawRect(
              Rect.fromLTWH(
                origin.dx + x * cellSize,
                origin.dy + y * cellSize,
                cellSize,
                cellSize,
              ),
              checkerPaint,
            );
          }
        }
      }
    }

    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final pixel = pixels[y * size + x];
        if (pixel == null) {
          continue;
        }
        canvas.drawRect(
          Rect.fromLTWH(
            origin.dx + x * cellSize,
            origin.dy + y * cellSize,
            cellSize,
            cellSize,
          ),
          Paint()..color = palette.colors[pixel],
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant SpriteThumbnailPainter oldDelegate) {
    return oldDelegate.size != size ||
        oldDelegate.pixels != pixels ||
        oldDelegate.palette != palette ||
        oldDelegate.showCheckerboard != showCheckerboard ||
        oldDelegate.padding != padding;
  }
}
