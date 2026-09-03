import 'package:prototype_gateway_protocol/prototype_gateway_protocol.dart';
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

  test('round-trips a generation request', () {
    final GatewayGenerateRequest request = GatewayGenerateRequest(
      providerId: 'opencode',
      prompt: 'Crie uma tela',
      catalog: catalog,
      conversationId: 'session-1',
    );

    final GatewayGenerateRequest decoded =
        GatewayGenerateRequest.fromJson(request.toJson());

    expect(decoded.providerId, 'opencode');
    expect(decoded.catalog.components.single.type, 'Text');
    expect(decoded.conversationId, 'session-1');
  });

  test('rejects duplicated component types', () {
    expect(
      () => GatewayCatalogContract(<GatewayComponentContract>[
        GatewayComponentContract(type: 'Text'),
        GatewayComponentContract(type: 'Text'),
      ]),
      throwsA(isA<GatewayProtocolException>()),
    );
  });

  test('round-trips a clarification response with selectable options', () {
    final GatewayGenerateResponse response =
        GatewayGenerateResponse.clarification(
      providerId: 'opencode',
      conversationId: 'session-1',
      clarification: const GatewayClarification(
        question: 'A tela deve permitir editar registros?',
        options: <String>['Somente criar', 'Criar e editar'],
      ),
    );

    final GatewayGenerateResponse decoded =
        GatewayGenerateResponse.fromJson(response.toJson());

    expect(decoded.isClarification, isTrue);
    expect(decoded.clarification?.question,
        'A tela deve permitir editar registros?');
    expect(decoded.clarification?.options, <String>[
      'Somente criar',
      'Criar e editar',
    ]);
  });
}
