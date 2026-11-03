## 0.3.1

- Complete README with features and examples.

## 0.3.0

- Renders tap actions, entrance animations (`EntranceAnimation`), icon badges, editable app bars and bottom navigation (`CanvasBottomNav`).
- **Auto layout for boxes:** a box can lay its children out freely, in a row or in a column, with a gap, arrangement and alignment, like Figma's auto layout.
- Children of a free box can **fill the whole box**, which makes round avatars easy.
- Widgets keep the exact width you give them, even inside columns that stretch their children, on the canvas and in exported code.
- Renders boxes (shapes with positioned children, borders and shadows) and free-form screens.
- Added `CanvasRenderDelegate.wrapLayer` and `FreeCanvas.wrapLayer`.
- Renders the new free canvas (`FreeCanvas`) with widgets at exact positions.
- Applies the width, height and margin that every widget now supports.

## 0.2.0

- Added `CanvasProjectView`, which runs a multi-screen design with real navigation.
- Buttons linked to a screen call the new `CanvasRenderDelegate.onNavigate`.
- `onAction` is now only called for buttons that have an action id.
- `CanvasView` accepts `onBack` to show a back button in its app bar.

## 0.1.0

- Initial release: `CanvasView`, `CanvasNodeView`, `AdaptiveRow`, `ResponsiveGrid` and render delegates with button actions.
