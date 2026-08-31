import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../models/palette.dart';
import '../models/sprite.dart';
import 'project_file.dart';
import 'project_storage_result.dart';

class ProjectStorage {
  const ProjectStorage({this.codec = const ProjectFileCodec()});

  final ProjectFileCodec codec;

  Future<ProjectOpenResult?> openProject() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['sprf'],
    );
    if (files.isEmpty) {
      return null;
    }

    final file = files.first;
    final bytes = file.path == null
        ? await file.readAsBytes()
        : await File(file.path!).readAsBytes();

    return ProjectOpenResult(
      document: codec.decode(utf8.decode(bytes)),
      displayName: file.name,
      path: file.path,
    );
  }

  Future<PickedBytesResult?> pickImageBytes() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) {
      return null;
    }

    final bytes = file.path == null
        ? await file.readAsBytes()
        : await File(file.path!).readAsBytes();
    return PickedBytesResult(
      bytes: bytes,
      displayName: file.name,
      path: file.path,
    );
  }

  Future<ProjectSaveResult?> saveProject(
    SpriteDocument document,
    SpritePalette palette, {
    String? path,
  }) async {
    if (path == null) {
      return saveProjectAs(document, palette);
    }

    final target = File(path);
    final contents = codec.encode(document, palette);
    await _writeAtomically(target, contents);
    return ProjectSaveResult(displayName: _fileNameFromPath(path), path: path);
  }

  Future<ProjectSaveResult?> saveProjectAs(
    SpriteDocument document,
    SpritePalette palette,
  ) async {
    final fileName = _sprfFileName(document.name);
    final uri = await FilePicker.saveFile(
      dialogTitle: 'Save Sprite Forge project',
      fileName: fileName,
      bytes: utf8.encode(codec.encode(document, palette)),
      mimeType: 'application/json',
      type: FileType.custom,
      allowedExtensions: ['sprf'],
    );
    if (uri == null) {
      return null;
    }

    return ProjectSaveResult(
      displayName: uri.pathSegments.isEmpty ? fileName : uri.pathSegments.last,
      path: uri.scheme == 'file' ? uri.toFilePath() : null,
    );
  }

  Future<ProjectSaveResult?> saveBytesAs({
    required String fileName,
    required List<int> bytes,
    required String mimeType,
    required List<String> allowedExtensions,
    required String dialogTitle,
  }) async {
    final uri = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      bytes: Uint8List.fromList(bytes),
      mimeType: mimeType,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (uri == null) {
      return null;
    }

    return ProjectSaveResult(
      displayName: uri.pathSegments.isEmpty ? fileName : uri.pathSegments.last,
      path: uri.scheme == 'file' ? uri.toFilePath() : null,
    );
  }

  Future<void> _writeAtomically(File target, String contents) async {
    final temp = File('${target.path}.tmp');
    await temp.writeAsString(contents, flush: true);
    if (await target.exists()) {
      await target.delete();
    }
    await temp.rename(target.path);
  }
}

String _sprfFileName(String name) {
  final cleaned = name.trim().isEmpty
      ? 'untitled-sprite'
      : name.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');
  return cleaned.toLowerCase().endsWith('.sprf') ? cleaned : '$cleaned.sprf';
}

String _fileNameFromPath(String path) {
  return path.split(Platform.pathSeparator).last;
}
