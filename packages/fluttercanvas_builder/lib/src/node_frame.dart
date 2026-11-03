import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';
import 'package:fluttercanvas_renderer/fluttercanvas_renderer.dart';

import 'builder_controller.dart';
import 'drag_chip.dart';
import 'drag_payload.dart';
import 'draw_layer.dart';

/// Makes every rendered widget selectable, draggable and a drop target.
class EditorRenderDelegate extends CanvasRenderDelegate {
  const EditorRenderDelegate(this.controller);

  final BuilderController controller;

  @override
  bool get interactive => false;

  @override
  Widget wrap(BuildContext context, WidgetNode node, Widget child) =>
      NodeFrame(controller: controller, node: node, child: child);

  @override
  Widget wrapLayer(BuildContext context, WidgetNode node, Widget layer) =>
      DrawLayer(
        controller: controller,
        parentId: node.id,
        onlyWhenSelected: node.type == WidgetTypes.box,
        child: layer,
      );

  @override
  Widget? emptySlot(BuildContext context, WidgetNode node) {
    // An empty box should look like a plain shape.
    if (node.type == WidgetTypes.box) return null;
    if (node.type == WidgetTypes.freeCanvas) {
      return const DropHint(
        text: 'Pick the box tool and drag here to draw,\n'
            'or drop widgets from the panel',
      );
    }
    return const DropHint();
  }
}

/// Placeholder shown inside empty layouts.
class DropHint extends StatelessWidget {
  const DropHint({super.key, this.text = 'Drop widgets here'});

  final String text;

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
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: scheme.primary),
      ),
    );
  }
}

/// Everything you can do to one widget on the canvas:
///
/// * tap to select, double-tap text or buttons to edit their words
/// * long-press and drag to move it into another layout
/// * drag a selected widget inside a free canvas to place it anywhere
/// * drag the corner handle to resize it
class NodeFrame extends StatefulWidget {
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
  State<NodeFrame> createState() => _NodeFrameState();
}

class _NodeFrameState extends State<NodeFrame> {
  Offset? _moveStart;
  Offset _origin = Offset.zero;
  Offset? _resizeStart;
  Size _sizeStart = Size.zero;

  BuilderController get _controller => widget.controller;
  WidgetNode get _node => widget.node;

  // Moving inside a free canvas ---------------------------------------------

  RenderBox? get _canvasBox =>
      context.findAncestorRenderObjectOfType<RenderStack>();

  void _startMove(DragStartDetails details) {
    _controller.select(_node.id);
    final canvas = _canvasBox;
    if (canvas == null) return;
    _moveStart = canvas.globalToLocal(details.globalPosition);
    _origin = Offset(_node.number('x'), _node.number('y'));
  }

  void _move(DragUpdateDetails details) {
    final canvas = _canvasBox;
    final start = _moveStart;
    if (canvas == null || start == null) return;
    final delta = canvas.globalToLocal(details.globalPosition) - start;
    final x = (_origin.dx + delta.dx).roundToDouble();
    final y = (_origin.dy + delta.dy).roundToDouble();
    _controller.updateProps(
      _node.id,
      {'x': x < 0 ? 0.0 : x, 'y': y < 0 ? 0.0 : y},
      mergeKey: 'move:${_node.id}',
    );
  }

  void _endMove(DragEndDetails details) {
    _moveStart = null;
    _controller.endGesture();
  }

  // Resizing -------------------------------------------------------------------

  void _startResize(DragStartDetails details) {
    final box = context.findRenderObject();
    if (box is! RenderBox) return;
    _resizeStart = box.globalToLocal(details.globalPosition);
    final margin = _node.number('margin') * 2;
    _sizeStart = Size(box.size.width - margin, box.size.height - margin);
  }

