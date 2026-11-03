import 'package:flutter/material.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

import 'builder_controller.dart';
import 'palette.dart';

/// Every widget on the current screen as a tree, like Figma's layers.
class LayersPanel extends StatelessWidget {
  const LayersPanel({super.key, required this.controller});

  final BuilderController controller;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    void visit(WidgetNode node, int depth) {
      rows.add(_LayerRow(controller: controller, node: node, depth: depth));
      for (final child in node.children) {
        visit(child, depth + 1);
      }
    }

    visit(controller.document.root, 0);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: rows,
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({
    required this.controller,
    required this.node,
    required this.depth,
  });

  final BuilderController controller;
  final WidgetNode node;
  final int depth;

  String get _label {
    if (node.id == controller.document.root.id) return 'Page';
    if (node.name.trim().isNotEmpty) return node.name;
    final type = WidgetCatalog.of(node.type)?.label ?? node.type;
    final words = node.type == WidgetTypes.text
        ? node.string('text')
        : node.type == WidgetTypes.button
            ? node.string('label')
            : '';
    if (words.isEmpty) return type;
    final short = words.length > 24 ? '${words.substring(0, 24)}…' : words;
    return '$type · $short';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = controller.selectedId == node.id;
    return Material(
      color: selected ? scheme.primaryContainer : Colors.transparent,
      child: InkWell(
        onTap: () => controller.select(node.id),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.0 + depth * 16, 7, 12, 7),
          child: Row(
            children: [
              Icon(
                WidgetPalette.iconFor(node.type),
                size: 16,
                color: selected ? scheme.onPrimaryContainer : scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: node.name.trim().isNotEmpty
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: selected ? scheme.onPrimaryContainer : null,
                  ),
                ),
              ),
              if (node.string('navigateTo').isNotEmpty)
                Icon(Icons.link, size: 14, color: scheme.tertiary),
            ],
          ),
        ),
      ),
    );
  }
}
