import 'widget_node.dart';

/// How many children a widget type accepts.
enum ChildMode { none, single, multiple }

/// The kind of editor used for a property.
enum PropKind {
  text,
  multilineText,
  number,
  color,
  toggle,
  choice,

  /// A link to another screen: empty for none, `back`, or a screen id.
  screenLink,
}

/// Describes one editable property of a widget type.
class PropSpec {
  const PropSpec(
    this.key,
    this.label,
    this.kind, {
    this.options = const [],
    this.min,
    this.max,
  });

  final String key;
  final String label;
  final PropKind kind;

  /// Allowed values for [PropKind.choice].
  final List<String> options;

  /// Lower bound for [PropKind.number].
  final double? min;

  /// Upper bound for [PropKind.number].
  final double? max;
}

/// Describes a widget type that can be placed on the canvas.
class WidgetSpec {
  const WidgetSpec({
    required this.type,
    required this.label,
    required this.category,
    required this.description,
    required this.childMode,
    required this.defaults,
    required this.props,
  });

  final String type;
  final String label;
  final String category;
  final String description;
  final ChildMode childMode;
  final Map<String, Object?> defaults;
  final List<PropSpec> props;

  bool get acceptsChildren => childMode != ChildMode.none;
}

/// Identifiers of the built-in widget types.
abstract final class WidgetTypes {
  static const column = 'column';
  static const row = 'row';
  static const adaptiveRow = 'adaptiveRow';
  static const grid = 'grid';
  static const freeCanvas = 'freeCanvas';
  static const box = 'box';
  static const container = 'container';
  static const card = 'card';
  static const text = 'text';
  static const button = 'button';
  static const icon = 'icon';
  static const image = 'image';
  static const textField = 'textField';
  static const customCode = 'customCode';
  static const divider = 'divider';
  static const spacer = 'spacer';
}

/// Allowed values for choice properties.
abstract final class PropOptions {
  static const mainAxis = [
    'start',
    'center',
    'end',
    'spaceBetween',
    'spaceAround',
    'spaceEvenly',
  ];
  static const columnCross = ['start', 'center', 'end', 'stretch'];
  static const rowCross = ['start', 'center', 'end'];
  static const fontWeight = ['normal', 'medium', 'semibold', 'bold'];
  static const textAlign = ['left', 'center', 'right'];
  static const buttonVariant = ['filled', 'elevated', 'outlined', 'text'];
  static const imageFit = ['cover', 'contain', 'fill'];

  /// How a box arranges its children: at exact positions, or in a line
  /// like Figma's auto layout.
  static const boxLayout = ['free', 'row', 'column'];

  /// Material icon names, matching `Icons.<name>` in Flutter.
  static const icons = [
    'star',
    'favorite',
    'home',
    'person',
    'settings',
    'search',
    'mail',
    'phone',
    'shopping_cart',
    'check',
    'info',
    'menu',
    'notifications',
    'lock',
    'calendar_today',
    'camera_alt',
    'storefront',
    'shopping_bag',
    'local_offer',
    'arrow_back',
    'close',
    'add',
    'remove',
    'delete',
    'share',
    'more_vert',
    'chevron_right',
    'location_on',
    'credit_card',
    'tune',
    'bookmark',
    'grid_view',
    'category',
  ];

  /// Icons plus an empty choice for "no icon".
  static const iconsOrNone = ['', ...icons];

  /// Entrance animations any widget can play when its screen opens.
  static const animations = ['none', 'fade', 'slideUp', 'slideLeft', 'scale'];
}

/// Registry of every widget type FlutterCanvas supports.
abstract final class WidgetCatalog {
  static const _spacing =
      PropSpec('spacing', 'Spacing', PropKind.number, min: 0, max: 200);
  static const _padding =
      PropSpec('padding', 'Padding', PropKind.number, min: 0, max: 200);
  static const _radius = PropSpec(
    'borderRadius',
    'Corner radius',
    PropKind.number,
    min: 0,
    max: 200,
  );

