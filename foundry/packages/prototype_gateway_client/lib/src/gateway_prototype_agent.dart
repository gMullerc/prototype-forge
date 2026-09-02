import 'dart:convert';

import 'package:prototype_agent/prototype_agent.dart';
import 'package:prototype_gateway_protocol/prototype_gateway_protocol.dart';
import 'package:prototype_runtime/prototype_runtime.dart';

import 'gateway_transport.dart';

class GatewayPrototypeAgent
    implements PrototypeAgent, PrototypeConversationalAgent {
  GatewayPrototypeAgent({
    required this.id,
    required this.label,
    required this.providerId,
    required GatewayTransport transport,
    required PrototypeCatalog catalog,
  })  : _transport = transport,
        _catalog = _encodeCatalog(catalog);

  @override
  final String id;

  @override
  final String label;

  final String providerId;
  final GatewayTransport _transport;
  final GatewayCatalogContract _catalog;
  String? _conversationId;

  String? get conversationId => _conversationId;

  Future<bool> isAvailable() async {
    try {
      final Map<String, Object?> response =
          await _transport.getJson(gatewayHealthPath);
      return response['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> generate(PrototypeBrief brief) async {
    final PrototypeAgentTurn turn = await respond(brief);
    if (turn.document != null) return turn.document!;
    throw GatewayTransportException(
      code: 'clarification_required',
      message: turn.question ?? 'O agente precisa de mais informações.',
    );
  }

  @override
  Future<PrototypeAgentTurn> respond(PrototypeBrief brief) async {
    final GatewayGenerateRequest request = GatewayGenerateRequest(
      providerId: providerId,
      prompt: brief.text,
      catalog: _catalog,
      conversationId: _conversationId,
    );
    final Map<String, Object?> payload = await _transport.postJson(
      gatewayGeneratePath,
      request.toJson(),
    );
    final GatewayGenerateResponse response =
        GatewayGenerateResponse.fromJson(payload);
    if (response.providerId != providerId) {
      throw GatewayTransportException(
        code: 'provider_mismatch',
        message:
            'O gateway respondeu com ${response.providerId}, mas $providerId era esperado.',
      );
    }
    _conversationId = response.conversationId;
    final GatewayClarification? clarification = response.clarification;
    if (clarification != null) {
      return PrototypeAgentTurn.clarification(
        question: clarification.question,
        options: clarification.options,
      );
    }
    return PrototypeAgentTurn.contract(
      document: jsonEncode(response.document),
    );
  }

  static GatewayCatalogContract _encodeCatalog(PrototypeCatalog catalog) {
    return GatewayCatalogContract(
      catalog.contracts.map(
        (ComponentContract component) => GatewayComponentContract(
          type: component.type,
          allowsChildren: component.allowsChildren,
          properties: <String, GatewayPropertyContract>{
            for (final MapEntry<String, PropertyContract> entry
                in component.properties.entries)
              entry.key: GatewayPropertyContract(
                type: _propertyType(entry.value.type),
                required: entry.value.required,
                allowedValues: entry.value.allowedValues,
              ),
          },
        ),
      ),
    );
  }

  static GatewayPropertyType _propertyType(PrototypePropertyType type) {
    return switch (type) {
      PrototypePropertyType.string => GatewayPropertyType.string,
      PrototypePropertyType.number => GatewayPropertyType.number,
      PrototypePropertyType.boolean => GatewayPropertyType.boolean,
      PrototypePropertyType.object => GatewayPropertyType.object,
      PrototypePropertyType.list => GatewayPropertyType.list,
    };
  }
}
