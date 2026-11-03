## 0.3.0

- **AI agent panel** next to Design, like Antigravity: pick a model (Gemini, Groq, OpenRouter, OpenAI), chat with history, attach images and PDFs, paste links, and the agent changes the screen you're on. Each change shows **Undo**.
- **Move like Figma:** drag any widget in a free layout without selecting it first; arrow keys nudge by 1 px (Shift for 10); Delete, Escape, Cmd/Ctrl+Z, Shift+Cmd/Ctrl+Z and Cmd/Ctrl+D work on the canvas.
- **Interaction and animation** sections for every widget, and **App bar** and **Bottom navigation** sections in screen settings.
- **Templates** menu with an animated e-commerce app.
- **Developer menu:** view or copy all code, design JSON, the CLI command, and an **AI assistant** that designs from a prompt with Gemini or any OpenAI-compatible API.
- **Auto layout for boxes:** a box can lay its children out freely, in a row or in a column, with a gap, arrangement and alignment, like Figma's auto layout.
- Children of a free box can **fill the whole box**, which makes round avatars easy.
- Images added to a box fill it, and icons are centered and sized to fit.
- **Put in a row / Put in a column** wraps the selected widget so the next one you add goes beside or below it.
- New boxes only go inside another box when that box is selected first.
- Widgets keep the exact width you give them, even inside columns that stretch their children, on the canvas and in exported code.
- **Box tool:** press and drag on the canvas to draw a box, like Figma's rectangle tool. Boxes have fill, corner radius, inner spacing, border and shadow, and can hold text, images and other boxes.
- **Free-form screens:** new screens start as one frame you can draw on anywhere. Responsive screens are still available from the **+** menu.
- **Light, dark or system theme** for the builder, from the toolbar.
- **Realistic devices:** iPhone with Dynamic Island, status bar and home indicator; Pixel with a punch-hole camera; iPad; Mac and Chrome windows with safe areas applied to the preview.
- A floating tool dock and a dotted board give the canvas a design-tool feel.
- **Free canvas:** a Figma-like frame. Select a widget inside it and drag to place it anywhere.
- **Resize anything:** drag the corner handle of the selected widget, or type a width and height. Every widget also has outer spacing.
- **Layers panel:** see every widget on the screen as a tree and select from it.
- **Edit in place:** double-tap text or a button on the canvas to change its words.
- **Copy widget code:** export just the selected widget from the properties panel.
- The palette moved under an **Insert** tab, next to **Layers**.

## 0.2.0

- **Screens:** add, open, duplicate and delete screens, and choose the start screen.
- **Linking:** set "On tap, go to" on any button to open another screen or go back. Linked buttons show a badge on the canvas.
- **Preview mode:** press the play button and tap through the app like a prototype.
- **Layer names:** name a layer and it is exported as its own widget class.
- **Export:** "Export code" now produces a whole `lib` folder (`main.dart`, `app_routes.dart`, one file per screen and shared widgets), shown file by file with copy buttons.
- Breaking: `onExport` now receives `List<GeneratedFile>`. Use `BuilderController.exportScreenCode()` for a single file.

## 0.1.0

- Initial release: drag-and-drop canvas, 13 widgets, properties panel, device previews (iPhone, Android, iPad, Mac, Chrome), undo/redo, JSON import/export and responsive code export.
