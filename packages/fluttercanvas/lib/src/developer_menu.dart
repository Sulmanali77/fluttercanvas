import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ai_assistant.dart';
import 'builder_controller.dart';
import 'dialogs.dart';

/// Everything for developers in one place: code, design JSON, the CLI and
/// the AI assistant.
Future<void> showDeveloperMenu(
  BuildContext context,
  BuilderController controller,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      void open(Future<void> Function() action) {
        Navigator.of(dialogContext).pop();
        action();
      }

      const command =
          'dart run fluttercanvas_core:fluttercanvas export design.json .';
      return SimpleDialog(
        title: const Text('Developer menu'),
        children: [
          _MenuItem(
            icon: Icons.code,
            title: 'View code',
            subtitle: 'Every file of your app, ready to copy',
            onTap: () =>
                open(() => showExportDialog(context, controller.exportCode())),
          ),
          _MenuItem(
            icon: Icons.copy_all_outlined,
            title: 'Copy all code',
            subtitle: 'All files in one go, with file names',
            onTap: () => open(() async {
              final text = [
                for (final file in controller.exportCode())
                  '// ===== ${file.path} =====\n${file.content}',
              ].join('\n');
              await Clipboard.setData(ClipboardData(text: text));
            }),
          ),
          _MenuItem(
            icon: Icons.data_object,
            title: 'Design JSON',
            subtitle: 'Save, share or load a design',
            onTap: () => open(() => showJsonDialog(context, controller)),
          ),
          _MenuItem(
            icon: Icons.auto_awesome,
            title: 'AI assistant',
            subtitle: 'Describe a screen and let AI build it',
            onTap: () => open(() => showAiAssistant(context, controller)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: Text('Command line'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 16, 12),
            child: Row(
              children: [
                const Expanded(
                  child: SelectableText(
                    command,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
                CopyButton(text: command),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
