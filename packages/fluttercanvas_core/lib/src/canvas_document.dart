import 'dart:convert';

import 'widget_catalog.dart';
import 'widget_node.dart';

/// Keys of [CanvasDocument.bars].
abstract final class BarKeys {
  static const appBarColor = 'appBarColor';
  static const appBarForeground = 'appBarForeground';
  static const centerTitle = 'centerTitle';
  static const leadingIcon = 'leadingIcon';
  static const leadingLink = 'leadingLink';
  static const action1Icon = 'action1Icon';
  static const action1Link = 'action1Link';
  static const action1Badge = 'action1Badge';
  static const action2Icon = 'action2Icon';
  static const action2Link = 'action2Link';

  /// Icon of this screen in the bottom navigation bar. Screens with an
  /// icon here share one bottom navigation bar.
  static const navIcon = 'navIcon';
  static const navLabel = 'navLabel';
}

/// One screen of a design: page settings plus the widget tree.
class CanvasDocument {
  CanvasDocument({
    required this.root,
    String? id,
    this.name = 'Home',
    this.title = 'Home',
    this.showAppBar = true,
    this.backgroundColor = '#FFFFFFFF',
    Map<String, Object?> bars = const {},
  })  : id = id ?? NodeIds.next(),
        bars = Map.unmodifiable(bars);

  /// An empty screen with a single root column.
  factory CanvasDocument.blank({String name = 'Home', String title = 'Home'}) =>
      CanvasDocument(
        name: name,
        title: title,
        root: WidgetNode(
          id: 'root',
          type: WidgetTypes.column,
          props: WidgetCatalog.defaultsFor(WidgetTypes.column),
        ),
      );

  /// An empty free-form screen: one phone-sized frame where you can draw
  /// boxes and place widgets anywhere.
  factory CanvasDocument.freeForm({
    String name = 'Home',
    String title = 'Home',
  }) =>
      CanvasDocument(
        name: name,
        title: title,
        root: WidgetNode(
          id: 'root',
          type: WidgetTypes.freeCanvas,
          props: {
            ...WidgetCatalog.defaultsFor(WidgetTypes.freeCanvas),
            'designWidth': 390,
            'designHeight': 760,
            'color': '#FFFFFFFF',
            'borderRadius': 0,
          },
        ),
      );

  /// A small sample page that shows off the responsive widgets.
  factory CanvasDocument.starter() {
    WidgetNode n(
      String type, [
      Map<String, Object?> props = const {},
      List<WidgetNode> children = const [],
    ]) =>
        WidgetNode(
          id: NodeIds.next(),
          type: type,
          props: {...WidgetCatalog.defaultsFor(type), ...props},
          children: children,
        );

    WidgetNode feature(String icon, String title, String body) => n(
          WidgetTypes.card,
          {'padding': 20},
          [
            n(WidgetTypes.column, {'spacing': 8, 'crossAxisAlignment': 'start'}, [
              n(WidgetTypes.icon, {'icon': icon, 'size': 28}),
              n(WidgetTypes.text, {
                'text': title,
                'fontSize': 18,
                'fontWeight': 'semibold',
              }),
              n(WidgetTypes.text, {
                'text': body,
                'fontSize': 14,
                'color': '#FF6B7280',
              }),
            ]),
          ],
        );

    return CanvasDocument(
      root: WidgetNode(
        id: 'root',
        type: WidgetTypes.column,
        props: {
          ...WidgetCatalog.defaultsFor(WidgetTypes.column),
          'spacing': 16,
        },
        children: [
          n(WidgetTypes.text, {
            'text': 'Welcome to FlutterCanvas',
            'fontSize': 28,
            'fontWeight': 'bold',
          }),
          n(WidgetTypes.text, {
            'text': 'Drag widgets from the palette, edit them on the right, '
                'then export clean, responsive Flutter code.',
            'fontSize': 16,
            'color': '#FF6B7280',
          }),
          n(WidgetTypes.grid, {}, [
            feature('favorite', 'Design visually',
                'Drag and drop widgets to build a screen in minutes.'),
            feature('phone', 'Responsive by default',
                'Layouts adapt to phones, tablets, desktop and the web.'),
            feature('check', 'Clean code export',
                'Readable Flutter code with no extra dependencies.'),
          ]),
          n(WidgetTypes.button, {'label': 'Get started'}),
        ],
      ),
    );
  }

  /// Creates a document from JSON produced by [toJson].
  factory CanvasDocument.fromJson(Map<String, Object?> json) {
    final root = json['root'];
    if (root is! Map) {
      throw const FormatException('Design JSON is missing a "root" widget.');
    }
    String text(String key, String fallback) {
      final value = json[key];
      return value is String ? value : fallback;
    }

    final showAppBar = json['showAppBar'];
    final id = json['id'];
    final bars = json['bars'];
    return CanvasDocument(
      bars: bars is Map ? _stringKeyed(bars) : const {},
      root: WidgetNode.fromJson(_stringKeyed(root)),
      id: id is String && id.isNotEmpty ? id : null,
      name: text('name', 'Home'),
      title: text('title', 'Home'),
      showAppBar: showAppBar is bool ? showAppBar : true,
      backgroundColor: text('backgroundColor', '#FFFFFFFF'),
    );
  }

  /// Parses a JSON string produced by [toJsonString].
  factory CanvasDocument.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Design JSON must be an object.');
    }
    return CanvasDocument.fromJson(_stringKeyed(decoded));
  }

  /// Version of the JSON format written by [toJson].
  static const int schemaVersion = 1;

  /// Unique id of this screen within its project. Buttons link to screens
  /// by this id.
  final String id;

  /// Screen name, used for the generated class and file names.
  final String name;

  /// App bar title.
  final String title;

  /// Whether the screen has an app bar.
  final bool showAppBar;

  /// Page background as `#AARRGGBB`, or empty for the theme default.
  final String backgroundColor;

  /// Root of the widget tree.
  final WidgetNode root;

  /// App bar and bottom navigation settings, keyed by [BarKeys].
  final Map<String, Object?> bars;

  /// Reads a text setting from [bars].
  String bar(String key) {
    final value = bars[key];
    return value is String ? value : '';
  }

  /// Reads an on/off setting from [bars].
  bool barFlag(String key) => bars[key] == true;

  CanvasDocument copyWith({
    WidgetNode? root,
    String? name,
    String? title,
    bool? showAppBar,
    String? backgroundColor,
    Map<String, Object?>? bars,
  }) {
    return CanvasDocument(
      root: root ?? this.root,
      id: id,
      bars: bars ?? this.bars,
      name: name ?? this.name,
      title: title ?? this.title,
      showAppBar: showAppBar ?? this.showAppBar,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'name': name,
        'title': title,
        'showAppBar': showAppBar,
        'backgroundColor': backgroundColor,
        if (bars.isNotEmpty) 'bars': Map<String, Object?>.of(bars),
        'root': root.toJson(),
      };

  String toJsonString({bool pretty = false}) => pretty
      ? const JsonEncoder.withIndent('  ').convert(toJson())
      : jsonEncode(toJson());
}

Map<String, Object?> _stringKeyed(Map<dynamic, dynamic> map) =>
    map.map((key, value) => MapEntry(key.toString(), value));
