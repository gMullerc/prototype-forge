import 'package:prototype_tool_discovery/prototype_tool_discovery.dart';

class ToolInventory {
  const ToolInventory(this.discovery);

  final ToolDiscovery discovery;

  Future<List<DiscoveredTool>> call() => discovery.discover();
}
