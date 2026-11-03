import 'breakpoints.dart';
import 'canvas_document.dart';
import 'canvas_project.dart';
import 'code_emitter.dart';
import 'colors.dart';
import 'widget_catalog.dart';
import 'widget_node.dart';

/// A file produced by [FlutterCodeGenerator.generateProject].
class GeneratedFile {
  const GeneratedFile(this.path, this.content);

  /// Path inside a Flutter project, such as `lib/screens/home_screen.dart`.
  final String path;
  final String content;
}

/// Turns designs into Flutter code that reads like a person wrote it.
///
/// The output only depends on `package:flutter/material.dart`. Buttons get
/// `// TODO` comments where your own logic goes; API calls, state and
/// controllers are left to you.
class FlutterCodeGenerator {
  const FlutterCodeGenerator();

  /// Generates one self-contained file for a single screen.
  String generate(CanvasDocument document) {
    final writer = _ScreenWriter(document, routeKeys: null);
    final screen = writer.write();
    final buffer = StringBuffer()
      ..writeln("import 'package:flutter/material.dart';");
    for (final line in writer.imports) {
      buffer.writeln(line);
    }
    buffer
      ..writeln()
      ..write(screen);
    for (final helper in _orderedHelpers(writer.helpers)) {
      buffer.write('\n$helper');
    }
    return buffer.toString();
  }

  /// Generates the code for one widget and everything inside it, for
  /// pasting into an existing screen.
  String generateWidget(WidgetNode node) {
    final writer = _ScreenWriter(CanvasDocument.blank(), routeKeys: null);
    final buffer = StringBuffer(writer.writeWidget(node));
    for (final helper in _orderedHelpers(writer.helpers)) {
      buffer.write('\n$helper');
    }
    return buffer.toString();
  }

