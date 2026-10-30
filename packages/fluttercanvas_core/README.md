# fluttercanvas_core

The design model, JSON format and code generator behind
[FlutterCanvas](https://github.com/sulmanali77/fluttercanvas), the open-source
drag-and-drop UI builder for Flutter.

This package is pure Dart, so you can read, write and generate code from
designs anywhere: in a Flutter app, a CLI tool or a backend.

## Usage

```dart
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

final document = CanvasDocument.fromJsonString(jsonFromYourServer);
final dartCode = const FlutterCodeGenerator().generate(document);
```

The generated file only imports `package:flutter/material.dart` and adapts to
phones, tablets, desktop and the web.

## What's inside

- `CanvasDocument` and `WidgetNode`: an immutable design tree with JSON support.
- `WidgetCatalog`: the 13 built-in widget types with their properties and defaults.
- `WidgetTree`: tree helpers such as `find`, `insert`, `move` and `remove`.
- `FlutterCodeGenerator`: turns a design into a ready-to-use Flutter screen.

To render designs at runtime, use
[fluttercanvas_renderer](https://pub.dev/packages/fluttercanvas_renderer). To
design visually, use
[fluttercanvas_builder](https://pub.dev/packages/fluttercanvas_builder).
