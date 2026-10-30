import 'widget_node.dart';

/// How many children a widget type accepts.
enum ChildMode { none, single, multiple }

/// The kind of editor used for a property.
enum PropKind { text, multilineText, number, color, toggle, choice }

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
  static const container = 'container';
  static const card = 'card';
  static const text = 'text';
  static const button = 'button';
  static const icon = 'icon';
  static const image = 'image';
  static const textField = 'textField';
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
  ];
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
        PropSpec('width', 'Width (0 = auto)', PropKind.number,
            min: 0, max: 4000),
        PropSpec('height', 'Height (0 = auto)', PropKind.number,
            min: 0, max: 4000),
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
        PropSpec('action', 'Action id (used by the renderer)', PropKind.text),
      ],
    ),
    WidgetSpec(
      type: WidgetTypes.icon,
      label: 'Icon',
      category: 'Content',
      description: 'A Material icon.',
      childMode: ChildMode.none,
      defaults: {'icon': 'star', 'size': 32, 'color': '#FF4F46E5'},
      props: [
        PropSpec('icon', 'Icon', PropKind.choice, options: PropOptions.icons),
        PropSpec('size', 'Size', PropKind.number, min: 8, max: 400),
        PropSpec('color', 'Color', PropKind.color),
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
  ];

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
