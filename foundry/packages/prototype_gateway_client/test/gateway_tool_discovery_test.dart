import 'package:prototype_gateway_client/prototype_gateway_client.dart';
import 'package:prototype_gateway_protocol/prototype_gateway_protocol.dart';
import 'package:prototype_tool_discovery/prototype_tool_discovery.dart';
import 'package:test/test.dart';

void main() {
  test('maps the local tools response without checking credentials', () async {
    final GatewayToolDiscovery discovery = GatewayToolDiscovery(
      transport: _ToolsTransport(),
    );

    final tools = await discovery.discover();

    expect(tools, hasLength(2));
    expect(tools.first.definition.id, 'opencode');
    expect(tools.first.availability, ToolAvailability.available);
    expect(tools.first.version, '1.18.26');
    expect(tools.last.availability, ToolAvailability.notFound);
  });
}

class _ToolsTransport implements GatewayTransport {
  @override
  Future<Map<String, Object?>> getJson(String path) async =>
      GatewayToolsResponse(
        tools: <GatewayToolInfo>[
          const GatewayToolInfo(
            id: 'opencode',
            label: 'OpenCode',
            executable: 'opencode',
            status: 'available',
            capabilities: <String>['agent'],
            version: '1.18.26',
          ),
          const GatewayToolInfo(
            id: 'codex-cli',
            label: 'OpenAI Codex CLI',
            executable: 'codex',
            status: 'not_found',
            capabilities: <String>['agent'],
          ),
        ],
      ).toJson();

  @override
  Future<Map<String, Object?>> postJson(
    String path,
    Map<String, Object?> body,
  ) async =>
      <String, Object?>{};
}
