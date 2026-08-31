import '../models/sprite.dart';

class ProjectOpenResult {
  const ProjectOpenResult({
    required this.document,
    required this.displayName,
    this.path,
  });

  final SpriteDocument document;
  final String displayName;
  final String? path;
}

class ProjectSaveResult {
  const ProjectSaveResult({required this.displayName, this.path});

  final String displayName;
  final String? path;
}

class PickedBytesResult {
  const PickedBytesResult({
    required this.bytes,
    required this.displayName,
    this.path,
  });

  final List<int> bytes;
  final String displayName;
  final String? path;
}
