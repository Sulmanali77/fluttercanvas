import 'package:flutter/material.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

import 'adaptive_row.dart';
import 'entrance_animation.dart';
import 'free_canvas.dart';
import 'render_delegate.dart';
import 'responsive_grid.dart';
import 'style_mapping.dart';

/// Renders one [WidgetNode] and its children.
class CanvasNodeView extends StatelessWidget {
  const CanvasNodeView({
    super.key,
    required this.node,
    this.delegate = const CanvasRenderDelegate(),
    this.isPositioned = false,
  });

  final WidgetNode node;
  final CanvasRenderDelegate delegate;

  /// True when the parent free canvas already applies this node's size and
  /// position with a [Positioned].
  final bool isPositioned;

  @override
  Widget build(BuildContext context) {
    final built = _animated(_tappable(_buildNode(context)));
    if (isPositioned) return delegate.wrap(context, node, built);
    final framed = delegate.wrap(context, node, _boxed(built));
    // A column that stretches its children would ignore the width, so a
    // widget with its own width keeps exactly that size.
    if (node.number('width') > 0) {
      return Align(
        alignment: Alignment.centerLeft,
        widthFactor: 1,
        child: framed,
      );
    }
    return framed;
  }

  /// Any widget except a button can open a screen or run an action.
  Widget _tappable(Widget child) {
    if (!delegate.interactive || node.type == WidgetTypes.button) return child;
    final target = node.string('navigateTo');
    final action = node.string('action').trim();
    if (target.isEmpty && action.isEmpty) return child;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (action.isNotEmpty) delegate.onAction?.call(action, node);
          if (target.isNotEmpty) delegate.onNavigate?.call(target, node);
        },
        child: child,
      ),
    );
  }

  Widget _animated(Widget child) {
    if (!delegate.interactive) return child;
    final effect = _choice('animation', PropOptions.animations);
    if (effect == 'none') return child;
    return EntranceAnimation(
      effect: EntranceEffect.values.byName(effect),
      duration: Duration(milliseconds: node.number('animationMs', 400).round()),
      child: child,
    );
  }

  /// Applies the width, height and outer spacing every widget can have.
  Widget _boxed(Widget child) {
    var result = child;
    if (node.type != WidgetTypes.container) {
      final width = node.number('width');
      final height = WidgetCatalog.fixedHeight(node) ?? 0;
      if (width > 0 || height > 0) {
        result = SizedBox(
          width: width > 0 ? width : null,
          height: height > 0 ? height : null,
          child: result,
        );
      }
    }
    final margin = node.number('margin');
    if (margin > 0) {
      result = Padding(padding: EdgeInsets.all(margin), child: result);
    }
    return result;
  }

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

  /// Children of a free canvas or free box, each at its exact position.
  List<Widget> _positionedChildren(BuildContext context) {
    final slot =
        node.children.isEmpty ? delegate.emptySlot(context, node) : null;
    return [
      if (slot != null) Positioned.fill(child: slot),
      for (final child in node.children)
        if (child.boolean('fill'))
          Positioned.fill(
            key: ValueKey(child.id),
            child: CanvasNodeView(
              node: child,
              delegate: delegate,
              isPositioned: true,
            ),
          )
        else
          Positioned(
            key: ValueKey(child.id),
            left: child.number('x'),
            top: child.number('y'),
            width: WidgetCatalog.freeCanvasWidth(child),
            height: WidgetCatalog.fixedHeight(child),
            child: CanvasNodeView(
              node: child,
              delegate: delegate,
              isPositioned: true,
            ),
          ),
    ];
  }

  /// A box's children: at exact positions, or in a row or column like
  /// Figma's auto layout.
  Widget _boxContent(BuildContext context) {
    final layout = _choice('layout', PropOptions.boxLayout);
    if (layout == 'free') {
      return delegate.wrapLayer(
        context,
        node,
        Stack(children: _positionedChildren(context)),
      );
    }
    final main = mainAxisOf(_choice('mainAxisAlignment', PropOptions.mainAxis));
    final cross =
        crossAxisOf(_choice('crossAxisAlignment', PropOptions.rowCross));
    final spacing = node.number('spacing');
    final children = _children(context);
    if (layout == 'row') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: main,
        crossAxisAlignment: cross,
        spacing: spacing,
        children: [for (final child in children) Flexible(child: child)],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: main,
      crossAxisAlignment: cross,
      spacing: spacing,
      children: children,
    );
  }

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
      case WidgetTypes.freeCanvas:
        return FreeCanvas(
          designWidth: node.number('designWidth', 360),
          designHeight: node.number('designHeight', 320),
          color: colorOf(node.string('color')),
          borderRadius: node.number('borderRadius'),
          wrapLayer: (layer) => delegate.wrapLayer(context, node, layer),
          children: _positionedChildren(context),
        );
      case WidgetTypes.box:
        {
          final borderColor = colorOf(node.string('borderColor'));
          final borderWidth = node.number('borderWidth');
          final shadow = node.number('shadow');
          return Container(
            padding: EdgeInsets.all(node.number('padding')),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colorOf(node.string('color')),
              borderRadius: BorderRadius.circular(node.number('borderRadius')),
              border: borderColor != null && borderWidth > 0
                  ? Border.all(color: borderColor, width: borderWidth)
                  : null,
              boxShadow: shadow > 0
                  ? [
                      BoxShadow(
                        color: const Color(0x33000000),
                        blurRadius: shadow * 2,
                        offset: Offset(0, shadow / 2),
                      ),
                    ]
                  : null,
            ),
            child: _boxContent(context),
          );
        }
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
        {
          final icon = Icon(
            iconOf(_choice('icon', PropOptions.icons)),
            size: node.number('size', 24),
            color: colorOf(node.string('color')),
          );
          final badge = node.string('badge').trim();
          return badge.isEmpty
              ? icon
              : Badge(label: Text(badge), child: icon);
        }
      case WidgetTypes.customCode:
        return _CustomCodePlaceholder(code: node.string('code'));
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
    void onPressed() {
      final action = node.string('action');
      if (action.isNotEmpty) delegate.onAction?.call(action, node);
      final target = node.string('navigateTo');
      if (target.isNotEmpty) delegate.onNavigate?.call(target, node);
    }

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

/// Custom Dart code can't run inside the builder, so it shows a labeled
/// placeholder. The exported code contains the real widget.
class _CustomCodePlaceholder extends StatelessWidget {
  const _CustomCodePlaceholder({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final firstLine = code.trim().split('\n').first;
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFA78BFA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.code, size: 18, color: Color(0xFF7C3AED)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              firstLine.isEmpty ? 'Custom code' : firstLine,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Color(0xFF5B21B6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
