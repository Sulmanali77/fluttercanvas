---
name: flutter-canvas
description: Design Flutter app screens as FlutterCanvas design JSON, and turn them into clean Flutter code. Use this skill whenever the user mentions FlutterCanvas, fluttercanvas_core, fluttercanvas_builder or fluttercanvas_renderer, asks for a design JSON to import into the builder, wants screens, navbars, bottom navigation, animations or an e-commerce/login/profile layout generated for FlutterCanvas, or wants to export, explain or fix FlutterCanvas output, even if they only say "make me a screen for my canvas app".
---

# FlutterCanvas

FlutterCanvas is an open-source, Figma-like builder for Flutter
(github.com/Sulmanali77/fluttercanvas). Designs are JSON. The builder shows
them, and `FlutterCodeGenerator` turns them into a `lib` folder that only
needs `material.dart`.

## What to produce

Most requests want one of these:

1. **A design to import.** Write a complete project JSON (format below). The
   user opens the builder, presses the terminal icon, then **Design JSON →
   Import**, pastes it and presses **Load design**.
2. **Flutter code.** Tell the user to export from the builder (**Export
   code**), or with the CLI:
   `dart run fluttercanvas_core:fluttercanvas export design.json .`
3. **Help with the builder or packages.** Explain using the real features
   listed in `references/design-format.md`. Don't invent options.

## Writing a design

Read `references/design-format.md` for every widget type and property before
writing JSON. The rules that matter most:

- Output the **whole project**, not a fragment: `schemaVersion`, `name`,
  `initialScreen`, `screens`. Every screen and widget needs a unique `id`.
- Pick the layout on purpose:
  - **Responsive screen** (root `column`): widgets stack and adapt to any
    width. Best for lists, forms and content pages.
  - **Free-form screen** (root `freeCanvas`, `designWidth` 390): exact `x`/`y`
    positions, like Figma. Best for hero sections and custom art.
  - To put things **side by side**, use a `box` with `layout: "row"` (or a
    `row`). Never expect a column to place things beside each other.
- A widget with a `width` keeps exactly that size, even in a stretched
  column. Use `width: 0` to let it fill the space.
- Round avatar: a `box` with equal width and height, `borderRadius` half the
  size, and an `image` child with `fill: true`.
- Link screens with `navigateTo` (a screen id or `"back"`) on any widget.
  Put `action` ids where the user's own code goes (`"checkout"`).
- Screens with `bars.navIcon` share a bottom navigation bar.
- Use `animation` (`fade`, `slideUp`, `slideLeft`, `scale`) sparingly, with
  `animationMs` stepped by about 100 ms for items in a list.
- Images: `https://picsum.photos/seed/<word>/<w>/<h>`.
- Colors are `#AARRGGBB`; `""` means none.
- For pub.dev packages, use a `customCode` widget with `code`, `imports` and
  `packages`. It exports as real code and lists the packages in
  `pubspec_dependencies.yaml`.

Before answering, check that every `navigateTo` points at an existing screen
id, that `initialScreen` exists, and that the JSON parses.

## Example

A request like "login screen with a logo, email, password and a button that
opens Home" becomes a two-screen project: a responsive `Login` screen (icon,
title text, two `textField`s with `obscure: true` on the password, a
full-width `button` with `navigateTo` set to Home's id) and a `Home` screen.
See `references/design-format.md` for a complete example.
