import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../export/png_exporter.dart';
import '../io/project_storage.dart';
import '../generator/procedural_generator.dart';
import '../state/editor_providers.dart';
import 'palette_panel.dart';
import 'pixel_canvas.dart';
import 'sprite_thumbnail.dart';
import 'tool_panel.dart';

class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final controller = ref.read(editorProvider.notifier);
    const storage = ProjectStorage();

    return Scaffold(
      backgroundColor: const Color(0xff090d1a),
      body: SafeArea(
        child: Column(
          children: [
            _EditorTopBar(
              editor: editor,
              controller: controller,
              storage: storage,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 980;
                  if (compact) {
                    return const Column(
                      children: [
                        ToolPanel(isCompact: true),
                        Expanded(child: _CanvasStage()),
                        _BottomInspector(),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      _LeftRail(),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: _CanvasStage()),
                            _FrameDeck(),
                          ],
                        ),
                      ),
                      _RightRail(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorTopBar extends StatelessWidget {
  const _EditorTopBar({
    required this.editor,
    required this.controller,
    required this.storage,
  });

  final EditorState editor;
  final EditorController controller;
  final ProjectStorage storage;
  static const _pngExporter = PngExporter();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Color(0xff0d1326),
        border: Border(bottom: BorderSide(color: Color(0xff202943))),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xff165dff), Color(0xff8a2be2)],
              ),
            ),
            child: const Icon(Icons.animation, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Text(
            'Sprite Forge',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xfff4f7ff),
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              '${editor.document.name}${editor.isDirty ? ' *' : ''}',
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xfff4f7ff),
                fontFeatures: const [],
              ),
            ),
          ),
          const Spacer(),
          _TopIconButton(
            tooltip: 'New project',
            icon: Icons.add_box_outlined,
            onPressed: controller.newDocument,
          ),
          _TopIconButton(
            tooltip: 'Open project',
            icon: Icons.folder_open_outlined,
            onPressed: () => _openProject(context),
          ),
          _TopIconButton(
            tooltip: 'Save project',
            icon: Icons.save_outlined,
            onPressed: () => _saveProject(context, saveAs: false),
          ),
          _TopIconButton(
            tooltip: 'Save project as',
            icon: Icons.drive_file_rename_outline,
            onPressed: () => _saveProject(context, saveAs: true),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: controller.generate,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Generate'),
          ),
          const SizedBox(width: 10),
          FilledButton.tonalIcon(
            onPressed: () => _exportPng(context),
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Export PNG'),
          ),
        ],
      ),
    );
  }

  Future<void> _openProject(BuildContext context) async {
    try {
      final result = await storage.openProject();
      if (!context.mounted) {
        return;
      }
      if (result == null) {
        _showMessage(context, 'Open cancelled');
        return;
      }
      controller.openDocument(result.document, path: result.path);
      _showMessage(context, 'Opened ${result.displayName}');
    } on Object catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not open project: $error');
      }
    }
  }

  Future<void> _saveProject(
    BuildContext context, {
    required bool saveAs,
  }) async {
    try {
      final result = saveAs
          ? await storage.saveProjectAs(editor.document, editor.palette)
          : await storage.saveProject(
              editor.document,
              editor.palette,
              path: editor.currentFilePath,
            );
      if (!context.mounted) {
        return;
      }
      if (result == null) {
        _showMessage(context, 'Save cancelled');
        return;
      }
      controller.markSaved(path: result.path, displayName: result.displayName);
      _showMessage(context, 'Saved ${result.displayName}');
    } on Object catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not save project: $error');
      }
    }
  }

  Future<void> _exportPng(BuildContext context) async {
    try {
      final bytes = editor.document.frames.length == 1
          ? _pngExporter.exportActiveFrame(editor.document, editor.palette)
          : _pngExporter.exportSpriteSheet(editor.document, editor.palette);
      final result = await storage.saveBytesAs(
        fileName: _pngFileName(editor.document.name),
        bytes: bytes,
        mimeType: 'image/png',
        allowedExtensions: ['png'],
        dialogTitle: 'Export PNG',
      );
      if (!context.mounted) {
        return;
      }
      if (result == null) {
        _showMessage(context, 'Export cancelled');
        return;
      }
      _showMessage(context, 'Exported ${result.displayName}');
    } on Object catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not export PNG: $error');
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

String _pngFileName(String name) {
  final cleaned = name.trim().isEmpty
      ? 'untitled-sprite'
      : name.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');
  return cleaned.toLowerCase().endsWith('.png') ? cleaned : '$cleaned.png';
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        color: const Color(0xffdfe6ff),
        icon: Icon(icon),
      ),
    );
  }
}

