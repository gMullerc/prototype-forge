import 'dart:convert';

import '../../domain/prototype_provider.dart';
import 'json_http_transport.dart';
import 'opencode_configuration.dart';
import 'opencode_host.dart';

class OpenCodeApiClient {
  OpenCodeApiClient({
    required OpenCodeConfiguration configuration,
    required OpenCodeHost host,
    required JsonHttpTransport transport,
  })  : _configuration = configuration,
        _host = host,
        _transport = transport;

  final OpenCodeConfiguration _configuration;
  final OpenCodeHost _host;
  final JsonHttpTransport _transport;

  Future<ProviderGenerationOutput> generate(
    ProviderGenerationInput input,
  ) async {
    await _host.ensureReady();
    final String sessionId = input.conversationId ?? await _createSession();
    final Object? payload = await _transport.send(
      method: 'POST',
      uri: _uri('/session/${Uri.encodeComponent(sessionId)}/message'),
      timeout: const Duration(minutes: 3),
      body: <String, Object?>{
        'model': <String, Object?>{
          'providerID': _configuration.providerId,
          'modelID': _configuration.modelId,
        },
        'agent': 'plan',
        'system': input.systemPrompt,
        'tools': _disabledTools,
        'format': const <String, Object?>{'type': 'text'},
        if (_configuration.variant != null) 'variant': _configuration.variant,
        'parts': <Object?>[
          <String, Object?>{'type': 'text', 'text': input.userPrompt},
        ],
      },
    );
    final Map<String, Object?> response = _map(payload, 'resposta');
    final Map<String, Object?> info = _map(response['info'], 'info');
    if (info['error'] != null) {
      throw StateError('OpenCode retornou um erro: ${info['error']}');
    }
    final Map<String, Object?> document = _extractDocument(response, info);
    return ProviderGenerationOutput(
      conversationId: sessionId,
      document: document,
    );
  }

  Future<String> _createSession() async {
    final Object? payload = await _transport.send(
      method: 'POST',
      uri: _uri('/session'),
      timeout: const Duration(seconds: 30),
      body: <String, Object?>{
        'title': 'Prototype Foundry',
        'agent': 'plan',
        'model': <String, Object?>{
          'id': _configuration.modelId,
          'providerID': _configuration.providerId,
          if (_configuration.variant != null) 'variant': _configuration.variant,
        },
        'permission': <Object?>[
          <String, Object?>{
            'permission': '*',
            'pattern': '*',
            'action': 'deny',
          },
        ],
      },
    );
    final Map<String, Object?> session = _map(payload, 'sessão');
    final Object? id = session['id'];
    if (id is! String || id.isEmpty) {
      throw StateError('OpenCode não retornou um ID de sessão.');
    }
    return id;
  }

  Map<String, Object?> _extractDocument(
    Map<String, Object?> response,
    Map<String, Object?> info,
  ) {
    final Object? structured = info['structured'];
    if (structured is Map<Object?, Object?>) {
      return _map(structured, 'documento estruturado');
    }

    final Object? partsValue = response['parts'];
    if (partsValue is! List<Object?>) {
      throw StateError(
          'OpenCode respondeu sem documento estruturado ou texto.');
    }
    final String text = partsValue
        .whereType<Map<Object?, Object?>>()
        .where((Map<Object?, Object?> part) => part['type'] == 'text')
        .map((Map<Object?, Object?> part) => part['text'])
        .whereType<String>()
        .join('\n')
        .trim();
    if (text.isEmpty) {
      throw StateError('OpenCode respondeu sem conteúdo utilizável.');
    }
    final String normalized = text
        .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '');
    return _map(jsonDecode(normalized), 'documento');
  }

  Uri _uri(String path) {
    final Uri uri = _configuration.baseUri.resolve(path);
    return uri.replace(
      queryParameters: <String, String>{
        'directory': _configuration.workspaceDirectory,
      },
    );
  }

  Map<String, Object?> _map(Object? value, String name) {
    if (value is! Map<Object?, Object?>) {
      throw StateError('$name do OpenCode não é um objeto JSON.');
    }
    return <String, Object?>{
      for (final MapEntry<Object?, Object?> entry in value.entries)
        if (entry.key is String) entry.key! as String: entry.value,
    };
  }

  static const Map<String, bool> _disabledTools = <String, bool>{
    'bash': false,
    'edit': false,
    'write': false,
    'apply_patch': false,
    'read': false,
    'glob': false,
    'grep': false,
    'task': false,
    'webfetch': false,
    'todowrite': false,
  };
}
