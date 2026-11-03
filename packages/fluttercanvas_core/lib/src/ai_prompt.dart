import 'dart:convert';

import 'canvas_document.dart';
import 'canvas_project.dart';
import 'widget_catalog.dart';

/// Builds prompts that let an AI model create or change a FlutterCanvas
/// design, and reads its reply back.
abstract final class DesignPrompt {
  /// A description of the design format, generated from [WidgetCatalog], so
  /// it always matches the widgets this version supports.
  static String formatGuide() {
    final buffer = StringBuffer()
      ..writeln('A FlutterCanvas project is JSON:')
      ..writeln('{"schemaVersion": 2, "name": "App name", "initialScreen": '
          '"<screen id>", "screens": [<screen>, ...]}')
      ..writeln('A screen is: {"id": "unique", "name": "Home", "title": '
          '"App bar title", "showAppBar": true, "backgroundColor": '
          '"#AARRGGBB", "bars": {<app bar and bottom navigation settings>}, '
          '"root": <widget>}')
      ..writeln('A widget is: {"id": "unique", "type": "<type>", "name": '
          '"optional layer name", "props": {...}, "children": [...]}')
      ..writeln()
      ..writeln('Colors are "#AARRGGBB" strings, or "" for none. Numbers are '
          'logical pixels.')
      ..writeln('Every widget also accepts: width, height (0 = automatic), '
          'margin, navigateTo ("" | "back" | a screen id), action (text id), '
          'animation (${PropOptions.animations.join(' | ')}), animationMs.')
      ..writeln('Children of a freeCanvas, or of a box whose layout is '
          '"free", use x and y (from the top left), and may set fill: true '
          'to cover the whole box.')
      ..writeln('Screen "bars" keys: ${[
        BarKeys.appBarColor,
        BarKeys.appBarForeground,
        BarKeys.centerTitle,
        BarKeys.leadingIcon,
        BarKeys.leadingLink,
        BarKeys.action1Icon,
        BarKeys.action1Link,
        BarKeys.action1Badge,
        BarKeys.action2Icon,
        BarKeys.action2Link,
        BarKeys.navIcon,
        BarKeys.navLabel,
      ].join(', ')}. Screens with a navIcon share a bottom navigation bar.')
      ..writeln()
      ..writeln('Widget types:');
    for (final spec in WidgetCatalog.all) {
      final props = [
        for (final prop in spec.props)
          prop.options.isEmpty
              ? '${prop.key} (${prop.kind.name})'
              : '${prop.key} (${prop.options.where((o) => o.isNotEmpty).join('|')})',
      ];
      final children = switch (spec.childMode) {
        ChildMode.none => 'no children',
        ChildMode.single => 'one child',
        ChildMode.multiple => 'many children',
      };
      buffer.writeln('- ${spec.type}: ${spec.description} $children. '
          'Props: ${props.join(', ')}.');
    }
    return buffer.toString();
  }

  /// The full prompt for creating or changing [current] as [request] asks.
  static String build({
    required String request,
    required CanvasProject current,
  }) {
    return '''
You are the design assistant inside FlutterCanvas, a visual Flutter app
builder. Change the project below so it does what the user asks. Keep the
parts the user did not mention. Use realistic content, pleasant spacing and
colors, and picsum.photos image URLs.

${formatGuide()}
Current project:
${current.toJsonString()}

User request:
$request

Reply with only the complete updated project JSON. No explanations, no
Markdown fences.
''';
  }

  /// The prompt for one chat turn. The model answers with a short message
  /// and, when the user asked for a change, the updated project.
  static String buildChat({
    required String request,
    required CanvasProject current,
    required String currentScreenId,
    String? selectedWidgetId,
  }) {
    final screen = current.screenById(currentScreenId);
    return '''
You are the design agent inside FlutterCanvas, a visual Flutter app builder
like FlutterFlow. Follow the user's instructions completely. You can change
any screen, add screens, link them, and add animations. When the user
attaches images or PDFs, use them as the reference for layout, colors and
content. When they share links, use what the pages contain.

The user is looking at the screen "${screen?.name ?? ''}" (id $currentScreenId).
Apply changes there unless they name another screen.
${selectedWidgetId == null ? '' : 'The selected widget has id $selectedWidgetId.\n'}
Keep everything the user did not ask to change. Use realistic content,
pleasant spacing, colors that match, and picsum.photos image URLs.

${formatGuide()}
Current project:
${current.toJsonString()}

User message:
$request

Reply with only one JSON object, no Markdown fences:
{"message": "One or two friendly sentences in the user's language about what you did",
 "project": <the complete updated project, or null if nothing should change>}
''';
  }

  /// Reads a chat reply: the message to show and, if the model changed the
  /// design, the new project. Plain-text replies become just a message.
  static ChatReply parseChatReply(String reply) {
    final start = reply.indexOf('{');
    final end = reply.lastIndexOf('}');
    if (start < 0 || end <= start) return ChatReply(reply.trim(), null);
    try {
      final decoded = jsonDecode(reply.substring(start, end + 1));
      if (decoded is! Map) return ChatReply(reply.trim(), null);
      final json = decoded.map((k, v) => MapEntry(k.toString(), v));
      if (json.containsKey('screens')) {
        return ChatReply('Done. I updated the design.',
            CanvasProject.fromJson(json));
      }
      final message = json['message'];
      final project = json['project'];
      return ChatReply(
        message is String && message.isNotEmpty
            ? message
            : 'Done. I updated the design.',
        project is Map
            ? CanvasProject.fromJson(
                project.map((k, v) => MapEntry(k.toString(), v)))
            : null,
      );
    } on FormatException {
      return ChatReply(reply.trim(), null);
    }
  }

  /// Reads a project from an AI reply, ignoring any text or code fences
  /// around the JSON. Throws a [FormatException] if there is no valid
  /// project in it.
  static CanvasProject parseReply(String reply) {
    final start = reply.indexOf('{');
    final end = reply.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('The reply did not contain a design.');
    }
    return CanvasProject.fromJsonString(reply.substring(start, end + 1));
  }
}

/// What the AI said, and the updated design if it made changes.
class ChatReply {
  const ChatReply(this.message, this.project);

  final String message;
  final CanvasProject? project;
}
