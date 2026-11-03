# fluttercanvas_builder

An open-source drag-and-drop UI builder for Flutter. Design a screen visually,
preview it on an iPhone, Android phone, iPad, Mac or Chrome window, then export
clean, responsive Flutter code you fully own.

Part of [FlutterCanvas](https://github.com/Sulmanali77/fluttercanvas).

## Install

```yaml
dev_dependencies:
  fluttercanvas_builder: ^0.3.0
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
(`flutter run -d chrome` works well), design your screens, press
**Export code** and copy the files into your `lib/` folder.

## Features

- **Free canvas:** place widgets anywhere, like a Figma frame.
- **Resize anything** from its corner handle, or type exact sizes.
- **Layers panel** and **double-tap to edit text** on the canvas.
- **Copy widget code** for just the selected widget.
- **Screens:** build a whole app, not just one page, and pick the start screen.
- **Links:** set "On tap, go to" on a button to open another screen or go back.
- **Preview:** press play and tap through your app like a prototype.
- **Clean export:** a ready-to-copy `lib` folder with `main.dart`,
  `app_routes.dart` and one file per screen. Named layers become their own
  widgets, and `// TODO` comments show where your API calls and logic go.
- Drag from the palette, or tap a widget to add it after the selection.
- Long-press any widget on the canvas to move it, including into another layout.
- Edit text, colors, spacing, alignment and more in the properties panel.
- Preview on phone, tablet, desktop and browser sizes.
- Undo and redo.
- Save and load designs as JSON.
- Exported code only depends on `material.dart`.

## Save designs automatically

```dart
final controller = BuilderController(
  project: CanvasProject.fromJsonString(savedJson),
);
controller.addListener(() => saveSomewhere(controller.exportJson()));

FlutterCanvasBuilder(controller: controller);
```
