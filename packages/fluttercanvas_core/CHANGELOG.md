## 0.3.0

- Any widget can open a screen or run an action when tapped (`navigateTo`, `action`), and play an entrance animation (`animation`, `animationMs`).
- Icons can show a `badge`. Screens have editable app bars and a shared bottom navigation bar (`CanvasDocument.bars`, `BarKeys`).
- `customCode` widgets use any pub.dev package; the export adds their imports and a `pubspec_dependencies.yaml`.
- Added `CanvasTemplates` (starter, blank, animated e-commerce), `DesignPrompt` for AI assistants, and the `fluttercanvas export` command.
- **Auto layout for boxes:** a box can lay its children out freely, in a row or in a column, with a gap, arrangement and alignment, like Figma's auto layout.
- Children of a free box can **fill the whole box**, which makes round avatars easy.
- Widgets keep the exact width you give them, even inside columns that stretch their children, on the canvas and in exported code.
- Added the `box` widget: a drawable shape with fill, corner radius, inner spacing, border and shadow, whose children sit at exact positions. Boxes can hold boxes.
- Added `CanvasDocument.freeForm()` for screens that are one free canvas, and `WidgetCatalog.isFreeLayout`.
- Added the `freeCanvas` widget: a Figma-like frame where children sit at exact `x`/`y` positions. It keeps its design size and shrinks to fit small screens.
- Every widget now supports `width`, `height` and `margin`.
- Added `FlutterCodeGenerator.generateWidget` to export the code for a single widget.
- `WidgetCatalog.layoutProps`, `positionProps` and `freeCanvasWidth` describe the new properties.

## 0.2.0

- Added `CanvasProject` for apps with several screens. Version 0.1 JSON still loads.
- Buttons can link to another screen or go back with the `navigateTo` property.
- Added `FlutterCodeGenerator.generateProject`, which writes `main.dart`, `app_routes.dart`, one file per screen and shared responsive widgets.
- Named layers are exported as their own `StatelessWidget` classes.
- Generated code adds `const` where possible, skips default values, and marks where your logic goes with `// TODO` comments.
- Screens now have an `id`, and the default screen name is `Home`.

## 0.1.0

- Initial release: widget model, JSON format, 13 widget types and a responsive Flutter code generator.
