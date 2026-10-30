import 'package:flutter/material.dart';
import 'package:fluttercanvas_builder/fluttercanvas_builder.dart';

void main() => runApp(const PlaygroundApp());

class PlaygroundApp extends StatelessWidget {
  const PlaygroundApp({super.key});

  static const _seed = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterCanvas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: _seed),
      darkTheme: ThemeData(
        colorSchemeSeed: _seed,
        brightness: Brightness.dark,
      ),
      home: const FlutterCanvasBuilder(),
    );
  }
}
