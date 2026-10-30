# FlutterCanvas

**An open-source drag-and-drop UI builder for Flutter.** Design screens
visually, preview them on phones, tablets, Mac and Chrome, and export clean,
responsive Flutter code that you fully own. No account, no lock-in, no extra
runtime dependency in the exported code.

> **Live demo:** `https://sulmanali77.github.io/fluttercanvas/` (published
> automatically by GitHub Actions after your first push)

## Why FlutterCanvas

- **Free and open source** under the MIT license.
- **Clean code export.** The generated screen only imports
  `package:flutter/material.dart`.
- **Responsive by default.** Exported screens use `LayoutBuilder` breakpoints
  and adapt to Android, iOS, web, macOS, Windows and Linux.
- **Runs inside your own app**, so you can design right next to your code in
  Android Studio or VS Code.
- **Designs are JSON**, so you can version them in git or serve them from a
  backend and render them at runtime.

## Packages

| Package | What it does |
| --- | --- |
| [`fluttercanvas_core`](packages/fluttercanvas_core) | Pure Dart design model, JSON format and code generator. |
| [`fluttercanvas_renderer`](packages/fluttercanvas_renderer) | Renders JSON designs as live widgets (server-driven UI). |
| [`fluttercanvas_builder`](packages/fluttercanvas_builder) | The drag-and-drop editor. |

## Quick start

### Design screens in your app

```yaml
dev_dependencies:
  fluttercanvas_builder: ^0.1.0
```

```dart
import 'package:flutter/foundation.dart';
import 'package:fluttercanvas_builder/fluttercanvas_builder.dart';

MaterialApp(
  home: kDebugMode ? const FlutterCanvasBuilder() : const MyHomePage(),
);
```

Run the app, design a screen, press **Export code**, and paste the file into
`lib/`.

### Render designs at runtime

```yaml
dependencies:
  fluttercanvas_renderer: ^0.1.0
```

```dart
CanvasView.fromJson(
  jsonFromServer,
  delegate: CanvasRenderDelegate(
    onAction: (action, node) => handle(action),
  ),
);
```

## How responsiveness works

| Screen width | Treated as | Grid columns (default) |
| --- | --- | --- |
| under 600 | phone | 1 |
| 600 to 1023 | tablet | 2 |
| 1024 and up | desktop and web | 3 |

- **Adaptive row** places children side by side, and stacks them on phones.
- **Responsive grid** uses a different column count per screen size.
- Page content is padded and capped at 1200 px wide on large screens.

## Widgets in 0.1

Layout: column, row, adaptive row, responsive grid, container, card.
Content: text, button, icon, image, text field, divider, space.

## Builder controls

| Action | How |
| --- | --- |
| Add a widget | Drag it from the palette, or tap it to add after the selection |
| Select | Tap a widget on the canvas |
| Move | Long-press a widget and drag it, or use the arrows in the properties panel |
| Edit | Change values in the properties panel |
| Preview another device | Device button in the toolbar |
| Save or load a design | **Design JSON** button |

## Repository layout

```
fluttercanvas/
├── packages/
│   ├── fluttercanvas_core/      # Model, JSON and code generator (pure Dart)
│   ├── fluttercanvas_renderer/  # Renders designs at runtime
│   └── fluttercanvas_builder/   # Drag-and-drop editor
├── apps/playground/             # Demo app, deployed to GitHub Pages
├── .github/workflows/           # CI and demo deployment
└── pubspec.yaml                 # Dart pub workspace
```

## Development

Requires Flutter 3.27 or newer.

```bash
flutter pub get                 # resolves every package at once
cd apps/playground
flutter create . --project-name fluttercanvas_playground --platforms=android,ios,macos,web,windows,linux
flutter run -d chrome           # or -d macos, or an emulator
```

Run tests from each package folder with `flutter test`.

## Publishing to pub.dev

1. Replace `sulmanali77` in every `pubspec.yaml` and `README.md`.
2. Check the names are free: search pub.dev for `fluttercanvas_core`,
   `fluttercanvas_renderer` and `fluttercanvas_builder`.
3. Publish in dependency order:

```bash
cd packages/fluttercanvas_core     && flutter pub publish --dry-run && flutter pub publish
cd ../fluttercanvas_renderer       && flutter pub publish --dry-run && flutter pub publish
cd ../fluttercanvas_builder        && flutter pub publish --dry-run && flutter pub publish
```

## Roadmap

- Drop indicators for inserting before a widget.
- Per-breakpoint property overrides.
- Theme editor that exports `ThemeData`.
- Screen templates: login, dashboard, profile, onboarding.
- Multiple screens with navigation.
- Layers panel.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). New widgets and templates are great
first contributions.

## License

MIT. See [LICENSE](LICENSE).
