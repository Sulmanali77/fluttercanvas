# FlutterCanvas

**An open-source drag-and-drop UI builder for Flutter.** Design screens
visually, preview them on phones, tablets, Mac and Chrome, and export clean,
responsive Flutter code that you fully own. No account, no lock-in, no extra
runtime dependency in the exported code.

> **Live demo:** `https://Sulmanali77.github.io/fluttercanvas/` (published
> automatically by GitHub Actions after your first push)

## Why FlutterCanvas

- **Free and open source** under the MIT license.
- **Clean code export.** The generated screen only imports
  `package:flutter/material.dart`.
- **Responsive by default.** Exported screens use `LayoutBuilder` breakpoints
  and adapt to Android, iOS, web, macOS, Windows and Linux.
- **Runs inside your own app**, so you can design right next to your code in
  Android Studio or VS Code.
- **Draw like Figma.** Pick the box tool, press and drag to draw a box, then
  give it a fill, corner radius, border and shadow, and put text, images or
  more boxes inside. New screens are free-form, so you can draw anywhere.
- **Design freely.** Drop widgets into a free canvas and drag them anywhere, resize anything from its corner handle, double-tap text to
  edit it, and browse everything in the layers panel. Free canvases keep
  their layout and shrink to fit small screens.
- **A real app in one click.** Start from the animated e-commerce template
  (shop, product, cart, profile, bottom navigation, cart badge).
- **AI assistant.** Describe a screen and let Gemini (free tier) or any
  OpenAI-compatible model design it. Every change can be undone.
- **Whole apps, not just screens.** Add screens, link buttons between them,
  and tap through them in preview mode, like a Figma prototype.
- **Code that reads like a person wrote it.** One file per screen, named
  routes, `const` where possible, named layers as their own widgets, and
  `// TODO` comments where your API calls and logic go. FlutterCanvas builds
  the UI; state, APIs and controllers stay yours.
- **Designs are JSON**, so you can version them in git or serve them from a
  backend and render them at runtime.

## Packages

| Package | What it does |
| --- | --- |
| [`fluttercanvas_core`](packages/fluttercanvas_core) | Pure Dart design model, JSON format and code generator. |
| [`fluttercanvas_renderer`](packages/fluttercanvas_renderer) | Renders JSON designs as live widgets (server-driven UI). |
| [`fluttercanvas`](packages/fluttercanvas) | The drag-and-drop editor. |

## Quick start

### Design screens in your app

```yaml
dev_dependencies:
  fluttercanvas: ^0.3.0
```

```dart
import 'package:flutter/foundation.dart';
import 'package:fluttercanvas/fluttercanvas.dart';

MaterialApp(
  home: kDebugMode ? const FlutterCanvasBuilder() : const MyHomePage(),
);
```

Run the app, design your screens, press **Export code**, and copy the files
into `lib/`:

```
lib/
├── main.dart
├── app_routes.dart
├── screens/
│   ├── home_screen.dart
│   └── details_screen.dart
└── widgets/
    └── responsive_layout.dart
```

### Render designs at runtime

```yaml
dependencies:
  fluttercanvas_renderer: ^0.3.0
```

```dart
CanvasProjectView(
  project: CanvasProject.fromJsonString(jsonFromServer),
  onAction: (action, node) => handle(action),
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

## Widgets in 0.3

Layout: column, row, adaptive row, responsive grid, free canvas, box, container, card.
Content: text, button, icon, image, text field, divider, space.

## Builder controls

| Action | How |
| --- | --- |
| Add a widget | Drag it from the palette, or tap it to add after the selection |
| Select | Tap a widget on the canvas, or use the **Layers** tab |
| Draw a box | Box tool in the bottom dock, then press and drag |
| Things side by side | Select a box, set **Layout** to **Row**, then add widgets. Or select a widget and press **Put in a row** |
| Round avatar | Draw a 40 × 40 box, radius 20, select it, add an **Image** (it fills the box) |
| Move precisely | Arrow keys (Shift for 10 px) |
| Tap actions and animations | **Interaction** and **Animation** in the properties panel |
| App bar and bottom bar | Screen settings: **App bar** and **Bottom navigation** |
| Use a pub.dev package | **Custom code** widget |
| Code, JSON, CLI, AI | Terminal icon in the toolbar |
| Light or dark mode | Theme button in the toolbar |
| Place anywhere | Add a **Free canvas**, select a widget inside it and drag |
| Resize | Drag the square handle at the selected widget's corner |
| Edit text | Double-tap text or a button |
| Copy one widget's code | **<>** button in the properties panel |
| Move | Long-press a widget and drag it, or use the arrows in the properties panel |
| Edit | Change values in the properties panel |
| Preview another device | Device button in the toolbar |
| Add a screen | **+** next to Screens |
| Link a button | Select it, then set **On tap, go to** |
| Try the app | Play button in the toolbar |
| Name a layer | **Layer name** in the properties panel |
| Save or load a design | **Design JSON** button |

## Claude skill

`skills/flutter-canvas` is a Claude skill that writes FlutterCanvas designs.
Zip the `flutter-canvas` folder and add it in Claude under
**Settings → Capabilities → Skills**.

## Repository layout

```
fluttercanvas/
├── packages/
│   ├── fluttercanvas_core/      # Model, JSON and code generator (pure Dart)
│   ├── fluttercanvas_renderer/  # Renders designs at runtime
│   └── fluttercanvas/   # Drag-and-drop editor
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

1. Replace `Sulmanali77` in every `pubspec.yaml` and `README.md`.
2. Check the names are free: search pub.dev for `fluttercanvas_core`,
   `fluttercanvas_renderer` and `fluttercanvas`.
3. Publish in dependency order:

```bash
cd packages/fluttercanvas_core     && flutter pub publish --dry-run && flutter pub publish
cd ../fluttercanvas_renderer       && flutter pub publish --dry-run && flutter pub publish
cd ../fluttercanvas        && flutter pub publish --dry-run && flutter pub publish
```

## Roadmap

- Theme editor that exports `ThemeData`, and more widgets (lists, tabs, bottom navigation).
- Download the exported code as a zip.
- Drop indicators for inserting before a widget.
- Per-breakpoint property overrides.
- Screen templates: login, dashboard, profile, onboarding.
- Layers panel.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). New widgets and templates are great
first contributions.

## License

MIT. See [LICENSE](LICENSE).
