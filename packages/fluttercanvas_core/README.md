# fluttercanvas_core

[![pub package](https://img.shields.io/pub/v/fluttercanvas_core.svg)](https://pub.dev/packages/fluttercanvas_core)
[![CI](https://github.com/Sulmanali77/fluttercanvas/actions/workflows/ci.yml/badge.svg)](https://github.com/Sulmanali77/fluttercanvas/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Sulmanali77/fluttercanvas/blob/main/LICENSE)

The design model, JSON format and code generator behind
[FlutterCanvas](https://pub.dev/packages/fluttercanvas), the open-source,
Figma-like UI builder for Flutter.

This package is **pure Dart**: read, write and generate code from designs in
a Flutter app, a command-line tool or a backend.

## Features

- **Design model.** `CanvasProject` (screens), `CanvasDocument` (one screen)
  and `WidgetNode` (the widget tree), all immutable, with JSON support.
- **17 widget types**, including boxes with auto layout, free canvases,
  responsive grids and custom code for any pub.dev package.
- **Code generator.** `FlutterCodeGenerator` writes a ready-to-copy `lib`
  folder that only depends on `material.dart`: named routes, one file per
  screen, app bars, bottom navigation, entrance animations, `const` where
  possible, and `// TODO` comments where your logic goes.
- **Templates.** `CanvasTemplates.ecommerce()` and more.
- **AI prompts.** `DesignPrompt` builds prompts so any AI model can create or
  change designs, and reads replies back safely.
- **CLI** to export a design from the terminal.

## Install

```yaml
dependencies:
  fluttercanvas_core: ^0.3.0
```

## Generate Flutter code

```dart
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

void main() {
  final project = CanvasProject.fromJsonString(jsonFromYourServer);
  for (final file in const FlutterCodeGenerator().generateProject(project)) {
    print('${file.path}\n${file.content}');
  }
}
```

Or export one screen as a single self-contained file:

```dart
final code = const FlutterCodeGenerator().generate(project.initialScreen);
```

## Build a design in code

```dart
final screen = CanvasDocument.blank(name: 'Profile');
final title = WidgetCatalog.create(WidgetTypes.text)
    .withProp('text', 'Hello from FlutterCanvas')
    .withProp('fontSize', 24);
final design = screen.copyWith(
  root: screen.root.insert(screen.root.id, 0, title),
);
print(design.toJsonString(pretty: true));
```

## Command line

```
dart run fluttercanvas_core:fluttercanvas export design.json .
```

## Design format

A project is JSON with screens, and each screen has a tree of widgets with
props. The
[format guide](https://github.com/Sulmanali77/fluttercanvas/blob/main/skills/flutter-canvas/references/design-format.md)
lists every widget and property.

## Related packages

- [`fluttercanvas`](https://pub.dev/packages/fluttercanvas): the visual builder
- [`fluttercanvas_renderer`](https://pub.dev/packages/fluttercanvas_renderer): render designs at runtime

## License

MIT
