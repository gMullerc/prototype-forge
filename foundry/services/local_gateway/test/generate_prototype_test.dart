import 'package:prototype_gateway_protocol/prototype_gateway_protocol.dart';
import 'package:prototype_local_gateway/application/generate_prototype.dart';
import 'package:prototype_local_gateway/application/prototype_contract_builder.dart';
import 'package:prototype_local_gateway/domain/prototype_provider.dart';
import 'package:test/test.dart';

void main() {
  final GatewayCatalogContract catalog = GatewayCatalogContract(
    <GatewayComponentContract>[
      GatewayComponentContract(
        type: 'Text',
        properties: <String, GatewayPropertyContract>{
          'text': GatewayPropertyContract(
            type: GatewayPropertyType.string,
            required: true,
          ),
        },
      ),
    ],
  );

  test('builds a provider-neutral structured generation request', () async {
    final _FakeProvider provider = _FakeProvider();
    final GeneratePrototype generate = GeneratePrototype(
      providers: PrototypeProviderRegistry(<PrototypeProvider>[provider]),
      contractBuilder: const PrototypeSpecContractBuilder(),
    );

    final GatewayGenerateResponse response = await generate(
      GatewayGenerateRequest(
        providerId: 'fake',
        prompt: 'Crie uma tela',
        catalog: catalog,
      ),
    );

    expect(response.providerId, 'fake');
    expect(provider.input?.systemPrompt, contains('Text'));
    expect(provider.input?.systemPrompt, contains('Prototype Spec 1.1'));
    final List<Object?> responseVariants =
        provider.input?.outputSchema['oneOf']! as List<Object?>;
    expect(responseVariants, hasLength(2));
    final Map<String, Object?> contractVariant =
        responseVariants[1]! as Map<String, Object?>;
    final Map<String, Object?> properties =
        contractVariant['properties']! as Map<String, Object?>;
    final Map<String, Object?> document =
        properties['document']! as Map<String, Object?>;
    expect(document['\$defs'], isNotNull);
    expect(document['properties'],
        containsPair('interaction', isA<Map<String, Object?>>()));
  });

  test('rejects providers that were not registered', () {
    final GeneratePrototype generate = GeneratePrototype(
      providers: PrototypeProviderRegistry(<PrototypeProvider>[
        _FakeProvider(),
      ]),
      contractBuilder: const PrototypeSpecContractBuilder(),
    );

    expect(
      () => generate(
        GatewayGenerateRequest(
          providerId: 'missing',
          prompt: 'Crie uma tela',
          catalog: catalog,
        ),
      ),
      throwsA(isA<GatewayRequestException>()),
    );
  });
}

class _FakeProvider implements PrototypeProvider {
  ProviderGenerationInput? input;

  @override
  String get id => 'fake';

  @override
  Future<void> close() async {}

  @override
  Future<ProviderGenerationOutput> generate(
    ProviderGenerationInput input,
  ) async {
    this.input = input;
    return ProviderGenerationOutput(
      conversationId: 'conversation',
      document: <String, Object?>{
        'specVersion': '1.0',
        'screen': <String, Object?>{},
      },
    );
  }

  @override
  Future<ProviderHealth> health() async =>
      const ProviderHealth(available: true);
}
