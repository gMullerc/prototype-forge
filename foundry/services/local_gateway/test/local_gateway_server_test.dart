import 'dart:convert';
import 'dart:io';

import 'package:prototype_gateway_protocol/prototype_gateway_protocol.dart';
import 'package:prototype_local_gateway/application/generate_prototype.dart';
import 'package:prototype_local_gateway/application/prototype_contract_builder.dart';
import 'package:prototype_local_gateway/domain/prototype_provider.dart';
import 'package:prototype_local_gateway/infrastructure/tools/tool_inventory.dart';
import 'package:prototype_local_gateway/interface/http/local_gateway_server.dart';
import 'package:prototype_tool_discovery/prototype_tool_discovery.dart';
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
      toolInventory: ToolInventory(_FakeToolDiscovery()),
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

    final HttpClientRequest toolsRequest = await client.getUrl(
      Uri.parse('http://127.0.0.1:${server.boundPort}$gatewayToolsPath'),
    );
    final HttpClientResponse toolsResponse = await toolsRequest.close();
    final Map<String, Object?> toolsPayload = Map<String, Object?>.from(
      jsonDecode(await utf8.decoder.bind(toolsResponse).join()) as Map,
    );
    expect(toolsResponse.statusCode, HttpStatus.ok);
    expect(toolsPayload['credentialsChecked'], isFalse);
    expect(
      (toolsPayload['tools'] as List).single['status'],
      'available',
    );
  });
}

class _FakeToolDiscovery implements ToolDiscovery {
  @override
  Future<List<DiscoveredTool>> discover() async => <DiscoveredTool>[
        const DiscoveredTool(
          definition: ToolDefinition(
            id: 'fake-tool',
            label: 'Fake Tool',
            executable: 'fake',
            capabilities: <String>['agent'],
          ),
          availability: ToolAvailability.available,
          version: '1.0.0',
        ),
      ];
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
