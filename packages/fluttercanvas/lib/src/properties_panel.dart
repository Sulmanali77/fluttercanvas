import 'package:flutter/material.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

import 'builder_controller.dart';
import 'dialogs.dart';
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
    final inFreeCanvas = WidgetCatalog.isFreeLayout(parent);
    final filling = inFreeCanvas && node.boolean('fill');
    final hideAutoLayout = WidgetCatalog.isFreeLayout(node);

    Widget editor(PropSpec prop) => PropEditor(
          key: ValueKey('${node.id}:${prop.key}:${controller.revision}'),
          spec: prop,
          value: node.props[prop.key],
          screenOptions: _screenLinks(controller),
          onChanged: (value) =>
              controller.updateProp(node.id, prop.key, value),
        );

    Widget pair(PropSpec first, PropSpec second) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(child: editor(first)),
              const SizedBox(width: 8),
              Expanded(child: editor(second)),
            ],
          ),
        );

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
                tooltip: 'Put in a row (place things side by side)',
                icon: const Icon(Icons.view_column_outlined),
                onPressed: () => controller.wrapIn(node.id, WidgetTypes.row),
              ),
              IconButton(
                tooltip: 'Put in a column (stack things)',
                icon: const Icon(Icons.view_agenda_outlined),
                onPressed: () =>
                    controller.wrapIn(node.id, WidgetTypes.column),
              ),
              IconButton(
                tooltip: 'Copy widget code',
                icon: const Icon(Icons.code),
                onPressed: () => showCodeDialog(
                  context,
                  title: 'Widget code',
                  code: const FlutterCodeGenerator().generateWidget(node),
                ),
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
        if (!isRoot) ...[
          PropEditor(
            key: ValueKey('${node.id}:#name:${controller.revision}'),
            spec: const PropSpec('name', 'Layer name', PropKind.text),
            value: node.name,
            onChanged: (value) =>
                controller.renameNode(node.id, value as String),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Text(
              'Named layers become their own widget in the exported code.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
        if (!isRoot) ...[
          Text('Size and position', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          if (inFreeCanvas)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: editor(WidgetCatalog.positionProps[2]),
            ),
          if (!filling) ...[
            pair(WidgetCatalog.layoutProps[0], WidgetCatalog.layoutProps[1]),
            if (inFreeCanvas)
              pair(
                WidgetCatalog.positionProps[0],
                WidgetCatalog.positionProps[1],
              ),
          ],
          if (!inFreeCanvas)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: editor(WidgetCatalog.layoutProps[2]),
            ),
          Text(
            inFreeCanvas
                ? 'Drag it on the canvas to place it, or drag the corner '
                    'handle to resize.'
                : 'Drag the corner handle on the canvas to resize.',
            style: theme.textTheme.bodySmall,
          ),
          const Divider(height: 24),
        ],
        if (!isRoot) ...[
          Text('Interaction', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final prop in WidgetCatalog.interactionProps)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: editor(prop),
            ),
          Text('Animation', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          pair(
            WidgetCatalog.animationProps[0],
            WidgetCatalog.animationProps[1],
          ),
          Text(
            'Animations play in preview mode and in the exported app.',
            style: theme.textTheme.bodySmall,
          ),
          const Divider(height: 24),
        ],
        if (spec != null)
          for (final prop in spec.props)
            if (!(hideAutoLayout &&
                node.type == WidgetTypes.box &&
                WidgetCatalog.autoLayoutKeys.contains(prop.key)))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: editor(prop),
              ),
      ],
    );
  }
}

