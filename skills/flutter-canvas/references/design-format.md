# FlutterCanvas design format (version 0.3)

## Project

```json
{
  "schemaVersion": 2,
  "name": "My App",
  "initialScreen": "<screen id>",
  "screens": [ <screen>, ... ]
}
```

## Screen

```json
{
  "id": "home",
  "name": "Home",
  "title": "App bar title",
  "showAppBar": true,
  "backgroundColor": "#FFFFFFFF",
  "bars": { "navIcon": "storefront", "navLabel": "Shop" },
  "root": <widget>
}
```

`bars` keys: `appBarColor`, `appBarForeground` (colors), `centerTitle`
(bool), `leadingIcon`, `action1Icon`, `action2Icon` (icon names),
`leadingLink`, `action1Link`, `action2Link` (screen id or `back`),
`action1Badge` (text), `navIcon`, `navLabel` (bottom navigation).

## Widget

```json
{ "id": "unique", "type": "box", "name": "Optional layer name",
  "props": { ... }, "children": [ ... ] }
```

A `name` turns the widget into its own `StatelessWidget` class in the code.

Every widget also accepts: `width`, `height` (0 = automatic), `margin`,
`navigateTo`, `action`, `animation` (`none`, `fade`, `slideUp`,
`slideLeft`, `scale`), `animationMs`. Inside a `freeCanvas` or a `box` with
`layout: "free"`, children also use `x`, `y` and optionally `fill: true`.

| Type | What it is | Props |
| --- | --- | --- |
| `column` | Stacks widgets vertically. | `mainAxisAlignment`, `crossAxisAlignment`, `spacing` |
| `row` | Places widgets side by side on every screen size. | `mainAxisAlignment`, `crossAxisAlignment`, `spacing` |
| `adaptiveRow` | Side by side on wide screens, stacked on phones. | `breakpoint`, `spacing` |
| `grid` | Sets a column count for phone, tablet and desktop. | `mobileColumns`, `tabletColumns`, `desktopColumns`, `spacing` |
| `freeCanvas` | Place widgets anywhere, like a Figma frame. Shrinks to fit small screens. | `designWidth`, `designHeight`, `color`, `borderRadius` |
| `box` | A shape you can draw. Holds text, images and other boxes anywhere inside. | `layout`, `spacing`, `mainAxisAlignment`, `crossAxisAlignment`, `color`, `padding`, `borderColor`, `borderWidth`, `shadow`, `borderRadius` |
| `container` | Box with padding, background and rounded corners. | `color`, `padding`, `borderRadius` |
| `card` | Raised surface that groups related content. | `elevation`, `color`, `padding`, `borderRadius` |
| `text` | Headings, labels and paragraphs. | `text`, `fontSize`, `fontWeight`, `textAlign`, `color` |
| `button` | Filled, elevated, outlined or text button. | `label`, `variant`, `color`, `fullWidth` |
| `icon` | A Material icon. | `icon`, `size`, `color`, `badge` |
| `image` | Image loaded from a URL. | `url`, `height`, `fit`, `borderRadius` |
| `textField` | Input with a label and hint. | `label`, `hint`, `obscure` |
| `divider` | Thin horizontal line. | `thickness`, `color` |
| `spacer` | Fixed empty space. | `size` |
| `customCode` | Any Flutter widget or pub.dev package, written in Dart. | `code`, `imports`, `packages` |

Choice values: `mainAxisAlignment` start, center, end, spaceBetween,
spaceAround, spaceEvenly. `crossAxisAlignment` start, center, end (column
also stretch). `fontWeight` normal, medium, semibold, bold. `textAlign` left,
center, right. Button `variant` filled, elevated, outlined, text. Image `fit`
cover, contain, fill. Box `layout` free, row, column.

Icons: star, favorite, home, person, settings, search, mail, phone,
shopping_cart, check, info, menu, notifications, lock, calendar_today,
camera_alt, storefront, shopping_bag, local_offer, arrow_back, close, add,
remove, delete, share, more_vert, chevron_right, location_on, credit_card,
tune, bookmark, grid_view, category.

## Complete example: login that opens Home

```json
{
  "schemaVersion": 2,
  "name": "Demo",
  "initialScreen": "login",
  "screens": [
    {
      "id": "login", "name": "Login", "title": "Welcome back",
      "showAppBar": false, "backgroundColor": "#FFFFFFFF",
      "root": { "id": "root", "type": "column",
        "props": { "crossAxisAlignment": "stretch", "spacing": 16 },
        "children": [
          { "id": "logo", "type": "icon", "props": { "icon": "lock", "size": 56, "animation": "scale" } },
          { "id": "t1", "type": "text", "props": { "text": "Sign in", "fontSize": 28, "fontWeight": "bold" } },
          { "id": "email", "type": "textField", "props": { "label": "Email" } },
          { "id": "pass", "type": "textField", "props": { "label": "Password", "obscure": true } },
          { "id": "go", "type": "button", "props": { "label": "Sign in", "fullWidth": true,
            "navigateTo": "home", "action": "sign_in" } }
        ] }
    },
    {
      "id": "home", "name": "Home", "title": "Home",
      "root": { "id": "root", "type": "column", "props": { "spacing": 12 },
        "children": [
          { "id": "hi", "type": "text", "props": { "text": "You're in!", "fontSize": 24 } }
        ] }
    }
  ]
}
```