  /// All widget specs, in palette order.
  static const List<WidgetSpec> all = [
    WidgetSpec(
      type: WidgetTypes.column,
      label: 'Column',
      category: 'Layout',
      description: 'Stacks widgets vertically.',
      childMode: ChildMode.multiple,
      defaults: {
        'mainAxisAlignment': 'start',
        'crossAxisAlignment': 'stretch',
        'spacing': 12,
      },
      props: [
        PropSpec('mainAxisAlignment', 'Vertical alignment', PropKind.choice,
            options: PropOptions.mainAxis),
        PropSpec('crossAxisAlignment', 'Horizontal alignment', PropKind.choice,
            options: PropOptions.columnCross),
        _spacing,
      ],
    ),
    WidgetSpec(
      type: WidgetTypes.row,
      label: 'Row',
      category: 'Layout',
      description: 'Places widgets side by side on every screen size.',
      childMode: ChildMode.multiple,
      defaults: {
        'mainAxisAlignment': 'start',
        'crossAxisAlignment': 'center',
        'spacing': 12,
      },
      props: [
        PropSpec('mainAxisAlignment', 'Horizontal alignment', PropKind.choice,
            options: PropOptions.mainAxis),
        PropSpec('crossAxisAlignment', 'Vertical alignment', PropKind.choice,
            options: PropOptions.rowCross),
        _spacing,
      ],
    ),
    WidgetSpec(
      type: WidgetTypes.adaptiveRow,
      label: 'Adaptive row',
      category: 'Layout',
      description: 'Side by side on wide screens, stacked on phones.',
      childMode: ChildMode.multiple,
      defaults: {'spacing': 16, 'breakpoint': 600},
      props: [
        _spacing,
        PropSpec('breakpoint', 'Stack below width', PropKind.number,
            min: 200, max: 2000),
      ],
    ),
    WidgetSpec(
      type: WidgetTypes.grid,
      label: 'Responsive grid',
      category: 'Layout',
      description: 'Sets a column count for phone, tablet and desktop.',
      childMode: ChildMode.multiple,
      defaults: {
        'mobileColumns': 1,
        'tabletColumns': 2,
        'desktopColumns': 3,
        'spacing': 16,
      },
      props: [
        PropSpec('mobileColumns', 'Columns on phones', PropKind.number,
            min: 1, max: 6),
        PropSpec('tabletColumns', 'Columns on tablets', PropKind.number,
            min: 1, max: 6),
        PropSpec('desktopColumns', 'Columns on desktop', PropKind.number,
            min: 1, max: 6),
        _spacing,
      ],
    ),
    WidgetSpec(
      type: WidgetTypes.freeCanvas,
      label: 'Free canvas',
      category: 'Layout',
      description: 'Place widgets anywhere, like a Figma frame. '
          'Shrinks to fit small screens.',
      childMode: ChildMode.multiple,
      defaults: {
        'designWidth': 360,
        'designHeight': 320,
        'color': '#FFF8FAFC',
        'borderRadius': 12,
      },
      props: [
        PropSpec('designWidth', 'Frame width', PropKind.number,
            min: 40, max: 4000),
        PropSpec('designHeight', 'Frame height', PropKind.number,
            min: 40, max: 4000),
        PropSpec('color', 'Background', PropKind.color),
        _radius,
      ],
    ),
    WidgetSpec(
      type: WidgetTypes.box,
      label: 'Box',
      category: 'Layout',
      description: 'A shape you can draw. Holds text, images and other '
          'boxes anywhere inside.',
      childMode: ChildMode.multiple,
      defaults: {
        'width': 160,
        'height': 120,
        'layout': 'free',
        'spacing': 8,
        'mainAxisAlignment': 'start',
        'crossAxisAlignment': 'center',
        'color': '#FFE0E7FF',
        'borderRadius': 16,
        'padding': 0,
        'borderColor': '',
        'borderWidth': 0,
        'shadow': 0,
      },
      props: [
        PropSpec('layout', 'Layout', PropKind.choice,
            options: PropOptions.boxLayout),
        PropSpec('spacing', 'Gap between items', PropKind.number,
            min: 0, max: 200),
        PropSpec('mainAxisAlignment', 'Arrange', PropKind.choice,
            options: PropOptions.mainAxis),
        PropSpec('crossAxisAlignment', 'Align', PropKind.choice,
            options: PropOptions.rowCross),
        PropSpec('color', 'Fill', PropKind.color),
        _radius,
        PropSpec('padding', 'Inner spacing', PropKind.number,
            min: 0, max: 200),
        PropSpec('borderColor', 'Border color', PropKind.color),
        PropSpec('borderWidth', 'Border width', PropKind.number,
            min: 0, max: 40),
        PropSpec('shadow', 'Shadow', PropKind.number, min: 0, max: 40),
      ],
    ),
    WidgetSpec(
      type: WidgetTypes.container,
      label: 'Container',
      category: 'Layout',
      description: 'Box with padding, background and rounded corners.',
      childMode: ChildMode.single,
      defaults: {
        'padding': 16,
        'color': '#FFF1F5F9',
        'borderRadius': 12,
        'width': 0,
        'height': 0,
      },
      props: [
        _padding,
        PropSpec('color', 'Background', PropKind.color),
        _radius,
      ],
    ),
    WidgetSpec(
      type: WidgetTypes.card,
      label: 'Card',
      category: 'Layout',
      description: 'Raised surface that groups related content.',
      childMode: ChildMode.single,
      defaults: {
        'padding': 16,
        'elevation': 1,
        'borderRadius': 12,
        'color': '',
      },
      props: [
        _padding,
        PropSpec('elevation', 'Elevation', PropKind.number, min: 0, max: 24),
        _radius,
        PropSpec('color', 'Background', PropKind.color),
      ],
    ),
    WidgetSpec(
      type: WidgetTypes.text,
      label: 'Text',
      category: 'Content',
      description: 'Headings, labels and paragraphs.',
      childMode: ChildMode.none,
      defaults: {
        'text': 'Text',
        'fontSize': 16,
        'fontWeight': 'normal',
        'color': '#FF1F2937',
        'textAlign': 'left',
      },
      props: [
        PropSpec('text', 'Text', PropKind.multilineText),
        PropSpec('fontSize', 'Font size', PropKind.number, min: 6, max: 200),
        PropSpec('fontWeight', 'Weight', PropKind.choice,
            options: PropOptions.fontWeight),
        PropSpec('textAlign', 'Alignment', PropKind.choice,
            options: PropOptions.textAlign),
        PropSpec('color', 'Color', PropKind.color),
      ],
    ),
    WidgetSpec(
      type: WidgetTypes.button,
      label: 'Button',
      category: 'Content',
      description: 'Filled, elevated, outlined or text button.',
      childMode: ChildMode.none,
      defaults: {
        'label': 'Button',
        'navigateTo': '',
        'variant': 'filled',
        'color': '#FF4F46E5',
        'fullWidth': false,
        'action': '',
      },
      props: [
        PropSpec('label', 'Label', PropKind.text),
        PropSpec('variant', 'Style', PropKind.choice,
            options: PropOptions.buttonVariant),
        PropSpec('color', 'Color', PropKind.color),
        PropSpec('fullWidth', 'Full width', PropKind.toggle),
      ],
    ),
    WidgetSpec(
      type: WidgetTypes.icon,
      label: 'Icon',
      category: 'Content',
      description: 'A Material icon.',
      childMode: ChildMode.none,
      defaults: {'icon': 'star', 'size': 32, 'color': '#FF4F46E5', 'badge': ''},
      props: [
        PropSpec('icon', 'Icon', PropKind.choice, options: PropOptions.icons),
        PropSpec('size', 'Size', PropKind.number, min: 8, max: 400),
        PropSpec('color', 'Color', PropKind.color),
        PropSpec('badge', 'Badge (for example 3 or New)', PropKind.text),
      ],
    ),
    WidgetSpec(
      type: WidgetTypes.image,
      label: 'Image',
      category: 'Content',
      description: 'Image loaded from a URL.',
      childMode: ChildMode.none,
      defaults: {
        'url': 'https://picsum.photos/seed/fluttercanvas/800/500',
        'height': 180,
        'borderRadius': 12,
        'fit': 'cover',
      },
      props: [
        PropSpec('url', 'Image URL', PropKind.text),
        PropSpec('height', 'Height', PropKind.number, min: 20, max: 2000),
        _radius,
        PropSpec('fit', 'Fit', PropKind.choice, options: PropOptions.imageFit),
      ],
    ),
    WidgetSpec(
      type: WidgetTypes.textField,
      label: 'Text field',
      category: 'Content',
      description: 'Input with a label and hint.',
      childMode: ChildMode.none,
      defaults: {'label': 'Label', 'hint': '', 'obscure': false},
      props: [
        PropSpec('label', 'Label', PropKind.text),
        PropSpec('hint', 'Hint', PropKind.text),
        PropSpec('obscure', 'Hide input (passwords)', PropKind.toggle),
      ],
    ),
    WidgetSpec(
      type: WidgetTypes.divider,
      label: 'Divider',
      category: 'Content',
      description: 'Thin horizontal line.',
      childMode: ChildMode.none,
      defaults: {'thickness': 1, 'color': '#FFE5E7EB'},
      props: [
        PropSpec('thickness', 'Thickness', PropKind.number, min: 0, max: 20),
        PropSpec('color', 'Color', PropKind.color),
      ],
    ),
    WidgetSpec(
      type: WidgetTypes.spacer,
      label: 'Space',
      category: 'Content',
      description: 'Fixed empty space.',
      childMode: ChildMode.none,
      defaults: {'size': 16},
      props: [
        PropSpec('size', 'Size', PropKind.number, min: 0, max: 400),
      ],
    ),
    WidgetSpec(
      type: WidgetTypes.customCode,
      label: 'Custom code',
      category: 'Advanced',
      description: 'Any Flutter widget or pub.dev package, written in Dart.',
      childMode: ChildMode.none,
      defaults: {
        'code': 'const FlutterLogo(size: 64)',
        'imports': '',
        'packages': '',
      },
      props: [
        PropSpec('code', 'Widget code (one Dart expression)',
            PropKind.multilineText),
        PropSpec('imports', 'Imports, one per line', PropKind.multilineText),
        PropSpec('packages', 'Packages for pubspec, one per line',
            PropKind.multilineText),
      ],
    ),
  ];

