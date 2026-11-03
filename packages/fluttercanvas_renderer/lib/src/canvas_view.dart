import 'package:flutter/material.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

import 'node_view.dart';
import 'render_delegate.dart';
import 'style_mapping.dart';

/// Renders a whole [CanvasDocument] as a responsive screen.
///
/// ```dart
/// CanvasView.fromJson(
///   jsonFromServer,
///   delegate: CanvasRenderDelegate(
///     onAction: (action, node) => print('Pressed $action'),
///   ),
/// )
/// ```
class CanvasView extends StatelessWidget {
  const CanvasView({
    super.key,
    required this.document,
    this.delegate = const CanvasRenderDelegate(),
    this.includeScaffold = true,
    this.onBack,
    this.bottomNav,
    this.onNavSelected,
  });

  /// Parses [json] and renders it. Throws a [FormatException] for invalid
  /// JSON.
  factory CanvasView.fromJson(
    String json, {
    Key? key,
    CanvasRenderDelegate delegate = const CanvasRenderDelegate(),
    bool includeScaffold = true,
  }) {
    return CanvasView(
      key: key,
      document: CanvasDocument.fromJsonString(json),
      delegate: delegate,
      includeScaffold: includeScaffold,
    );
  }

  final CanvasDocument document;
  final CanvasRenderDelegate delegate;

  /// When false, only the scrollable page body is built, so you can embed a
  /// design inside your own screen.
  final bool includeScaffold;

  /// When set, the app bar shows a back button that calls this. Useful when
  /// you switch screens yourself instead of using a `Navigator`.
  final VoidCallback? onBack;

  /// The bottom navigation bar to show, from [CanvasBottomNav.forScreen].
  final CanvasBottomNav? bottomNav;

  /// Called with a screen id when a bottom navigation item is tapped.
  final ValueChanged<String>? onNavSelected;

  @override
  Widget build(BuildContext context) {
    final rootView = CanvasNodeView(node: document.root, delegate: delegate);
    // Free-form screens are one frame that fills the page.
    final Widget body = WidgetCatalog.isFreeLayout(document.root)
        ? SingleChildScrollView(child: rootView)
        : _responsiveBody(rootView);
    if (!includeScaffold) return body;
    return Scaffold(
      backgroundColor: colorOf(document.backgroundColor),
      appBar: document.showAppBar ? _appBar() : null,
      bottomNavigationBar: bottomNav == null
          ? null
          : NavigationBar(
              selectedIndex: bottomNav!.selectedIndex,
              onDestinationSelected: (index) =>
                  onNavSelected?.call(bottomNav!.items[index].screenId),
              destinations: [
                for (final item in bottomNav!.items)
                  NavigationDestination(
                    icon: Icon(iconOf(item.icon)),
                    label: item.label,
                  ),
              ],
            ),
      body: body,
    );
  }

  PreferredSizeWidget _appBar() {
    final doc = document;
    void go(String target) {
      if (target.isNotEmpty) delegate.onNavigate?.call(target, doc.root);
    }

    Widget iconButton(String icon, String link, [String badge = '']) {
      final glyph = Icon(iconOf(icon));
      return IconButton(
        onPressed: () => go(link),
        icon: badge.trim().isEmpty
            ? glyph
            : Badge(label: Text(badge.trim()), child: glyph),
      );
    }

    final leading = doc.bar(BarKeys.leadingIcon);
    return AppBar(
      title: Text(doc.title),
      centerTitle: doc.barFlag(BarKeys.centerTitle),
      backgroundColor: colorOf(doc.bar(BarKeys.appBarColor)),
      foregroundColor: colorOf(doc.bar(BarKeys.appBarForeground)),
      leading: onBack != null
          ? BackButton(onPressed: onBack)
          : leading.isNotEmpty
              ? iconButton(leading, doc.bar(BarKeys.leadingLink))
              : null,
      actions: [
        if (doc.bar(BarKeys.action1Icon).isNotEmpty)
          iconButton(
            doc.bar(BarKeys.action1Icon),
            doc.bar(BarKeys.action1Link),
            doc.bar(BarKeys.action1Badge),
          ),
        if (doc.bar(BarKeys.action2Icon).isNotEmpty)
          iconButton(doc.bar(BarKeys.action2Icon), doc.bar(BarKeys.action2Link)),
      ],
    );
  }

  Widget _responsiveBody(Widget rootView) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Breakpoints.maxContentWidth,
              ),
              child: SizedBox(width: double.infinity, child: rootView),
            ),
          ),
        );
      },
    );
  }
}

/// One item of a bottom navigation bar.
class CanvasNavItem {
  const CanvasNavItem({
    required this.screenId,
    required this.icon,
    required this.label,
  });

  final String screenId;
  final String icon;
  final String label;
}

/// The bottom navigation bar of a screen: every screen with a nav icon,
/// with the current one selected.
class CanvasBottomNav {
  const CanvasBottomNav({required this.items, required this.selectedIndex});

  final List<CanvasNavItem> items;
  final int selectedIndex;

  /// The bar for [screen], or null when [screen] isn't in it.
  static CanvasBottomNav? forScreen(
    CanvasProject project,
    CanvasDocument screen,
  ) {
    final items = [
      for (final s in project.screens)
        if (s.bar(BarKeys.navIcon).isNotEmpty)
          CanvasNavItem(
            screenId: s.id,
            icon: s.bar(BarKeys.navIcon),
            label: s.bar(BarKeys.navLabel).isEmpty
                ? s.name
                : s.bar(BarKeys.navLabel),
          ),
    ];
    final index = items.indexWhere((item) => item.screenId == screen.id);
    if (index < 0) return null;
    return CanvasBottomNav(items: items, selectedIndex: index);
  }
}
