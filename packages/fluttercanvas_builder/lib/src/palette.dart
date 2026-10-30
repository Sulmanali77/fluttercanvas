import 'package:flutter/material.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

import 'builder_controller.dart';
import 'drag_chip.dart';
import 'drag_payload.dart';

/// The list of widgets that can be dragged onto the canvas.
class WidgetPalette extends StatelessWidget {
  const WidgetPalette({
    super.key,
    required this.controller,
    this.touchMode = false,
    this.onDragStarted,
    this.onAdded,
  });

  final BuilderController controller;

  /// Uses long-press dragging so lists can still scroll on touch screens.
  final bool touchMode;
  final VoidCallback? onDragStarted;
  final VoidCallback? onAdded;

  static const Map<String, IconData> _icons = {
    WidgetTypes.column: Icons.view_agenda_outlined,
    WidgetTypes.row: Icons.view_column_outlined,
    WidgetTypes.adaptiveRow: Icons.view_quilt_outlined,
    WidgetTypes.grid: Icons.grid_view,
    WidgetTypes.container: Icons.crop_square,
    WidgetTypes.card: Icons.web_asset,
    WidgetTypes.text: Icons.title,
    WidgetTypes.button: Icons.smart_button,
    WidgetTypes.icon: Icons.star_outline,
    WidgetTypes.image: Icons.image_outlined,
    WidgetTypes.textField: Icons.input,
    WidgetTypes.divider: Icons.horizontal_rule,
    WidgetTypes.spacer: Icons.height,
  };

  static IconData iconFor(String type) => _icons[type] ?? Icons.widgets_outlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = {for (final spec in WidgetCatalog.all) spec.category};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Widgets', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          touchMode
              ? 'Tap to add, or long-press and drag onto the canvas.'
              : 'Drag onto the canvas, or click to add after the selection.',
          style: theme.textTheme.bodySmall,
        ),
        for (final category in categories) ...[
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Text(
              category,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final spec in WidgetCatalog.all.where((s) => s.category == category))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PaletteItem(
                spec: spec,
                controller: controller,
                touchMode: touchMode,
                onDragStarted: onDragStarted,
                onAdded: onAdded,
              ),
            ),
        ],
      ],
    );
  }
}

class _PaletteItem extends StatelessWidget {
  const _PaletteItem({
    required this.spec,
    required this.controller,
    required this.touchMode,
    this.onDragStarted,
    this.onAdded,
  });

  final WidgetSpec spec;
  final BuilderController controller;
  final bool touchMode;
  final VoidCallback? onDragStarted;
  final VoidCallback? onAdded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final icon = WidgetPalette.iconFor(spec.type);

    final tile = Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          controller.addWidget(spec.type);
          onAdded?.call();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spec.label, style: theme.textTheme.labelLarge),
                    Text(
                      spec.description,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.drag_indicator, size: 18, color: scheme.outline),
            ],
          ),
        ),
      ),
    );

    final feedback = DragChip(label: spec.label, icon: icon);
    final data = NewWidgetPayload(spec.type);
    if (touchMode) {
      return LongPressDraggable<DragPayload>(
        data: data,
        feedback: feedback,
        onDragStarted: onDragStarted,
        child: tile,
      );
    }
    return Draggable<DragPayload>(
      data: data,
      feedback: feedback,
      onDragStarted: onDragStarted,
      childWhenDragging: Opacity(opacity: 0.5, child: tile),
      child: tile,
    );
  }
}
