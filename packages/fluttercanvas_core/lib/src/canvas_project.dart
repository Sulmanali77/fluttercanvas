import 'dart:convert';

import 'canvas_document.dart';
import 'tree_ops.dart';
import 'widget_catalog.dart';
import 'widget_node.dart';

/// A whole app design: several screens and the one the app starts on.
class CanvasProject {
  CanvasProject({
    required List<CanvasDocument> screens,
    String? initialScreenId,
    this.name = 'My App',
  })  : assert(screens.isNotEmpty, 'A project needs at least one screen.'),
        screens = List.unmodifiable(screens),
        initialScreenId = initialScreenId != null &&
                screens.any((screen) => screen.id == initialScreenId)
            ? initialScreenId
            : screens.first.id;

  /// A two-screen sample where a button on Home opens Details.
  factory CanvasProject.starter() {
    final details = CanvasDocument(
      name: 'Details',
      title: 'Details',
      root: WidgetNode(
        id: 'root',
        type: WidgetTypes.column,
        props: {
          ...WidgetCatalog.defaultsFor(WidgetTypes.column),
          'spacing': 16,
        },
        children: [
          _node(WidgetTypes.text, {
            'text': 'Details',
            'fontSize': 24,
            'fontWeight': 'bold',
          }),
          _node(WidgetTypes.text, {
            'text': 'You got here through a linked button. '
                'Press the play button in the toolbar to try it.',
            'color': '#FF6B7280',
          }),
          _node(WidgetTypes.button, {
            'label': 'Go back',
            'variant': 'outlined',
            'navigateTo': 'back',
          }),
        ],
      ),
    );

    var home = CanvasDocument.starter();
    final button = home.root.children
        .lastWhere((node) => node.type == WidgetTypes.button);
    home = home.copyWith(
      root: home.root.update(
        button.id,
        (node) => node.withProp('navigateTo', details.id),
      ),
    );
    return CanvasProject(screens: [home, details]);
  }

  /// Reads a project, or a single screen saved by version 0.1.
  factory CanvasProject.fromJson(Map<String, Object?> json) {
    final rawScreens = json['screens'];
    if (rawScreens is List) {
      final screens = [
        for (final screen in rawScreens)
          if (screen is Map) CanvasDocument.fromJson(_stringKeyed(screen)),
      ];
      if (screens.isEmpty) {
        throw const FormatException('A project needs at least one screen.');
      }
      final initial = json['initialScreen'];
      final name = json['name'];
      return CanvasProject(
        screens: screens,
        initialScreenId: initial is String ? initial : null,
        name: name is String ? name : 'My App',
      );
    }
    return CanvasProject(screens: [CanvasDocument.fromJson(json)]);
  }

  factory CanvasProject.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Design JSON must be an object.');
    }
    return CanvasProject.fromJson(_stringKeyed(decoded));
  }

  /// Version of the JSON format written by [toJson].
  static const int schemaVersion = 2;

  /// App name, used as the title in the generated `main.dart`.
  final String name;
  final List<CanvasDocument> screens;

  /// Id of the screen the app opens on.
  final String initialScreenId;

  CanvasDocument get initialScreen => screenById(initialScreenId)!;

  CanvasDocument? screenById(String id) {
    for (final screen in screens) {
      if (screen.id == id) return screen;
    }
    return null;
  }

  CanvasProject copyWith({
    String? name,
    List<CanvasDocument>? screens,
    String? initialScreenId,
  }) {
    return CanvasProject(
      name: name ?? this.name,
      screens: screens ?? this.screens,
      initialScreenId: initialScreenId ?? this.initialScreenId,
    );
  }

  /// Replaces the screen that has the same id as [screen].
  CanvasProject withScreen(CanvasDocument screen) => copyWith(
        screens: [
          for (final existing in screens)
            existing.id == screen.id ? screen : existing,
        ],
      );

  CanvasProject addScreen(CanvasDocument screen) =>
      copyWith(screens: [...screens, screen]);

  /// Removes a screen. The last screen can't be removed.
  CanvasProject removeScreen(String id) {
    final rest = screens.where((screen) => screen.id != id).toList();
    if (rest.isEmpty) return this;
    return CanvasProject(
      name: name,
      screens: rest,
      initialScreenId: initialScreenId == id ? rest.first.id : initialScreenId,
    );
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'name': name,
        'initialScreen': initialScreenId,
        'screens': [for (final screen in screens) screen.toJson()],
      };

  String toJsonString({bool pretty = false}) => pretty
      ? const JsonEncoder.withIndent('  ').convert(toJson())
      : jsonEncode(toJson());
}

WidgetNode _node(String type, Map<String, Object?> props) => WidgetNode(
      id: NodeIds.next(),
      type: type,
      props: {...WidgetCatalog.defaultsFor(type), ...props},
    );

Map<String, Object?> _stringKeyed(Map<dynamic, dynamic> map) =>
    map.map((key, value) => MapEntry(key.toString(), value));
