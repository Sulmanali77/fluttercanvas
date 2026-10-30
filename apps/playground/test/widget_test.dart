import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttercanvas_playground/main.dart';

void main() {
  testWidgets('playground starts', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const PlaygroundApp());
    expect(find.text('FlutterCanvas'), findsWidgets);
  });
}
