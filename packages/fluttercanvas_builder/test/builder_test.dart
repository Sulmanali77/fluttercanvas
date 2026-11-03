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

    test('manages screens and follows links in preview', () {
      final controller = BuilderController();
      expect(controller.project.screens, hasLength(2));
      final home = controller.document.id;
      final details = controller.project.screens.last.id;

      controller.togglePreview();
      controller.previewNavigate(details);
      expect(controller.document.id, details);
      expect(controller.canPreviewBack, isTrue);
      controller.previewNavigate('back');
      expect(controller.document.id, home);
      controller.togglePreview();

      controller.addScreen();
      expect(controller.project.screens, hasLength(3));
      final added = controller.document.id;
      controller.deleteScreen(added);
      expect(controller.project.screens, hasLength(2));
      expect(controller.document.id, home);

      controller.undo();
      expect(controller.project.screens, hasLength(3));
    });

    test('exports the whole app as files', () {
      final files = BuilderController().exportCode();
      expect(
        files.map((file) => file.path),
        containsAll([
          'lib/main.dart',
          'lib/app_routes.dart',
          'lib/screens/home_screen.dart',
          'lib/screens/details_screen.dart',
        ]),
      );
    });

    test('names layers', () {
      final controller = BuilderController(document: CanvasDocument.blank());
      controller.addWidget(WidgetTypes.card);
      final id = controller.selectedId!;
      controller.renameNode(id, 'Promo card');
      expect(controller.document.root.find(id)!.name, 'Promo card');
      expect(controller.exportScreenCode(), contains('class PromoCard'));
    });

    test('places widgets in a free canvas and drags them in one undo step',
        () {
      final controller = BuilderController(document: CanvasDocument.blank());
      controller.addWidget(WidgetTypes.freeCanvas);
      final canvas = controller.selectedId!;
      controller.addWidget(WidgetTypes.text);
      final text = controller.selectedId!;

      expect(controller.document.root.parentOf(text)!.id, canvas);
      final start = controller.document.root.find(text)!.number('x');
      expect(start, greaterThan(0));

      controller.updateProps(text, {'x': 50.0, 'y': 60.0}, mergeKey: 'move');
      controller.updateProps(text, {'x': 70.0, 'y': 80.0}, mergeKey: 'move');
      controller.endGesture();
      expect(controller.document.root.find(text)!.number('x'), 70);

      controller.undo();
      expect(controller.document.root.find(text)!.number('x'), start);
    });

    test('draws boxes with the box tool, inside other boxes too', () {
      final controller = BuilderController();
      controller.addScreen();
      final root = controller.document.root;
      expect(root.type, WidgetTypes.freeCanvas);

      controller.tool = CanvasTool.box;
      controller.drawBox(root.id, const Rect.fromLTWH(20, 40, 150, 90));
      expect(controller.tool, CanvasTool.select);
      final outer = controller.selectedNode!;
      expect(outer.type, WidgetTypes.box);
      expect(outer.number('x'), 20);
      expect(outer.number('width'), 150);

      controller.drawBox(outer.id, const Rect.fromLTWH(10, 10, 40, 30));
      final inner = controller.selectedNode!;
      expect(controller.document.root.parentOf(inner.id)!.id, outer.id);

      controller.addWidget(WidgetTypes.text);
      expect(
        controller.document.root.parentOf(controller.selectedId!)!.id,
        inner.id,
      );
    });

    test('images fill a box and icons sit in its middle', () {
      final controller = BuilderController();
      controller.addScreen();
      final root = controller.document.root;
      controller.drawBox(root.id, const Rect.fromLTWH(10, 10, 40, 40));
      final avatar = controller.selectedId!;

      controller.addWidget(WidgetTypes.image);
      final image = controller.selectedNode!;
      expect(image.boolean('fill'), isTrue);

      controller.select(avatar);
      controller.addWidget(WidgetTypes.icon);
      final icon = controller.selectedNode!;
      expect(icon.number('size'), lessThanOrEqualTo(24));
      expect(icon.number('x') + icon.number('size') / 2, closeTo(20, 1));
    });

    test('puts a widget in a row so the next one lands beside it', () {
      final controller = BuilderController(document: CanvasDocument.blank());
      controller.addWidget(WidgetTypes.box);
      final avatar = controller.selectedId!;

      controller.wrapIn(avatar, WidgetTypes.row);
      final row = controller.selectedNode!;
      expect(row.type, WidgetTypes.row);
      expect(row.children.single.id, avatar);

      controller.addWidget(WidgetTypes.text);
      expect(
        controller.document.root.find(row.id)!.children.map((c) => c.type),
        [WidgetTypes.box, WidgetTypes.text],
      );
    });

    test('box drawn on a responsive screen joins the page', () {
      final controller = BuilderController(document: CanvasDocument.blank());
      final root = controller.document.root;
      controller.drawBox(root.id, const Rect.fromLTWH(30, 30, 200, 80));
      final box = controller.selectedNode!;
      expect(controller.document.root.children.single.id, box.id);
      expect(box.number('height'), 80);
    });

    test('arrow keys nudge in free layouts and reorder in columns', () {
      final controller = BuilderController();
      controller.addScreen();
      controller.drawBox(
          controller.document.root.id, const Rect.fromLTWH(20, 20, 40, 40));
      final box = controller.selectedId!;
      controller.nudge(1, 0);
      controller.nudge(0, 1, big: true);
      final moved = controller.document.root.find(box)!;
      expect(moved.number('x'), 21);
      expect(moved.number('y'), 30);

      controller.loadProject(CanvasTemplates.ecommerce());
      expect(controller.project.screens, hasLength(4));
      controller.updateBars(BarKeys.appBarColor, '#FF000000');
      expect(controller.document.bar(BarKeys.appBarColor), '#FF000000');
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
    expect(find.text('Screens'), findsOneWidget);
    expect(find.text('Details'), findsWidgets);
    expect(find.text('Welcome to FlutterCanvas'), findsOneWidget);
    expect(find.text('Screen settings'), findsOneWidget);
    expect(find.text('Export code'), findsOneWidget);
    expect(find.text('Drag to move · arrow keys nudge · Shift for 10 px'),
        findsOneWidget);
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

    await tester.tap(find.text('Column').first);
    await tester.pump();
    expect(controller.document.root.children.single.type, WidgetTypes.column);
  });
}
