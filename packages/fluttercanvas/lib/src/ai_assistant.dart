import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttercanvas_core/fluttercanvas_core.dart';
import 'package:http/http.dart' as http;

import 'builder_controller.dart';

/// Which kind of AI service to call.
enum AiProvider {
  /// Google's Gemini API, which has a free tier.
  gemini('Google Gemini (free tier)', 'gemini-2.5-flash', ''),

  /// Any service with an OpenAI-style chat API, such as Groq or OpenRouter.
  openAiCompatible(
    'OpenAI-compatible (Groq, OpenRouter...)',
    'llama-3.3-70b-versatile',
    'https://api.groq.com/openai/v1',
  );

  const AiProvider(this.label, this.defaultModel, this.defaultBaseUrl);

  final String label;
  final String defaultModel;
  final String defaultBaseUrl;
}

/// A ready-made model choice for the chat panel.
class AiModelPreset {
  const AiModelPreset({
    required this.label,
    required this.provider,
    required this.model,
    required this.keyName,
    this.baseUrl = '',
    this.free = false,
    this.vision = true,
  });

  final String label;
  final AiProvider provider;
  final String model;

  /// Which saved key this preset uses: gemini, groq, openrouter or openai.
  final String keyName;
  final String baseUrl;
  final bool free;

  /// Whether the model can look at images.
  final bool vision;

  static const all = [
    AiModelPreset(
      label: 'Gemini 2.5 Flash',
      provider: AiProvider.gemini,
      model: 'gemini-2.5-flash',
      keyName: 'gemini',
      free: true,
    ),
    AiModelPreset(
      label: 'Gemini 2.5 Flash-Lite',
      provider: AiProvider.gemini,
      model: 'gemini-2.5-flash-lite',
      keyName: 'gemini',
      free: true,
    ),
    AiModelPreset(
      label: 'Groq · Llama 3.3 70B',
      provider: AiProvider.openAiCompatible,
      model: 'llama-3.3-70b-versatile',
      keyName: 'groq',
      baseUrl: 'https://api.groq.com/openai/v1',
      free: true,
      vision: false,
    ),
    AiModelPreset(
      label: 'OpenRouter · free model',
      provider: AiProvider.openAiCompatible,
      model: 'meta-llama/llama-3.3-70b-instruct:free',
      keyName: 'openrouter',
      baseUrl: 'https://openrouter.ai/api/v1',
      free: true,
      vision: false,
    ),
    AiModelPreset(
      label: 'OpenAI · GPT-4o mini',
      provider: AiProvider.openAiCompatible,
      model: 'gpt-4o-mini',
      keyName: 'openai',
      baseUrl: 'https://api.openai.com/v1',
    ),
  ];
}

