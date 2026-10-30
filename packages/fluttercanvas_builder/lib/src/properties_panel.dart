import 'package:flutter/material.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

import 'builder_controller.dart';
import 'prop_editors.dart';

/// Edits the selected widget, or the screen settings when nothing is
/// selected.
class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({super.key, required this.controller});

  final BuilderController controller;

  @override
  Widget build(BuildContext context) {
    final node = controller.selectedNode;
    if (node == null) return _ScreenSettings(controller: controller);

    final theme = Theme.of(context);
    final root = controller.document.root;
    final spec = WidgetCatalog.of(node.type);
    final isRoot = node.id == root.id;
    final parent = root.parentOf(node.id);
    final index = parent?.indexOfChild(node.id) ?? -1;
    final siblingCount = parent?.children.length ?? 0;
    final canDuplicate = parent != null &&
        WidgetCatalog.of(parent.type)?.childMode == ChildMode.multiple;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isRoot ? 'Page layout' : spec?.label ?? node.type,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Show screen settings',
              icon: const Icon(Icons.close),
              onPressed: () => controller.select(null),
            ),
          ],
        ),
        if (spec != null)
          Text(spec.description, style: theme.textTheme.bodySmall),
        if (!isRoot) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [
              IconButton(
                tooltip: 'Move up',
                icon: const Icon(Icons.arrow_upward),
                onPressed: index > 0
                    ? () => controller.moveSibling(node.id, -1)
                    : null,
              ),
              IconButton(
                tooltip: 'Move down',
                icon: const Icon(Icons.arrow_downward),
                onPressed: index >= 0 && index < siblingCount - 1
                    ? () => controller.moveSibling(node.id, 1)
                    : null,
              ),
              IconButton(
                tooltip: 'Duplicate',
                icon: const Icon(Icons.content_copy),
                onPressed:
                    canDuplicate ? () => controller.duplicateNode(node.id) : null,
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                color: theme.colorScheme.error,
                onPressed: () => controller.deleteNode(node.id),
              ),
            ],
          ),
        ],
        const Divider(height: 24),
        if (spec != null)
          for (final prop in spec.props)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PropEditor(
                key: ValueKey('${node.id}:${prop.key}:${controller.revision}'),
                spec: prop,
                value: node.props[prop.key],
                onChanged: (value) =>
                    controller.updateProp(node.id, prop.key, value),
              ),
            ),
      ],
    );
  }
}

class _ScreenSettings extends StatelessWidget {
  const _ScreenSettings({required this.controller});

  final BuilderController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final document = controller.document;
    final revision = controller.revision;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Screen settings', style: theme.textTheme.titleMedium),
        Text(
          'Select a widget on the canvas to edit it.',
          style: theme.textTheme.bodySmall,
        ),
        const Divider(height: 24),
        PropEditor(
          key: ValueKey('document:name:$revision'),
          spec: const PropSpec('name', 'Screen name', PropKind.text),
          value: document.name,
          onChanged: (value) => controller.updateDocument(name: value as String),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            'Exports as ${FlutterCodeGenerator.className(document.name)} '
            'in ${FlutterCodeGenerator.fileName(document.name)}',
            style: theme.textTheme.bodySmall,
          ),
        ),
        PropEditor(
          key: ValueKey('document:title:$revision'),
          spec: const PropSpec('title', 'App bar title', PropKind.text),
          value: document.title,
          onChanged: (value) =>
              controller.updateDocument(title: value as String),
        ),
        const SizedBox(height: 4),
        PropEditor(
          key: ValueKey('document:appBar:$revision'),
          spec: const PropSpec('showAppBar', 'Show app bar', PropKind.toggle),
          value: document.showAppBar,
          onChanged: (value) =>
              controller.updateDocument(showAppBar: value as bool),
        ),
        const SizedBox(height: 8),
        PropEditor(
          key: ValueKey('document:background:$revision'),
          spec: const PropSpec('backgroundColor', 'Background', PropKind.color),
          value: document.backgroundColor,
          onChanged: (value) =>
              controller.updateDocument(backgroundColor: value as String),
        ),
        const Divider(height: 32),
        OutlinedButton.icon(
          onPressed: () => controller.select(document.root.id),
          icon: const Icon(Icons.account_tree_outlined),
          label: const Text('Edit page layout'),
        ),
      ],
    );
  }
}
