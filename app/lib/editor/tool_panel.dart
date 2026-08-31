import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sprite.dart';
import '../state/editor_providers.dart';

class ToolPanel extends ConsumerWidget {
  const ToolPanel({super.key, this.isCompact = false}) : isEmbedded = false;

  const ToolPanel.embedded({super.key}) : isCompact = false, isEmbedded = true;

  final bool isCompact;
  final bool isEmbedded;

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

    Widget toolButton(_ToolConfig tool) {
      final selected = editor.tool == tool.tool;
      return IconButton(
        tooltip: tool.label,
        isSelected: selected,
        style: IconButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xffff5a1f)
              : const Color(0xff10172a),
          foregroundColor: selected
              ? Colors.white
              : colorScheme.onSurfaceVariant,
          fixedSize: isEmbedded
              ? const Size.fromHeight(58)
              : const Size(44, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(
            color: selected ? const Color(0xffff8a45) : const Color(0xff273150),
          ),
        ),
        onPressed: () => controller.selectTool(tool.tool),
        icon: Icon(tool.icon),
      );
    }

    final children = [
      for (final tool in _tools)
        Padding(padding: const EdgeInsets.all(5), child: toolButton(tool)),
    ];

    if (isEmbedded) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        children: children,
      );
    }

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
