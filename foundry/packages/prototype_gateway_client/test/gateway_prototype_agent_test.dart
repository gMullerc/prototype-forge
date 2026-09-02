import 'dart:convert';

import 'package:prototype_agent/prototype_agent.dart';
import 'package:prototype_gateway_client/prototype_gateway_client.dart';
import 'package:prototype_runtime/prototype_runtime.dart';
import 'package:test/test.dart';

void main() {
  test('maps the runtime catalog and keeps the gateway conversation', () async {
    final _RecordingTransport transport = _RecordingTransport();
    final GatewayPrototypeAgent agent = GatewayPrototypeAgent(
      id: 'opencode',
      label: 'OpenCode',
      providerId: 'opencode',
      transport: transport,
      catalog: PrototypeCatalog(<ComponentContract>[
        ComponentContract(
          type: 'Text',
          properties: const <String, PropertyContract>{
            'text': PropertyContract(
              type: PrototypePropertyType.string,
              required: true,
            ),
          },
        ),
      ]),
    );

    final String first =
        await agent.generate(const PrototypeBrief(text: 'Primeira tela'));
    await agent.generate(const PrototypeBrief(text: 'Refine a tela'));

    expect(jsonDecode(first), contains('specVersion'));
    expect(transport.requests.first['catalog'], isA<Map<Object?, Object?>>());
    expect(transport.requests.last['conversationId'], 'conversation-1');
  });

  test('returns clarification turns without pretending they are contracts',
      () async {
    final _RecordingTransport transport = _RecordingTransport(
      clarification: true,
    );
    final GatewayPrototypeAgent agent = GatewayPrototypeAgent(
      id: 'opencode',
      label: 'OpenCode',
      providerId: 'opencode',
      transport: transport,
      catalog: PrototypeCatalog(<ComponentContract>[
        ComponentContract(type: 'Divider'),
      ]),
    );

    final PrototypeAgentTurn turn = await agent.respond(
      const PrototypeBrief(text: 'Quero uma tela de cadastro'),
    );

    expect(turn.isClarification, isTrue);
    expect(turn.question, contains('editar'));
    expect(turn.options, <String>['Somente criar', 'Criar e editar']);
  });
}

class _RecordingTransport implements GatewayTransport {
  _RecordingTransport({this.clarification = false});

  final bool clarification;
  final List<Map<String, Object?>> requests = <Map<String, Object?>>[];

  @override
  Future<Map<String, Object?>> getJson(String path) async =>
      <String, Object?>{'status': 'ok'};

  @override
  Future<Map<String, Object?>> postJson(
    String path,
    Map<String, Object?> body,
  ) async {
    requests.add(body);
    if (clarification) {
      return <String, Object?>{
        'protocolVersion': '1',
        'providerId': 'opencode',
        'conversationId': 'conversation-1',
        'kind': 'clarification',
        'clarification': <String, Object?>{
          'question': 'A tela deve permitir editar registros?',
          'options': <String>['Somente criar', 'Criar e editar'],
        },
      };
    }
    return <String, Object?>{
      'protocolVersion': '1',
      'providerId': 'opencode',
      'conversationId': 'conversation-1',
      'document': <String, Object?>{
        'specVersion': '1.0',
        'screen': <String, Object?>{},
      },
    };
  }
}
