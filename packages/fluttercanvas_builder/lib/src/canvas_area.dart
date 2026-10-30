import 'package:flutter/material.dart';
import 'package:fluttercanvas_renderer/fluttercanvas_renderer.dart';

import 'builder_controller.dart';
import 'device_frame.dart';
import 'node_frame.dart';

/// The center of the builder: the design inside a scaled device frame.
class CanvasArea extends StatelessWidget {
  const CanvasArea({super.key, required this.controller});

  final BuilderController controller;

  // The preview uses Flutter's default theme so it matches what the exported
  // code looks like in a fresh app.
  static final ThemeData _previewTheme = ThemeData();

  @override
  Widget build(BuildContext context) {
    final device = controller.device;
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: DeviceFrame(
              device: device,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: Size(device.width, device.height),
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                  viewInsets: EdgeInsets.zero,
                ),
                child: Theme(
                  data: _previewTheme,
                  child: CanvasView(
                    document: controller.document,
                    delegate: EditorRenderDelegate(controller),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
