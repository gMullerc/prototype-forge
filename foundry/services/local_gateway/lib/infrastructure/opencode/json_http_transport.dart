import 'dart:async';
import 'dart:convert';
import 'dart:io';

class JsonHttpException implements Exception {
  const JsonHttpException({
    required this.message,
    this.code = 'http_error',
    this.statusCode,
    this.payload,
  });

  final String message;
  final String code;
  final int? statusCode;
  final Object? payload;

  @override
  String toString() => message;
}

abstract interface class JsonHttpTransport {
  Future<Object?> send({
    required String method,
    required Uri uri,
    Object? body,
    Duration timeout,
  });
}

class DartJsonHttpTransport implements JsonHttpTransport {
  DartJsonHttpTransport({HttpClient? client})
      : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  Future<Object?> send({
    required String method,
    required Uri uri,
    Object? body,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    try {
      final HttpClientRequest request =
          await _client.openUrl(method, uri).timeout(timeout);
      request.headers.contentType = ContentType.json;
      if (body != null) {
        request.write(jsonEncode(body));
      }
      final HttpClientResponse response =
          await request.close().timeout(timeout);
      final String raw =
          await utf8.decoder.bind(response).join().timeout(timeout);
      Object? payload;
      if (raw.trim().isNotEmpty) {
        try {
          payload = jsonDecode(raw);
        } on FormatException {
          payload = raw;
        }
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw JsonHttpException(
          statusCode: response.statusCode,
          payload: payload,
          message: _errorMessage(response.statusCode, payload),
        );
      }
      return payload;
    } on JsonHttpException {
      rethrow;
    } on TimeoutException {
      throw JsonHttpException(
        code: 'timeout',
        message: 'Tempo limite ao acessar o OpenCode em $uri.',
      );
    } on Object catch (error) {
      throw JsonHttpException(
        message: 'Falha ao acessar $uri: $error',
      );
    }
  }

  void close() => _client.close(force: true);

  String _errorMessage(int statusCode, Object? payload) {
    if (payload is Map<Object?, Object?>) {
      final Object? error = payload['error'];
      if (error is Map<Object?, Object?>) {
        final Object? data = error['data'];
        if (data is Map<Object?, Object?> && data['message'] is String) {
          return 'OpenCode $statusCode: ${data['message']}';
        }
        if (error['message'] is String) {
          return 'OpenCode $statusCode: ${error['message']}';
        }
      }
      if (payload['message'] is String) {
        return 'OpenCode $statusCode: ${payload['message']}';
      }
    }
    return 'OpenCode respondeu HTTP $statusCode.';
  }
}