  /// Generates a ready-to-copy `lib` folder: `main.dart`, `app_routes.dart`,
  /// one file per screen, and shared responsive widgets when needed.
  List<GeneratedFile> generateProject(CanvasProject project) {
    final usedClasses = <String>{};
    final usedRoutes = <String>{'routes'};
    final classNames = <String, String>{};
    final routeKeys = <String, String>{};

    for (final screen in project.screens) {
      final baseClass = screenClassName(screen.name);
      var className = baseClass;
      final baseRoute = routeName(screen.name);
      var route = baseRoute;
      for (var i = 2; usedClasses.contains(className); i++) {
        className =
            '${baseClass.substring(0, baseClass.length - 6)}${i}Screen';
      }
      for (var i = 2; usedRoutes.contains(route); i++) {
        route = '$baseRoute$i';
      }
      usedClasses.add(className);
      usedRoutes.add(route);
      classNames[screen.id] = className;
      routeKeys[screen.id] = route;
    }

    final files = <GeneratedFile>[];
    final helpers = <_Helper>{};
    final screenImports = <String>[];
    final packages = <String>{};
    final navItems = [
      for (final screen in project.screens)
        if (screen.bar(BarKeys.navIcon).isNotEmpty)
          _NavItem(
            screenId: screen.id,
            route: routeKeys[screen.id]!,
            icon: screen.bar(BarKeys.navIcon),
            label: screen.bar(BarKeys.navLabel).isEmpty
                ? screen.name
                : screen.bar(BarKeys.navLabel),
          ),
    ];

    for (final screen in project.screens) {
      final className = classNames[screen.id]!;
      final file = _snake(className);
      final writer = _ScreenWriter(
        screen,
        routeKeys: routeKeys,
        className: className,
      )..navItems = navItems;
      final body = writer.write();
      packages.addAll(writer.packages);
      final usesLayout = writer.helpers.isNotEmpty;
      helpers.addAll(writer.helpers);
      final buffer = StringBuffer()
        ..writeln("import 'package:flutter/material.dart';");
      for (final line in writer.imports) {
        buffer.writeln(line);
      }
      buffer.writeln();
      if (writer.usesRoutes) buffer.writeln("import '../app_routes.dart';");
      if (usesLayout) {
        buffer.writeln("import '../widgets/responsive_layout.dart';");
      }
      if (writer.usesRoutes || usesLayout) buffer.writeln();
      buffer.write(body);
      files.add(GeneratedFile('lib/screens/$file.dart', buffer.toString()));
      screenImports.add("import 'screens/$file.dart';");
    }

    screenImports.sort();
    final routes = StringBuffer()
      ..writeln("import 'package:flutter/material.dart';")
      ..writeln();
    for (final line in screenImports) {
      routes.writeln(line);
    }
    routes
      ..writeln()
      ..writeln('/// Route names and builders for every screen in the app.')
      ..writeln('abstract final class AppRoutes {');
    for (final screen in project.screens) {
      final key = routeKeys[screen.id]!;
      final path = screen.id == project.initialScreenId ? '/' : '/${_kebab(key)}';
      routes.writeln("  static const $key = '$path';");
    }
    routes
      ..writeln()
      ..writeln('  static final Map<String, WidgetBuilder> routes = {');
    for (final screen in project.screens) {
      routes.writeln(
          '    ${routeKeys[screen.id]}: (context) => const ${classNames[screen.id]}(),');
    }
    routes
      ..writeln('  };')
      ..writeln('}');

    final main = StringBuffer()
      ..writeln("import 'package:flutter/material.dart';")
      ..writeln()
      ..writeln("import 'app_routes.dart';")
      ..writeln()
      ..writeln('void main() => runApp(const MyApp());')
      ..writeln()
      ..writeln('class MyApp extends StatelessWidget {')
      ..writeln('  const MyApp({super.key});')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  Widget build(BuildContext context) {')
      ..writeln('    return MaterialApp(')
      ..writeln('      title: ${dartString(project.name)},')
      ..writeln('      initialRoute: AppRoutes.${routeKeys[project.initialScreenId]},')
      ..writeln('      routes: AppRoutes.routes,')
      ..writeln('    );')
      ..writeln('  }')
      ..writeln('}');

    return [
      GeneratedFile('lib/main.dart', main.toString()),
      GeneratedFile('lib/app_routes.dart', routes.toString()),
      ...files,
      if (packages.isNotEmpty)
        GeneratedFile(
          'pubspec_dependencies.yaml',
          '# Add these under `dependencies:` in your pubspec.yaml,\n'
              '# then run `flutter pub get`.\n'
              'dependencies:\n'
              '${packages.map((p) => '  $p').join('\n')}\n',
        ),
      if (helpers.isNotEmpty)
        GeneratedFile(
          'lib/widgets/responsive_layout.dart',
          "import 'package:flutter/material.dart';\n\n"
              '${_orderedHelpers(helpers).join('\n')}',
        ),
    ];
  }

  /// Converts a name such as `my home page` into `MyHomePage`.
  static String className(String raw) {
    final words = raw
        .split(RegExp(r'[^A-Za-z0-9]+'))
        .where((word) => word.isNotEmpty);
    final name = words
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join();
    if (name.isEmpty) return 'Generated';
    if (RegExp(r'^[0-9]').hasMatch(name)) return 'Widget$name';
    return name;
  }

  /// Class name for a screen: `Login` becomes `LoginScreen`.
  static String screenClassName(String raw) {
    final name = className(raw);
    return name.endsWith('Screen') ? name : '${name}Screen';
  }

  /// Suggested file name for a screen, such as `login_screen.dart`.
  static String fileName(String raw) => '${_snake(screenClassName(raw))}.dart';

  /// Field name in `AppRoutes` for a screen: `Login screen` becomes `login`.
  static String routeName(String raw) {
    var name = className(raw);
    if (name.endsWith('Screen') && name.length > 6) {
      name = name.substring(0, name.length - 6);
    }
    final route = name[0].toLowerCase() + name.substring(1);
    return _reserved.contains(route) ? '${route}Screen' : route;
  }

  static const _reserved = {
    'class', 'const', 'default', 'do', 'else', 'enum', 'false', 'final',
    'for', 'if', 'in', 'is', 'new', 'null', 'return', 'super', 'switch',
    'this', 'true', 'var', 'void', 'while', 'with', 'routes',
  };
}

/// Shared widgets the generated code can depend on.
enum _Helper { adaptiveRow, responsiveGrid, freeCanvas, entranceAnimation }

class _NavItem {
  const _NavItem({
    required this.screenId,
    required this.route,
    required this.icon,
    required this.label,
  });

  final String screenId;
  final String route;
  final String icon;
  final String label;
}

List<String> _orderedHelpers(Set<_Helper> helpers) => [
      for (final helper in _Helper.values)
        if (helpers.contains(helper))
          switch (helper) {
            _Helper.adaptiveRow => _adaptiveRowSource,
            _Helper.responsiveGrid => _responsiveGridSource,
            _Helper.freeCanvas => _freeCanvasSource,
            _Helper.entranceAnimation => _entranceAnimationSource,
          },
    ];

String _snake(String name) => name
    .replaceAllMapped(RegExp(r'(?<=[a-z0-9])[A-Z]'), (m) => '_${m[0]}')
    .toLowerCase();

String _kebab(String name) => name
    .replaceAllMapped(RegExp(r'(?<=[a-z0-9])[A-Z]'), (m) => '-${m[0]}')
    .toLowerCase();

/// Writes one screen class plus the widget classes extracted from named
/// layers.
class _ScreenWriter {
  _ScreenWriter(this.document, {required this.routeKeys, String? className})
      : className =
            className ?? FlutterCodeGenerator.screenClassName(document.name);

