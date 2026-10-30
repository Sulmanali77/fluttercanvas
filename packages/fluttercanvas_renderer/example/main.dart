import 'package:flutter/material.dart';
import 'package:fluttercanvas_renderer/fluttercanvas_renderer.dart';

/// A design exported from the FlutterCanvas builder. In a real app this JSON
/// would usually come from your server, so you can change screens without
/// shipping an app update.
const designJson = '''
{
  "name": "PromoScreen",
  "title": "Summer sale",
  "root": {
    "type": "column",
    "props": {"spacing": 16},
    "children": [
      {"type": "text", "props": {"text": "Up to 50% off", "fontSize": 32, "fontWeight": "bold"}},
      {"type": "text", "props": {"text": "Only this week, on everything in the store.", "color": "#FF6B7280"}},
      {"type": "button", "props": {"label": "Shop now", "action": "open_shop", "fullWidth": true}}
    ]
  }
}
''';

void main() => runApp(const RendererExampleApp());

class RendererExampleApp extends StatelessWidget {
  const RendererExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => CanvasView.fromJson(
          designJson,
          delegate: CanvasRenderDelegate(
            onAction: (action, node) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Action: $action')),
              );
            },
          ),
        ),
      ),
    );
  }
}
