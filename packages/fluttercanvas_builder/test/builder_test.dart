import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttercanvas_builder/fluttercanvas_builder.dart';

void main() {
  group('BuilderController', () {
    test('adds, edits, undoes and redoes', () {
      final controller = BuilderController(document: CanvasDocument.blank());
      controller.addWidget(WidgetTypes.text);
      expect(controller.document.root.children, hasLength(1));

      final id = controller.document.root.children.single.id;
      expect(controller.selectedId, id);

      // Typing produces many edits but only one undo step.
      controller.updateProp(id, 'text', 'H');
      controller.updateProp(id, 'text', 'Hello');
      expect(controller.document.root.find(id)!.string('text'), 'Hello');

      controller.undo();
      expect(controller.document.root.find(id)!.string('text'), 'Text');

      controller.undo();
      expect(controller.document.root.children, isEmpty);
      expect(controller.selectedId, isNull);

      controller.redo();
      expect(controller.document.root.children, hasLength(1));
    });

    test('drops into layouts and after other widgets', () {
      final controller = BuilderController(document: CanvasDocument.blank());
      controller.addWidget(WidgetTypes.column);
      final column = controller.selectedId!;
      controller.addWidget(WidgetTypes.text);
      final text = controller.selectedId!;

      expect(controller.document.root.parentOf(text)!.id, column);
      expect(
        controller.resolveDrop(text),
        (parentId: column, index: 1),
      );
      expect(
        controller.canDrop(const NewWidgetPayload(WidgetTypes.button), text),
        isTrue,
      );
    });

    test('never drops a widget into itself', () {
      final controller = BuilderController(document: CanvasDocument.blank());
      controller.addWidget(WidgetTypes.column);
      final column = controller.selectedId!;
      controller.addWidget(WidgetTypes.text);
      final text = controller.selectedId!;

      expect(controller.canDrop(MoveNodePayload(column), column), isFalse);
      expect(controller.canDrop(MoveNodePayload(column), text), isFalse);
      expect(
        controller.canDrop(MoveNodePayload(controller.document.root.id), text),
        isFalse,
      );
    });

    test('loads and exports JSON', () {
      final controller = BuilderController();
      final json = controller.exportJson();
      controller.loadJson(json);
      expect(controller.exportJson(), json);
      expect(() => controller.loadJson('not json'), throwsFormatException);
    });
  });

  testWidgets('shows palette, canvas and properties on wide screens',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: FlutterCanvasBuilder()));

    expect(find.text('Widgets'), findsOneWidget);
    expect(find.text('Welcome to FlutterCanvas'), findsOneWidget);
    expect(find.text('Screen settings'), findsOneWidget);
    expect(find.text('Export code'), findsOneWidget);
  });

  testWidgets('tapping a palette item adds a widget', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = BuilderController(document: CanvasDocument.blank());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: FlutterCanvasBuilder(controller: controller)),
    );

    await tester.tap(find.text('Button').first);
    await tester.pump();
    expect(controller.document.root.children.single.type, WidgetTypes.button);
  });
}
