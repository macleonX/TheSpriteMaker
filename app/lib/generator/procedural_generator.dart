import 'dart:math' as math;

import '../models/sprite.dart';

enum SpriteArchetype { humanoid, creature, vehicle, icon, weapon }

enum PaletteMood { auto, fire, water, toxic, shadow, royal, metal, nature }

enum GenerationMode { singleFrame, idleAnimation }

class GeneratedSprite {
  const GeneratedSprite({required this.name, required this.frames});

  final String name;
  final List<SpriteFrame> frames;

  SpriteFrame get frame => frames.first;
}

class ProceduralGenerator {
  const ProceduralGenerator();

  GeneratedSprite generate({
    required String prompt,
    required int seed,
    required int size,
    SpriteArchetype? archetype,
    PaletteMood mood = PaletteMood.auto,
    GenerationMode mode = GenerationMode.singleFrame,
    bool includeOutline = true,
  }) {
    final normalized = prompt.trim().toLowerCase();
    final random = math.Random(
      seed + normalized.codeUnits.fold(0, (a, b) => a + b * 31),
    );
    final resolvedArchetype = archetype ?? _archetypeForPrompt(normalized);
    final colors = _colorsForPrompt(normalized, mood);

    final frame = _generateFrame(
      archetype: resolvedArchetype,
      size: size,
      colors: colors,
      random: random,
      includeOutline: includeOutline,
    );

    return GeneratedSprite(
      name: normalized.isEmpty ? 'Generated sprite' : normalized,
      frames: mode == GenerationMode.idleAnimation
          ? _idleFrames(frame, size)
          : [frame],
    );
  }

  SpriteFrame _generateFrame({
    required SpriteArchetype archetype,
    required int size,
    required _PromptColors colors,
    required math.Random random,
    required bool includeOutline,
  }) {
    final base = List<int?>.filled(size * size, null);
    final shadow = List<int?>.filled(size * size, null);
    final accent = List<int?>.filled(size * size, null);

    switch (archetype) {
      case SpriteArchetype.humanoid:
        _drawHumanoid(base, shadow, accent, size, colors, random);
      case SpriteArchetype.creature:
        _drawCreature(base, shadow, accent, size, colors, random);
      case SpriteArchetype.vehicle:
        _drawVehicle(base, shadow, accent, size, colors, random);
      case SpriteArchetype.icon:
        _drawIcon(base, shadow, accent, size, colors, random);
      case SpriteArchetype.weapon:
        _drawWeapon(base, shadow, accent, size, colors, random);
    }

    final outline = includeOutline
        ? _outlineFor([base, shadow, accent], size)
        : List<int?>.filled(size * size, null);
    final layers = [
      SpriteLayer(name: 'outline', visible: true, opacity: 1, pixels: outline),
      SpriteLayer(name: 'base', visible: true, opacity: 1, pixels: base),
      SpriteLayer(name: 'shading', visible: true, opacity: 1, pixels: shadow),
      SpriteLayer(name: 'accent', visible: true, opacity: 1, pixels: accent),
    ];

    return SpriteFrame(layers: layers);
  }

  SpriteArchetype _archetypeForPrompt(String prompt) {
    if (_hasAny(prompt, ['sword', 'axe', 'staff', 'wand', 'dagger', 'gun'])) {
      return SpriteArchetype.weapon;
    }
    if (_hasAny(prompt, ['ship', 'car', 'tank', 'mech', 'plane', 'rocket'])) {
      return SpriteArchetype.vehicle;
    }
    if (_hasAny(prompt, ['slime', 'wolf', 'beast', 'dragon', 'monster'])) {
      return SpriteArchetype.creature;
    }
    if (_hasAny(prompt, ['coin', 'gem', 'potion', 'heart', 'star', 'orb'])) {
      return SpriteArchetype.icon;
    }
    return SpriteArchetype.humanoid;
  }

  _PromptColors _colorsForPrompt(String prompt, PaletteMood mood) {
    switch (mood) {
      case PaletteMood.fire:
        return const _PromptColors(base: 3, shadow: 2, accent: 4);
      case PaletteMood.water:
        return const _PromptColors(base: 10, shadow: 9, accent: 11);
      case PaletteMood.toxic:
      case PaletteMood.nature:
        return const _PromptColors(base: 6, shadow: 7, accent: 5);
      case PaletteMood.shadow:
        return const _PromptColors(base: 8, shadow: 1, accent: 12);
      case PaletteMood.royal:
        return const _PromptColors(base: 2, shadow: 1, accent: 11);
      case PaletteMood.metal:
        return const _PromptColors(base: 13, shadow: 14, accent: 10);
      case PaletteMood.auto:
        break;
    }

    if (_hasAny(prompt, ['fire', 'flame', 'lava'])) {
      return const _PromptColors(base: 3, shadow: 2, accent: 4);
    }
    if (_hasAny(prompt, ['water', 'ice', 'frost', 'blue'])) {
      return const _PromptColors(base: 10, shadow: 9, accent: 11);
    }
    if (_hasAny(prompt, ['toxic', 'slime', 'forest', 'nature'])) {
      return const _PromptColors(base: 6, shadow: 7, accent: 5);
    }
    if (_hasAny(prompt, ['shadow', 'ghost', 'void', 'dark'])) {
      return const _PromptColors(base: 8, shadow: 1, accent: 12);
    }
    if (_hasAny(prompt, ['royal', 'magic', 'wizard'])) {
      return const _PromptColors(base: 2, shadow: 1, accent: 11);
    }
    if (_hasAny(prompt, ['robot', 'metal', 'armor'])) {
      return const _PromptColors(base: 13, shadow: 14, accent: 10);
    }
    return const _PromptColors(base: 6, shadow: 14, accent: 12);
  }

