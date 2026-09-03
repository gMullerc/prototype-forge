import 'dart:async';
import 'dart:io';

import 'package:prototype_tool_discovery/prototype_tool_discovery.dart';

class ProcessToolProbe implements ToolProbe {
  const ProcessToolProbe({this.timeout = const Duration(seconds: 2)});

  final Duration timeout;

  @override
  Future<DiscoveredTool> probe(ToolDefinition definition) async {
    final String? executablePath = await _resolve(definition.executable);
    if (executablePath == null) {
      return DiscoveredTool(
        definition: definition,
        availability: ToolAvailability.notFound,
      );
    }

    try {
      final ProcessResult result = await Process.run(
        definition.executable,
        const <String>['--version'],
        runInShell: Platform.isWindows,
      ).timeout(timeout);
      final String? version =
          _firstLine(result.stdout) ?? _firstLine(result.stderr);
      return DiscoveredTool(
        definition: definition,
        availability: ToolAvailability.available,
        executablePath: executablePath,
        version: version,
      );
    } on TimeoutException {
      return DiscoveredTool(
        definition: definition,
        availability: ToolAvailability.available,
        executablePath: executablePath,
        diagnostic:
            'Executável detectado, mas não respondeu ao probe de versão.',
      );
    } on Object {
      return DiscoveredTool(
        definition: definition,
        availability: ToolAvailability.available,
        executablePath: executablePath,
        diagnostic: 'Executável detectado, mas a versão não pôde ser lida.',
      );
    }
  }

  Future<String?> _resolve(String executable) async {
    final String resolver = Platform.isWindows ? 'where' : 'which';
    try {
      final ProcessResult result = await Process.run(
        resolver,
        <String>[executable],
        runInShell: Platform.isWindows,
      ).timeout(timeout);
      if (result.exitCode != 0) return null;
      return _firstLine(result.stdout);
    } on Object {
      return null;
    }
  }

  String? _firstLine(Object? value) {
    final String raw = '$value'.trim();
    if (raw.isEmpty || raw == 'null') return null;
    final String line = raw.split(RegExp(r'\r?\n')).first.trim();
    if (line.isEmpty) return null;
    return line.length <= 160 ? line : line.substring(0, 160);
  }
}
