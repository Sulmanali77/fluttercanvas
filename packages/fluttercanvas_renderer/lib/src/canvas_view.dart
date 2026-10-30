import 'package:flutter/material.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

import 'node_view.dart';
import 'render_delegate.dart';
import 'style_mapping.dart';

/// Renders a whole [CanvasDocument] as a responsive screen.
///
/// ```dart
/// CanvasView.fromJson(
///   jsonFromServer,
///   delegate: CanvasRenderDelegate(
///     onAction: (action, node) => print('Pressed $action'),
///   ),
/// )
/// ```
class CanvasView extends StatelessWidget {
  const CanvasView({
    super.key,
    required this.document,
    this.delegate = const CanvasRenderDelegate(),
    this.includeScaffold = true,
  });

  /// Parses [json] and renders it. Throws a [FormatException] for invalid
  /// JSON.
  factory CanvasView.fromJson(
    String json, {
    Key? key,
    CanvasRenderDelegate delegate = const CanvasRenderDelegate(),
    bool includeScaffold = true,
  }) {
    return CanvasView(
      key: key,
      document: CanvasDocument.fromJsonString(json),
      delegate: delegate,
      includeScaffold: includeScaffold,
    );
  }

  final CanvasDocument document;
  final CanvasRenderDelegate delegate;

  /// When false, only the scrollable page body is built, so you can embed a
  /// design inside your own screen.
  final bool includeScaffold;

  @override
  Widget build(BuildContext context) {
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < Breakpoints.tablet;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Breakpoints.maxContentWidth,
              ),
              child: SizedBox(
                width: double.infinity,
                child: CanvasNodeView(node: document.root, delegate: delegate),
              ),
            ),
          ),
        );
      },
    );
    if (!includeScaffold) return body;
    return Scaffold(
      backgroundColor: colorOf(document.backgroundColor),
      appBar: document.showAppBar ? AppBar(title: Text(document.title)) : null,
      body: body,
    );
  }
}
