import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttercanvas_builder/fluttercanvas_builder.dart';

/// Opens the builder in debug builds only, so it never ships to users.
///
/// Run with `flutter run -d chrome` (or any device), design your screens,
/// link buttons between them, then press "Export code" and copy the files
/// into your project's `lib` folder.
void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF4F46E5)),
      home: kDebugMode
          ? FlutterCanvasBuilder(
              onExport: (files) => debugPrint('Exported ${files.length} files'),
            )
          : const Scaffold(body: Center(child: Text('Your real app'))),
    ),
  );
}
