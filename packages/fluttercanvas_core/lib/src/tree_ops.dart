import 'widget_node.dart';

/// Immutable tree operations. Every method returns a new tree and leaves the
/// original untouched, which makes undo and redo trivial.
extension WidgetTree on WidgetNode {
  /// Finds the node with [nodeId] in this subtree.
  WidgetNode? find(String nodeId) {
    if (id == nodeId) return this;
    for (final child in children) {
      final found = child.find(nodeId);
      if (found != null) return found;
    }
    return null;
  }

  /// Finds the parent of the node with [nodeId] in this subtree.
  WidgetNode? parentOf(String nodeId) {
    for (final child in children) {
      if (child.id == nodeId) return this;
      final parent = child.parentOf(nodeId);
      if (parent != null) return parent;
    }
    return null;
  }

  /// Whether this subtree contains [nodeId], including this node itself.
  bool contains(String nodeId) => find(nodeId) != null;

  /// Index of the direct child with [nodeId], or -1.
  int indexOfChild(String nodeId) =>
      children.indexWhere((child) => child.id == nodeId);

  /// Replaces the node with [nodeId] by the result of [transform].
  WidgetNode update(
    String nodeId,
    WidgetNode Function(WidgetNode node) transform,
  ) {
    if (id == nodeId) return transform(this);
    var changed = false;
    final next = <WidgetNode>[];
    for (final child in children) {
      final updated = child.update(nodeId, transform);
      if (!identical(updated, child)) changed = true;
      next.add(updated);
    }
    return changed ? copyWith(children: next) : this;
  }

  /// Removes the node with [nodeId] and its subtree.
  WidgetNode remove(String nodeId) {
    var changed = false;
    final next = <WidgetNode>[];
    for (final child in children) {
      if (child.id == nodeId) {
        changed = true;
        continue;
      }
      final updated = child.remove(nodeId);
      if (!identical(updated, child)) changed = true;
      next.add(updated);
    }
    return changed ? copyWith(children: next) : this;
  }

  /// Inserts [child] into the node with [parentId] at [index].
  WidgetNode insert(String parentId, int index, WidgetNode child) {
    return update(parentId, (parent) {
      final next = [...parent.children];
      final at = index < 0 ? 0 : (index > next.length ? next.length : index);
      next.insert(at, child);
      return parent.copyWith(children: next);
    });
  }

  /// Moves the node with [nodeId] into [newParentId] at [index].
  ///
  /// Moving a node into its own subtree is ignored.
  WidgetNode move(String nodeId, String newParentId, int index) {
    final node = find(nodeId);
    final oldParent = parentOf(nodeId);
    if (node == null || oldParent == null) return this;
    if (node.contains(newParentId)) return this;
    var target = index;
    if (oldParent.id == newParentId) {
      final oldIndex = oldParent.indexOfChild(nodeId);
      if (oldIndex < target) target -= 1;
    }
    return remove(nodeId).insert(newParentId, target, node);
  }

  /// Deep copy with fresh ids, used for duplicating widgets.
  WidgetNode cloneWithNewIds() => WidgetNode(
        id: NodeIds.next(),
        type: type,
        props: props,
        children: [for (final child in children) child.cloneWithNewIds()],
      );
}
