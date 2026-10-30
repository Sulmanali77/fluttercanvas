import 'package:flutter/widgets.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

/// A grid whose column count depends on the screen width.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16,
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final columns = switch (
        Breakpoints.sizeFor(MediaQuery.sizeOf(context).width)) {
      ScreenSize.desktop => desktopColumns,
      ScreenSize.tablet => tabletColumns,
      ScreenSize.mobile => mobileColumns,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - spacing * (columns - 1);
        final itemWidth =
            available <= 0 ? 0.0 : (available / columns).floorToDouble();
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
