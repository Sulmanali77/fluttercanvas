/// Data carried while dragging on the builder canvas.
sealed class DragPayload {
  const DragPayload();
}

/// A new widget dragged from the palette.
class NewWidgetPayload extends DragPayload {
  const NewWidgetPayload(this.type);

  final String type;
}

/// An existing widget being moved on the canvas.
class MoveNodePayload extends DragPayload {
  const MoveNodePayload(this.nodeId);

  final String nodeId;
}
