import 'package:flutter/material.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';
import 'package:fluttercanvas_renderer/fluttercanvas_renderer.dart';

import 'builder_controller.dart';
import 'drag_chip.dart';
import 'drag_payload.dart';

/// Makes every rendered widget selectable, draggable and a drop target.
class EditorRenderDelegate extends CanvasRenderDelegate {
  const EditorRenderDelegate(this.controller);

  final BuilderController controller;

  @override
  Widget wrap(BuildContext context, WidgetNode node, Widget child) =>
      NodeFrame(controller: controller, node: node, child: child);

  @override
  Widget? emptySlot(BuildContext context, WidgetNode node) => const DropHint();
}

/// Placeholder shown inside empty layouts.
class DropHint extends StatelessWidget {
  const DropHint({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
      ),
      child: Text(
        'Drop widgets here',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: scheme.primary),
      ),
    );
  }
}

/// Selection outline, tap-to-select, long-press-to-move and drop handling
/// around one widget on the canvas.
class NodeFrame extends StatelessWidget {
  const NodeFrame({
    super.key,
    required this.controller,
    required this.node,
    required this.child,
  });

  final BuilderController controller;
  final WidgetNode node;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final spec = WidgetCatalog.of(node.type);
    final isRoot = node.id == controller.document.root.id;
    final selected = controller.selectedId == node.id;
    final scheme = Theme.of(context).colorScheme;

    // Leaf widgets such as buttons and text fields should not react to taps
    // while designing, so the frame receives the tap instead.
    final content = spec == null || spec.childMode == ChildMode.none
        ? IgnorePointer(child: child)
        : child;

    final frame = DragTarget<DragPayload>(
      onWillAcceptWithDetails: (details) =>
          controller.canDrop(details.data, node.id),
      onAcceptWithDetails: (details) => controller.drop(details.data, node.id),
      builder: (context, candidates, rejected) {
        final hovering = candidates.isNotEmpty;
        final Color? outline = hovering
            ? const Color(0xFF10B981)
            : selected
                ? scheme.primary
                : null;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => controller.select(node.id),
          child: Container(
            foregroundDecoration: outline == null
                ? null
                : BoxDecoration(
                    border: Border.all(color: outline, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
            child: content,
          ),
        );
      },
    );

    if (isRoot) return frame;
    return LongPressDraggable<DragPayload>(
      data: MoveNodePayload(node.id),
      delay: const Duration(milliseconds: 250),
      feedback: DragChip(label: spec?.label ?? node.type),
      childWhenDragging: Opacity(opacity: 0.35, child: frame),
      child: frame,
    );
  }
}
