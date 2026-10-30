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
}
