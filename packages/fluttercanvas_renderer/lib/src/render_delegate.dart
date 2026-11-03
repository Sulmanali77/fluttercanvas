import 'package:flutter/widgets.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

/// Called when a rendered button with a non-empty action id is pressed.
typedef CanvasActionCallback = void Function(String action, WidgetNode node);

/// Called when a button linked to a screen is pressed. [target] is a screen
/// id, or `back`.
typedef CanvasNavigateCallback = void Function(String target, WidgetNode node);

/// Hooks for customizing how a design is rendered.
///
/// The default delegate renders the design as-is. The visual builder uses a
/// subclass to make every widget selectable and draggable.
class CanvasRenderDelegate {
  const CanvasRenderDelegate({this.onAction, this.onNavigate});

  /// Handles button presses. Use the button's action id to decide what to do,
  /// for example `open_settings` or `checkout`.
  final CanvasActionCallback? onAction;

  /// Handles buttons linked to another screen. `CanvasProjectView` sets this
  /// for you.
  final CanvasNavigateCallback? onNavigate;

  /// Whether taps run actions and animations play. The builder turns this
  /// off while editing so a tap selects instead.
  bool get interactive => true;

  /// Wraps the widget built for [node].
  Widget wrap(BuildContext context, WidgetNode node, Widget child) => child;

  /// Wraps the layer of a free canvas or box that holds positioned
  /// children. [layer] is a [Stack] in the same coordinates as `x` and `y`.
  Widget wrapLayer(BuildContext context, WidgetNode node, Widget layer) =>
      layer;

  /// Widget shown inside a layout that has no children yet, or null for
  /// nothing.
  Widget? emptySlot(BuildContext context, WidgetNode node) => null;
}
