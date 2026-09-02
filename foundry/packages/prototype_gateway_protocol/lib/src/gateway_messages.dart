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
    this.clarification,
  });

  const GatewayGenerateResponse.clarification({
    required this.providerId,
    required this.conversationId,
    required GatewayClarification this.clarification,
  }) : document = const <String, Object?>{};

  factory GatewayGenerateResponse.fromJson(Object? value) {
    final Map<String, Object?> json = gatewayMap(value, 'response');
    if (json['protocolVersion'] != gatewayProtocolVersion) {
      throw GatewayProtocolException(
        'Versão de protocolo incompatível: ${json['protocolVersion']}.',
      );
    }
    final String providerId = gatewayString(json, 'providerId');
    final String conversationId = gatewayString(json, 'conversationId');
    final Object? rawClarification = json['clarification'];
    if (json['kind'] == 'clarification' || rawClarification != null) {
      if (rawClarification == null) {
        throw const GatewayProtocolException(
          'Uma resposta de clarification precisa informar clarification.',
        );
      }
      return GatewayGenerateResponse.clarification(
        providerId: providerId,
        conversationId: conversationId,
        clarification: GatewayClarification.fromJson(rawClarification),
      );
    }
    return GatewayGenerateResponse(
      providerId: providerId,
      conversationId: conversationId,
      document: gatewayMap(json['document'], 'document'),
    );
  }

  final String providerId;
  final String conversationId;
  final Map<String, Object?> document;
  final GatewayClarification? clarification;

  bool get isClarification => clarification != null;

  Map<String, Object?> toJson() => <String, Object?>{
        'protocolVersion': gatewayProtocolVersion,
        'providerId': providerId,
        'conversationId': conversationId,
        'kind': isClarification ? 'clarification' : 'contract',
        if (isClarification)
          'clarification': clarification!.toJson()
        else
          'document': document,
      };
}

class GatewayClarification {
  const GatewayClarification({
    required this.question,
    this.options = const <String>[],
  });

  factory GatewayClarification.fromJson(Object? value) {
    final Map<String, Object?> json = gatewayMap(value, 'clarification');
    final Object? rawOptions = json['options'];
    if (rawOptions != null &&
        (rawOptions is! List ||
            rawOptions.any((Object? option) => option is! String))) {
      throw const GatewayProtocolException(
        'clarification.options precisa ser uma lista de textos.',
      );
    }
    final List<String> options = rawOptions == null
        ? const <String>[]
        : (rawOptions as List<Object?>).cast<String>();
    return GatewayClarification(
      question: gatewayString(json, 'question'),
      options: options,
    );
  }

  final String question;
  final List<String> options;

  Map<String, Object?> toJson() => <String, Object?>{
        'question': question,
        if (options.isNotEmpty) 'options': options,
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

class GatewayToolsResponse {
  const GatewayToolsResponse({required this.tools});

  factory GatewayToolsResponse.fromJson(Object? value) {
    final Map<String, Object?> json = gatewayMap(value, 'response');
    if (json['protocolVersion'] != gatewayProtocolVersion) {
      throw GatewayProtocolException(
        'Versão de protocolo incompatível: ${json['protocolVersion']}.',
      );
    }
    final Object? rawTools = json['tools'];
    if (rawTools is! List<Object?>) {
      throw const GatewayProtocolException('tools precisa ser uma lista.');
    }
    return GatewayToolsResponse(
      tools: rawTools.map(GatewayToolInfo.fromJson).toList(growable: false),
    );
  }

  final List<GatewayToolInfo> tools;

  Map<String, Object?> toJson() => <String, Object?>{
        'protocolVersion': gatewayProtocolVersion,
        'detection': 'executable-path-and-version',
        'credentialsChecked': false,
        'tools': tools.map((GatewayToolInfo tool) => tool.toJson()).toList(),
      };
}

class GatewayToolInfo {
  const GatewayToolInfo({
    required this.id,
    required this.label,
    required this.executable,
    required this.status,
    required this.capabilities,
    this.executablePath,
    this.version,
    this.diagnostic,
    this.setupHint,
  });

  factory GatewayToolInfo.fromJson(Object? value) {
    final Map<String, Object?> json = gatewayMap(value, 'tool');
    final Object? rawCapabilities = json['capabilities'];
    if (rawCapabilities is! List<Object?> ||
        rawCapabilities.any((Object? item) => item is! String)) {
      throw const GatewayProtocolException(
        'tool.capabilities precisa ser uma lista de textos.',
      );
    }
    return GatewayToolInfo(
      id: gatewayString(json, 'id'),
      label: gatewayString(json, 'label'),
      executable: gatewayString(json, 'executable'),
      status: gatewayString(json, 'status'),
      capabilities: rawCapabilities.cast<String>(),
      executablePath: gatewayOptionalString(json, 'executablePath'),
      version: gatewayOptionalString(json, 'version'),
      diagnostic: gatewayOptionalString(json, 'diagnostic'),
      setupHint: gatewayOptionalString(json, 'setupHint'),
    );
  }

  final String id;
  final String label;
  final String executable;
  final String status;
  final List<String> capabilities;
  final String? executablePath;
  final String? version;
  final String? diagnostic;
  final String? setupHint;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'label': label,
        'executable': executable,
        'status': status,
        'capabilities': capabilities,
        if (executablePath != null) 'executablePath': executablePath,
        if (version != null) 'version': version,
        if (diagnostic != null) 'diagnostic': diagnostic,
        if (setupHint != null) 'setupHint': setupHint,
      };
}
