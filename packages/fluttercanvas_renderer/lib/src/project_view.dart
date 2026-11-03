import 'package:flutter/material.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

import 'canvas_view.dart';
import 'render_delegate.dart';

/// Runs a whole multi-screen design. Linked buttons open their screens and
/// "go back" buttons return, using a regular Flutter [Navigator].
///
/// ```dart
/// MaterialApp(
///   home: CanvasProjectView(
///     project: CanvasProject.fromJsonString(jsonFromServer),
///     onAction: (action, node) => handle(action),
///   ),
/// );
/// ```
class CanvasProjectView extends StatelessWidget {
  const CanvasProjectView({super.key, required this.project, this.onAction});

  final CanvasProject project;
  final CanvasActionCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        final name = settings.name ?? '/';
        final screen = name == '/'
            ? project.initialScreen
            : project.screenById(name) ?? project.initialScreen;
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => CanvasView(
            document: screen,
            bottomNav: CanvasBottomNav.forScreen(project, screen),
            onNavSelected: (target) {
              if (target != screen.id) {
                Navigator.of(context).pushReplacementNamed(target);
              }
            },
            delegate: CanvasRenderDelegate(
              onAction: onAction,
              onNavigate: (target, node) {
                if (target == 'back') {
                  Navigator.of(context).maybePop();
                } else if (project.screenById(target) != null) {
                  Navigator.of(context).pushNamed(target);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
