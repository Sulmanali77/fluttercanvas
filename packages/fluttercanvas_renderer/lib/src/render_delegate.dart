import 'package:flutter/widgets.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

/// Called when a rendered button with a non-empty action id is pressed.
typedef CanvasActionCallback = void Function(String action, WidgetNode node);

/// Hooks for customizing how a design is rendered.
///
/// The default delegate renders the design as-is. The visual builder uses a
/// subclass to make every widget selectable and draggable.
class CanvasRenderDelegate {
  const CanvasRenderDelegate({this.onAction});

  /// Handles button presses. Use the button's action id to decide what to do,
  /// for example `open_settings` or `checkout`.
  final CanvasActionCallback? onAction;

  /// Wraps the widget built for [node].
  Widget wrap(BuildContext context, WidgetNode node, Widget child) => child;

  /// Widget shown inside a layout that has no children yet, or null for
  /// nothing.
  Widget? emptySlot(BuildContext context, WidgetNode node) => null;
}
