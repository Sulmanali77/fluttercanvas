# fluttercanvas_renderer

Render [FlutterCanvas](https://github.com/sulmanali77/fluttercanvas) designs as
real Flutter widgets at runtime. Design a screen in the builder, save it as
JSON, and show it in any app on Android, iOS, web, macOS, Windows or Linux.

Because designs are plain JSON, you can serve them from your backend and
update screens without an app store release (server-driven UI).

## Usage

```dart
import 'package:fluttercanvas_renderer/fluttercanvas_renderer.dart';

CanvasView.fromJson(
  jsonFromServer,
  delegate: CanvasRenderDelegate(
    onAction: (action, node) {
      if (action == 'checkout') Navigator.pushNamed(context, '/checkout');
    },
  ),
);
```

Give a button an **Action id** in the builder, and `onAction` receives it when
the button is pressed.

Set `includeScaffold: false` to embed a design inside one of your own screens.

## Responsive widgets

`AdaptiveRow` and `ResponsiveGrid` are exported too, so you can use them in
hand-written code:

```dart
ResponsiveGrid(
  mobileColumns: 1,
  tabletColumns: 2,
  desktopColumns: 4,
  children: products.map(ProductCard.new).toList(),
);
```
