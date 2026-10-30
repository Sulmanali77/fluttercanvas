/// The broad screen classes FlutterCanvas designs adapt to.
enum ScreenSize { mobile, tablet, desktop }

/// Screen-width breakpoints shared by the renderer and the code generator.
abstract final class Breakpoints {
  /// Widths below this are phones.
  static const double tablet = 600;

  /// Widths at or above this are desktops and browsers.
  static const double desktop = 1024;

  /// Maximum width of page content on large screens.
  static const double maxContentWidth = 1200;

  /// Returns the screen class for a logical [width].
  static ScreenSize sizeFor(double width) {
    if (width >= desktop) return ScreenSize.desktop;
    if (width >= tablet) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }
}
