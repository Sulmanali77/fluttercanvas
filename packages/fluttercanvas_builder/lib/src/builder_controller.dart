import 'package:flutter/foundation.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

import 'device_preset.dart';
import 'drag_payload.dart';

/// Where a dropped widget will be inserted.
typedef DropDestination = ({String parentId, int index});

/// State of the builder: the design, the selection, the preview device and
/// undo history.
///
/// Create your own controller to load a design, listen for changes or save
/// the design somewhere:
///
/// ```dart
/// final controller = BuilderController(
///   document: CanvasDocument.fromJsonString(savedJson),
/// );
/// controller.addListener(() => save(controller.exportJson()));
/// ```
class BuilderController extends ChangeNotifier {
  BuilderController({
    CanvasDocument? document,
    DevicePreset device = DevicePreset.iphone,
  })  : _document = document ?? CanvasDocument.starter(),
        _device = device;

  static const _historyLimit = 100;

  CanvasDocument _document;
  DevicePreset _device;
  String? _selectedId;
  String? _mergeKey;
  int _revision = 0;
  final List<CanvasDocument> _undo = [];
  final List<CanvasDocument> _redo = [];

  /// The current design.
  CanvasDocument get document => _document;

  WidgetNode get _root => _document.root;

  /// Id of the selected widget, or null when the screen settings are shown.
  String? get selectedId => _selectedId;

  /// The selected widget, if any.
  WidgetNode? get selectedNode {
    final id = _selectedId;
    return id == null ? null : _root.find(id);
  }

  /// Device used for the canvas preview.
  DevicePreset get device => _device;
  set device(DevicePreset value) {
    if (value == _device) return;
    _device = value;
    notifyListeners();
  }

  /// Changes whenever the document is replaced by undo, redo or loading,
  /// so editors know to refresh their text fields.
  int get revision => _revision;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Selects the widget with [id], or clears the selection.
  void select(String? id) {
    if (_selectedId == id) return;
    _selectedId = id;
    _mergeKey = null;
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    _redo.add(_document);
    _document = _undo.removeLast();
    _afterHistoryJump();
  }

  void redo() {
    if (!canRedo) return;
    _undo.add(_document);
    _document = _redo.removeLast();
    _afterHistoryJump();
  }

  /// Where a payload dropped on [targetId] will go, or null if nowhere.
  ///
  /// Layouts accept drops inside them. Other widgets insert the drop right
  /// after themselves in the nearest layout that accepts children.
  DropDestination? resolveDrop(String targetId) {
    final target = _root.find(targetId);
    if (target == null) return null;
    final mode = WidgetCatalog.of(target.type)?.childMode ?? ChildMode.none;
    if (mode == ChildMode.multiple) {
      return (parentId: target.id, index: target.children.length);
    }
    if (mode == ChildMode.single && target.children.isEmpty) {
      return (parentId: target.id, index: 0);
    }
    return _insertAfter(target.id);
  }

  DropDestination? _insertAfter(String nodeId) {
    final parent = _root.parentOf(nodeId);
    if (parent == null) return null;
    final mode = WidgetCatalog.of(parent.type)?.childMode ?? ChildMode.none;
    if (mode == ChildMode.multiple) {
      return (parentId: parent.id, index: parent.indexOfChild(nodeId) + 1);
    }
    return _insertAfter(parent.id);
  }

  /// Whether [payload] can be dropped on [targetId].
  bool canDrop(DragPayload payload, String targetId) {
    if (payload is MoveNodePayload) {
      if (payload.nodeId == _root.id) return false;
      final moving = _root.find(payload.nodeId);
      if (moving == null || moving.contains(targetId)) return false;
    }
    return resolveDrop(targetId) != null;
  }

