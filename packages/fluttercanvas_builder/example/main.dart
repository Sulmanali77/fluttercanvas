import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttercanvas_builder/fluttercanvas_builder.dart';

/// Opens the builder in debug builds only, so it never ships to users.
///
/// Run with `flutter run -d chrome` (or any device), design a screen, then
/// press "Export code" and paste the result into your project.
void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF4F46E5)),
      home: kDebugMode
          ? FlutterCanvasBuilder(onExport: (code) => debugPrint(code))
          : const Scaffold(body: Center(child: Text('Your real app'))),
    ),
  );
}