  /// Size and spacing every widget has, shown under "Size and position".
  static const layoutProps = [
    PropSpec('width', 'Width (0 = auto)', PropKind.number, min: 0, max: 4000),
    PropSpec('height', 'Height (0 = auto)', PropKind.number,
        min: 0, max: 4000),
    PropSpec('margin', 'Outer spacing', PropKind.number, min: 0, max: 400),
  ];

  /// Position of a widget inside a free canvas.
  static const positionProps = [
    PropSpec('x', 'X', PropKind.number, min: 0, max: 4000),
    PropSpec('y', 'Y', PropKind.number, min: 0, max: 4000),
    PropSpec('fill', 'Fill the whole box', PropKind.toggle),
  ];

  /// What happens when any widget is tapped.
  static const interactionProps = [
    PropSpec('navigateTo', 'On tap, go to', PropKind.screenLink),
    PropSpec('action', 'Action id (for your own code)', PropKind.text),
  ];

  /// The entrance animation any widget can play.
  static const animationProps = [
    PropSpec('animation', 'Entrance animation', PropKind.choice,
        options: PropOptions.animations),
    PropSpec('animationMs', 'Duration (ms)', PropKind.number,
        min: 0, max: 5000),
  ];

  /// Whether the children of [node] sit at exact `x`/`y` positions: a free
  /// canvas, or a box whose layout is `free`.
  static bool isFreeLayout(WidgetNode? node) {
    if (node == null) return false;
    if (node.type == WidgetTypes.freeCanvas) return true;
    return node.type == WidgetTypes.box &&
        choiceOf(node, 'layout', PropOptions.boxLayout) == 'free';
  }

