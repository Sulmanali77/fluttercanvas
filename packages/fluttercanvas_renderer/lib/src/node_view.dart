import 'package:flutter/material.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

import 'adaptive_row.dart';
import 'render_delegate.dart';
import 'responsive_grid.dart';
import 'style_mapping.dart';

/// Renders one [WidgetNode] and its children.
class CanvasNodeView extends StatelessWidget {
  const CanvasNodeView({
    super.key,
    required this.node,
    this.delegate = const CanvasRenderDelegate(),
  });

  final WidgetNode node;
  final CanvasRenderDelegate delegate;

  @override
  Widget build(BuildContext context) =>
      delegate.wrap(context, node, _buildNode(context));

  Widget _childView(WidgetNode child) =>
      CanvasNodeView(key: ValueKey(child.id), node: child, delegate: delegate);

  List<Widget> _children(BuildContext context) {
    if (node.children.isEmpty) {
      final slot = delegate.emptySlot(context, node);
      return slot == null ? const [] : [slot];
    }
    return [for (final child in node.children) _childView(child)];
  }

  Widget? _singleChild(BuildContext context) => node.children.isEmpty
      ? delegate.emptySlot(context, node)
      : _childView(node.children.first);

  String _choice(String key, List<String> options) =>
      WidgetCatalog.choiceOf(node, key, options);

  int _columns(String key) {
    final value = node.number(key, 1).round();
    return value < 1 ? 1 : (value > 12 ? 12 : value);
  }

  Widget _buildNode(BuildContext context) {
    switch (node.type) {
      case WidgetTypes.column:
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
              mainAxisOf(_choice('mainAxisAlignment', PropOptions.mainAxis)),
          crossAxisAlignment: crossAxisOf(
              _choice('crossAxisAlignment', PropOptions.columnCross)),
          spacing: node.number('spacing'),
          children: _children(context),
        );
      case WidgetTypes.row:
        return Row(
          mainAxisAlignment:
              mainAxisOf(_choice('mainAxisAlignment', PropOptions.mainAxis)),
          crossAxisAlignment:
              crossAxisOf(_choice('crossAxisAlignment', PropOptions.rowCross)),
          spacing: node.number('spacing'),
          children: [
            for (final child in _children(context)) Flexible(child: child),
          ],
        );
      case WidgetTypes.adaptiveRow:
        return AdaptiveRow(
          breakpoint: node.number('breakpoint', Breakpoints.tablet),
          spacing: node.number('spacing'),
          children: _children(context),
        );
      case WidgetTypes.grid:
        return ResponsiveGrid(
          mobileColumns: _columns('mobileColumns'),
          tabletColumns: _columns('tabletColumns'),
          desktopColumns: _columns('desktopColumns'),
          spacing: node.number('spacing'),
          children: _children(context),
        );
      case WidgetTypes.container:
        {
          final width = node.number('width');
          final height = node.number('height');
          return Container(
            width: width > 0 ? width : null,
            height: height > 0 ? height : null,
            padding: EdgeInsets.all(node.number('padding')),
            decoration: BoxDecoration(
              color: colorOf(node.string('color')),
              borderRadius:
                  BorderRadius.circular(node.number('borderRadius')),
            ),
            child: _singleChild(context),
          );
        }
      case WidgetTypes.card:
        return Card(
          margin: EdgeInsets.zero,
          color: colorOf(node.string('color')),
          elevation: node.number('elevation'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(node.number('borderRadius')),
          ),
          child: Padding(
            padding: EdgeInsets.all(node.number('padding')),
            child: _singleChild(context),
          ),
        );
      case WidgetTypes.text:
        return Text(
          node.string('text'),
          textAlign: textAlignOf(_choice('textAlign', PropOptions.textAlign)),
          style: TextStyle(
            fontSize: node.number('fontSize', 16).clamp(1.0, 400.0).toDouble(),
            fontWeight:
                fontWeightOf(_choice('fontWeight', PropOptions.fontWeight)),
            color: colorOf(node.string('color')),
          ),
        );
      case WidgetTypes.button:
        return _button();
      case WidgetTypes.icon:
        return Icon(
          iconOf(_choice('icon', PropOptions.icons)),
          size: node.number('size', 24),
          color: colorOf(node.string('color')),
        );
      case WidgetTypes.image:
        {
          final height = node.number('height', 180);
          return ClipRRect(
            borderRadius: BorderRadius.circular(node.number('borderRadius')),
            child: Image.network(
              node.string('url'),
              height: height,
              width: double.infinity,
              fit: boxFitOf(_choice('fit', PropOptions.imageFit)),
              errorBuilder: (context, error, stackTrace) => Container(
                height: height,
                color: const Color(0xFFE5E7EB),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ),
          );
        }
      case WidgetTypes.textField:
        {
          final label = node.string('label');
          final hint = node.string('hint');
          return TextField(
            obscureText: node.boolean('obscure'),
            decoration: InputDecoration(
              labelText: label.isEmpty ? null : label,
              hintText: hint.isEmpty ? null : hint,
              border: const OutlineInputBorder(),
            ),
          );
        }
      case WidgetTypes.divider:
        return Divider(
          thickness: node.number('thickness', 1),
          color: colorOf(node.string('color')),
        );
      case WidgetTypes.spacer:
        {
          final size = node.number('size', 16);
          return SizedBox(width: size, height: size);
        }
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          color: const Color(0xFFFEE2E2),
          child: Text('Unknown widget "${node.type}"'),
        );
    }
  }

  Widget _button() {
    final color = colorOf(node.string('color'));
    final label = Text(node.string('label'));
    void onPressed() => delegate.onAction?.call(node.string('action'), node);

    final Widget button = switch (
        _choice('variant', PropOptions.buttonVariant)) {
      'elevated' => ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: color == null ? null : Colors.white,
          ),
          child: label,
        ),
      'outlined' => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: color == null ? null : BorderSide(color: color),
          ),
          child: label,
        ),
      'text' => TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(foregroundColor: color),
          child: label,
        ),
      _ => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(backgroundColor: color),
          child: label,
        ),
    };
    return node.boolean('fullWidth')
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
