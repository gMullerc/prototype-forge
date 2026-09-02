import 'gateway_catalog.dart';
import 'gateway_protocol.dart';

class GatewayGenerateRequest {
  const GatewayGenerateRequest({
    required this.providerId,
    required this.prompt,
    required this.catalog,
    this.conversationId,
  });

  factory GatewayGenerateRequest.fromJson(Object? value) {
    final Map<String, Object?> json = gatewayMap(value, 'request');
    if (json['protocolVersion'] != gatewayProtocolVersion) {
      throw GatewayProtocolException(
        'Versão de protocolo incompatível: ${json['protocolVersion']}.',
      );
    }
    return GatewayGenerateRequest(
      providerId: gatewayString(json, 'providerId'),
      prompt: gatewayString(json, 'prompt'),
      catalog: GatewayCatalogContract.fromJson(json['catalog']),
      conversationId: gatewayOptionalString(json, 'conversationId'),
    );
  }

  final String providerId;
  final String prompt;
  final GatewayCatalogContract catalog;
  final String? conversationId;

  Map<String, Object?> toJson() => <String, Object?>{
        'protocolVersion': gatewayProtocolVersion,
        'providerId': providerId,
        'prompt': prompt,
        'catalog': catalog.toJson(),
        if (conversationId != null) 'conversationId': conversationId,
      };
}

class GatewayGenerateResponse {
  const GatewayGenerateResponse({
    required this.providerId,
    required this.conversationId,
    required this.document,
  });

  factory GatewayGenerateResponse.fromJson(Object? value) {
    final Map<String, Object?> json = gatewayMap(value, 'response');
    if (json['protocolVersion'] != gatewayProtocolVersion) {
      throw GatewayProtocolException(
        'Versão de protocolo incompatível: ${json['protocolVersion']}.',
      );
    }
    return GatewayGenerateResponse(
      providerId: gatewayString(json, 'providerId'),
      conversationId: gatewayString(json, 'conversationId'),
      document: gatewayMap(json['document'], 'document'),
    );
  }

  final String providerId;
  final String conversationId;
  final Map<String, Object?> document;

  Map<String, Object?> toJson() => <String, Object?>{
        'protocolVersion': gatewayProtocolVersion,
        'providerId': providerId,
        'conversationId': conversationId,
        'document': document,
      };
}

class GatewayErrorResponse {
  const GatewayErrorResponse({required this.code, required this.message});

  final String code;
  final String message;

  Map<String, Object?> toJson() => <String, Object?>{
        'protocolVersion': gatewayProtocolVersion,
        'error': <String, Object?>{'code': code, 'message': message},
      };
}