  List<SpriteFrame> _idleFrames(SpriteFrame source, int size) {
    return [
      source,
      _shiftLowerBody(source, size, dx: 1),
      source,
      _shiftLowerBody(source, size, dx: -1),
    ];
  }

  SpriteFrame _shiftLowerBody(SpriteFrame frame, int size, {required int dx}) {
    final splitY = (size * 0.58).round();
    return SpriteFrame(
      layers: [
        for (final layer in frame.layers)
          layer.copyWith(pixels: _shiftPixels(layer.pixels, size, splitY, dx)),
      ],
    );
  }

  List<int?> _shiftPixels(List<int?> pixels, int size, int splitY, int dx) {
    final shifted = List<int?>.filled(size * size, null);
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final value = pixels[y * size + x];
        if (value == null) {
          continue;
        }
        final nx = y >= splitY ? x + dx : x;
        if (nx >= 0 && nx < size) {
          shifted[y * size + nx] = value;
        }
      }
    }
    return shifted;
  }

  void _drawHumanoid(
    List<int?> base,
    List<int?> shadow,
    List<int?> accent,
    int size,
    _PromptColors colors,
    math.Random random,
  ) {
    final cx = size ~/ 2;
    final headTop = (size * 0.16).round();
    final headHalf = math.max(2, (size * 0.15).round());
    final bodyTop = (size * 0.40).round();
    final bodyBottom = (size * 0.72).round();

    _ellipse(
      base,
      size,
      cx,
      headTop + headHalf,
      headHalf,
      headHalf,
      colors.base,
    );
    _rect(
      base,
      size,
      cx - headHalf,
      bodyTop,
      cx + headHalf,
      bodyBottom,
      colors.base,
    );
    _rect(
      shadow,
      size,
      cx - headHalf,
      bodyBottom - 1,
      cx + headHalf,
      bodyBottom,
      colors.shadow,
    );
    _rect(
      base,
      size,
      cx - headHalf - 2,
      bodyTop + 1,
      cx - headHalf - 1,
      bodyBottom - 1,
      colors.base,
    );
    _rect(
      base,
      size,
      cx + headHalf + 1,
      bodyTop + 1,
      cx + headHalf + 2,
      bodyBottom - 1,
      colors.base,
    );
    _rect(
      base,
      size,
      cx - headHalf,
      bodyBottom + 1,
      cx - 1,
      size - 3,
      colors.base,
    );
    _rect(
      base,
      size,
      cx + 1,
      bodyBottom + 1,
      cx + headHalf,
      size - 3,
      colors.base,
    );

    final eyeY = headTop + headHalf;
    _set(accent, size, cx - math.max(1, headHalf ~/ 2), eyeY, 0);
    _set(accent, size, cx + math.max(1, headHalf ~/ 2), eyeY, 0);
    if (random.nextBool()) {
      _set(accent, size, cx + headHalf, headTop, colors.accent);
    }
  }

  void _drawCreature(
    List<int?> base,
    List<int?> shadow,
    List<int?> accent,
    int size,
    _PromptColors colors,
    math.Random random,
  ) {
    final cx = size ~/ 2;
    final cy = (size * 0.55).round();
    _ellipse(
      base,
      size,
      cx,
      cy,
      (size * 0.28).round(),
      (size * 0.22).round(),
      colors.base,
    );
    _ellipse(
      shadow,
      size,
      cx,
      cy + 2,
      (size * 0.22).round(),
      (size * 0.10).round(),
      colors.shadow,
    );
    _rect(base, size, cx - 4, cy + 3, cx - 2, size - 3, colors.base);
    _rect(base, size, cx + 2, cy + 3, cx + 4, size - 3, colors.base);

    final hornY = (size * 0.27).round();
    _set(accent, size, cx - 3, hornY, colors.accent);
    _set(accent, size, cx + 3, hornY, colors.accent);
    _set(accent, size, cx - 2, hornY + 1, colors.accent);
    _set(accent, size, cx + 2, hornY + 1, colors.accent);
    _set(accent, size, cx - 2, cy - 1, 0);
    _set(accent, size, cx + 2, cy - 1, 0);

    if (random.nextBool()) {
      _rect(accent, size, cx + 5, cy, cx + 7, cy + 1, colors.accent);
    }
  }

  void _drawVehicle(
    List<int?> base,
    List<int?> shadow,
    List<int?> accent,
    int size,
    _PromptColors colors,
    math.Random random,
  ) {
    final cx = size ~/ 2;
    final cy = size ~/ 2;
    _rect(base, size, cx - 5, cy - 2, cx + 5, cy + 3, colors.base);
    _rect(base, size, cx - 3, cy - 5, cx + 3, cy - 2, colors.base);
    _rect(shadow, size, cx - 5, cy + 2, cx + 5, cy + 3, colors.shadow);
    _rect(accent, size, cx - 2, cy - 4, cx + 2, cy - 3, colors.accent);
    _set(accent, size, cx - 5, cy + 4, 0);
    _set(accent, size, cx + 5, cy + 4, 0);
    if (random.nextBool()) {
      _rect(accent, size, cx + 6, cy - 1, cx + 7, cy + 1, colors.accent);
    }
  }

  void _drawIcon(
    List<int?> base,
    List<int?> shadow,
    List<int?> accent,
    int size,
    _PromptColors colors,
    math.Random random,
  ) {
    final cx = size ~/ 2;
    final cy = size ~/ 2;
    final radius = (size * 0.26).round();
    _ellipse(base, size, cx, cy, radius, radius, colors.base);
    _ellipse(shadow, size, cx, cy + 2, radius - 2, radius ~/ 2, colors.shadow);
    _set(accent, size, cx - 1, cy - 2, colors.accent);
    _set(accent, size, cx, cy - 2, colors.accent);
    _set(accent, size, cx + 1, cy - 2, colors.accent);
    if (random.nextBool()) {
      _set(accent, size, cx, cy + 1, colors.accent);
    }
  }

  void _drawWeapon(
    List<int?> base,
    List<int?> shadow,
    List<int?> accent,
    int size,
    _PromptColors colors,
    math.Random random,
  ) {
    final cx = size ~/ 2;
    for (var i = 2; i < size - 4; i++) {
      _set(base, size, cx, i, colors.base);
      if (i.isEven) {
        _set(shadow, size, cx + 1, i, colors.shadow);
      }
    }
    _rect(accent, size, cx - 3, size - 6, cx + 3, size - 5, colors.accent);
    _rect(base, size, cx - 1, size - 5, cx + 1, size - 2, colors.shadow);
    if (random.nextBool()) {
      _set(accent, size, cx, 1, colors.accent);
    }
  }

  List<int?> _outlineFor(List<List<int?>> sources, int size) {
    final outline = List<int?>.filled(size * size, null);
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final index = y * size + x;
        if (sources.any((pixels) => pixels[index] != null)) {
          continue;
        }
        final touches = [
          _getAny(sources, size, x + 1, y),
          _getAny(sources, size, x - 1, y),
          _getAny(sources, size, x, y + 1),
          _getAny(sources, size, x, y - 1),
        ].any((value) => value);
        if (touches) {
          outline[index] = 0;
        }
      }
    }
    return outline;
  }

  bool _getAny(List<List<int?>> sources, int size, int x, int y) {
    if (x < 0 || y < 0 || x >= size || y >= size) {
      return false;
    }
    final index = y * size + x;
    return sources.any((pixels) => pixels[index] != null);
  }

  void _ellipse(
    List<int?> pixels,
    int size,
    int cx,
    int cy,
    int rx,
    int ry,
    int color,
  ) {
    for (var y = cy - ry; y <= cy + ry; y++) {
      for (var x = cx - rx; x <= cx + rx; x++) {
        final dx = (x - cx) / math.max(1, rx);
        final dy = (y - cy) / math.max(1, ry);
        if (dx * dx + dy * dy <= 1) {
          _set(pixels, size, x, y, color);
        }
      }
    }
  }

  void _rect(
    List<int?> pixels,
    int size,
    int left,
    int top,
    int right,
    int bottom,
    int color,
  ) {
    for (var y = top; y <= bottom; y++) {
      for (var x = left; x <= right; x++) {
        _set(pixels, size, x, y, color);
      }
    }
  }

  void _set(List<int?> pixels, int size, int x, int y, int color) {
    if (x < 0 || y < 0 || x >= size || y >= size) {
      return;
    }
    pixels[y * size + x] = color;
  }

  bool _hasAny(String prompt, List<String> keywords) {
    return keywords.any(prompt.contains);
  }
}

class _PromptColors {
  const _PromptColors({
    required this.base,
    required this.shadow,
    required this.accent,
  });

  final int base;
  final int shadow;
  final int accent;
}
