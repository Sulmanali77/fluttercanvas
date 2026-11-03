import 'package:flutter/material.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';

import 'ai_chat.dart';
import 'builder_controller.dart';
import 'canvas_area.dart';
import 'device_preset.dart';
import 'developer_menu.dart';
import 'dialogs.dart';
import 'layers_panel.dart';
import 'palette.dart';
import 'properties_panel.dart';
import 'screens_panel.dart';

/// The complete drag-and-drop builder.
///
/// On wide screens the screens list and palette, the canvas and the
/// properties sit side by side. On phones the side panels move into drawers.
///
/// ```dart
/// MaterialApp(
///   home: FlutterCanvasBuilder(
///     onExport: (files) => debugPrint('Exported ${files.length} files'),
///   ),
/// );
/// ```
class FlutterCanvasBuilder extends StatefulWidget {
  const FlutterCanvasBuilder({
    super.key,
    this.controller,
    this.title = 'FlutterCanvas',
    this.onExport,
    this.seedColor = const Color(0xFF4F46E5),
    this.initialThemeMode = ThemeMode.system,
  });

  /// Optional controller to load, observe or save the design. One is created
  /// automatically when omitted.
  final BuilderController? controller;

  /// Text in the builder's app bar.
  final String title;

  /// Called with the generated files each time the user exports.
  final ValueChanged<List<GeneratedFile>>? onExport;

  /// Main color of the builder's own interface.
  final Color seedColor;

  /// Light, dark, or follow the system. The user can change it from the
  /// toolbar.
  final ThemeMode initialThemeMode;

  @override
  State<FlutterCanvasBuilder> createState() => _FlutterCanvasBuilderState();
}

