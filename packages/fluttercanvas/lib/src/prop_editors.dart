import 'package:flutter/material.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

/// Edits one property, picking the right control for its [PropSpec.kind].
class PropEditor extends StatelessWidget {
  const PropEditor({
    super.key,
    required this.spec,
    required this.value,
    required this.onChanged,
    this.screenOptions = const {'': 'Nothing'},
  });

  final PropSpec spec;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  /// Values and labels for [PropKind.screenLink], such as
  /// `{'': 'Nothing', 'back': 'Go back', screenId: 'Profile'}`.
  final Map<String, String> screenOptions;

  static const _decoration = InputDecoration(
    border: OutlineInputBorder(),
    isDense: true,
  );

  @override
  Widget build(BuildContext context) {
    return switch (spec.kind) {
      PropKind.text => _textField(multiline: false),
      PropKind.multilineText => _textField(multiline: true),
      PropKind.number => _numberField(),
      PropKind.color => ColorPropField(
          label: spec.label,
          value: value is String ? value as String : '',
          onChanged: onChanged,
        ),
      PropKind.toggle => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(spec.label),
          value: value == true,
          onChanged: (checked) => onChanged(checked),
        ),
      PropKind.choice => _choiceField(),
      PropKind.screenLink => _dropdown(
          screenOptions,
          value is String && screenOptions.containsKey(value)
              ? value as String
              : screenOptions.keys.first,
        ),
    };
  }

  Widget _textField({required bool multiline}) {
    return TextFormField(
      initialValue: value is String ? value as String : '',
      minLines: 1,
      maxLines: multiline ? 4 : 1,
      decoration: _decoration.copyWith(labelText: spec.label),
      onChanged: onChanged,
    );
  }

  Widget _numberField() =>
      _NumberField(spec: spec, value: value, onChanged: onChanged);

  Widget _choiceField() {
    final options = spec.options;
    final current = value is String && options.contains(value)
        ? value as String
        : options.first;
    return _dropdown({for (final option in options) option: humanize(option)},
        current);
  }

  Widget _dropdown(Map<String, String> options, String current) {
    return InputDecorator(
      decoration: _decoration.copyWith(
        labelText: spec.label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          isExpanded: true,
          isDense: true,
          items: [
            for (final entry in options.entries)
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ),
    );
  }
}

/// A number input that also updates when the value changes elsewhere, for
/// example while dragging or resizing on the canvas.
class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.spec,
    required this.value,
    required this.onChanged,
  });

  final PropSpec spec;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final _text = TextEditingController(text: _format(widget.value));
  final _focus = FocusNode();

  static String _format(Object? value) =>
      value is num ? _formatNumber(value.toDouble()) : '';

  @override
  void didUpdateWidget(_NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Don't overwrite what the user is typing.
    if (_focus.hasFocus) return;
    final formatted = _format(widget.value);
    if (_text.text != formatted) _text.text = formatted;
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed(String text) {
    final number = double.tryParse(text.trim());
    if (number == null) return;
    final min = widget.spec.min;
    final max = widget.spec.max;
    if (min != null && number < min) return;
    if (max != null && number > max) return;
    widget.onChanged(number);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _text,
      focusNode: _focus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: PropEditor._decoration.copyWith(labelText: widget.spec.label),
      onChanged: _changed,
    );
  }
}

/// Turns `spaceBetween` or `shopping_cart` into `Space between` or
/// `Shopping cart`.
String humanize(String value) {
  if (value.isEmpty) return 'None';
  final spaced = value
      .replaceAll('_', ' ')
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (m) => '${m[1]} ${m[2]!.toLowerCase()}',
      );
  if (spaced.isEmpty) return spaced;
  return spaced[0].toUpperCase() + spaced.substring(1);
}

/// Color swatches plus a hex input.
class ColorPropField extends StatefulWidget {
  const ColorPropField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<Object?> onChanged;

  @override
  State<ColorPropField> createState() => _ColorPropFieldState();
}

class _ColorPropFieldState extends State<ColorPropField> {
  static const _swatches = [
    '',
    '#FFFFFFFF',
    '#FF000000',
    '#FF1F2937',
    '#FF6B7280',
    '#FFE5E7EB',
    '#FFF1F5F9',
    '#FF4F46E5',
    '#FF2563EB',
    '#FF0EA5E9',
    '#FF10B981',
    '#FFF59E0B',
    '#FFEF4444',
    '#FFEC4899',
  ];

  late final TextEditingController _text =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(ColorPropField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _text.text) _text.text = widget.value;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _pick(String hex) {
    _text.text = hex;
    widget.onChanged(hex);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = parseHexColor(widget.value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final hex in _swatches)
              _Swatch(
                hex: hex,
                selected: parseHexColor(hex) == current,
                onTap: () => _pick(hex),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _text,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            hintText: '#AARRGGBB, or empty for none',
          ),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.hex, required this.selected, required this.onTap});

  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = parseHexColor(hex);
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: hex.isEmpty ? 'None' : hex,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: value == null ? Colors.transparent : Color(value),
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 3 : 1,
            ),
          ),
          child: value == null
              ? Icon(Icons.block, size: 16, color: scheme.outline)
              : null,
        ),
      ),
    );
  }
}

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
