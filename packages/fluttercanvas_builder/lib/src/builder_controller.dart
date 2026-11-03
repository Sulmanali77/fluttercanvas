import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

import 'device_preset.dart';
import 'drag_payload.dart';

/// What dragging on the canvas does.
enum CanvasTool {
  /// Select, move and resize widgets.
  select,

  /// Press and drag to draw a new box.
  box,
}

/// Where a dropped widget will be inserted.
typedef DropDestination = ({String parentId, int index});

/// State of the builder: the project and its screens, the selection, the
/// preview device, preview mode and undo history.
///
/// Create your own controller to load a design, listen for changes or save
/// it somewhere:
///
/// ```dart
/// final controller = BuilderController(
///   project: CanvasProject.fromJsonString(savedJson),
/// );
/// controller.addListener(() => save(controller.exportJson()));
/// ```
class BuilderController extends ChangeNotifier {
  BuilderController({
    CanvasProject? project,
    CanvasDocument? document,
    DevicePreset device = DevicePreset.iphone,
  })  : _project = project ??
            (document != null
                ? CanvasProject(screens: [document])
                : CanvasProject.starter()),
        _device = device {
    _currentScreenId = _project.initialScreenId;
  }

  static const _historyLimit = 100;

  CanvasProject _project;
  late String _currentScreenId;
  DevicePreset _device;
  String? _selectedId;
  String? _mergeKey;
  int _revision = 0;
  bool _previewing = false;
  CanvasTool _tool = CanvasTool.select;
  final List<String> _previewStack = [];
  final List<CanvasProject> _undo = [];
  final List<CanvasProject> _redo = [];

  /// Every screen in the design.
  CanvasProject get project => _project;

  /// The screen shown on the canvas.
  CanvasDocument get document =>
      _project.screenById(_currentScreenId) ?? _project.initialScreen;

  WidgetNode get _root => document.root;

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

  /// Changes whenever the design is replaced by undo, redo, loading or
  /// switching screens, so editors know to refresh their text fields.
  int get revision => _revision;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Whether the canvas runs the design like an app instead of editing it.
  bool get isPreviewing => _previewing;

  /// The active canvas tool.
  CanvasTool get tool => _tool;
  set tool(CanvasTool value) {
    if (value == _tool) return;
    _tool = value;
    if (_previewing && value != CanvasTool.select) _previewing = false;
    notifyListeners();
  }

  /// Whether preview mode can go back to a previous screen.
  bool get canPreviewBack => _previewStack.isNotEmpty;

  // Screens ------------------------------------------------------------------

  /// Shows another screen on the canvas.
  void selectScreen(String id) {
    if (id == document.id || _project.screenById(id) == null) return;
    _currentScreenId = id;
    _selectedId = null;
    _mergeKey = null;
    _previewStack.clear();
    _revision++;
    notifyListeners();
  }

  /// Adds an empty screen and opens it. Free-form screens let you draw
  /// boxes anywhere; responsive screens stack widgets in a column.
  void addScreen({bool freeForm = true}) {
    final number = _project.screens.length + 1;
    final screen = freeForm
        ? CanvasDocument.freeForm(name: 'Screen $number', title: 'Screen $number')
        : CanvasDocument.blank(name: 'Screen $number', title: 'Screen $number');
    _currentScreenId = screen.id;
    _selectedId = null;
    _revision++;
    _commitProject(_project.addScreen(screen));
  }

  /// Adds a copy of a screen and opens it.
  void duplicateScreen(String id) {
    final source = _project.screenById(id);
    if (source == null) return;
    final copy = CanvasDocument(
      root: source.root.cloneWithNewIds(),
      name: '${source.name} copy',
      title: source.title,
      showAppBar: source.showAppBar,
      backgroundColor: source.backgroundColor,
    );
    _currentScreenId = copy.id;
    _selectedId = null;
    _revision++;
    _commitProject(_project.addScreen(copy));
  }

