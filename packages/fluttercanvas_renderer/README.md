# fluttercanvas_renderer

[![pub package](https://img.shields.io/pub/v/fluttercanvas_renderer.svg)](https://pub.dev/packages/fluttercanvas_renderer)
[![CI](https://github.com/Sulmanali77/fluttercanvas/actions/workflows/ci.yml/badge.svg)](https://github.com/Sulmanali77/fluttercanvas/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Sulmanali77/fluttercanvas/blob/main/LICENSE)

Render [FlutterCanvas](https://pub.dev/packages/fluttercanvas) designs as
real, responsive Flutter widgets at runtime, on Android, iOS, web, macOS,
Windows and Linux.

Because designs are JSON, you can serve them from your backend and change
screens **without an app store release** (server-driven UI).

![A rendered e-commerce design](https://raw.githubusercontent.com/Sulmanali77/fluttercanvas/main/docs/screenshots/renderer.png)

## Features

- `CanvasProjectView` runs a whole multi-screen design with real navigation,
  app bars and a bottom navigation bar.
- `CanvasView` renders one screen, with or without a `Scaffold`.
- Button and tap **actions** come back to your code by id.
- **Entrance animations**, icon **badges**, boxes with **auto layout**,
  free-form layouts and responsive grids.
- Reusable widgets: `AdaptiveRow`, `ResponsiveGrid`, `FreeCanvas` and
  `EntranceAnimation`.

## Install

```yaml
dependencies:
  fluttercanvas_renderer: ^0.3.0
```

## Run a whole app design

```dart
import 'package:fluttercanvas_renderer/fluttercanvas_renderer.dart';

MaterialApp(
  home: CanvasProjectView(
    project: CanvasProject.fromJsonString(jsonFromServer),
    onAction: (action, node) {
      if (action == 'checkout') startCheckout();
    },
  ),
);
```

## Render one screen

```dart
CanvasView.fromJson(
  screenJson,
  delegate: CanvasRenderDelegate(
    onAction: (action, node) => handle(action),
  ),
);
```

Set `includeScaffold: false` to place a design inside one of your own
screens.

## Responsive widgets for your own code

```dart
ResponsiveGrid(
  mobileColumns: 1,
  tabletColumns: 2,
  desktopColumns: 4,
  children: products.map(ProductCard.new).toList(),
);
```

## Related packages

- [`fluttercanvas`](https://pub.dev/packages/fluttercanvas): design visually and export code
- [`fluttercanvas_core`](https://pub.dev/packages/fluttercanvas_core): the design model and code generator

## License

MIT
