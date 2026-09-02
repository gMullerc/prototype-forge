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
        'format': <String, Object?>{
          'type': 'json_schema',
          // The complete catalog schema is recursive and intentionally stays
          // in the Foundry validator. OpenCode receives a compact transport
          // schema so structured output remains reliable across models.
          'schema': _structuredOutputSchema,
          // OpenCode asks the model to repair the structured response before
          // returning it to the gateway.
          'retryCount': 2,
        },
        if (_configuration.variant != null) 'variant': _configuration.variant,
        'parts': <Object?>[
          <String, Object?>{'type': 'text', 'text': input.userPrompt},
        ],
      },
    );
    final Map<String, Object?> response = _map(payload, 'resposta');
    final Map<String, Object?> info = _map(response['info'], 'info');
    if (info['error'] != null) {
      throw _generationExceptionFor(info['error']);
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
    final Object? structured = info['structured'] ?? info['structured_output'];
    if (structured is Map<Object?, Object?>) {
      return _map(structured, 'documento estruturado');
    }
    if (structured != null) {
      throw _invalidResponse();
    }

    final Object? partsValue = response['parts'];
    if (partsValue is! List<Object?>) {
      throw _invalidResponse();
    }
    final String text = partsValue
        .whereType<Map<Object?, Object?>>()
        .where((Map<Object?, Object?> part) => part['type'] == 'text')
        .map((Map<Object?, Object?> part) => part['text'])
        .whereType<String>()
        .join('\n')
        .trim();
    if (text.isEmpty) {
      throw _invalidResponse();
    }
    try {
      return _map(jsonDecode(_normalizeTextJson(text)), 'documento');
    } on FormatException {
      throw _invalidResponse();
    } on StateError {
      throw _invalidResponse();
    }
  }

  ProviderGenerationException _generationExceptionFor(Object? error) {
    if (error is Map<Object?, Object?> &&
        error['name'] == 'StructuredOutputError') {
      return _invalidResponse();
    }
    return const ProviderGenerationException(
      code: 'provider_failure',
      message: 'O OpenCode retornou um erro durante a geração.',
    );
  }

  ProviderGenerationException _invalidResponse() {
    return const ProviderGenerationException(
      code: 'provider_response_invalid',
      message:
          'O OpenCode respondeu, mas não produziu um contrato JSON válido após as tentativas automáticas.',
    );
  }

  String _normalizeTextJson(String text) {
    String normalized = text
        .replaceFirst(RegExp(r'^\s*```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```\s*$'), '')
        .trim();
    final int start = normalized.indexOf('{');
    if (start > 0) normalized = normalized.substring(start);
    final int end = _balancedObjectEnd(normalized);
    if (end >= 0 && end < normalized.length - 1) {
      normalized = normalized.substring(0, end + 1);
    }
    return normalized;
  }

  int _balancedObjectEnd(String value) {
    int depth = 0;
    bool inString = false;
    bool escaped = false;
    for (int index = 0; index < value.length; index++) {
      final String character = value[index];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (character == '\\') {
          escaped = true;
        } else if (character == '"') {
          inString = false;
        }
        continue;
      }
      if (character == '"') {
        inString = true;
      } else if (character == '{') {
        depth++;
      } else if (character == '}') {
        depth--;
        if (depth == 0) return index;
      }
    }
    return -1;
  }

  static const Map<String, Object?> _structuredOutputSchema = <String, Object?>{
    'type': 'object',
    'properties': <String, Object?>{
      'specVersion': <String, Object?>{'type': 'string'},
      'screen': <String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{
          'id': <String, Object?>{'type': 'string'},
          'title': <String, Object?>{'type': 'string'},
          // Component-level rules are checked by PrototypeEngine after the
          // provider response arrives.
          'root': <String, Object?>{
            'type': 'object',
            'properties': <String, Object?>{
              'id': <String, Object?>{'const': 'root'},
              'type': <String, Object?>{'type': 'string'},
            },
            'required': <String>['id', 'type'],
          },
        },
        'required': <String>['id', 'title', 'root'],
        'additionalProperties': false,
      },
    },
    'required': <String>['specVersion', 'screen'],
    'additionalProperties': false,
  };

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
