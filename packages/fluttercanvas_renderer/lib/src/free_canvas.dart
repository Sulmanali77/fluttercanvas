import 'package:flutter/material.dart';

/// A design frame where children sit at exact positions, like a Figma
/// frame. It keeps its design size and shrinks to fit narrower screens.
///
/// Wrap each child in a [Positioned].
class FreeCanvas extends StatelessWidget {
  const FreeCanvas({
    super.key,
    required this.designWidth,
    required this.designHeight,
    required this.children,
    this.color,
    this.borderRadius = 0,
    this.wrapLayer,
  });

  final double designWidth;
  final double designHeight;
  final List<Widget> children;
  final Color? color;
  final double borderRadius;

  /// Wraps the [Stack] that holds the children. The builder uses this to
  /// draw new boxes with the mouse.
  final Widget Function(Widget layer)? wrapLayer;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topCenter,
        child: Container(
          width: designWidth,
          height: designHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: wrapLayer == null
              ? Stack(children: children)
              : wrapLayer!(Stack(children: children)),
        ),
      ),
    );
  }
}
