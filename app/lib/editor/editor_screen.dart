import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/editor_providers.dart';
import 'palette_panel.dart';
import 'pixel_canvas.dart';
import 'tool_panel.dart';

class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final controller = ref.read(editorProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(editor.document.name),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {},
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'New sprite',
            onPressed: controller.clear,
            icon: const Icon(Icons.add_box_outlined),
          ),
          IconButton(
            tooltip: 'Open project',
            onPressed: () {},
            icon: const Icon(Icons.folder_open_outlined),
          ),
          IconButton(
            tooltip: 'Save project',
            onPressed: () {},
            icon: const Icon(Icons.save_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
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

            return const Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ToolPanel(),
                Expanded(child: _CanvasStage()),
                _InspectorPanel(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CanvasStage extends StatelessWidget {
  const _CanvasStage();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xff0b1111),
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

class _InspectorPanel extends ConsumerWidget {
  const _InspectorPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final controller = ref.read(editorProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 340,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(left: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: ListView(
        children: [
          const PalettePanel(),
          const SizedBox(height: 24),
          _GeneratorPanel(editor: editor, controller: controller),
          const SizedBox(height: 24),
          _DocumentPanel(editor: editor, controller: controller),
          const SizedBox(height: 24),
          const _FramesPanel(),
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
      height: 228,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [PalettePanel(), SizedBox(height: 16), _FramesPanel()],
        ),
      ),
    );
  }
}

class _GeneratorPanel extends StatelessWidget {
  const _GeneratorPanel({required this.editor, required this.controller});

  final EditorState editor;
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return _PanelSection(
      title: 'Generator',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            initialValue: editor.prompt,
            onChanged: controller.setPrompt,
            decoration: const InputDecoration(
              hintText: 'dragon, slime, fire knight...',
            ),
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
          Text(
            'Seed ${editor.seed}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _DocumentPanel extends StatelessWidget {
  const _DocumentPanel({required this.editor, required this.controller});

  final EditorState editor;
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return _PanelSection(
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
          const SizedBox(height: 12),
          Row(
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

class _FramesPanel extends StatelessWidget {
  const _FramesPanel();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _PanelSection(
      title: 'Frames',
      child: Row(
        children: [
          Container(
            width: 76,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border.all(color: colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('1'),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: 'Add frame',
            onPressed: () {},
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _PanelSection extends StatelessWidget {
  const _PanelSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}
