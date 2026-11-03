# FlutterCanvas

[![pub package](https://img.shields.io/pub/v/fluttercanvas.svg)](https://pub.dev/packages/fluttercanvas)
[![CI](https://github.com/Sulmanali77/fluttercanvas/actions/workflows/ci.yml/badge.svg)](https://github.com/Sulmanali77/fluttercanvas/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Sulmanali77/fluttercanvas/blob/main/LICENSE)

**An open-source, Figma-like UI builder for Flutter that runs inside your own app.**
Draw and arrange screens visually, link them, preview them on real device
frames, and export clean Flutter code you fully own. No account, no
subscription, no lock-in.

**[Try the live demo](https://sulmanali77.github.io/fluttercanvas/)**

![FlutterCanvas builder](https://raw.githubusercontent.com/Sulmanali77/fluttercanvas/main/docs/screenshots/builder.png)

## Features

- **Draw like Figma.** Press and drag to draw boxes. Give them a fill, corner
  radius, border and shadow, and put text, images or more boxes inside.
- **Auto layout.** Boxes lay out children freely, in a row or in a column,
  with gap, arrangement and alignment.
- **Move and resize precisely.** Drag anything in a free layout, resize from
  the corner handle, and nudge with the arrow keys (Shift for 10 px).
- **Whole apps.** Multiple screens, any widget can open another screen,
  editable app bars, and a shared bottom navigation bar.
- **Animations.** Fade, slide and scale entrance animations on any widget.
- **Prototype mode.** Press play and tap through your app.
- **Real devices.** iPhone with Dynamic Island, Pixel, iPad, Mac and Chrome,
  with safe areas applied.
- **AI agent.** Chat with Gemini (free tier), Groq, OpenRouter or OpenAI to
  design screens. Attach screenshots or PDFs, paste links, and undo any
  change.
- **Templates.** Start from an animated e-commerce app.
- **Any package.** Use any pub.dev widget through the Custom code widget.
- **Clean export.** A ready-to-copy `lib` folder: `main.dart`, named routes,
  one file per screen, `const` where possible, and `// TODO` comments where
  your API calls and logic go.
- **Light, dark or system theme**, layers panel, undo and redo, and keyboard
  shortcuts.

## Install

```yaml
dev_dependencies:
  fluttercanvas: ^0.3.0
```

## Use

Open the builder while you develop. `kDebugMode` keeps it out of release
builds:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttercanvas/fluttercanvas.dart';

void main() {
  runApp(
    MaterialApp(
      home: kDebugMode ? const FlutterCanvasBuilder() : const MyHomePage(),
    ),
  );
}
```

Run it with `flutter run -d chrome` (or on any device), design your screens,
press **Export code**, and copy the files into your `lib` folder:

```
lib/
├── main.dart
├── app_routes.dart
├── screens/
│   ├── shop_screen.dart
│   └── cart_screen.dart
└── widgets/
    └── responsive_layout.dart
```

## Keyboard shortcuts

| Keys | Action |
| --- | --- |
| Arrow keys | Move the selected widget by 1 px (Shift: 10 px) |
| Delete / Backspace | Delete the selected widget |
| Cmd/Ctrl + Z | Undo (add Shift to redo) |
| Cmd/Ctrl + D | Duplicate |
| Esc | Clear the selection |

## Save and load designs

Designs are plain JSON, so you can keep them in git or on a server:

```dart
final controller = BuilderController(
  project: CanvasProject.fromJsonString(savedJson),
);
controller.addListener(() => save(controller.exportJson()));

FlutterCanvasBuilder(controller: controller);
```

## The AI agent

Open the **AI agent** tab, pick a model and paste an API key. Keys stay in
memory for the session only. Gemini has a free tier: get a key at
[aistudio.google.com](https://aistudio.google.com). Never ship an app with an
API key inside it.

## Packages

| Package | What it does |
| --- | --- |
| [`fluttercanvas`](https://pub.dev/packages/fluttercanvas) | The visual builder (this package) |
| [`fluttercanvas_core`](https://pub.dev/packages/fluttercanvas_core) | Pure Dart design model, JSON format, code generator and CLI |
| [`fluttercanvas_renderer`](https://pub.dev/packages/fluttercanvas_renderer) | Renders designs at runtime for server-driven UI |

## Contributing

Issues and pull requests are welcome on
[GitHub](https://github.com/Sulmanali77/fluttercanvas). New widgets and
templates make great first contributions.

## License

MIT
