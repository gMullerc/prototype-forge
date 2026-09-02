// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:prototype_gateway_client/prototype_gateway_client.dart';

import 'gateway_response_decoder.dart';

GatewayTransport createGatewayTransport(Uri baseUri) =>
    _WebGatewayTransport(baseUri);

class _WebGatewayTransport implements GatewayTransport {
  const _WebGatewayTransport(this._baseUri);

  final Uri _baseUri;

  @override
  Future<Map<String, Object?>> getJson(String path) => _request('GET', path);

  @override
  Future<Map<String, Object?>> postJson(
    String path,
    Map<String, Object?> body,
  ) =>
      _request('POST', path, body: body);

  Future<Map<String, Object?>> _request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final Uri uri = _baseUri.resolve(path);
    try {
      final HttpRequest response = HttpRequest();
      response.open(method, uri.toString());
      response.setRequestHeader('content-type', 'application/json');
      response.send(body == null ? null : jsonEncode(body));
      await response.onLoadEnd.first.timeout(const Duration(minutes: 3));
      return decodeGatewayResponse(
        statusCode: response.status ?? 0,
        body: response.responseText ?? '',
      );
    } on GatewayTransportException {
      rethrow;
    } on TimeoutException {
      throw const GatewayTransportException(
        code: 'timeout',
        message: 'O gateway local demorou demais para responder.',
      );
    } on Object catch (error) {
      throw GatewayTransportException(
        message:
            'Não foi possível acessar o gateway local em $_baseUri: $error',
      );
    }
  }
}
