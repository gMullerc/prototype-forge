enum ToolAvailability {
  available,
  notFound,
  probeError,
}

class ToolDefinition {
  const ToolDefinition({
    required this.id,
    required this.label,
    required this.executable,
    required this.capabilities,
    this.setupHint,
  });

  final String id;
  final String label;
  final String executable;
  final List<String> capabilities;
  final String? setupHint;
}

class DiscoveredTool {
  const DiscoveredTool({
    required this.definition,
    required this.availability,
    this.executablePath,
    this.version,
    this.diagnostic,
  });

  final ToolDefinition definition;
  final ToolAvailability availability;
  final String? executablePath;
  final String? version;
  final String? diagnostic;

  bool get isAvailable => availability == ToolAvailability.available;
}

abstract interface class ToolDiscovery {
  Future<List<DiscoveredTool>> discover();
}

abstract interface class ToolProbe {
  Future<DiscoveredTool> probe(ToolDefinition definition);
}

class LocalToolDiscovery implements ToolDiscovery {
  LocalToolDiscovery({
    Iterable<ToolDefinition> definitions = defaultToolDefinitions,
    required ToolProbe probe,
  })  : _definitions = List<ToolDefinition>.unmodifiable(definitions),
        _probe = probe;

  final List<ToolDefinition> _definitions;
  final ToolProbe _probe;

  @override
  Future<List<DiscoveredTool>> discover() async {
    return List<DiscoveredTool>.unmodifiable(
      await Future.wait<DiscoveredTool>(
        _definitions.map(_probe.probe),
      ),
    );
  }
}

const List<ToolDefinition> defaultToolDefinitions = <ToolDefinition>[
  ToolDefinition(
    id: 'opencode',
    label: 'OpenCode',
    executable: 'opencode',
    capabilities: <String>['agent', 'prototype-generation'],
    setupHint: 'opencode auth login',
  ),
  ToolDefinition(
    id: 'copilot-cli',
    label: 'GitHub Copilot CLI',
    executable: 'copilot',
    capabilities: <String>['agent'],
    setupHint: 'copilot login',
  ),
  ToolDefinition(
    id: 'codex-cli',
    label: 'OpenAI Codex CLI',
    executable: 'codex',
    capabilities: <String>['agent'],
    setupHint: 'codex --login',
  ),
  ToolDefinition(
    id: 'claude-code',
    label: 'Claude Code',
    executable: 'claude',
    capabilities: <String>['agent'],
    setupHint: 'claude',
  ),
  ToolDefinition(
    id: 'gemini-cli',
    label: 'Gemini CLI',
    executable: 'gemini',
    capabilities: <String>['agent'],
    setupHint: 'gemini',
  ),
  ToolDefinition(
    id: 'aider',
    label: 'Aider',
    executable: 'aider',
    capabilities: <String>['agent'],
    setupHint: 'aider',
  ),
];
