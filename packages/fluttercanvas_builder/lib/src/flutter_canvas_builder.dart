import 'package:flutter/material.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

import 'builder_controller.dart';
import 'canvas_area.dart';
import 'device_preset.dart';
import 'dialogs.dart';
import 'palette.dart';
import 'properties_panel.dart';

/// The complete drag-and-drop builder.
///
/// On wide screens the palette, canvas and properties sit side by side. On
/// phones the palette and properties move into drawers.
///
/// ```dart
/// MaterialApp(
///   home: FlutterCanvasBuilder(
///     onExport: (code) => debugPrint(code),
///   ),
/// );
/// ```
class FlutterCanvasBuilder extends StatefulWidget {
  const FlutterCanvasBuilder({
    super.key,
    this.controller,
    this.title = 'FlutterCanvas',
    this.onExport,
  });

  /// Optional controller to load, observe or save the design. One is created
  /// automatically when omitted.
  final BuilderController? controller;

  /// Text in the builder's app bar.
  final String title;

  /// Called with the generated code each time the user exports.
  final ValueChanged<String>? onExport;

  @override
  State<FlutterCanvasBuilder> createState() => _FlutterCanvasBuilderState();
}

class _FlutterCanvasBuilderState extends State<FlutterCanvasBuilder> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  BuilderController? _ownedController;

  BuilderController get _controller =>
      widget.controller ?? (_ownedController ??= BuilderController());

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  void _closeDrawer() => _scaffoldKey.currentState?.closeDrawer();

  void _exportCode(BuildContext context) {
    final code = _controller.exportCode();
    widget.onExport?.call(code);
    showCodeDialog(
      context,
      title: FlutterCodeGenerator.fileName(_controller.document.name),
      code: code,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1000;
          final palette = WidgetPalette(
            controller: controller,
            touchMode: !wide,
            onDragStarted: wide ? null : _closeDrawer,
            onAdded: wide ? null : _closeDrawer,
          );
          final properties = PropertiesPanel(controller: controller);

          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text(widget.title),
              actions: [
                IconButton(
                  tooltip: 'Undo',
                  icon: const Icon(Icons.undo),
                  onPressed: controller.canUndo ? controller.undo : null,
                ),
                IconButton(
                  tooltip: 'Redo',
                  icon: const Icon(Icons.redo),
                  onPressed: controller.canRedo ? controller.redo : null,
                ),
                _DevicePicker(controller: controller),
                IconButton(
                  tooltip: 'Design JSON',
                  icon: const Icon(Icons.data_object),
                  onPressed: () => showJsonDialog(context, controller),
                ),
                if (wide)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: FilledButton.icon(
                      onPressed: () => _exportCode(context),
                      icon: const Icon(Icons.code),
                      label: const Text('Export code'),
                    ),
                  )
                else
                  IconButton(
                    tooltip: 'Export code',
                    icon: const Icon(Icons.code),
                    onPressed: () => _exportCode(context),
                  ),
                if (!wide)
                  IconButton(
                    tooltip: 'Properties',
                    icon: const Icon(Icons.tune),
                    onPressed: () =>
                        _scaffoldKey.currentState?.openEndDrawer(),
                  ),
              ],
            ),
            drawer: wide ? null : Drawer(child: SafeArea(child: palette)),
            endDrawer: wide
                ? null
                : Drawer(width: 340, child: SafeArea(child: properties)),
            body: wide
                ? Row(
                    children: [
                      SizedBox(width: 260, child: palette),
                      const VerticalDivider(width: 1),
                      Expanded(child: CanvasArea(controller: controller)),
                      const VerticalDivider(width: 1),
                      SizedBox(width: 320, child: properties),
                    ],
                  )
                : CanvasArea(controller: controller),
          );
        },
      ),
    );
  }
}

class _DevicePicker extends StatelessWidget {
  const _DevicePicker({required this.controller});

  final BuilderController controller;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DevicePreset>(
      tooltip: 'Preview device',
      icon: Icon(controller.device.icon),
      initialValue: controller.device,
      onSelected: (device) => controller.device = device,
      itemBuilder: (context) => [
        for (final device in DevicePreset.values)
          PopupMenuItem(
            value: device,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(device.icon),
              title: Text(device.label),
              subtitle: Text(
                '${device.width.toInt()} × ${device.height.toInt()}',
              ),
            ),
          ),
      ],
    );
  }
}
