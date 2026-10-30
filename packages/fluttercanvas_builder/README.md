# fluttercanvas_builder

An open-source drag-and-drop UI builder for Flutter. Design a screen visually,
preview it on an iPhone, Android phone, iPad, Mac or Chrome window, then export
clean, responsive Flutter code you fully own.

Part of [FlutterCanvas](https://github.com/sulmanali77/fluttercanvas).

## Install

```yaml
dev_dependencies:
  fluttercanvas_builder: ^0.1.0
```

## Use it in your app

Open the builder while developing. The `kDebugMode` check keeps it out of
release builds:

```dart
import 'package:flutter/foundation.dart';
import 'package:fluttercanvas_builder/fluttercanvas_builder.dart';

MaterialApp(
  home: kDebugMode ? const FlutterCanvasBuilder() : const MyHomePage(),
);
```

Then run your app from Android Studio, VS Code or the terminal
(`flutter run -d chrome` works well), design a screen, press **Export code**
and paste the file into your `lib/` folder.

## Features

- Drag from the palette, or tap a widget to add it after the selection.
- Long-press any widget on the canvas to move it, including into another layout.
- Edit text, colors, spacing, alignment and more in the properties panel.
- Preview on phone, tablet, desktop and browser sizes.
- Undo and redo.
- Save and load designs as JSON.
- Export a Flutter screen that only depends on `material.dart`.

## Save designs automatically

```dart
final controller = BuilderController(
  document: CanvasDocument.fromJsonString(savedJson),
);
controller.addListener(() => saveSomewhere(controller.exportJson()));

FlutterCanvasBuilder(controller: controller);
```