/// A file attached to a chat message: an image or a PDF.
class ChatAttachment {
  const ChatAttachment({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;

  bool get isImage => mimeType.startsWith('image/');
}

/// One earlier message in the conversation.
class ChatTurn {
  const ChatTurn({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;
}

/// Sends a design request to an AI model and returns the updated project.
///
/// Keys are only kept in memory. Don't ship an app with your key inside it.
class DesignAssistant {
  DesignAssistant({
    required this.provider,
    required this.apiKey,
    required this.model,
    this.baseUrl = '',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final AiProvider provider;
  final String apiKey;
  final String model;
  final String baseUrl;
  final http.Client _client;

  Future<CanvasProject> generate({
    required String request,
    required CanvasProject current,
  }) async {
    final prompt = DesignPrompt.build(request: request, current: current);
    final reply = switch (provider) {
      AiProvider.gemini => await _gemini(prompt),
      AiProvider.openAiCompatible => await _openAi(prompt),
    };
    return DesignPrompt.parseReply(reply);
  }

  /// One chat turn: earlier messages, the new request and any attachments.
  Future<ChatReply> chat({
    required List<ChatTurn> history,
    required String request,
    required CanvasProject current,
    required String currentScreenId,
    String? selectedWidgetId,
    List<ChatAttachment> attachments = const [],
  }) async {
    final prompt = DesignPrompt.buildChat(
      request: request,
      current: current,
      currentScreenId: currentScreenId,
      selectedWidgetId: selectedWidgetId,
    );
    final reply = switch (provider) {
      AiProvider.gemini => await _geminiChat(history, prompt, attachments,
          readLinks: request.contains('http')),
      AiProvider.openAiCompatible =>
        await _openAiChat(history, prompt, attachments),
    };
    return DesignPrompt.parseChatReply(reply);
  }

  Future<String> _geminiChat(
    List<ChatTurn> history,
    String prompt,
    List<ChatAttachment> attachments, {
    required bool readLinks,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent',
    );
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
      body: jsonEncode({
        'contents': [
          for (final turn in history)
            {
              'role': turn.fromUser ? 'user' : 'model',
              'parts': [
                {'text': turn.text},
              ],
            },
          {
            'role': 'user',
            'parts': [
              for (final file in attachments)
                {
                  'inline_data': {
                    'mime_type': file.mimeType,
                    'data': base64Encode(file.bytes),
                  },
                },
              {'text': prompt},
            ],
          },
        ],
        // Lets Gemini open links the user pastes.
        if (readLinks)
          'tools': [
            {'url_context': <String, Object>{}},
          ],
      }),
    );
    final body = _decode(response);
    final parts = body['candidates'][0]['content']['parts'] as List;
    return parts.map((part) => part['text'] ?? '').join();
  }

  Future<String> _openAiChat(
    List<ChatTurn> history,
    String prompt,
    List<ChatAttachment> attachments,
  ) async {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final images = attachments.where((file) => file.isImage).toList();
    final response = await _client.post(
      Uri.parse('$base/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          for (final turn in history)
            {
              'role': turn.fromUser ? 'user' : 'assistant',
              'content': turn.text,
            },
          {
            'role': 'user',
            'content': images.isEmpty
                ? prompt
                : [
                    {'type': 'text', 'text': prompt},
                    for (final file in images)
                      {
                        'type': 'image_url',
                        'image_url': {
                          'url': 'data:${file.mimeType};base64,'
                              '${base64Encode(file.bytes)}',
                        },
                      },
                  ],
          },
        ],
      }),
    );
    final body = _decode(response);
    return body['choices'][0]['message']['content'] as String;
  }

  Future<String> _gemini(String prompt) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent',
    );
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'responseMimeType': 'application/json'},
      }),
    );
    final body = _decode(response);
    final parts = body['candidates'][0]['content']['parts'] as List;
    return parts.map((part) => part['text'] ?? '').join();
  }

  Future<String> _openAi(String prompt) async {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final response = await _client.post(
      Uri.parse('$base/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );
    final body = _decode(response);
    return body['choices'][0]['message']['content'] as String;
  }

  dynamic _decode(http.Response response) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 400) {
      final message = body is Map && body['error'] is Map
          ? body['error']['message']
          : response.reasonPhrase;
      throw Exception('The AI service said: $message');
    }
    return body;
  }
}

/// Opens the AI assistant.
Future<void> showAiAssistant(
  BuildContext context,
  BuilderController controller,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _AiDialog(controller: controller),
  );
}

class _AiDialog extends StatefulWidget {
  const _AiDialog({required this.controller});

  final BuilderController controller;

  @override
  State<_AiDialog> createState() => _AiDialogState();
}

class _AiDialogState extends State<_AiDialog> {
  // Remembered for this session only, never saved.
  static AiProvider _provider = AiProvider.gemini;
  static String _key = '';
  static String _model = AiProvider.gemini.defaultModel;
  static String _baseUrl = AiProvider.openAiCompatible.defaultBaseUrl;

  final _prompt = TextEditingController();
  late final _keyField = TextEditingController(text: _key);
  late final _modelField = TextEditingController(text: _model);
  late final _baseField = TextEditingController(text: _baseUrl);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _prompt.dispose();
    _keyField.dispose();
    _modelField.dispose();
    _baseField.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    _key = _keyField.text.trim();
    _model = _modelField.text.trim();
    _baseUrl = _baseField.text.trim();
    if (_key.isEmpty || _prompt.text.trim().isEmpty) {
      setState(() => _error = 'Add your API key and describe what you want.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final project = await DesignAssistant(
        provider: _provider,
        apiKey: _key,
        model: _model,
        baseUrl: _baseUrl,
      ).generate(
        request: _prompt.text.trim(),
        current: widget.controller.project,
      );
      widget.controller.loadProject(project);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome),
          SizedBox(width: 10),
          Text('AI assistant'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(
                'Describe a screen or a change, for example "Add a login '
                'screen with email, password and a big blue button". The '
                'AI rewrites the design and you can undo it.',
                style: theme.textTheme.bodySmall,
              ),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Service',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AiProvider>(
                    value: _provider,
                    isExpanded: true,
                    isDense: true,
                    items: [
                      for (final p in AiProvider.values)
                        DropdownMenuItem(value: p, child: Text(p.label)),
                    ],
                    onChanged: (value) => setState(() {
                      _provider = value ?? AiProvider.gemini;
                      _modelField.text = _provider.defaultModel;
                    }),
                  ),
                ),
              ),
              TextField(
                controller: _keyField,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API key',
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: _modelField,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_provider == AiProvider.openAiCompatible)
                TextField(
                  controller: _baseField,
                  decoration: const InputDecoration(
                    labelText: 'API base URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              TextField(
                controller: _prompt,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'What should the AI design?',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              Text(
                'Your key stays in this session only. Never put an API key '
                'inside an app you publish.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _run,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(_busy ? 'Designing…' : 'Generate'),
        ),
      ],
    );
  }
}
