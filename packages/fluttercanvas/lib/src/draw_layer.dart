import 'package:flutter/material.dart';

import 'builder_controller.dart';

/// Lets the box tool draw a new box by pressing and dragging, like the
/// rectangle tool in Figma. The preview follows the pointer and the box is
/// added when the pointer is released.
class DrawLayer extends StatefulWidget {
  const DrawLayer({
    super.key,
    required this.controller,
    required this.parentId,
    required this.child,
    this.onlyWhenSelected = false,
  });

  /// When true, drawing here only works while [parentId] is selected.
  /// Boxes use this so new boxes don't fall into them by accident.
  final bool onlyWhenSelected;

  final BuilderController controller;

  /// The free canvas or box the new box goes into, or the screen's root.
  final String parentId;
  final Widget child;

  @override
  State<DrawLayer> createState() => _DrawLayerState();
}

class _DrawLayerState extends State<DrawLayer> {
  Offset? _start;
  Offset? _current;

  Rect? get _rect {
    final start = _start;
    final current = _current;
    if (start == null || current == null) return null;
    return Rect.fromPoints(start, current);
  }

  void _finish() {
    final rect = _rect;
    setState(() {
      _start = null;
      _current = null;
    });
    if (rect == null || (rect.width < 8 && rect.height < 8)) return;
    widget.controller.drawBox(widget.parentId, rect);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final drawing = controller.tool == CanvasTool.box &&
        !controller.isPreviewing &&
        (!widget.onlyWhenSelected || controller.selectedId == widget.parentId);
    final rect = _rect;
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: drawing ? SystemMouseCursors.precise : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: drawing
            ? (details) => setState(() {
                  _start = details.localPosition;
                  _current = details.localPosition;
                })
            : null,
        onPanUpdate: drawing
            ? (details) => setState(() => _current = details.localPosition)
            : null,
        onPanEnd: drawing ? (_) => _finish() : null,
        onPanCancel: drawing ? _finish : null,
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.passthrough,
          children: [
            widget.child,
            if (rect != null)
              Positioned.fromRect(
                rect: rect,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      border: Border.all(color: scheme.primary, width: 1.5),
                    ),
                    alignment: Alignment.bottomRight,
                    child: _SizeLabel(size: rect.size),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SizeLabel extends StatelessWidget {
  const _SizeLabel({required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Transform.translate(
      offset: const Offset(0, 22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${size.width.round()} × ${size.height.round()}',
          style: TextStyle(fontSize: 10, color: scheme.onPrimary),
        ),
      ),
    );
  }
}
