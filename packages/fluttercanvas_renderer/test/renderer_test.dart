import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttercanvas_renderer/fluttercanvas_renderer.dart';

void main() {
  testWidgets('renders the starter design', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CanvasView(document: CanvasDocument.starter())),
    );
    expect(find.text('Welcome to FlutterCanvas'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.byType(ResponsiveGrid), findsOneWidget);
  });

  testWidgets('reports button actions', (tester) async {
    String? pressed;
    const json = '''
{
  "title": "Shop",
  "root": {
    "type": "column",
    "children": [
      {"type": "button", "props": {"label": "Buy now", "action": "checkout"}}
    ]
  }
}''';
    await tester.pumpWidget(
      MaterialApp(
        home: CanvasView.fromJson(
          json,
          delegate: CanvasRenderDelegate(
            onAction: (action, node) => pressed = action,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buy now'));
    expect(pressed, 'checkout');
    expect(find.text('Shop'), findsOneWidget);
  });

  testWidgets('adaptive row stacks on narrow widths', (tester) async {
    Widget build(double width) => MaterialApp(
          home: Center(
            child: SizedBox(
              width: width,
              child: const AdaptiveRow(
                children: [Text('A'), Text('B')],
              ),
            ),
          ),
        );

    await tester.pumpWidget(build(300));
    expect(find.byType(Column), findsOneWidget);

    await tester.pumpWidget(build(700));
    expect(find.byType(Row), findsOneWidget);
  });

  testWidgets('project view moves between linked screens', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CanvasProjectView(project: CanvasProject.starter())),
    );
    expect(find.text('Welcome to FlutterCanvas'), findsOneWidget);

    await tester.ensureVisible(find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Go back'), findsOneWidget);

    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('free canvas places widgets at exact positions', (tester) async {
    final document = CanvasDocument.blank().copyWith(
      root: WidgetNode(
        id: 'root',
        type: WidgetTypes.column,
        props: WidgetCatalog.defaultsFor(WidgetTypes.column),
        children: [
          WidgetNode(
            id: 'frame',
            type: WidgetTypes.freeCanvas,
            props: WidgetCatalog.defaultsFor(WidgetTypes.freeCanvas),
            children: [
              WidgetNode(
                id: 'label',
                type: WidgetTypes.text,
                props: {
                  ...WidgetCatalog.defaultsFor(WidgetTypes.text),
                  'text': 'Hello free',
                  'x': 30,
                  'y': 40,
                },
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pumpWidget(MaterialApp(home: CanvasView(document: document)));
    expect(find.text('Hello free'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FreeCanvas),
        matching: find.byType(Positioned),
      ),
      findsOneWidget,
    );
  });

  testWidgets('free-form screens render boxes inside boxes', (tester) async {
    final screen = CanvasDocument.freeForm();
    final document = screen.copyWith(
      root: screen.root.copyWith(children: [
        WidgetNode(
          id: 'outer',
          type: WidgetTypes.box,
          props: {...WidgetCatalog.defaultsFor(WidgetTypes.box), 'x': 20},
          children: [
            WidgetNode(
              id: 'label',
              type: WidgetTypes.text,
              props: {
                ...WidgetCatalog.defaultsFor(WidgetTypes.text),
                'text': 'In a box',
                'x': 8,
                'y': 8,
              },
            ),
          ],
        ),
      ]),
    );
    await tester.pumpWidget(MaterialApp(home: CanvasView(document: document)));
    expect(find.text('In a box'), findsOneWidget);
  });

  testWidgets('a 40 by 40 box stays 40 by 40 in a stretched column',
      (tester) async {
    final document = CanvasDocument.blank().copyWith(
      root: WidgetNode(
        id: 'root',
        type: WidgetTypes.column,
        props: WidgetCatalog.defaultsFor(WidgetTypes.column),
        children: [
          WidgetNode(
            id: 'badge',
            type: WidgetTypes.box,
            props: {
              ...WidgetCatalog.defaultsFor(WidgetTypes.box),
              'width': 40,
              'height': 40,
            },
          ),
        ],
      ),
    );
    await tester.pumpWidget(MaterialApp(home: CanvasView(document: document)));
    final sized = find.byWidgetPredicate(
      (widget) => widget is SizedBox && widget.width == 40 && widget.height == 40,
    );
    expect(sized, findsOneWidget);
    expect(tester.getSize(sized), const Size(40, 40));
  });

  testWidgets('e-commerce template: bottom navigation and tappable cards',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: CanvasProjectView(project: CanvasTemplates.ecommerce())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Find your style'), findsOneWidget);

    await tester.tap(find.text('Cart').last);
    await tester.pumpAndSettle();
    expect(find.text('Your cart'), findsOneWidget);
  });
}
