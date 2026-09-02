import 'package:prototype_gateway_protocol/prototype_gateway_protocol.dart';

import '../domain/prototype_provider.dart';
import 'prototype_contract_builder.dart';

class GatewayRequestException implements Exception {
  const GatewayRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GeneratePrototype {
  const GeneratePrototype({
    required PrototypeProviderRegistry providers,
    required PrototypeContractBuilder contractBuilder,
  })  : _providers = providers,
        _contractBuilder = contractBuilder;

  final PrototypeProviderRegistry _providers;
  final PrototypeContractBuilder _contractBuilder;

  Future<GatewayGenerateResponse> call(GatewayGenerateRequest request) async {
    final String prompt = request.prompt.trim();
    if (prompt.isEmpty) {
      throw const GatewayRequestException('O briefing não pode estar vazio.');
    }
    if (prompt.length > 6000) {
      throw const GatewayRequestException(
        'O briefing excede o limite local de 6000 caracteres.',
      );
    }
    final PrototypeProvider? provider = _providers.find(request.providerId);
    if (provider == null) {
      throw GatewayRequestException(
        'Provider não registrado: ${request.providerId}.',
      );
    }
    final PrototypeGenerationContract contract =
        _contractBuilder.build(request.catalog);
    final ProviderGenerationOutput generated = await provider.generate(
      ProviderGenerationInput(
        userPrompt: prompt,
        systemPrompt: contract.systemPrompt,
        outputSchema: contract.outputSchema,
        conversationId: request.conversationId,
      ),
    );
    return GatewayGenerateResponse(
      providerId: provider.id,
      conversationId: generated.conversationId,
      document: generated.document,
    );
  }
}