  /// Box properties that only matter when the box lays out in a row or
  /// column.
  static const autoLayoutKeys = {
    'spacing',
    'mainAxisAlignment',
    'crossAxisAlignment',
  };

  /// Height a widget really gets. Boxes with a free layout need a height,
  /// so they fall back to 120 when none is set.
  static double? fixedHeight(WidgetNode node) {
    final height = node.number('height');
    if (height > 0) return height;
    return isFreeLayout(node) ? 120 : null;
  }

  /// Width used for widgets inside a free canvas that have no width set.
  static const double freeCanvasDefaultWidth = 200;

  /// Width of [node] inside a free canvas, or null to let it size itself.
  ///
  /// Widgets that stretch to fill their parent (images, text fields,
  /// layouts) need a width there, so they get [freeCanvasDefaultWidth].
  static double? freeCanvasWidth(WidgetNode node) {
    final width = node.number('width');
    if (width > 0) return width;
    final sizesItself = node.type == WidgetTypes.text ||
        node.type == WidgetTypes.icon ||
        node.type == WidgetTypes.spacer ||
        (node.type == WidgetTypes.button && !node.boolean('fullWidth'));
    return sizesItself ? null : freeCanvasDefaultWidth;
  }

  static final Map<String, WidgetSpec> _byType = {
    for (final spec in all) spec.type: spec,
  };

  /// Returns the spec for [type], or null for unknown types.
  static WidgetSpec? of(String type) => _byType[type];

  /// Default properties for [type].
  static Map<String, Object?> defaultsFor(String type) =>
      _byType[type]?.defaults ?? const {};

  /// Creates a new node of [type] with default properties.
  static WidgetNode create(String type) {
    final spec = of(type);
    if (spec == null) {
      throw ArgumentError.value(type, 'type', 'Unknown widget type');
    }
    return WidgetNode(id: NodeIds.next(), type: type, props: spec.defaults);
  }

  /// Reads a choice property, falling back to the type's default or the
  /// first option when the stored value is not allowed.
  static String choiceOf(WidgetNode node, String key, List<String> options) {
    final value = node.string(key);
    if (options.contains(value)) return value;
    final fallback = defaultsFor(node.type)[key];
    return fallback is String && options.contains(fallback)
        ? fallback
        : options.first;
  }
}
