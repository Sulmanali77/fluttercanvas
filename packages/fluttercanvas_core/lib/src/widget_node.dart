import 'dart:math';

import 'widget_catalog.dart';

/// Generates unique ids for widget nodes.
abstract final class NodeIds {
  static int _counter = 0;
  static final Random _random = Random();

  /// Returns a new id that is unique within a running app.
  static String next() {
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final count = (_counter++).toRadixString(36);
    final noise = _random.nextInt(1 << 20).toRadixString(36);
    return 'n$time$count$noise';
  }
}

/// One widget in a design: its type, its properties and its children.
///
/// Nodes are immutable. Use [copyWith], [withProp] and the tree helpers in
/// the `WidgetTree` extension to produce changed copies.
class WidgetNode {
  WidgetNode({
    required this.id,
    required this.type,
    Map<String, Object?> props = const {},
    List<WidgetNode> children = const [],
  })  : props = Map.unmodifiable(props),
        children = List.unmodifiable(children);

  /// Creates a node from JSON produced by [toJson].
  ///
  /// Missing properties fall back to the defaults in [WidgetCatalog].
  factory WidgetNode.fromJson(Map<String, Object?> json) {
    final type = json['type'];
    if (type is! String || type.isEmpty) {
      throw const FormatException('Every widget needs a "type".');
    }
    final id = json['id'];
    final rawProps = json['props'];
    final rawChildren = json['children'];
    return WidgetNode(
      id: id is String && id.isNotEmpty ? id : NodeIds.next(),
      type: type,
      props: {
        ...WidgetCatalog.defaultsFor(type),
        if (rawProps is Map) ..._stringKeyed(rawProps),
      },
      children: [
        if (rawChildren is List)
          for (final child in rawChildren)
            if (child is Map) WidgetNode.fromJson(_stringKeyed(child)),
      ],
    );
  }

  /// Unique id of this node within its document.
  final String id;

  /// Widget type, one of [WidgetTypes].
  final String type;

  /// Property values. Only JSON-friendly values: strings, numbers and bools.
  final Map<String, Object?> props;

  /// Child nodes, in order.
  final List<WidgetNode> children;

  /// Returns a copy with new [props] and/or [children].
  WidgetNode copyWith({
    Map<String, Object?>? props,
    List<WidgetNode>? children,
  }) {
    return WidgetNode(
      id: id,
      type: type,
      props: props ?? this.props,
      children: children ?? this.children,
    );
  }

  /// Returns a copy with one property changed.
  WidgetNode withProp(String key, Object? value) =>
      copyWith(props: {...props, key: value});

  /// Reads a string property.
  String string(String key, [String fallback = '']) {
    final value = props[key];
    return value is String ? value : fallback;
  }

  /// Reads a numeric property as a double.
  double number(String key, [double fallback = 0]) {
    final value = props[key];
    return value is num ? value.toDouble() : fallback;
  }

  /// Reads a boolean property.
  bool boolean(String key, [bool fallback = false]) {
    final value = props[key];
    return value is bool ? value : fallback;
  }

  /// Converts this node and its children to JSON.
  Map<String, Object?> toJson() => {
        'id': id,
        'type': type,
        'props': Map<String, Object?>.of(props),
        if (children.isNotEmpty)
          'children': [for (final child in children) child.toJson()],
      };

  @override
  String toString() => 'WidgetNode($type#$id)';
}

Map<String, Object?> _stringKeyed(Map<dynamic, dynamic> map) =>
    map.map((key, value) => MapEntry(key.toString(), value));
