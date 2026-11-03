import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ai_assistant.dart';
import 'builder_controller.dart';

/// One bubble in the chat.
class ChatMessage {
  ChatMessage({
    required this.fromUser,
    required this.text,
    this.attachments = const [],
    this.changedDesign = false,
    this.isError = false,
  });

  final bool fromUser;
  final String text;
  final List<ChatAttachment> attachments;

  /// Whether this reply changed the design, so the bubble can offer undo.
  final bool changedDesign;
  final bool isError;
}

/// The conversation with the design agent. It lives outside the panel so
/// the chat survives switching tabs.
class AiChatController extends ChangeNotifier {
  AiChatController(this.builder);

  final BuilderController builder;

  /// API keys by name (gemini, groq, openrouter, openai). Kept in memory for
  /// this session only.
  static final Map<String, String> keys = {};

  final List<ChatMessage> messages = [];
  final List<ChatAttachment> pending = [];
  AiModelPreset preset = AiModelPreset.all.first;
  bool busy = false;

  void choose(AiModelPreset value) {
    preset = value;
    notifyListeners();
  }

  void attach(ChatAttachment file) {
    pending.add(file);
    notifyListeners();
  }

  void removeAttachment(ChatAttachment file) {
    pending.remove(file);
    notifyListeners();
  }

  void clear() {
    messages.clear();
    pending.clear();
    notifyListeners();
  }

  bool get hasKey => (keys[preset.keyName] ?? '').isNotEmpty;

