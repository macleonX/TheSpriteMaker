import 'package:flutter/material.dart';

class SpritePalette {
  const SpritePalette(this.colors);

  static const pico8 = SpritePalette([
    Color(0xff1a1c2c),
    Color(0xff5d275d),
    Color(0xffb13e53),
    Color(0xffef7d57),
    Color(0xffffcd75),
    Color(0xffa7f070),
    Color(0xff38b764),
    Color(0xff257179),
    Color(0xff29366f),
    Color(0xff3b5dc9),
    Color(0xff41a6f6),
    Color(0xff73eff7),
    Color(0xfff4f4f4),
    Color(0xff94b0c2),
    Color(0xff566c86),
  ]);

  final List<Color> colors;
}
