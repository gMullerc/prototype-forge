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
    Object? payload;
    try {
      payload = await _send(
        method: 'POST',
        uri: _uri('/session/${Uri.encodeComponent(sessionId)}/message'),
        timeout: _configuration.generationTimeout,
        body: <String, Object?>{
          'model': <String, Object?>{
            'providerID': _configuration.providerId,
            'modelID': _configuration.modelId,
          },
          'agent': 'plan',
          'system': input.systemPrompt,
          'tools': _disabledTools,
          if (_configuration.variant != null) 'variant': _configuration.variant,
          'parts': <Object?>[
            <String, Object?>{'type': 'text', 'text': input.userPrompt},
          ],
        },
      );
    } on ProviderGenerationException catch (error) {
      if (error.code == 'provider_timeout') {
        // OpenCode can publish the assistant's final text before the HTTP
        // request finishes. Recover that turn before aborting so a slow
        // transport does not discard an otherwise valid contract.
        try {
          return await _recoverTurnFromSession(sessionId);
        } on ProviderGenerationException {
          await _abortSession(sessionId);
        }
      }
      rethrow;
    }
    final Map<String, Object?> response = _map(payload, 'resposta');
    final Map<String, Object?> info = _map(response['info'], 'info');
    if (info['error'] != null) {
      final ProviderGenerationException error =
          _generationExceptionFor(info['error']);
      if (error.code == 'provider_response_invalid') {
        try {
          return await _recoverTurnFromSession(sessionId);
        } on ProviderGenerationException {
          // Preserve the provider error when the session has no recoverable
          // assistant turn yet.
        }
      }
      throw error;
    }
    late final ProviderGenerationOutput generated;
    try {
      generated = _extractTurn(response, info, sessionId);
    } on ProviderGenerationException catch (error) {
      if (error.code != 'provider_response_invalid') rethrow;
      generated = await _recoverTurnFromSession(sessionId);
    }
    return generated;
  }

  Future<String> _createSession() async {
    final Object? payload = await _send(
      method: 'POST',
      uri: _uri('/session'),
      timeout: const Duration(seconds: 30),
      body: <String, Object?>{
        'title': 'Prototype Foundry',
      },
    );
    final Map<String, Object?> session = _map(payload, 'sessão');
    final Object? id = session['id'];
    if (id is! String || id.isEmpty) {
      throw StateError('OpenCode não retornou um ID de sessão.');
    }
    return id;
  }

  Future<Object?> _send({
    required String method,
    required Uri uri,
    required Duration timeout,
    Object? body,
  }) async {
    try {
      return await _transport.send(
        method: method,
        uri: uri,
        timeout: timeout,
        body: body,
      );
    } on JsonHttpException catch (error) {
      if (error.code == 'timeout') {
        throw ProviderGenerationException(
          code: 'provider_timeout',
          message:
              'O OpenCode não respondeu dentro de ${timeout.inSeconds} segundos.',
        );
      }
      rethrow;
    }
  }

  Future<void> _abortSession(String sessionId) async {
    try {
      await _transport.send(
        method: 'POST',
        uri: _uri('/session/${Uri.encodeComponent(sessionId)}/abort'),
        timeout: const Duration(seconds: 5),
      );
    } on Object {
      // The timeout is already the actionable failure. Abort is best effort.
    }
  }

  Future<ProviderGenerationOutput> _recoverTurnFromSession(
    String sessionId,
  ) async {
    final Object? payload = await _send(
      method: 'GET',
      uri: _uri('/session/${Uri.encodeComponent(sessionId)}/message'),
      timeout: const Duration(seconds: 15),
    );
    if (payload is! List) throw _invalidResponse();
    for (final Object? value in payload.reversed) {
      if (value is! Map) continue;
      final Map<String, Object?> response = _map(value, 'mensagem');
      final Object? infoValue = response['info'];
      if (infoValue is! Map) continue;
      final Map<String, Object?> info = _map(infoValue, 'info');
      if (info['role'] != 'assistant') continue;
      if (info['error'] != null) {
        throw _generationExceptionFor(info['error']);
      }
      return _extractTurn(response, info, sessionId);
    }
    throw _invalidResponse();
  }

  ProviderGenerationOutput _extractTurn(
    Map<String, Object?> response,
    Map<String, Object?> info,
    String sessionId,
  ) {
    final Object? structured = info['structured'] ?? info['structured_output'];
    if (structured is Map<Object?, Object?>) {
      return _turnFromMap(_map(structured, 'resposta estruturada'), sessionId);
    }
    if (structured != null) {
      throw _invalidResponse();
    }

    final Object? partsValue = response['parts'];
    if (partsValue is! List) {
      throw _invalidResponse();
    }
    final String text = partsValue
        .whereType<Map>()
        .where((Map part) => part['type'] == 'text')
        .map((Map part) => part['text'])
        .whereType<String>()
        .join('\n')
        .trim();
    if (text.isEmpty) {
      throw _invalidResponse();
    }
    try {
      return _turnFromMap(
        _map(jsonDecode(_normalizeTextJson(text)), 'resposta'),
        sessionId,
      );
    } on FormatException {
      throw _invalidResponse();
    } on StateError {
      throw _invalidResponse();
    }
  }

  ProviderGenerationOutput _turnFromMap(
    Map<String, Object?> value,
    String sessionId,
  ) {
    if (value['type'] == 'clarification') {
      final Object? rawQuestion = value['question'];
      final Object? rawOptions = value['options'];
      if (rawQuestion is! String || rawQuestion.trim().isEmpty) {
        throw _invalidResponse();
      }
      if (rawOptions != null &&
          (rawOptions is! List ||
              rawOptions.any((Object? option) => option is! String))) {
        throw _invalidResponse();
      }
      final List<String> options = rawOptions == null
          ? const <String>[]
          : List<String>.from(rawOptions as List);
      return ProviderGenerationOutput.clarification(
        conversationId: sessionId,
        question: rawQuestion,
        options: options,
      );
    }
    final Object? rawDocument =
        value['type'] == 'contract' ? value['document'] : value;
    if (rawDocument is! Map) throw _invalidResponse();
    return ProviderGenerationOutput(
      conversationId: sessionId,
      document: _map(rawDocument, 'documento'),
    );
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

  Uri _uri(String path) {
    final Uri uri = _configuration.baseUri.resolve(path);
    return uri.replace(
      queryParameters: <String, String>{
        'directory': _configuration.workspaceDirectory,
      },
    );
  }

  Map<String, Object?> _map(Object? value, String name) {
    if (value is! Map) {
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