  void _resize(DragUpdateDetails details) {
    final box = context.findRenderObject();
    final start = _resizeStart;
    if (box is! RenderBox || start == null) return;
    final delta = box.globalToLocal(details.globalPosition) - start;
    final width = (_sizeStart.width + delta.dx).roundToDouble();
    final height = (_sizeStart.height + delta.dy).roundToDouble();
    _controller.updateProps(
      _node.id,
      {
        'width': width < 16 ? 16.0 : width,
        'height': height < 16 ? 16.0 : height,
      },
      mergeKey: 'resize:${_node.id}',
    );
  }

  void _endResize(DragEndDetails details) {
    _resizeStart = null;
    _controller.endGesture();
  }

  // Editing text in place ----------------------------------------------------

  Future<void> _editText() async {
    final isButton = _node.type == WidgetTypes.button;
    final key = isButton ? 'label' : 'text';
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _TextEditDialog(
        title: isButton ? 'Edit button label' : 'Edit text',
        initialText: _node.string(key),
        multiline: !isButton,
      ),
    );
    if (result != null) _controller.updateProp(_node.id, key, result);
  }

  @override
  Widget build(BuildContext context) {
    final node = _node;
    final controller = _controller;
    final spec = WidgetCatalog.of(node.type);
    final root = controller.document.root;
    final isRoot = node.id == root.id;
    final selected = controller.selectedId == node.id;
    final inFreeCanvas =
        WidgetCatalog.isFreeLayout(root.parentOf(node.id));
    final editsText =
        node.type == WidgetTypes.text || node.type == WidgetTypes.button;
    final scheme = Theme.of(context).colorScheme;

    // Leaf widgets such as buttons and text fields should not react to taps
    // while designing, so the frame receives the tap instead.
    final content = spec == null || spec.childMode == ChildMode.none
        ? IgnorePointer(child: widget.child)
        : widget.child;

    // Buttons linked to a screen show where they go, like Figma's
    // prototype arrows.
    final link = node.string('navigateTo');
    final linkLabel = link.isEmpty
        ? null
        : link == 'back'
            ? 'Back'
            : controller.project.screenById(link)?.name ?? 'Missing screen';

    final canDrag = inFreeCanvas &&
        controller.tool == CanvasTool.select &&
        !controller.isPreviewing;
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
        return MouseRegion(
          cursor: canDrag ? SystemMouseCursors.move : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => controller.select(node.id),
            onDoubleTap: editsText ? _editText : null,
            onPanStart: canDrag ? _startMove : null,
            onPanUpdate: canDrag ? _move : null,
            onPanEnd: canDrag ? _endMove : null,
            child: Container(
              foregroundDecoration: outline == null
                  ? null
                  : BoxDecoration(
                      border: Border.all(color: outline, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.passthrough,
                children: [
                  content,
                  if (linkLabel != null)
                    Positioned(
                      top: -10,
                      right: -6,
                      child: _LinkBadge(label: linkLabel),
                    ),
                  if (selected && !isRoot)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: _ResizeHandle(
                        onStart: _startResize,
                        onUpdate: _resize,
                        onEnd: _endResize,
                      ),
                    ),
                ],
              ),
            ),
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

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  final GestureDragStartCallback onStart;
  final GestureDragUpdateCallback onUpdate;
  final GestureDragEndCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeDownRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: onStart,
        onPanUpdate: onUpdate,
        onPanEnd: onEnd,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: scheme.primary, width: 2),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _LinkBadge extends StatelessWidget {
  const _LinkBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: scheme.tertiary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_forward, size: 11, color: scheme.onTertiary),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: scheme.onTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextEditDialog extends StatefulWidget {
  const _TextEditDialog({
    required this.title,
    required this.initialText,
    required this.multiline,
  });

  final String title;
  final String initialText;
  final bool multiline;

  @override
  State<_TextEditDialog> createState() => _TextEditDialogState();
}

class _TextEditDialogState extends State<_TextEditDialog> {
  late final _text = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_text.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _text,
          autofocus: true,
          minLines: 1,
          maxLines: widget.multiline ? 5 : 1,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: widget.multiline ? null : (_) => _save(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
