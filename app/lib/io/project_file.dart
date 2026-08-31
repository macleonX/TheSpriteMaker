import 'dart:convert';

import '../models/palette.dart';
import '../models/sprite.dart';

class ProjectFileCodec {
  const ProjectFileCodec();

  static const currentFormatVersion = 1;

  String encode(SpriteDocument document, SpritePalette palette) {
    return const JsonEncoder.withIndent('  ').convert({
      'formatVersion': currentFormatVersion,
      'projectName': document.name,
      'palette': palette.hexColors,
      'sprites': [document.toJson()],
    });
  }

  SpriteDocument decode(String contents) {
    final json = jsonDecode(contents) as Map<String, Object?>;
    final version = (json['formatVersion'] as num?)?.toInt();
    if (version != currentFormatVersion) {
      throw const FormatException('Unsupported .sprf format version');
    }

    final sprites = json['sprites'] as List<Object?>?;
    if (sprites == null || sprites.isEmpty) {
      return SpriteDocument.blank(
        name: json['projectName'] as String? ?? 'Untitled sprite',
      );
    }

    return SpriteDocument.fromJson(sprites.first as Map<String, Object?>);
  }
}
