import 'package:flutter/widgets.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

/// Shows [children] side by side on wide layouts and stacks them on narrow
/// ones.
class AdaptiveRow extends StatelessWidget {
  const AdaptiveRow({
    super.key,
    required this.children,
    this.spacing = 16,
    this.breakpoint = Breakpoints.tablet,
  });

  final List<Widget> children;
  final double spacing;

  /// Below this available width, children are stacked vertically.
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: spacing,
            children: children,
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: spacing,
          children: [for (final child in children) Expanded(child: child)],
        );
      },
    );
  }
}
