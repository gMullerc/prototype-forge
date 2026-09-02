import 'package:prototype_tool_discovery/prototype_tool_discovery.dart';
import 'package:test/test.dart';

void main() {
  test('discovers registered tools through the injected probe', () async {
    final LocalToolDiscovery discovery = LocalToolDiscovery(
      definitions: const <ToolDefinition>[
        ToolDefinition(
          id: 'fake',
          label: 'Fake Tool',
          executable: 'fake',
          capabilities: <String>['agent'],
        ),
      ],
      probe: _FakeToolProbe(),
    );

    final List<DiscoveredTool> tools = await discovery.discover();

    expect(tools, hasLength(1));
    expect(tools.single.isAvailable, isTrue);
    expect(tools.single.version, '1.2.3');
  });

  test('keeps unavailable tools in the inventory', () async {
    final LocalToolDiscovery discovery = LocalToolDiscovery(
      definitions: const <ToolDefinition>[
        ToolDefinition(
          id: 'missing',
          label: 'Missing Tool',
          executable: 'missing',
          capabilities: <String>['agent'],
        ),
      ],
      probe: _MissingToolProbe(),
    );

    final List<DiscoveredTool> tools = await discovery.discover();

    expect(tools.single.availability, ToolAvailability.notFound);
    expect(tools.single.isAvailable, isFalse);
  });
}

class _FakeToolProbe implements ToolProbe {
  @override
  Future<DiscoveredTool> probe(ToolDefinition definition) async =>
      DiscoveredTool(
        definition: definition,
        availability: ToolAvailability.available,
        executablePath: r'C:\tools\fake.exe',
        version: '1.2.3',
      );
}

class _MissingToolProbe implements ToolProbe {
  @override
  Future<DiscoveredTool> probe(ToolDefinition definition) async =>
      DiscoveredTool(
        definition: definition,
        availability: ToolAvailability.notFound,
      );
}