const _appBarProps = [
  PropSpec(BarKeys.appBarColor, 'Background', PropKind.color),
  PropSpec(BarKeys.appBarForeground, 'Text and icon color', PropKind.color),
  PropSpec(BarKeys.centerTitle, 'Center the title', PropKind.toggle),
  PropSpec(BarKeys.leadingIcon, 'Left icon', PropKind.choice,
      options: PropOptions.iconsOrNone),
  PropSpec(BarKeys.leadingLink, 'Left icon goes to', PropKind.screenLink),
  PropSpec(BarKeys.action1Icon, 'Right icon 1', PropKind.choice,
      options: PropOptions.iconsOrNone),
  PropSpec(BarKeys.action1Link, 'Right icon 1 goes to', PropKind.screenLink),
  PropSpec(BarKeys.action1Badge, 'Right icon 1 badge', PropKind.text),
  PropSpec(BarKeys.action2Icon, 'Right icon 2', PropKind.choice,
      options: PropOptions.iconsOrNone),
  PropSpec(BarKeys.action2Link, 'Right icon 2 goes to', PropKind.screenLink),
];

Map<String, String> _screenLinks(BuilderController controller) => {
      '': 'Nothing',
      'back': 'Go back',
      for (final screen in controller.project.screens)
        if (screen.id != controller.document.id) screen.id: screen.name,
    };

class _ScreenSettings extends StatelessWidget {
  const _ScreenSettings({required this.controller});

  final BuilderController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final document = controller.document;
    final key = '${document.id}:${controller.revision}';
    final className = FlutterCodeGenerator.screenClassName(document.name);
    Widget bar(PropSpec prop) => PropEditor(
          key: ValueKey('bar:${prop.key}:$key'),
          spec: prop,
          value: document.bars[prop.key] ??
              (prop.kind == PropKind.choice ? '' : null),
          screenOptions: _screenLinks(controller),
          onChanged: (value) => controller.updateBars(prop.key, value),
        );
    final fileName = FlutterCodeGenerator.fileName(document.name);
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
          key: ValueKey('name:$key'),
          spec: const PropSpec('name', 'Screen name', PropKind.text),
          value: document.name,
          onChanged: (value) => controller.updateDocument(name: value as String),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            'Exports as $className in lib/screens/$fileName',
            style: theme.textTheme.bodySmall,
          ),
        ),
        PropEditor(
          key: ValueKey('title:$key'),
          spec: const PropSpec('title', 'App bar title', PropKind.text),
          value: document.title,
          onChanged: (value) =>
              controller.updateDocument(title: value as String),
        ),
        const SizedBox(height: 4),
        PropEditor(
          key: ValueKey('appBar:$key'),
          spec: const PropSpec('showAppBar', 'Show app bar', PropKind.toggle),
          value: document.showAppBar,
          onChanged: (value) =>
              controller.updateDocument(showAppBar: value as bool),
        ),
        const SizedBox(height: 8),
        PropEditor(
          key: ValueKey('background:$key'),
          spec: const PropSpec('backgroundColor', 'Background', PropKind.color),
          value: document.backgroundColor,
          onChanged: (value) =>
              controller.updateDocument(backgroundColor: value as String),
        ),
        if (document.showAppBar) ...[
          const Divider(height: 32),
          Text('App bar', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final prop in _appBarProps)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: bar(prop),
            ),
        ],
        const Divider(height: 32),
        Text('Bottom navigation', style: theme.textTheme.titleSmall),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            'Give screens an icon to put them in a shared bottom bar.',
            style: theme.textTheme.bodySmall,
          ),
        ),
        bar(const PropSpec(BarKeys.navIcon, 'Icon in bottom bar',
            PropKind.choice, options: PropOptions.iconsOrNone)),
        const SizedBox(height: 12),
        bar(const PropSpec(BarKeys.navLabel, 'Label', PropKind.text)),
        const Divider(height: 32),
        Text('App', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        PropEditor(
          key: ValueKey('project:${controller.revision}'),
          spec: const PropSpec('appName', 'App name', PropKind.text),
          value: controller.project.name,
          onChanged: (value) => controller.renameProject(value as String),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => controller.select(document.root.id),
          icon: const Icon(Icons.account_tree_outlined),
          label: const Text('Edit page layout'),
        ),
      ],
    );
  }
}