  /// Deletes a screen. The last screen can't be deleted.
  void deleteScreen(String id) {
    if (_project.screens.length <= 1) return;
    final next = _project.removeScreen(id);
    if (_currentScreenId == id) {
      _currentScreenId = next.initialScreenId;
      _selectedId = null;
    }
    _revision++;
    _commitProject(next);
  }

  /// Makes a screen the one the app opens on.
  void setInitialScreen(String id) {
    if (_project.screenById(id) == null) return;
    _commitProject(_project.copyWith(initialScreenId: id));
  }

  // Preview ------------------------------------------------------------------

  /// Switches between editing and running the design.
  void togglePreview() {
    _previewing = !_previewing;
    _previewStack.clear();
    _selectedId = null;
    notifyListeners();
  }

  /// Follows a button link while previewing.
  void previewNavigate(String target) {
    if (target == 'back') {
      previewBack();
      return;
    }
    if (_project.screenById(target) == null) return;
    _previewStack.add(document.id);
    _currentScreenId = target;
    _revision++;
    notifyListeners();
  }

  /// Switches screens from the bottom navigation bar while previewing.
  void previewSwitch(String screenId) {
    if (_project.screenById(screenId) == null) return;
    _previewStack.clear();
    _currentScreenId = screenId;
    _revision++;
    notifyListeners();
  }

  /// Returns to the previous screen while previewing.
  void previewBack() {
    if (_previewStack.isEmpty) return;
    _currentScreenId = _previewStack.removeLast();
    _revision++;
    notifyListeners();
  }

  // Selection and history ----------------------------------------------------

  /// Selects the widget with [id], or clears the selection.
  void select(String? id) {
    if (_selectedId == id) return;
    _selectedId = id;
    _mergeKey = null;
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    _redo.add(_project);
    _project = _undo.removeLast();
    _afterHistoryJump();
  }

  void redo() {
    if (!canRedo) return;
    _undo.add(_project);
    _project = _redo.removeLast();
    _afterHistoryJump();
  }