  /// Drops [payload] on [targetId].
  void drop(DragPayload payload, String targetId) {
    if (!canDrop(payload, targetId)) return;
    final destination = resolveDrop(targetId)!;
    switch (payload) {
      case NewWidgetPayload(:final type):
        final node = WidgetCatalog.create(type);
        _selectedId = node.id;
        _setRoot(_root.insert(destination.parentId, destination.index, node));
      case MoveNodePayload(:final nodeId):
        _setRoot(_root.move(nodeId, destination.parentId, destination.index));
    }
  }

  /// Adds a new widget inside or after the selection, or at the end of the
  /// page when nothing is selected.
  void addWidget(String type) {
    final selected = _selectedId;
    final destination = (selected == null ? null : resolveDrop(selected)) ??
        (parentId: _root.id, index: _root.children.length);
    final node = WidgetCatalog.create(type);
    _selectedId = node.id;
    _setRoot(_root.insert(destination.parentId, destination.index, node));
  }

  /// Changes one property. Consecutive edits to the same property are merged
  /// into a single undo step.
  void updateProp(String nodeId, String key, Object? value) {
    _setRoot(
      _root.update(nodeId, (node) => node.withProp(key, value)),
      mergeKey: '$nodeId:$key',
    );
  }

  /// Changes page-level settings.
  void updateDocument({
    String? name,
    String? title,
    bool? showAppBar,
    String? backgroundColor,
  }) {
    final field = name != null
        ? 'name'
        : title != null
            ? 'title'
            : 'background';
    _commit(
      _document.copyWith(
        name: name,
        title: title,
        showAppBar: showAppBar,
        backgroundColor: backgroundColor,
      ),
      mergeKey: showAppBar != null ? null : 'document:$field',
    );
  }

  /// Deletes a widget and selects its parent.
  void deleteNode(String id) {
    if (id == _root.id) return;
    final parent = _root.parentOf(id);
    if (parent == null) return;
    _selectedId = parent.id;
    _setRoot(_root.remove(id));
  }

  /// Inserts a copy of a widget right after it.
  void duplicateNode(String id) {
    final parent = _root.parentOf(id);
    final node = _root.find(id);
    if (parent == null || node == null) return;
    if (WidgetCatalog.of(parent.type)?.childMode != ChildMode.multiple) return;
    final copy = node.cloneWithNewIds();
    _selectedId = copy.id;
    _setRoot(_root.insert(parent.id, parent.indexOfChild(id) + 1, copy));
  }

  /// Moves a widget up (-1) or down (+1) among its siblings.
  void moveSibling(String id, int delta) {
    final parent = _root.parentOf(id);
    if (parent == null) return;
    final index = parent.indexOfChild(id);
    final target = index + delta;
    if (target < 0 || target >= parent.children.length) return;
    final children = [...parent.children];
    final node = children.removeAt(index);
    children.insert(target, node);
    _setRoot(_root.update(parent.id, (p) => p.copyWith(children: children)));
  }

  /// Replaces the whole design. This can be undone.
  void loadDocument(CanvasDocument document) {
    _selectedId = null;
    _revision++;
    _commit(document);
  }

  /// Loads a design from JSON. Throws a [FormatException] for invalid input.
  void loadJson(String json) =>
      loadDocument(CanvasDocument.fromJsonString(json));

  /// The design as pretty-printed JSON.
  String exportJson() => _document.toJsonString(pretty: true);

  /// The design as a Flutter screen.
  String exportCode() => const FlutterCodeGenerator().generate(_document);

  void _setRoot(WidgetNode root, {String? mergeKey}) =>
      _commit(_document.copyWith(root: root), mergeKey: mergeKey);

  void _commit(CanvasDocument next, {String? mergeKey}) {
    if (mergeKey == null || mergeKey != _mergeKey) {
      _undo.add(_document);
      if (_undo.length > _historyLimit) _undo.removeAt(0);
    }
    _redo.clear();
    _mergeKey = mergeKey;
    _document = next;
    notifyListeners();
  }

  void _afterHistoryJump() {
    _mergeKey = null;
    _revision++;
    final id = _selectedId;
    if (id != null && _root.find(id) == null) _selectedId = null;
    notifyListeners();
  }
}
