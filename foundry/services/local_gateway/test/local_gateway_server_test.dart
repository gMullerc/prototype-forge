import 'dart:convert';
import 'dart:io';

import 'package:prototype_gateway_protocol/prototype_gateway_protocol.dart';
import 'package:prototype_local_gateway/application/generate_prototype.dart';
import 'package:prototype_local_gateway/application/prototype_contract_builder.dart';
import 'package:prototype_local_gateway/domain/prototype_provider.dart';
import 'package:prototype_local_gateway/interface/http/local_gateway_server.dart';
import 'package:test/test.dart';

void main() {
  test('serves the versioned local protocol over HTTP', () async {
    final _HttpFakeProvider provider = _HttpFakeProvider();
    final PrototypeProviderRegistry providers =
        PrototypeProviderRegistry(<PrototypeProvider>[provider]);
    final LocalGatewayServer server = LocalGatewayServer(
      host: '127.0.0.1',
      port: 0,
      generatePrototype: GeneratePrototype(
        providers: providers,
        contractBuilder: const PrototypeSpecContractBuilder(),
      ),
      providers: providers,
    );
    final Future<void> running = server.start();
    while (server.boundPort == null) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    addTearDown(() async {
      await server.close();
      await running;
    });

    final HttpClient client = HttpClient();
    addTearDown(client.close);
    final Uri endpoint = Uri.parse(
      'http://127.0.0.1:${server.boundPort}$gatewayGeneratePath',
    );
    final HttpClientRequest request = await client.postUrl(endpoint);
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode(
        GatewayGenerateRequest(
          providerId: 'fake',
          prompt: 'Crie uma tela',
          catalog: GatewayCatalogContract(<GatewayComponentContract>[
            GatewayComponentContract(type: 'Divider'),
          ]),
        ).toJson(),
      ),
    );
    final HttpClientResponse response = await request.close();
    final Map<String, Object?> payload = Map<String, Object?>.from(
      jsonDecode(await utf8.decoder.bind(response).join()) as Map,
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(payload['providerId'], 'fake');
  });
}

class _HttpFakeProvider implements PrototypeProvider {
  @override
  String get id => 'fake';

  @override
  Future<void> close() async {}

  @override
  Future<ProviderGenerationOutput> generate(
    ProviderGenerationInput input,
  ) async =>
      ProviderGenerationOutput(
        conversationId: 'conversation',
        document: <String, Object?>{
          'specVersion': '1.0',
          'screen': <String, Object?>{
            'id': 'screen',
            'title': 'Screen',
            'root': <String, Object?>{
              'id': 'root',
              'type': 'Divider',
            },
          },
        },
      );

  @override
  Future<ProviderHealth> health() async =>
      const ProviderHealth(available: true, version: 'test');
}
