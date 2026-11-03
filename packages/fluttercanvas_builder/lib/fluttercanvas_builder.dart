/// A drag-and-drop UI builder for Flutter.
///
/// Drop [FlutterCanvasBuilder] into any app, design a screen visually and
/// export responsive Flutter code.
library;

export 'package:fluttercanvas_core/fluttercanvas_core.dart';
export 'package:fluttercanvas_renderer/fluttercanvas_renderer.dart';

export 'src/ai_assistant.dart'
    show AiModelPreset, AiProvider, ChatAttachment, ChatTurn, DesignAssistant;
export 'src/ai_chat.dart' show AiChatController, AiChatPanel;
export 'src/builder_controller.dart';
export 'src/device_preset.dart';
export 'src/drag_payload.dart';
export 'src/flutter_canvas_builder.dart';
