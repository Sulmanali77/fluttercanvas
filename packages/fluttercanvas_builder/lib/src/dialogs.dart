import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'builder_controller.dart';

/// Shows generated code with a copy button.
Future<void> showCodeDialog(
  BuildContext context, {
  required String title,
  required String code,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _CodeDialog(title: title, code: code),
  );
}

/// Shows the design JSON, with tabs to copy it or load another design.
Future<void> showJsonDialog(BuildContext context, BuilderController controller) {
  return showDialog<void>(
    context: context,
    builder: (_) => _JsonDialog(controller: controller),
  );
}

class _CodeDialog extends StatelessWidget {
  const _CodeDialog({required this.title, required this.code});

  final String title;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 760,
        height: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DialogHeader(title: title, actions: [CopyButton(text: code)]),
            const Divider(height: 1),
            Expanded(child: CodeView(code: code)),
          ],
        ),
      ),
    );
  }
}

class _JsonDialog extends StatefulWidget {
  const _JsonDialog({required this.controller});

  final BuilderController controller;

  @override
  State<_JsonDialog> createState() => _JsonDialogState();
}

class _JsonDialogState extends State<_JsonDialog> {
  final _input = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _load() {
    try {
      widget.controller.loadJson(_input.text);
      Navigator.of(context).pop();
    } catch (error) {
      setState(() => _error = 'This is not a FlutterCanvas design: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final json = widget.controller.exportJson();
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 760,
        height: 640,
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DialogHeader(
                title: 'Design JSON',
                actions: [CopyButton(text: json)],
              ),
              const TabBar(tabs: [Tab(text: 'Export'), Tab(text: 'Import')]),
              Expanded(
                child: TabBarView(
                  children: [
                    CodeView(code: json),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _input,
                              expands: true,
                              maxLines: null,
                              minLines: null,
                              textAlignVertical: TextAlignVertical.top,
                              style: CodeView.textStyle,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                hintText: 'Paste design JSON here',
                                errorText: _error,
                                errorMaxLines: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.file_upload_outlined),
                              label: const Text('Load design'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...actions,
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Scrollable, selectable monospace code.
class CodeView extends StatelessWidget {
  const CodeView({super.key, required this.code});

  final String code;

  static const textStyle = TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: ['Menlo', 'Consolas', 'Courier New'],
    fontSize: 13,
    height: 1.45,
  );

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(code, style: textStyle),
      ),
    );
  }
}

/// Copies [text] to the clipboard and confirms it.
class CopyButton extends StatefulWidget {
  const CopyButton({super.key, required this.text});

  final String text;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _copy,
      icon: Icon(_copied ? Icons.check : Icons.copy),
      label: Text(_copied ? 'Copied' : 'Copy'),
    );
  }
}
