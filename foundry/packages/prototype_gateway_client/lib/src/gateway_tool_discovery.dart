import 'package:prototype_gateway_protocol/prototype_gateway_protocol.dart';
import 'package:prototype_tool_discovery/prototype_tool_discovery.dart';

import 'gateway_transport.dart';

class GatewayToolDiscovery implements ToolDiscovery {
  const GatewayToolDiscovery({required GatewayTransport transport})
      : _transport = transport;

  final GatewayTransport _transport;

  @override
  Future<List<DiscoveredTool>> discover() async {
    final Map<String, Object?> payload =
        await _transport.getJson(gatewayToolsPath);
    final GatewayToolsResponse response =
        GatewayToolsResponse.fromJson(payload);
    return response.tools
        .map(
          (GatewayToolInfo tool) => DiscoveredTool(
            definition: ToolDefinition(
              id: tool.id,
              label: tool.label,
              executable: tool.executable,
              capabilities: tool.capabilities,
              setupHint: tool.setupHint,
            ),
            availability: _availability(tool.status),
            executablePath: tool.executablePath,
            version: tool.version,
            diagnostic: tool.diagnostic,
          ),
        )
        .toList(growable: false);
  }

  ToolAvailability _availability(String status) => switch (status) {
        'available' => ToolAvailability.available,
        'not_found' => ToolAvailability.notFound,
        _ => ToolAvailability.probeError,
      };
}
