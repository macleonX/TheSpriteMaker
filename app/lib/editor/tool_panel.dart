import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sprite.dart';
import '../state/editor_providers.dart';

class ToolPanel extends ConsumerWidget {
  const ToolPanel({super.key, this.isCompact = false});

  final bool isCompact;

  static const _tools = [
    _ToolConfig(SpriteTool.pencil, Icons.edit_outlined, 'Pencil'),
    _ToolConfig(SpriteTool.eraser, Icons.auto_fix_off_outlined, 'Eraser'),
    _ToolConfig(SpriteTool.fill, Icons.format_color_fill_outlined, 'Fill'),
    _ToolConfig(SpriteTool.eyedropper, Icons.colorize_outlined, 'Eyedropper'),
    _ToolConfig(SpriteTool.line, Icons.show_chart_outlined, 'Line'),
    _ToolConfig(SpriteTool.rectangle, Icons.crop_square_outlined, 'Rectangle'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final controller = ref.read(editorProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    final children = [
      for (final tool in _tools)
        IconButton(
          tooltip: tool.label,
          isSelected: editor.tool == tool.tool,
          style: IconButton.styleFrom(
            backgroundColor: editor.tool == tool.tool
                ? colorScheme.primaryContainer
                : null,
            foregroundColor: editor.tool == tool.tool
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
            fixedSize: const Size(44, 44),
          ),
          onPressed: () => controller.selectTool(tool.tool),
          icon: Icon(tool.icon),
        ),
    ];

    return Container(
      width: isCompact ? null : 72,
      height: isCompact ? 64 : null,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          right: isCompact
              ? BorderSide.none
              : BorderSide(color: colorScheme.outlineVariant),
          bottom: isCompact
              ? BorderSide(color: colorScheme.outlineVariant)
              : BorderSide.none,
        ),
      ),
      child: isCompact
          ? ListView(scrollDirection: Axis.horizontal, children: children)
          : Column(children: children),
    );
  }
}

class _ToolConfig {
  const _ToolConfig(this.tool, this.icon, this.label);

  final SpriteTool tool;
  final IconData icon;
  final String label;
}