class _FlutterCanvasBuilderState extends State<FlutterCanvasBuilder> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  BuilderController? _ownedController;
  late ThemeMode _themeMode = widget.initialThemeMode;
  AiChatController? _chatController;

  AiChatController get _chat =>
      _chatController ??= AiChatController(_controller);

  BuilderController get _controller =>
      widget.controller ?? (_ownedController ??= BuilderController());

  @override
  void dispose() {
    _chatController?.dispose();
    _ownedController?.dispose();
    super.dispose();
  }

  void _closeDrawer() => _scaffoldKey.currentState?.closeDrawer();

  void _exportCode(BuildContext context) {
    final files = _controller.exportCode();
    widget.onExport?.call(files);
    showExportDialog(context, files);
  }

  ThemeData _theme(BuildContext context) {
    final brightness = switch (_themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };
    return ThemeData(
      colorSchemeSeed: widget.seedColor,
      brightness: brightness,
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Theme(
      data: _theme(context),
      child: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1000;
          final leftPanel = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreensPanel(
                controller: controller,
                onSelected: wide ? null : _closeDrawer,
              ),
              const Divider(height: 1),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [Tab(text: 'Insert'), Tab(text: 'Layers')],
                      ),
                      Expanded(
                        child: TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            WidgetPalette(
                              controller: controller,
                              touchMode: !wide,
                              onDragStarted: wide ? null : _closeDrawer,
                              onAdded: wide ? null : _closeDrawer,
                            ),
                            LayersPanel(controller: controller),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
          // Design properties and the AI agent share the right side, like
          // the agent panel in Antigravity.
          final properties = DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Design'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 16),
                          SizedBox(width: 6),
                          Text('AI agent'),
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      PropertiesPanel(controller: controller),
                      AiChatPanel(chat: _chat),
                    ],
                  ),
                ),
              ],
            ),
          );

          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              titleSpacing: 16,
              title: _Brand(
                title: widget.title,
                screenName: wide ? controller.document.name : null,
                compact: !wide,
              ),
              actions: [
                IconButton(
                  tooltip: 'Undo',
                  icon: const Icon(Icons.undo),
                  onPressed: controller.canUndo ? controller.undo : null,
                ),
                if (wide)
                  IconButton(
                    tooltip: 'Redo',
                    icon: const Icon(Icons.redo),
                    onPressed: controller.canRedo ? controller.redo : null,
                  ),
                _TemplatePicker(controller: controller),
                _DevicePicker(controller: controller),
                _ThemePicker(
                  mode: _themeMode,
                  onChanged: (mode) => setState(() => _themeMode = mode),
                ),
                IconButton(
                  tooltip: controller.isPreviewing
                      ? 'Back to editing'
                      : 'Preview (tap buttons to move between screens)',
                  isSelected: controller.isPreviewing,
                  icon: const Icon(Icons.play_arrow_outlined),
                  selectedIcon: const Icon(Icons.edit_outlined),
                  onPressed: controller.togglePreview,
                ),
                IconButton(
                  tooltip: 'Developer menu: code, JSON, CLI and AI',
                  icon: const Icon(Icons.terminal),
                  onPressed: () => showDeveloperMenu(context, controller),
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
                if (!wide) ...[
                  IconButton(
                    tooltip: 'Properties',
                    icon: const Icon(Icons.tune),
                    onPressed: () =>
                        _scaffoldKey.currentState?.openEndDrawer(),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'More',
                    onSelected: (value) {
                      if (value == 'redo') controller.redo();
                      if (value == 'json') showJsonDialog(context, controller);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'redo',
                        enabled: controller.canRedo,
                        child: const Text('Redo'),
                      ),
                      const PopupMenuItem(
                        value: 'json',
                        child: Text('Design JSON'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            drawer: wide ? null : Drawer(child: SafeArea(child: leftPanel)),
            endDrawer: wide
                ? null
                : Drawer(width: 380, child: SafeArea(child: properties)),
            body: wide
                ? Row(
                    children: [
                      SizedBox(width: 270, child: leftPanel),
                      const VerticalDivider(width: 1),
                      Expanded(child: CanvasArea(controller: controller)),
                      const VerticalDivider(width: 1),
                      SizedBox(width: 380, child: properties),
                    ],
                  )
                : CanvasArea(controller: controller),
          );
        },
      ),
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

class _Brand extends StatelessWidget {
  const _Brand({required this.title, this.screenName, this.compact = false});

  final String title;
  final String? screenName;

  /// Shows only the logo, for narrow screens.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.tertiary],
            ),
          ),
          child: Icon(Icons.auto_awesome_mosaic, size: 18, color: scheme.onPrimary),
        ),
        if (!compact) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (screenName != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '/',
              style: TextStyle(color: scheme.outline, fontSize: 18),
            ),
          ),
          Flexible(
            child: Text(
              screenName!,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  static const _icons = {
    ThemeMode.system: Icons.brightness_auto_outlined,
    ThemeMode.light: Icons.light_mode_outlined,
    ThemeMode.dark: Icons.dark_mode_outlined,
  };

  static const _labels = {
    ThemeMode.system: 'System',
    ThemeMode.light: 'Light',
    ThemeMode.dark: 'Dark',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Theme',
      icon: Icon(_icons[mode]),
      initialValue: mode,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final option in ThemeMode.values)
          CheckedPopupMenuItem(
            value: option,
            checked: option == mode,
            child: Row(
              children: [
                Icon(_icons[option], size: 18),
                const SizedBox(width: 10),
                Text(_labels[option]!),
              ],
            ),
          ),
      ],
    );
  }
}

class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker({required this.controller});

  final BuilderController controller;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CanvasProject Function()>(
      tooltip: 'Templates',
      icon: const Icon(Icons.dashboard_customize_outlined),
      onSelected: (make) => controller.loadProject(make()),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: CanvasTemplates.ecommerce,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.storefront_outlined),
            title: Text('E-commerce app'),
            subtitle: Text('Shop, product, cart and profile, animated'),
          ),
        ),
        PopupMenuItem(
          value: CanvasTemplates.starter,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.auto_awesome_outlined),
            title: Text('Starter'),
            subtitle: Text('Two linked screens'),
          ),
        ),
        PopupMenuItem(
          value: CanvasTemplates.blank,
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.crop_free),
            title: Text('Blank free-form'),
            subtitle: Text('An empty screen to draw on'),
          ),
        ),
      ],
    );
  }
}