class _LeftRail extends StatelessWidget {
  const _LeftRail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 310,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xff0b1122),
        border: Border(right: BorderSide(color: Color(0xff202943))),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelCard(title: 'Tools', child: ToolPanel.embedded()),
          SizedBox(height: 10),
          _SymmetryCard(),
          SizedBox(height: 10),
          _PanelCard(title: 'Palette', child: PalettePanel(showTitle: false)),
        ],
      ),
    );
  }
}

class _CanvasStage extends StatelessWidget {
  const _CanvasStage();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      decoration: BoxDecoration(
        color: const Color(0xff10172a),
        border: Border.all(color: const Color(0xff242d4a)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
            child: const PixelCanvas(),
          ),
        ),
      ),
    );
  }
}

class _RightRail extends StatelessWidget {
  const _RightRail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xff0b1122),
        border: Border(left: BorderSide(color: Color(0xff202943))),
      ),
      child: ListView(
        children: [
          const _PreviewPanel(),
          const SizedBox(height: 10),
          const _LayersPanel(),
          const SizedBox(height: 10),
          const _GeneratorCard(),
          const SizedBox(height: 10),
          const _DocumentCard(),
        ],
      ),
    );
  }
}

class _BottomInspector extends StatelessWidget {
  const _BottomInspector();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 240,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_FrameDeck(compact: true)],
        ),
      ),
    );
  }
}

class _PreviewPanel extends ConsumerStatefulWidget {
  const _PreviewPanel();

