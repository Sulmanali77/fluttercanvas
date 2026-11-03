import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';
import 'package:fluttercanvas_renderer/fluttercanvas_renderer.dart';

import 'builder_controller.dart';
import 'device_frame.dart';
import 'draw_layer.dart';
import 'node_frame.dart';

/// The center of the builder: the design inside a device frame on a dotted
/// board, with a floating tool dock.
class CanvasArea extends StatefulWidget {
  const CanvasArea({super.key, required this.controller});

  final BuilderController controller;

  @override
  State<CanvasArea> createState() => _CanvasAreaState();
}

class _CanvasAreaState extends State<CanvasArea> {
  // The preview uses Flutter's default theme so it matches what the exported
  // code looks like in a fresh app.
  static final ThemeData _previewTheme = ThemeData();

  final _focus = FocusNode(debugLabel: 'canvas');

  BuilderController get controller => widget.controller;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// Figma-style shortcuts while the canvas has focus: arrows move (Shift
  /// for 10 px), Delete removes, Escape deselects, Cmd/Ctrl+Z undoes,
  /// Shift+Cmd/Ctrl+Z redoes and Cmd/Ctrl+D duplicates.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    final shift = keyboard.isShiftPressed;
    final command = keyboard.isMetaPressed || keyboard.isControlPressed;
    final key = event.logicalKey;
    final selected = controller.selectedId;

    if (command && key == LogicalKeyboardKey.keyZ) {
      shift ? controller.redo() : controller.undo();
      return KeyEventResult.handled;
    }
    if (command && key == LogicalKeyboardKey.keyD && selected != null) {
      controller.duplicateNode(selected);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      controller.select(null);
      return KeyEventResult.handled;
    }
    if ((key == LogicalKeyboardKey.delete ||
            key == LogicalKeyboardKey.backspace) &&
        selected != null) {
      controller.deleteNode(selected);
      return KeyEventResult.handled;
    }
    final move = switch (key) {
      LogicalKeyboardKey.arrowLeft => (-1, 0),
      LogicalKeyboardKey.arrowRight => (1, 0),
      LogicalKeyboardKey.arrowUp => (0, -1),
      LogicalKeyboardKey.arrowDown => (0, 1),
      _ => null,
    };
    if (move != null && selected != null) {
      controller.nudge(move.$1, move.$2, big: shift);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final device = controller.device;
    final scheme = Theme.of(context).colorScheme;
    final document = controller.document;
    final freeForm = WidgetCatalog.isFreeLayout(document.root);

    final bottomNav = CanvasBottomNav.forScreen(controller.project, document);
    Widget view = controller.isPreviewing
        ? CanvasView(
            key: ValueKey('preview:${document.id}'),
            document: document,
            bottomNav: bottomNav,
            onNavSelected: controller.previewSwitch,
            onBack: controller.canPreviewBack ? controller.previewBack : null,
            delegate: CanvasRenderDelegate(
              onNavigate: (target, node) => controller.previewNavigate(target),
            ),
          )
        : CanvasView(
            document: document,
            bottomNav: bottomNav,
            delegate: EditorRenderDelegate(controller),
          );

    // On responsive screens the box tool still works: a box drawn anywhere
    // is added to the page with the drawn size.
    if (!controller.isPreviewing && !freeForm) {
      view = DrawLayer(
        controller: controller,
        parentId: document.root.id,
        child: view,
      );
    }

    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      child: Listener(
      onPointerDown: (_) => _focus.requestFocus(),
      child: ColoredBox(
      color: scheme.surfaceContainerLow,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DotGrid(scheme.outlineVariant.withValues(alpha: 0.6)),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 88),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: DeviceFrame(
                    device: device,
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: Size(device.width, device.height),
                        padding: EdgeInsets.only(
                          top: device.safeTop,
                          bottom: device.safeBottom,
                        ),
                        viewPadding: EdgeInsets.only(
                          top: device.safeTop,
                          bottom: device.safeBottom,
                        ),
                        viewInsets: EdgeInsets.zero,
                      ),
                      child: Theme(data: _previewTheme, child: view),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(child: _ToolDock(controller: controller)),
          ),
        ],
      ),
      ),
      ),
    );
  }
}

/// Floating tools, like the toolbar at the bottom of Figma.
class _ToolDock extends StatelessWidget {
  const _ToolDock({required this.controller});

  final BuilderController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hint = controller.isPreviewing
        ? 'Preview: tap buttons to move between screens'
        : switch (controller.tool) {
            CanvasTool.select =>
              'Drag to move · arrow keys nudge · Shift for 10 px',
            CanvasTool.box =>
              'Drag to draw · select a box first to draw inside it',
          };

    Widget tool(CanvasTool value, IconData icon, String tooltip) {
      final active = controller.tool == value && !controller.isPreviewing;
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => controller.tool = value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: active ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            tool(CanvasTool.select, Icons.near_me_outlined, 'Select and move'),
            const SizedBox(width: 4),
            tool(CanvasTool.box, Icons.crop_square, 'Box: drag to draw'),
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: scheme.outlineVariant,
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotGrid extends CustomPainter {
  _DotGrid(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const gap = 22.0;
    for (var y = gap / 2; y < size.height; y += gap) {
      for (var x = gap / 2; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGrid oldDelegate) => oldDelegate.color != color;
}
