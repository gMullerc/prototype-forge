import 'dart:convert';
import 'dart:io';

import 'package:prototype_gateway_protocol/prototype_gateway_protocol.dart';

import '../../application/generate_prototype.dart';
import '../../domain/prototype_provider.dart';

class LocalGatewayServer {
  LocalGatewayServer({
    required String host,
    required int port,
    required GeneratePrototype generatePrototype,
    required PrototypeProviderRegistry providers,
    this.shutdownToken,
    this.onShutdown,
  })  : _host = host,
        _port = port,
        _generatePrototype = generatePrototype,
        _providers = providers;

  final String _host;
  final int _port;
  final GeneratePrototype _generatePrototype;
  final PrototypeProviderRegistry _providers;
  final String? shutdownToken;
  final Future<void> Function()? onShutdown;
  HttpServer? _server;

  int? get boundPort => _server?.port;

  Future<void> start() async {
    if (_server != null) return;
    final HttpServer server = await HttpServer.bind(_host, _port);
    _server = server;
    await for (final HttpRequest request in server) {
      _handle(request);
    }
  }

  Future<void> close() async {
    final HttpServer? server = _server;
    _server = null;
    await server?.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      if (!_allowOrigin(request)) {
        _json(
          request.response,
          HttpStatus.forbidden,
          const GatewayErrorResponse(
            code: 'origin_not_allowed',
            message: 'Somente origens locais podem acessar o gateway.',
          ).toJson(),
        );
        return;
      }
      _cors(request);
      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
        return;
      }
      if (request.method == 'GET' && request.uri.path == gatewayHealthPath) {
        await _health(request.response);
        return;
      }
      if (request.method == 'POST' && request.uri.path == gatewayGeneratePath) {
        await _generate(request);
        return;
      }
      if (request.method == 'POST' &&
          request.uri.path == '/internal/shutdown' &&
          shutdownToken != null &&
          request.headers.value('x-prototype-shutdown-token') ==
              shutdownToken) {
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
        final Future<void> Function()? callback = onShutdown;
        if (callback != null) Future<void>.microtask(callback);
        return;
      }
      _json(
        request.response,
        HttpStatus.notFound,
        const GatewayErrorResponse(
          code: 'not_found',
          message: 'Rota não encontrada.',
        ).toJson(),
      );
    } on GatewayProtocolException catch (error) {
      _json(
        request.response,
        HttpStatus.badRequest,
        GatewayErrorResponse(
          code: 'invalid_protocol',
          message: error.message,
        ).toJson(),
      );
    } on GatewayRequestException catch (error) {
      _json(
        request.response,
        HttpStatus.badRequest,
        GatewayErrorResponse(
          code: 'invalid_request',
          message: error.message,
        ).toJson(),
      );
    } on Object catch (error) {
      _json(
        request.response,
        HttpStatus.badGateway,
        GatewayErrorResponse(
          code: 'provider_failure',
          message: '$error',
        ).toJson(),
      );
    }
  }

  Future<void> _health(HttpResponse response) async {
    final Map<String, Object?> providers = <String, Object?>{};
    for (final PrototypeProvider provider in _providers.providers) {
      final ProviderHealth health = await provider.health();
      providers[provider.id] = <String, Object?>{
        'available': health.available,
        if (health.version != null) 'version': health.version,
        if (health.message != null) 'message': health.message,
      };
    }
    _json(response, HttpStatus.ok, <String, Object?>{
      'protocolVersion': gatewayProtocolVersion,
      'status': 'ok',
      'providers': providers,
    });
  }

  Future<void> _generate(HttpRequest request) async {
    final Object? payload = await _readJson(request);
    final GatewayGenerateRequest generation =
        GatewayGenerateRequest.fromJson(payload);
    final GatewayGenerateResponse result = await _generatePrototype(generation);
    _json(request.response, HttpStatus.ok, result.toJson());
  }

  Future<Object?> _readJson(HttpRequest request) async {
    const int maxBytes = 256 * 1024;
    final List<int> bytes = <int>[];
    await for (final List<int> chunk in request) {
      bytes.addAll(chunk);
      if (bytes.length > maxBytes) {
        throw const GatewayRequestException(
          'A requisição excede o limite local de 256 KB.',
        );
      }
    }
    if (bytes.isEmpty) {
      throw const GatewayRequestException('O corpo JSON é obrigatório.');
    }
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const GatewayRequestException('O corpo não contém JSON válido.');
    }
  }

  bool _allowOrigin(HttpRequest request) {
    final String? origin = request.headers.value('origin');
    if (origin == null) return true;
    final Uri? uri = Uri.tryParse(origin);
    return uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1');
  }

  void _cors(HttpRequest request) {
    final String? origin = request.headers.value('origin');
    if (origin != null) {
      request.response.headers.set('access-control-allow-origin', origin);
      request.response.headers.set('vary', 'Origin');
    }
    request.response.headers.set(
      'access-control-allow-headers',
      'content-type',
    );
    request.response.headers.set(
      'access-control-allow-methods',
      'GET,POST,OPTIONS',
    );
  }

  void _json(HttpResponse response, int statusCode, Object payload) {
    if (response.headers.contentType == null) {
      response.headers.contentType = ContentType.json;
    }
    response.statusCode = statusCode;
    response.write(jsonEncode(payload));
    response.close();
  }
}
