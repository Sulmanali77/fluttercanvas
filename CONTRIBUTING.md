# Contributing to FlutterCanvas

Thanks for helping! Bug reports, new widgets and templates are all welcome.

## Set up

```bash
git clone https://github.com/sulmanali77/fluttercanvas.git
cd fluttercanvas
flutter pub get
```

## Before opening a pull request

```bash
dart format .
flutter analyze
(cd packages/fluttercanvas_core && flutter test)
(cd packages/fluttercanvas_renderer && flutter test)
(cd packages/fluttercanvas_builder && flutter test)
```

## Adding a widget type

1. Add a `WidgetSpec` to `WidgetCatalog.all` in `fluttercanvas_core`.
2. Render it in `CanvasNodeView` in `fluttercanvas_renderer`.
3. Generate code for it in `FlutterCodeGenerator` in `fluttercanvas_core`.
4. Add a palette icon in `WidgetPalette` in `fluttercanvas_builder`.
5. Add tests, and make sure the renderer and the generated code look the same.