  final CanvasDocument document;

  /// Screen id to `AppRoutes` field, or null when writing a single file.
  final Map<String, String>? routeKeys;
  final String className;

  final helpers = <_Helper>{};
  bool usesRoutes = false;

  /// Extra imports and pubspec packages needed by custom code widgets.
  final imports = <String>{};
  final packages = <String>{};

  /// Screens in the bottom navigation bar, in order, when writing a project.
  List<_NavItem> navItems = const [];

  final _extracted = <String>[];
  late final _usedNames = <String>{className};

  String write() {
    final isFreeForm = WidgetCatalog.isFreeLayout(document.root);
    final root = _node(document.root, extract: false)
        .render(isFreeForm ? 4 : 9);
    final background = _colorLiteral(document.backgroundColor);

    final buffer = StringBuffer()
      ..writeln('/// Generated by FlutterCanvas.')
      ..writeln('class $className extends StatelessWidget {')
      ..writeln('  const $className({super.key});')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  Widget build(BuildContext context) {')
      ..writeln('    return Scaffold(');
    if (background != null) {
      buffer.writeln('      backgroundColor: const $background,');
    }
    if (document.showAppBar) {
      buffer.writeln('      appBar: ${_appBar().render(3)},');
    }
    _writeBottomNav(buffer);
    if (isFreeForm) {
      // Free-form screens are one frame that fills the page.
      buffer
        ..writeln('      body: SingleChildScrollView(')
        ..writeln('        child: $root,')
        ..writeln('      ),')
        ..writeln('    );')
        ..writeln('  }')
        ..writeln('}');
      for (final source in _extracted) {
        buffer
          ..writeln()
          ..write(source);
      }
      return buffer.toString();
    }
    buffer
      ..writeln('      body: LayoutBuilder(')
      ..writeln('        builder: (context, constraints) {')
      ..writeln('          final isMobile = constraints.maxWidth < '
          '${formatNumber(Breakpoints.tablet)};')
      ..writeln('          return SingleChildScrollView(')
      ..writeln('            padding: EdgeInsets.all(isMobile ? 16 : 24),')
      ..writeln('            child: Align(')
      ..writeln('              alignment: Alignment.topCenter,')
      ..writeln('              child: ConstrainedBox(')
      ..writeln('                constraints: const BoxConstraints('
          'maxWidth: ${formatNumber(Breakpoints.maxContentWidth)}),')
      ..writeln('                child: SizedBox(')
      ..writeln('                  width: double.infinity,')
      ..writeln('                  child: $root,')
      ..writeln('                ),')
      ..writeln('              ),')
      ..writeln('            ),')
      ..writeln('          );')
      ..writeln('        },')
      ..writeln('      ),')
      ..writeln('    );')
      ..writeln('  }')
      ..writeln('}');
    for (final source in _extracted) {
      buffer
        ..writeln()
        ..write(source);
    }
    return buffer.toString();
  }

  CodeExpr _appBar() {
    final doc = document;
    final background = _color(doc.bar(BarKeys.appBarColor));
    final foreground = _color(doc.bar(BarKeys.appBarForeground));
    CodeExpr iconButton(String icon, String link, {String badge = ''}) {
      CodeExpr glyph = CallCode('Icon', [Arg.positional(RawCode('Icons.$icon'))]);
      if (badge.trim().isNotEmpty) {
        glyph = CallCode('Badge', [
          Arg('label', CallCode('Text', [Arg.positional(RawCode(dartString(badge.trim())))])),
          Arg('child', glyph),
        ]);
      }
      return CallCode('IconButton', [
        Arg('onPressed', BlockCode(_tapLines(link, ''))),
        Arg('icon', glyph),
      ]);
    }

    final leading = doc.bar(BarKeys.leadingIcon);
    final actions = [
      if (doc.bar(BarKeys.action1Icon).isNotEmpty)
        iconButton(doc.bar(BarKeys.action1Icon), doc.bar(BarKeys.action1Link),
            badge: doc.bar(BarKeys.action1Badge)),
      if (doc.bar(BarKeys.action2Icon).isNotEmpty)
        iconButton(doc.bar(BarKeys.action2Icon), doc.bar(BarKeys.action2Link)),
    ];
    return CallCode('AppBar', [
      Arg('title', CallCode('Text', [Arg.positional(RawCode(dartString(doc.title)))])),
      if (doc.barFlag(BarKeys.centerTitle))
        const Arg('centerTitle', RawCode('true')),
      if (background != null) Arg('backgroundColor', background),
      if (foreground != null) Arg('foregroundColor', foreground),
      if (leading.isNotEmpty)
        Arg('leading', iconButton(leading, doc.bar(BarKeys.leadingLink))),
      if (actions.isNotEmpty) Arg('actions', ListCode(actions)),
    ]);
  }

  void _writeBottomNav(StringBuffer buffer) {
    final index = navItems.indexWhere((item) => item.screenId == document.id);
    if (index < 0) return;
    usesRoutes = true;
    final routes = navItems.map((item) => 'AppRoutes.${item.route}').join(', ');
    buffer
      ..writeln('      bottomNavigationBar: NavigationBar(')
      ..writeln('        selectedIndex: $index,')
      ..writeln('        onDestinationSelected: (index) {')
      ..writeln('          const routes = [$routes];')
      ..writeln('          if (index != $index) {')
      ..writeln('            Navigator.pushReplacementNamed(context, routes[index]);')
      ..writeln('          }')
      ..writeln('        },')
      ..writeln('        destinations: const [');
    for (final item in navItems) {
      buffer.writeln('          NavigationDestination(icon: Icon(Icons.${item.icon}), '
          'label: ${dartString(item.label)}),');
    }
    buffer
      ..writeln('        ],')
      ..writeln('      ),');
  }

  /// One widget expression followed by any extracted widget classes.
  String writeWidget(WidgetNode node) {
    final buffer = StringBuffer(_node(node, extract: false).render(0));
    for (final source in _extracted) {
      buffer
        ..writeln()
        ..writeln()
        ..write(source.trimRight());
    }
    buffer.writeln();
    return buffer.toString();
  }

  /// Builds a node, sized and spaced, or positioned when it sits in a free
  /// canvas. Named layers become their own `StatelessWidget`.
  CodeExpr _node(WidgetNode n, {bool extract = true, WidgetNode? parent}) {
    CodeExpr expr;
    if (extract && n.name.trim().isNotEmpty) {
      expr = _extract(n);
    } else {
      expr = _build(n);
    }
    expr = _animated(n, _tappable(n, expr));
    return WidgetCatalog.isFreeLayout(parent)
        ? _positioned(n, expr)
        : _boxed(n, expr);
  }

  /// Any widget except a button (which has `onPressed`) can open a screen
  /// or run an action when tapped.
  CodeExpr _tappable(WidgetNode n, CodeExpr expr) {
    if (n.type == WidgetTypes.button) return expr;
    if (n.string('navigateTo').isEmpty && n.string('action').trim().isEmpty) {
      return expr;
    }
    return CallCode('GestureDetector', [
      const Arg('behavior', RawCode('HitTestBehavior.opaque')),
      Arg('onTap', BlockCode(_tapLines(n.string('navigateTo'), n.string('action')))),
      Arg('child', expr),
    ]);
  }

  /// Plays the widget's entrance animation when the screen opens.
  CodeExpr _animated(WidgetNode n, CodeExpr expr) {
    final effect =
        WidgetCatalog.choiceOf(n, 'animation', PropOptions.animations);
    if (effect == 'none') return expr;
    helpers.add(_Helper.entranceAnimation);
    final ms = n.number('animationMs', 400);
    return CallCode('EntranceAnimation', [
      Arg('effect', RawCode('EntranceEffect.$effect')),
      Arg(
        'duration',
        CallCode('Duration', [Arg('milliseconds', RawCode(formatNumber(ms)))]),
      ),
      Arg('child', expr),
    ]);
  }

  /// Applies the width, height and outer spacing every widget can have.
  CodeExpr _boxed(WidgetNode n, CodeExpr expr) {
    var result = expr;
    if (n.type != WidgetTypes.container) {
      final width = n.number('width');
      final height = WidgetCatalog.fixedHeight(n) ?? 0;
      if (width > 0 || height > 0) {
        result = CallCode('SizedBox', [
          if (width > 0) Arg('width', _num(width)),
          if (height > 0) Arg('height', _num(height)),
          Arg('child', result),
        ]);
      }
    }
    final margin = n.number('margin');
    if (margin > 0) {
      result = CallCode('Padding', [
        Arg('padding', _edgeAll(margin)),
        Arg('child', result),
      ]);
    }
    // A column that stretches its children would ignore the width, so a
    // widget with its own width keeps exactly that size.
    if (n.number('width') > 0) {
      result = CallCode('Align', [
        const Arg('alignment', RawCode('Alignment.centerLeft')),
        const Arg('widthFactor', RawCode('1')),
        Arg('child', result),
      ]);
    }
    return result;
  }

  CodeExpr _positioned(WidgetNode n, CodeExpr expr) {
    if (n.boolean('fill')) {
      return CallCode('Positioned.fill', [Arg('child', expr)]);
    }
    final width = WidgetCatalog.freeCanvasWidth(n);
    final height = WidgetCatalog.fixedHeight(n) ?? 0;
    return CallCode('Positioned', [
      Arg('left', _num(n.number('x'))),
      Arg('top', _num(n.number('y'))),
      if (width != null) Arg('width', _num(width)),
      if (height > 0) Arg('height', _num(height)),
      Arg('child', expr),
    ]);
  }

  /// Turns a named layer into its own widget class and returns a call to it.
  CodeExpr _extract(WidgetNode n) {
    final base = FlutterCodeGenerator.className(n.name);
    var name = base;
    for (var i = 2; _usedNames.contains(name); i++) {
      name = '$base$i';
    }
    _usedNames.add(name);
    final body = _build(n).render(2);
    _extracted.add(
      'class $name extends StatelessWidget {\n'
      '  const $name({super.key});\n'
      '\n'
      '  @override\n'
      '  Widget build(BuildContext context) {\n'
      '    return $body;\n'
      '  }\n'
      '}\n',
    );
    return CallCode(name);
  }

  List<CodeExpr> _children(WidgetNode n) => [
        for (final child in n.children) _node(child, parent: n),
      ];

  CodeExpr _build(WidgetNode n) {
    String choice(String key, List<String> options) =>
        WidgetCatalog.choiceOf(n, key, options);

    switch (n.type) {
      case WidgetTypes.column:
        {
          final main = choice('mainAxisAlignment', PropOptions.mainAxis);
          final cross = choice('crossAxisAlignment', PropOptions.columnCross);
          final spacing = n.number('spacing');
          return CallCode('Column', [
            const Arg('mainAxisSize', RawCode('MainAxisSize.min')),
            if (main != 'start')
              Arg('mainAxisAlignment', RawCode('MainAxisAlignment.$main')),
            if (cross != 'center')
              Arg('crossAxisAlignment', RawCode('CrossAxisAlignment.$cross')),
            if (spacing > 0) Arg('spacing', _num(spacing)),
            Arg('children', ListCode(_children(n))),
          ]);
        }
      case WidgetTypes.row:
        {
          final main = choice('mainAxisAlignment', PropOptions.mainAxis);
          final cross = choice('crossAxisAlignment', PropOptions.rowCross);
          final spacing = n.number('spacing');
          return CallCode('Row', [
            if (main != 'start')
              Arg('mainAxisAlignment', RawCode('MainAxisAlignment.$main')),
            if (cross != 'center')
              Arg('crossAxisAlignment', RawCode('CrossAxisAlignment.$cross')),
            if (spacing > 0) Arg('spacing', _num(spacing)),
            Arg(
              'children',
              ListCode([
                for (final child in _children(n))
                  CallCode('Flexible', [Arg('child', child)]),
              ]),
            ),
          ]);
        }
      case WidgetTypes.adaptiveRow:
        helpers.add(_Helper.adaptiveRow);
        return CallCode('AdaptiveRow', [
          Arg('breakpoint', _num(n.number('breakpoint', Breakpoints.tablet))),
          Arg('spacing', _num(n.number('spacing'))),
          Arg('children', ListCode(_children(n))),
        ]);
      case WidgetTypes.grid:
        helpers.add(_Helper.responsiveGrid);
        return CallCode('ResponsiveGrid', [
          Arg('mobileColumns', RawCode('${_columns(n, 'mobileColumns')}')),
          Arg('tabletColumns', RawCode('${_columns(n, 'tabletColumns')}')),
          Arg('desktopColumns', RawCode('${_columns(n, 'desktopColumns')}')),
          Arg('spacing', _num(n.number('spacing'))),
          Arg('children', ListCode(_children(n))),
        ]);
      case WidgetTypes.freeCanvas:
        {
          helpers.add(_Helper.freeCanvas);
          final color = _color(n.string('color'));
          return CallCode('FreeCanvas', [
            Arg('designWidth', _num(n.number('designWidth', 360))),
            Arg('designHeight', _num(n.number('designHeight', 320))),
            if (color != null) Arg('color', color),
            Arg('borderRadius', _num(n.number('borderRadius'))),
            Arg('children', ListCode(_children(n))),
          ]);
        }
      case WidgetTypes.box:
        {
          final color = _color(n.string('color'));
          final borderColor = _color(n.string('borderColor'));
          final borderWidth = n.number('borderWidth');
          final shadow = n.number('shadow');
          final padding = n.number('padding');
          return CallCode(
            'Container',
            [
              if (padding > 0) Arg('padding', _edgeAll(padding)),
              const Arg('clipBehavior', RawCode('Clip.antiAlias')),
              Arg(
                'decoration',
                CallCode('BoxDecoration', [
                  if (color != null) Arg('color', color),
                  Arg('borderRadius', _radius(n.number('borderRadius'))),
                  if (borderColor != null && borderWidth > 0)
                    Arg(
                      'border',
                      CallCode('Border.fromBorderSide', [
                        Arg.positional(CallCode('BorderSide', [
                          Arg('color', borderColor),
                          Arg('width', _num(borderWidth)),
                        ])),
                      ]),
                    ),
                  if (shadow > 0)
                    Arg(
                      'boxShadow',
                      ListCode([
                        CallCode('BoxShadow', [
                          const Arg('color', RawCode('Color(0x33000000)')),
                          Arg('blurRadius', _num(shadow * 2)),
                          Arg(
                            'offset',
                            CallCode('Offset', [
                              const Arg.positional(RawCode('0')),
                              Arg.positional(_num(shadow / 2)),
                            ]),
                          ),
                        ]),
                      ]),
                    ),
                ]),
              ),
              Arg('child', _boxContent(n)),
            ],
            false,
          );
        }
      case WidgetTypes.container:
        {
          final color = _color(n.string('color'));
          final width = n.number('width');
          final height = n.number('height');
          return CallCode(
            'Container',
            [
              if (width > 0) Arg('width', _num(width)),
              if (height > 0) Arg('height', _num(height)),
              Arg('padding', _edgeAll(n.number('padding'))),
              Arg(
                'decoration',
                CallCode('BoxDecoration', [
                  if (color != null) Arg('color', color),
                  Arg('borderRadius', _radius(n.number('borderRadius'))),
                ]),
              ),
              if (n.children.isNotEmpty) Arg('child', _node(n.children.first)),
            ],
            false,
          );
        }
      case WidgetTypes.card:
        {
          final color = _color(n.string('color'));
          final elevation = n.number('elevation', 1);
          return CallCode('Card', [
            const Arg('margin', RawCode('EdgeInsets.zero')),
            if (color != null) Arg('color', color),
            if (elevation != 1) Arg('elevation', _num(elevation)),
            Arg(
              'shape',
              CallCode('RoundedRectangleBorder', [
                Arg('borderRadius', _radius(n.number('borderRadius'))),
              ]),
            ),
            Arg(
              'child',
              CallCode('Padding', [
                Arg('padding', _edgeAll(n.number('padding'))),
                if (n.children.isNotEmpty)
                  Arg('child', _node(n.children.first)),
              ]),
            ),
          ]);
        }
      case WidgetTypes.text:
        {
          final color = _color(n.string('color'));
          final weight = choice('fontWeight', PropOptions.fontWeight);
          final align = choice('textAlign', PropOptions.textAlign);
          return CallCode('Text', [
            Arg.positional(RawCode(dartString(n.string('text')))),
            if (align != 'left') Arg('textAlign', RawCode('TextAlign.$align')),
            Arg(
              'style',
              CallCode('TextStyle', [
                Arg('fontSize', _num(n.number('fontSize', 16))),
                if (weight != 'normal')
                  Arg('fontWeight', RawCode(_fontWeight(weight))),
                if (color != null) Arg('color', color),
              ]),
            ),
          ]);
        }
      case WidgetTypes.button:
        return _button(n);
      case WidgetTypes.icon:
        {
          final color = _color(n.string('color'));
          final icon = CallCode('Icon', [
            Arg.positional(
                RawCode('Icons.${choice('icon', PropOptions.icons)}')),
            Arg('size', _num(n.number('size', 24))),
            if (color != null) Arg('color', color),
          ]);
          final badge = n.string('badge').trim();
          if (badge.isEmpty) return icon;
          return CallCode('Badge', [
            Arg('label', CallCode('Text', [Arg.positional(RawCode(dartString(badge)))])),
            Arg('child', icon),
          ]);
        }
      case WidgetTypes.customCode:
        {
          for (final line in n.string('imports').split('\n')) {
            final trimmed = line.trim();
            if (trimmed.isNotEmpty) imports.add(trimmed);
          }
          for (final line in n.string('packages').split('\n')) {
            final trimmed = line.trim();
            if (trimmed.isNotEmpty) packages.add(trimmed);
          }
          final code = n.string('code').trim();
          return RawCode(
            code.isEmpty ? 'const SizedBox.shrink()' : code,
            isConst: false,
          );
        }
      case WidgetTypes.image:
        return CallCode('ClipRRect', [
          Arg('borderRadius', _radius(n.number('borderRadius'))),
          Arg(
            'child',
            CallCode(
              'Image.network',
              [
                Arg.positional(RawCode(dartString(n.string('url')))),
                Arg('height', _num(n.number('height', 180))),
                const Arg('width', RawCode('double.infinity')),
                Arg('fit', RawCode('BoxFit.${choice('fit', PropOptions.imageFit)}')),
              ],
              false,
            ),
          ),
        ]);
      case WidgetTypes.textField:
        {
          final label = n.string('label');
          final hint = n.string('hint');
          return CallCode('TextField', [
            if (n.boolean('obscure')) const Arg('obscureText', RawCode('true')),
            Arg(
              'decoration',
              CallCode('InputDecoration', [
                if (label.isNotEmpty)
                  Arg('labelText', RawCode(dartString(label))),
                if (hint.isNotEmpty) Arg('hintText', RawCode(dartString(hint))),
                const Arg('border', CallCode('OutlineInputBorder')),
              ]),
            ),
          ]);
        }
      case WidgetTypes.divider:
        {
          final color = _color(n.string('color'));
          return CallCode('Divider', [
            Arg('thickness', _num(n.number('thickness', 1))),
            if (color != null) Arg('color', color),
          ]);
        }
      case WidgetTypes.spacer:
        {
          final size = _num(n.number('size', 16));
          return CallCode('SizedBox', [Arg('width', size), Arg('height', size)]);
        }
      default:
        final type = n.type.replaceAll('*/', '');
        return RawCode(
          'const SizedBox.shrink() /* unsupported: $type */',
          isConst: false,
        );
    }
  }

  /// A box's children: at exact positions, or in a row or column like
  /// Figma's auto layout.
  CodeExpr _boxContent(WidgetNode n) {
    final layout = WidgetCatalog.choiceOf(n, 'layout', PropOptions.boxLayout);
    if (layout == 'free') {
      return CallCode('Stack', [Arg('children', ListCode(_children(n)))]);
    }
    final main =
        WidgetCatalog.choiceOf(n, 'mainAxisAlignment', PropOptions.mainAxis);
    final cross =
        WidgetCatalog.choiceOf(n, 'crossAxisAlignment', PropOptions.rowCross);
    final spacing = n.number('spacing');
    final isRow = layout == 'row';
    final children = _children(n);
    return CallCode(isRow ? 'Row' : 'Column', [
      const Arg('mainAxisSize', RawCode('MainAxisSize.min')),
      if (main != 'start')
        Arg('mainAxisAlignment', RawCode('MainAxisAlignment.$main')),
      if (cross != 'center')
        Arg('crossAxisAlignment', RawCode('CrossAxisAlignment.$cross')),
      if (spacing > 0) Arg('spacing', _num(spacing)),
      Arg(
        'children',
        ListCode(isRow
            ? [
                for (final child in children)
                  CallCode('Flexible', [Arg('child', child)]),
              ]
            : children),
      ),
    ]);
  }

  CodeExpr _button(WidgetNode n) {
    final color = _color(n.string('color'));
    final variant =
        WidgetCatalog.choiceOf(n, 'variant', PropOptions.buttonVariant);
    final String widget;
    final List<Arg> style;
    switch (variant) {
      case 'elevated':
        widget = 'ElevatedButton';
        style = [
          if (color != null) Arg('backgroundColor', color),
          if (color != null)
            const Arg('foregroundColor', RawCode('Colors.white')),
        ];
      case 'outlined':
        widget = 'OutlinedButton';
        style = [
          if (color != null) Arg('foregroundColor', color),
          if (color != null)
            Arg('side', CallCode('BorderSide', [Arg('color', color)])),
        ];
      case 'text':
        widget = 'TextButton';
        style = [if (color != null) Arg('foregroundColor', color)];
      default:
        widget = 'FilledButton';
        style = [if (color != null) Arg('backgroundColor', color)];
    }

    CodeExpr button = CallCode(widget, [
      Arg('onPressed',
          BlockCode(_tapLines(n.string('navigateTo'), n.string('action')))),
      if (style.isNotEmpty)
        Arg('style', CallCode('$widget.styleFrom', style, false)),
      Arg(
        'child',
        CallCode('Text', [
          Arg.positional(RawCode(dartString(n.string('label')))),
        ]),
      ),
    ]);
    if (n.boolean('fullWidth')) {
      button = CallCode('SizedBox', [
        const Arg('width', RawCode('double.infinity')),
        Arg('child', button),
      ]);
    }
    return button;
  }

  /// What a tap does: run an action, open a screen, or go back.
  List<String> _tapLines(String target, String rawAction) {
    final lines = <String>[];
    final action = rawAction.replaceAll(RegExp(r'[\r\n]'), ' ').trim();
    if (action.isNotEmpty) lines.add('// TODO: Handle the "$action" action.');
    if (target == 'back') {
      lines.add('Navigator.maybePop(context);');
    } else if (target.isNotEmpty) {
      final key = routeKeys?[target];
      if (key != null) {
        usesRoutes = true;
        lines.add('Navigator.pushNamed(context, AppRoutes.$key);');
      } else {
        lines.add('// TODO: Open the next screen.');
      }
    }
    if (lines.isEmpty) lines.add('// TODO: Add what this button does.');
    return lines;
  }

  static CodeExpr _num(double value) => RawCode(formatNumber(value));

  static CodeExpr _edgeAll(double value) =>
      CallCode('EdgeInsets.all', [Arg.positional(_num(value))]);

  static CodeExpr _radius(double value) => CallCode('BorderRadius.all', [
        Arg.positional(
            CallCode('Radius.circular', [Arg.positional(_num(value))])),
      ]);

  static int _columns(WidgetNode n, String key) {
    final value = n.number(key, 1).round();
    return value < 1 ? 1 : (value > 12 ? 12 : value);
  }

  static String? _colorLiteral(String hex) {
    final value = parseHexColor(hex);
    if (value == null) return null;
    return 'Color(0x${value.toRadixString(16).padLeft(8, '0').toUpperCase()})';
  }

  static CodeExpr? _color(String hex) {
    final value = parseHexColor(hex);
    if (value == null) return null;
    final literal = value.toRadixString(16).padLeft(8, '0').toUpperCase();
    return CallCode('Color', [Arg.positional(RawCode('0x$literal'))]);
  }

  static String _fontWeight(String weight) => switch (weight) {
        'medium' => 'FontWeight.w500',
        'semibold' => 'FontWeight.w600',
        'bold' => 'FontWeight.w700',
        _ => 'FontWeight.w400',
      };
}

const _adaptiveRowSource = '''
/// Shows children side by side on wide screens and stacks them on phones.
class AdaptiveRow extends StatelessWidget {
  const AdaptiveRow({
    super.key,
    required this.children,
    this.spacing = 16,
    this.breakpoint = 600,
  });

  final List<Widget> children;
  final double spacing;
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
''';

const _responsiveGridSource = '''
/// Lays children out in a grid whose column count depends on screen width.
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final columns = screenWidth >= 1024
        ? desktopColumns
        : screenWidth >= 600
            ? tabletColumns
            : mobileColumns;
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
''';

const _freeCanvasSource = '''
/// A design frame where children sit at exact positions, like a Figma
/// frame. It keeps its design size and shrinks to fit narrower screens.
class FreeCanvas extends StatelessWidget {
  const FreeCanvas({
    super.key,
    required this.designWidth,
    required this.designHeight,
    required this.children,
    this.color,
    this.borderRadius = 0,
  });

  final double designWidth;
  final double designHeight;
  final List<Widget> children;
  final Color? color;
  final double borderRadius;

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
          child: Stack(children: children),
        ),
      ),
    );
  }
}
''';

const _entranceAnimationSource = '''
/// The ways a widget can appear when its screen opens.
enum EntranceEffect { fade, slideUp, slideLeft, scale }

/// Plays a short entrance animation once, when the widget first appears.
class EntranceAnimation extends StatelessWidget {
  const EntranceAnimation({
    super.key,
    required this.effect,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
  });

  final EntranceEffect effect;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        final faded = Opacity(opacity: value, child: child);
        return switch (effect) {
          EntranceEffect.fade => faded,
          EntranceEffect.slideUp => Transform.translate(
              offset: Offset(0, 24 * (1 - value)),
              child: faded,
            ),
          EntranceEffect.slideLeft => Transform.translate(
              offset: Offset(24 * (1 - value), 0),
              child: faded,
            ),
          EntranceEffect.scale => Transform.scale(
              scale: 0.85 + 0.15 * value,
              child: faded,
            ),
        };
      },
    );
  }
}
''';