  // Editing ------------------------------------------------------------------

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
        final node = _placed(destination.parentId, WidgetCatalog.create(type));
        _selectedId = node.id;
        _setRoot(_root.insert(destination.parentId, destination.index, node));
      case MoveNodePayload(:final nodeId):
        var root = _root.move(nodeId, destination.parentId, destination.index);
        final parent = root.find(destination.parentId);
        if (WidgetCatalog.isFreeLayout(parent)) {
          root = root.update(nodeId, (node) => _placed(parent!.id, node));
        }
        _setRoot(root);
    }
  }

  /// Gives widgets added to a free canvas or free box a sensible spot.
  ///
  /// In a box, images fill the box and icons sit in the middle, so a round
  /// avatar or badge looks right straight away. Other widgets step down and
  /// right so they don't cover each other.
  WidgetNode _placed(String parentId, WidgetNode node) {
    final parent = _root.find(parentId);
    if (parent == null || !WidgetCatalog.isFreeLayout(parent)) {
      return node;
    }
    final props = {...node.props};
    if (parent.type == WidgetTypes.box) {
      final padding = parent.number('padding') * 2;
      final width = parent.number('width') - padding;
      final height = (WidgetCatalog.fixedHeight(parent) ?? 0) - padding;
      if (node.type == WidgetTypes.image) {
        props['fill'] = true;
        props['borderRadius'] = 0;
      } else if (node.type == WidgetTypes.icon) {
        var size = node.number('size', 24);
        final smallest = width < height ? width : height;
        if (smallest > 0 && size > smallest * 0.6) {
          size = (smallest * 0.6).roundToDouble();
        }
        props['size'] = size;
        props['x'] = width > size ? ((width - size) / 2).roundToDouble() : 0.0;
        props['y'] = height > size ? ((height - size) / 2).roundToDouble() : 0.0;
      } else {
        final step = 8.0 + (parent.children.length % 4) * 12;
        props['x'] = step;
        props['y'] = step;
      }
    } else {
      final offset = 16.0 + (parent.children.length % 8) * 24;
      props['x'] = offset;
      props['y'] = offset;
    }
    return node.copyWith(props: props);
  }

  /// Adds a new widget inside or after the selection, or at the end of the
  /// screen when nothing is selected.
  void addWidget(String type) {
    final selected = _selectedId;
    final destination = (selected == null ? null : resolveDrop(selected)) ??
        (parentId: _root.id, index: _root.children.length);
    final node = _placed(destination.parentId, WidgetCatalog.create(type));
    _selectedId = node.id;
    _setRoot(_root.insert(destination.parentId, destination.index, node));
  }

  /// Adds a box drawn with the box tool. [rect] is in the coordinates of
  /// [parentId]'s layer. Inside a free canvas or box the new box keeps its
  /// position; anywhere else it is added at the end of the screen with the
  /// drawn size. Switches back to the select tool, like Figma.
  void drawBox(String parentId, Rect rect) {
    final parent = _root.find(parentId);
    if (parent == null) return;
    final free = WidgetCatalog.isFreeLayout(parent);
    double whole(double value) => value < 0 ? 0 : value.roundToDouble();
    final box = WidgetCatalog.create(WidgetTypes.box).copyWith(
      props: {
        ...WidgetCatalog.defaultsFor(WidgetTypes.box),
        'width': whole(rect.width),
        'height': whole(rect.height),
        if (free) 'x': whole(rect.left),
        if (free) 'y': whole(rect.top),
      },
    );
    final targetId = free ? parent.id : _root.id;
    _selectedId = box.id;
    _tool = CanvasTool.select;
    _setRoot(_root.insert(targetId, _root.find(targetId)!.children.length, box));
  }

  /// Changes several properties in one step, for example `x` and `y` while
  /// dragging. Calls with the same [mergeKey] form a single undo step.
  void updateProps(
    String nodeId,
    Map<String, Object?> values, {
    String? mergeKey,
  }) {
    _setRoot(
      _root.update(
        nodeId,
        (node) => node.copyWith(props: {...node.props, ...values}),
      ),
      mergeKey: mergeKey,
    );
  }

  /// Ends a drag or resize, so the next one becomes its own undo step.
  void endGesture() => _mergeKey = null;

  /// Changes one property. Consecutive edits to the same property are merged
  /// into a single undo step.
  void updateProp(String nodeId, String key, Object? value) {
    _setRoot(
      _root.update(nodeId, (node) => node.withProp(key, value)),
      mergeKey: '$nodeId:$key',
    );
  }

  /// Names a layer. Named layers become their own widget class in the
  /// exported code.
  void renameNode(String nodeId, String name) {
    _setRoot(
      _root.update(nodeId, (node) => node.copyWith(name: name)),
      mergeKey: '$nodeId:#name',
    );
  }

  /// Changes settings of the current screen.
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
    _commitProject(
      _project.withScreen(
        document.copyWith(
          name: name,
          title: title,
          showAppBar: showAppBar,
          backgroundColor: backgroundColor,
        ),
      ),
      mergeKey: showAppBar != null ? null : '${document.id}:$field',
    );
  }

  /// Changes an app bar or bottom navigation setting of the current screen.
  void updateBars(String key, Object? value) {
    _commitProject(
      _project.withScreen(
        document.copyWith(bars: {...document.bars, key: value}),
      ),
      mergeKey: value is bool ? null : '${document.id}:bars:$key',
    );
  }

  /// Moves the selected widget with the arrow keys, like Figma: by 1 pixel,
  /// or 10 with [big]. Widgets in a row or column swap places instead.
  void nudge(int dx, int dy, {bool big = false}) {
    final id = _selectedId;
    if (id == null || id == _root.id) return;
    final parent = _root.parentOf(id);
    final node = _root.find(id);
    if (parent == null || node == null) return;
    if (WidgetCatalog.isFreeLayout(parent)) {
      final step = big ? 10 : 1;
      final x = node.number('x') + dx * step;
      final y = node.number('y') + dy * step;
      updateProps(
        id,
        {'x': x < 0 ? 0.0 : x, 'y': y < 0 ? 0.0 : y},
        mergeKey: 'nudge:$id',
      );
    } else {
      moveSibling(id, dy != 0 ? dy : dx);
    }
  }

  /// Renames the app.
  void renameProject(String name) =>
      _commitProject(_project.copyWith(name: name), mergeKey: 'project:name');

  /// Puts a widget inside a new row or column (or any other layout type)
  /// in the same spot, like Figma's auto layout, and selects the new layout
  /// so the next widget you add lands next to it.
  void wrapIn(String id, String layoutType) {
    if (id == _root.id) return;
    final parent = _root.parentOf(id);
    final node = _root.find(id);
    if (parent == null || node == null) return;
    final inFree = WidgetCatalog.isFreeLayout(parent);
    final child = node.copyWith(
      props: {...node.props}
        ..remove('x')
        ..remove('y')
        ..remove('fill'),
    );
    final base = WidgetCatalog.create(layoutType);
    final wrapper = base.copyWith(
      props: {
        ...base.props,
        if (inFree) 'x': node.number('x'),
        if (inFree) 'y': node.number('y'),
      },
      children: [child],
    );
    _selectedId = wrapper.id;
    _setRoot(
      _root.update(
        parent.id,
        (p) => p.copyWith(
          children: [
            for (final c in p.children) c.id == id ? wrapper : c,
          ],
        ),
      ),
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

  // Loading and exporting ----------------------------------------------------

  /// Replaces the whole design. This can be undone.
  void loadProject(CanvasProject project) {
    _selectedId = null;
    _revision++;
    _previewStack.clear();
    _currentScreenId = project.initialScreenId;
    _commitProject(project);
  }

  /// Replaces the design but stays on the same screen when it still
  /// exists, for example after the AI changed it. This can be undone.
  void applyProject(CanvasProject project) {
    final keep = project.screenById(_currentScreenId) != null;
    final selected = _selectedId;
    _revision++;
    _previewStack.clear();
    if (!keep) _currentScreenId = project.initialScreenId;
    _selectedId = selected != null &&
            (project.screenById(_currentScreenId)?.root.find(selected) != null)
        ? selected
        : null;
    _commitProject(project);
  }

  /// Replaces the design with a single screen. This can be undone.
  void loadDocument(CanvasDocument document) =>
      loadProject(CanvasProject(screens: [document]));

  /// Loads a project, or a single screen saved by version 0.1. Throws a
  /// [FormatException] for invalid input.
  void loadJson(String json) => loadProject(CanvasProject.fromJsonString(json));

  /// The whole design as pretty-printed JSON.
  String exportJson() => _project.toJsonString(pretty: true);

  /// The whole app as Flutter files: `main.dart`, `app_routes.dart`, one file
  /// per screen and shared widgets.
  List<GeneratedFile> exportCode() =>
      const FlutterCodeGenerator().generateProject(_project);

  /// Only the current screen, as one self-contained file.
  String exportScreenCode() => const FlutterCodeGenerator().generate(document);

  void _setRoot(WidgetNode root, {String? mergeKey}) => _commitProject(
        _project.withScreen(document.copyWith(root: root)),
        mergeKey: mergeKey,
      );

  void _commitProject(CanvasProject next, {String? mergeKey}) {
    if (mergeKey == null || mergeKey != _mergeKey) {
      _undo.add(_project);
      if (_undo.length > _historyLimit) _undo.removeAt(0);
    }
    _redo.clear();
    _mergeKey = mergeKey;
    _project = next;
    notifyListeners();
  }

  void _afterHistoryJump() {
    _mergeKey = null;
    _revision++;
    if (_project.screenById(_currentScreenId) == null) {
      _currentScreenId = _project.initialScreenId;
    }
    final id = _selectedId;
    if (id != null && _root.find(id) == null) _selectedId = null;
    notifyListeners();
  }
}
