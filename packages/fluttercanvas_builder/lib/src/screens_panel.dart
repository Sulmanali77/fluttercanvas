import 'package:flutter/material.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

import 'builder_controller.dart';

/// List of screens in the project, like pages in Figma.
class ScreensPanel extends StatelessWidget {
  const ScreensPanel({super.key, required this.controller, this.onSelected});

  final BuilderController controller;

  /// Called after the user opens a screen, for example to close a drawer.
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final project = controller.project;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text('Screens', style: theme.textTheme.titleMedium),
                ),
                PopupMenuButton<bool>(
                  tooltip: 'Add screen',
                  icon: const Icon(Icons.add),
                  onSelected: (freeForm) =>
                      controller.addScreen(freeForm: freeForm),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: true,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.gesture),
                        title: Text('Free-form screen'),
                        subtitle: Text('Draw boxes and place things anywhere'),
                      ),
                    ),
                    PopupMenuItem(
                      value: false,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.view_agenda_outlined),
                        title: Text('Responsive screen'),
                        subtitle: Text('Widgets stack and adapt to any size'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              children: [
                for (final screen in project.screens)
                  _ScreenTile(
                    controller: controller,
                    screen: screen,
                    onSelected: onSelected,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenTile extends StatelessWidget {
  const _ScreenTile({
    required this.controller,
    required this.screen,
    this.onSelected,
  });

  final BuilderController controller;
  final CanvasDocument screen;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final project = controller.project;
    final isStart = screen.id == project.initialScreenId;
    final canDelete = project.screens.length > 1;
    return ListTile(
      dense: true,
      selected: screen.id == controller.document.id,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(
        isStart ? Icons.home_outlined : Icons.crop_portrait,
        size: 20,
      ),
      title: Text(screen.name, overflow: TextOverflow.ellipsis),
      subtitle: isStart ? const Text('Start screen') : null,
      onTap: () {
        controller.selectScreen(screen.id);
        onSelected?.call();
      },
      trailing: PopupMenuButton<String>(
        tooltip: 'Screen options',
        icon: const Icon(Icons.more_vert, size: 18),
        onSelected: (value) {
          switch (value) {
            case 'start':
              controller.setInitialScreen(screen.id);
            case 'duplicate':
              controller.duplicateScreen(screen.id);
            case 'delete':
              controller.deleteScreen(screen.id);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'start',
            enabled: !isStart,
            child: const Text('Set as start screen'),
          ),
          const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
          PopupMenuItem(
            value: 'delete',
            enabled: canDelete,
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