  @override
  ConsumerState<_PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends ConsumerState<_PreviewPanel> {
  Timer? _timer;
  Duration? _timerInterval;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(editorProvider);
    final controller = ref.read(editorProvider.notifier);
    final previewFrame =
        editor.document.frames[editor.isPreviewPlaying
            ? editor.previewFrameIndex
            : editor.document.activeFrameIndex];
    _syncTimer(editor);

    return _PanelCard(
      title: 'Preview',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.outlined(
            tooltip: editor.isPreviewPlaying ? 'Pause preview' : 'Play preview',
            onPressed: editor.isPreviewPlaying
                ? controller.stopPreview
                : controller.playPreview,
            icon: Icon(
              editor.isPreviewPlaying ? Icons.pause : Icons.play_arrow,
            ),
          ),
          const SizedBox(width: 6),
          IconButton.outlined(
            tooltip: 'Stop preview',
            onPressed: controller.stopPreview,
            icon: const Icon(Icons.stop),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 168,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xff0f1729),
                border: Border.all(color: const Color(0xff273150)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SpriteThumbnail(
                size: editor.document.size,
                pixels: previewFrame.compositePixels(editor.document.size),
                palette: editor.palette,
                padding: 26,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('FPS'),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<int>(
                  selected: {editor.document.fps},
                  segments: const [
                    ButtonSegment(value: 4, label: Text('4')),
                    ButtonSegment(value: 6, label: Text('6')),
                    ButtonSegment(value: 8, label: Text('8')),
                    ButtonSegment(value: 12, label: Text('12')),
                  ],
                  onSelectionChanged: (selection) =>
                      ref.read(editorProvider.notifier).setFps(selection.first),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _syncTimer(EditorState editor) {
    if (!editor.isPreviewPlaying || editor.document.frames.length <= 1) {
      _timer?.cancel();
      _timer = null;
      _timerInterval = null;
      return;
    }

    final interval = Duration(
      milliseconds: (1000 / editor.document.fps).round(),
    );
    if (_timer != null && _timerInterval == interval) {
      return;
    }

    _timer?.cancel();
    _timerInterval = interval;
    _timer = Timer.periodic(interval, (_) {
      if (mounted) {
        ref.read(editorProvider.notifier).advancePreview();
      }
    });
  }
}

class _SymmetryCard extends ConsumerWidget {
  const _SymmetryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final controller = ref.read(editorProvider.notifier);
    return _PanelCard(
      title: 'Symmetry',
      child: Row(
        children: [
          Expanded(
            child: FilterChip(
              label: const Text('Mirror X'),
              selected: editor.mirrorX,
              onSelected: (_) => controller.toggleMirrorX(),
              avatar: const Icon(Icons.swap_horiz, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilterChip(
              label: const Text('Mirror Y'),
              selected: editor.mirrorY,
              onSelected: (_) => controller.toggleMirrorY(),
              avatar: const Icon(Icons.swap_vert, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratorCard extends ConsumerWidget {
  const _GeneratorCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final controller = ref.read(editorProvider.notifier);
    return _PanelCard(
      title: 'Generator',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            initialValue: editor.prompt,
            onChanged: controller.setPrompt,
            decoration: const InputDecoration(
              hintText: 'blue robot, fire knight, slime...',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<SpriteArchetype?>(
            initialValue: editor.generatorArchetype,
            decoration: const InputDecoration(labelText: 'Type'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Auto')),
              DropdownMenuItem(
                value: SpriteArchetype.humanoid,
                child: Text('Humanoid'),
              ),
              DropdownMenuItem(
                value: SpriteArchetype.creature,
                child: Text('Creature'),
              ),
              DropdownMenuItem(
                value: SpriteArchetype.vehicle,
                child: Text('Vehicle'),
              ),
              DropdownMenuItem(
                value: SpriteArchetype.icon,
                child: Text('Icon'),
              ),
              DropdownMenuItem(
                value: SpriteArchetype.weapon,
                child: Text('Weapon'),
              ),
            ],
            onChanged: controller.setGeneratorArchetype,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<PaletteMood>(
            initialValue: editor.paletteMood,
            decoration: const InputDecoration(labelText: 'Mood'),
            items: const [
              DropdownMenuItem(value: PaletteMood.auto, child: Text('Auto')),
              DropdownMenuItem(value: PaletteMood.fire, child: Text('Fire')),
              DropdownMenuItem(value: PaletteMood.water, child: Text('Water')),
              DropdownMenuItem(value: PaletteMood.toxic, child: Text('Toxic')),
              DropdownMenuItem(
                value: PaletteMood.shadow,
                child: Text('Shadow'),
              ),
              DropdownMenuItem(value: PaletteMood.royal, child: Text('Royal')),
              DropdownMenuItem(value: PaletteMood.metal, child: Text('Metal')),
              DropdownMenuItem(
                value: PaletteMood.nature,
                child: Text('Nature'),
              ),
            ],
            onChanged: (mood) {
              if (mood != null) {
                controller.setPaletteMood(mood);
              }
            },
          ),
          const SizedBox(height: 10),
          SegmentedButton<GenerationMode>(
            selected: {editor.generationMode},
            segments: const [
              ButtonSegment(
                value: GenerationMode.singleFrame,
                icon: Icon(Icons.crop_square),
                label: Text('Single'),
              ),
              ButtonSegment(
                value: GenerationMode.idleAnimation,
                icon: Icon(Icons.movie_filter_outlined),
                label: Text('Idle'),
              ),
            ],
            onSelectionChanged: (selection) =>
                controller.setGenerationMode(selection.first),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Outline')),
              Switch(
                value: editor.includeOutline,
                onChanged: controller.setIncludeOutline,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: controller.generate,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Generate'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Reroll seed',
                onPressed: controller.rerollSeed,
                icon: const Icon(Icons.casino_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _importReferenceImage(context, ref),
            icon: const Icon(Icons.image_search_outlined),
            label: const Text('Use image reference'),
          ),
          const SizedBox(height: 8),
          Text(
            'Seed ${editor.seed}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _importReferenceImage(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      const storage = ProjectStorage();
      final result = await storage.pickImageBytes();
      if (!context.mounted) {
        return;
      }
      if (result == null) {
        _showMessage(context, 'Image reference cancelled');
        return;
      }
      ref
          .read(editorProvider.notifier)
          .importReferenceImage(result.bytes, displayName: result.displayName);
      _showMessage(context, 'Imported ${result.displayName}');
    } on Object catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not import image: $error');
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DocumentCard extends ConsumerWidget {
  const _DocumentCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final controller = ref.read(editorProvider.notifier);
    return _PanelCard(
      title: 'Sprite',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 8, label: Text('8')),
              ButtonSegment(value: 16, label: Text('16')),
              ButtonSegment(value: 24, label: Text('24')),
              ButtonSegment(value: 32, label: Text('32')),
            ],
            selected: {editor.document.size},
            onSelectionChanged: (selection) =>
                controller.setSize(selection.first),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: controller.clear,
            icon: const Icon(Icons.delete_sweep_outlined),
            label: const Text('Clear canvas'),
          ),
        ],
      ),
    );
  }
}

class _LayersPanel extends ConsumerWidget {
  const _LayersPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final controller = ref.read(editorProvider.notifier);
    final layers = editor.document.activeFrame.layers;

    return _PanelCard(
      title: 'Layers',
      trailing: IconButton.filledTonal(
        tooltip: 'Add layer',
        onPressed: controller.addLayer,
        icon: const Icon(Icons.add),
      ),
      child: Column(
        children: [
          for (var index = layers.length - 1; index >= 0; index--)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LayerTile(index: index),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.duplicateLayer,
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Duplicate'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.deleteLayer,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LayerTile extends ConsumerWidget {
  const _LayerTile({required this.index});

  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final controller = ref.read(editorProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final layer = editor.document.activeFrame.layers[index];
    final selected = editor.document.activeLayerIndex == index;

    return InkWell(
      onTap: () => controller.selectLayer(index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff16264a) : const Color(0xff11182c),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colorScheme.primary : const Color(0xff273150),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: layer.visible ? 'Hide layer' : 'Show layer',
                  onPressed: () =>
                      controller.setLayerVisibility(index, !layer.visible),
                  icon: Icon(
                    layer.visible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                SizedBox(
                  width: 46,
                  height: 46,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xff0b1020),
                      border: Border.all(color: const Color(0xff273150)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SpriteThumbnail(
                      size: editor.document.size,
                      pixels: layer.pixels,
                      palette: editor.palette,
                      padding: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    layer.name,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Column(
                  children: [
                    Text('${(layer.opacity * 100).round()}%'),
                    if (selected)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LayerActionButton(
                            tooltip: 'Move layer up',
                            icon: Icons.keyboard_arrow_up,
                            onPressed: controller.moveLayerUp,
                          ),
                          _LayerActionButton(
                            tooltip: 'Move layer down',
                            icon: Icons.keyboard_arrow_down,
                            onPressed: controller.moveLayerDown,
                          ),
                          _LayerActionButton(
                            tooltip: 'Merge down',
                            icon: Icons.call_merge_outlined,
                            onPressed: controller.mergeLayerDown,
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            Slider(
              value: layer.opacity,
              onChanged: (value) => controller.setLayerOpacity(index, value),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerActionButton extends StatelessWidget {
  const _LayerActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      padding: EdgeInsets.zero,
      iconSize: 18,
      icon: Icon(icon),
    );
  }
}

class _FrameDeck extends ConsumerWidget {
  const _FrameDeck({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final controller = ref.read(editorProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: compact ? null : 184,
      margin: EdgeInsets.fromLTRB(compact ? 0 : 8, 4, compact ? 0 : 8, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff0d1326),
        border: Border.all(color: const Color(0xff202943)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text('Frames', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: editor.document.frames.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final frame = editor.document.frames[index];
                  final selected = editor.document.activeFrameIndex == index;
                  return InkWell(
                    onTap: () => controller.selectFrame(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 104,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xff10172a),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? colorScheme.primary
                              : const Color(0xff273150),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${index + 1}'),
                          Expanded(
                            child: SpriteThumbnail(
                              size: editor.document.size,
                              pixels: frame.compositePixels(
                                editor.document.size,
                              ),
                              palette: editor.palette,
                              padding: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: 'Add frame',
                onPressed: controller.addFrame,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add),
              ),
              const SizedBox(height: 4),
              IconButton.outlined(
                tooltip: 'Duplicate frame',
                onPressed: controller.duplicateFrame,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.copy_outlined),
              ),
              const SizedBox(height: 4),
              IconButton.outlined(
                tooltip: 'Delete frame',
                onPressed: controller.deleteFrame,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xff0d1326),
        border: Border.all(color: const Color(0xff202943)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...?(trailing == null ? null : [trailing!]),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
