import 'dart:convert';
import 'dart:io';

import 'package:prototype_gateway_client/prototype_gateway_client.dart';

import 'gateway_response_decoder.dart';

GatewayTransport createGatewayTransport(Uri baseUri) =>
    _IoGatewayTransport(baseUri);

class _IoGatewayTransport implements GatewayTransport {
  _IoGatewayTransport(this._baseUri);

  final Uri _baseUri;
  final HttpClient _client = HttpClient();

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
      final HttpClientRequest request = await _client
          .openUrl(method, uri)
          .timeout(const Duration(seconds: 10));
      request.headers.contentType = ContentType.json;
      if (body != null) request.write(jsonEncode(body));
      final HttpClientResponse response =
          await request.close().timeout(const Duration(minutes: 3));
      final String raw = await utf8.decoder.bind(response).join();
      return decodeGatewayResponse(
        statusCode: response.statusCode,
        body: raw,
      );
    } on GatewayTransportException {
      rethrow;
    } on Object catch (error) {
      throw GatewayTransportException(
        message:
            'Não foi possível acessar o gateway local em $_baseUri: $error',
      );
    }
  }
}