  Future<void> send(String text) async {
    final request = text.trim();
    if (request.isEmpty || busy) return;
    final files = List<ChatAttachment>.of(pending);
    pending.clear();
    final history = [
      for (final m in messages.where((m) => !m.isError))
        ChatTurn(fromUser: m.fromUser, text: m.text),
    ];
    messages.add(ChatMessage(fromUser: true, text: request, attachments: files));
    busy = true;
    notifyListeners();

    try {
      final assistant = DesignAssistant(
        provider: preset.provider,
        apiKey: keys[preset.keyName] ?? '',
        model: preset.model,
        baseUrl: preset.baseUrl,
      );
      final reply = await assistant.chat(
        history: history,
        request: request,
        current: builder.project,
        currentScreenId: builder.document.id,
        selectedWidgetId: builder.selectedId,
        attachments: files,
      );
      final project = reply.project;
      if (project != null) builder.applyProject(project);
      messages.add(ChatMessage(
        fromUser: false,
        text: reply.message,
        changedDesign: project != null,
      ));
    } catch (error) {
      messages.add(ChatMessage(
        fromUser: false,
        text: _friendly(error),
        isError: true,
      ));
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  String _friendly(Object error) {
    final text = '$error';
    if (text.contains('Failed to fetch') || text.contains('XMLHttpRequest')) {
      return 'Could not reach ${preset.label}. Check your internet '
          'connection and API key in settings.';
    }
    return text.replaceFirst('Exception: ', '');
  }
}

/// A chat panel like the agent panel in Antigravity: pick a model, talk to
/// the agent, attach images or PDFs, paste links, and watch the design
/// change on the screen you're looking at.
class AiChatPanel extends StatefulWidget {
  const AiChatPanel({super.key, required this.chat});

  final AiChatController chat;

  @override
  State<AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<AiChatPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  AiChatController get chat => widget.chat;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!chat.hasKey) {
      await showAiSettings(context);
      if (!chat.hasKey) return;
    }
    final text = _input.text;
    _input.clear();
    _scrollToEnd();
    await chat.send(text);
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _attach() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'pdf'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null) continue;
      final ext = (file.extension ?? '').toLowerCase();
      final mime = switch (ext) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      chat.attach(ChatAttachment(name: file.name, mimeType: mime, bytes: bytes));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListenableBuilder(
      listenable: chat,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(chat: chat),
          const Divider(height: 1),
          Expanded(
            child: chat.messages.isEmpty
                ? _EmptyState(onPick: (text) {
                    _input.text = text;
                    _send();
                  })
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    itemCount: chat.messages.length + (chat.busy ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chat.messages.length) {
                        return const _Thinking();
                      }
                      return _Bubble(
                        message: chat.messages[index],
                        onUndo: chat.builder.undo,
                      );
                    },
                  ),
          ),
          if (chat.pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final file in chat.pending)
                    InputChip(
                      avatar: Icon(
                        file.isImage
                            ? Icons.image_outlined
                            : Icons.picture_as_pdf_outlined,
                        size: 16,
                      ),
                      label: Text(file.name, overflow: TextOverflow.ellipsis),
                      onDeleted: () => chat.removeAttachment(file),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              padding: const EdgeInsets.fromLTRB(12, 4, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.enter): _send,
                    },
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 6,
                      enabled: !chat.busy,
                      decoration: const InputDecoration(
                        hintText: 'Ask the agent to design or change anything…',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Attach images or PDFs',
                        icon: const Icon(Icons.attach_file),
                        onPressed: chat.busy ? null : _attach,
                      ),
                      Expanded(
                        child: Text(
                          'Enter to send · Shift+Enter for a new line',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'Send',
                        onPressed: chat.busy ? null : _send,
                        icon: const Icon(Icons.arrow_upward),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.chat});

  final AiChatController chat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: PopupMenuButton<AiModelPreset>(
              tooltip: 'Choose a model',
              initialValue: chat.preset,
              onSelected: chat.choose,
              itemBuilder: (context) => [
                for (final preset in AiModelPreset.all)
                  PopupMenuItem(
                    value: preset,
                    child: Row(
                      children: [
                        Expanded(child: Text(preset.label)),
                        if (preset.free)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Text('free tier',
                                style: TextStyle(fontSize: 11)),
                          ),
                      ],
                    ),
                  ),
              ],
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      chat.preset.label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const Icon(Icons.expand_more, size: 18),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(Icons.add_comment_outlined, size: 20),
            onPressed: chat.clear,
          ),
          IconButton(
            tooltip: 'API keys',
            icon: const Icon(Icons.key_outlined, size: 20),
            onPressed: () => showAiSettings(context),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPick});

  final ValueChanged<String> onPick;

  static const _ideas = [
    'Add a login screen with email, password and a big blue button',
    'Make this screen dark with white text',
    'When I tap a product, open a details screen with a big photo, '
        'price and an Add to cart button, all animated',
    'Add a profile row with a round photo, my name and a badge',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Icon(Icons.auto_awesome, size: 36, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          'Design with the agent',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Tell it what to build on this screen. Attach screenshots or PDFs, '
          'or paste links. Every change can be undone.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        for (final idea in _ideas)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(12),
              ),
              onPressed: () => onPick(idea),
              child: Text(idea),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.onUndo});

  final ChatMessage message;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = message.fromUser;
    final color = message.isError
        ? scheme.errorContainer
        : user
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest;
    final textColor = message.isError
        ? scheme.onErrorContainer
        : user
            ? scheme.onPrimaryContainer
            : scheme.onSurface;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
      ),
      child: Align(
        alignment: user ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(user ? 16 : 4),
                bottomRight: Radius.circular(user ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.attachments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final file in message.attachments)
                          file.isImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    file.bytes,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Chip(
                                  avatar: const Icon(
                                      Icons.picture_as_pdf_outlined,
                                      size: 16),
                                  label: Text(file.name),
                                ),
                      ],
                    ),
                  ),
                SelectableText(message.text, style: TextStyle(color: textColor)),
                if (message.changedDesign) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 16, color: scheme.primary),
                      const SizedBox(width: 6),
                      Text('Design updated', style: theme.textTheme.labelMedium),
                      const SizedBox(width: 8),
                      TextButton(onPressed: onUndo, child: const Text('Undo')),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thinking extends StatefulWidget {
  const _Thinking();

  @override
  State<_Thinking> createState() => _ThinkingState();
}

class _ThinkingState extends State<_Thinking>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(
                      alpha: 0.3 +
                          0.7 *
                              (1 - ((_pulse.value * 3 - i) % 3).clamp(0.0, 1.0).toDouble()),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                'Designing…',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where to paste API keys. Each service has its own key.
Future<void> showAiSettings(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const _KeysDialog(),
  );
}

class _KeysDialog extends StatefulWidget {
  const _KeysDialog();

  @override
  State<_KeysDialog> createState() => _KeysDialogState();
}

class _KeysDialogState extends State<_KeysDialog> {
  static const _services = [
    ('gemini', 'Google Gemini', 'aistudio.google.com → Get API key'),
    ('groq', 'Groq', 'console.groq.com → API Keys'),
    ('openrouter', 'OpenRouter', 'openrouter.ai → Keys'),
    ('openai', 'OpenAI (paid)', 'platform.openai.com → API keys'),
  ];

  late final _fields = {
    for (final (name, _, _) in _services)
      name: TextEditingController(text: AiChatController.keys[name] ?? ''),
  };

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  void _save() {
    for (final entry in _fields.entries) {
      AiChatController.keys[entry.key] = entry.value.text.trim();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('API keys'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Paste a key for the service you want to use. Keys stay in '
                'this browser session only.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              for (final (name, label, hint) in _services) ...[
                TextField(
                  controller: _fields[name],
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: label,
                    helperText: 'Get one at $hint',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
