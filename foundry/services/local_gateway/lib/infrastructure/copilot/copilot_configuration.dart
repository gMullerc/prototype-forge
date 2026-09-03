import 'dart:io';

class CopilotConfiguration {
  const CopilotConfiguration({
    required this.executable,
    required this.workspaceDirectory,
    this.model,
    this.generationTimeout = const Duration(seconds: 90),
  });

  factory CopilotConfiguration.fromEnvironment(
    Map<String, String> environment,
  ) {
    return CopilotConfiguration(
      executable: environment['PROTOTYPE_COPILOT_EXECUTABLE'] ?? 'copilot',
      workspaceDirectory:
          environment['PROTOTYPE_WORKSPACE'] ?? Directory.current.path,
      model: _nonEmpty(environment['PROTOTYPE_COPILOT_MODEL']),
      generationTimeout: Duration(
        seconds: _positiveInt(
          environment['PROTOTYPE_COPILOT_TIMEOUT_SECONDS'],
          defaultValue: 90,
          variableName: 'PROTOTYPE_COPILOT_TIMEOUT_SECONDS',
        ),
      ),
    );
  }

  final String executable;
  final String workspaceDirectory;
  final String? model;
  final Duration generationTimeout;

  static String? _nonEmpty(String? value) {
    final String? trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static int _positiveInt(
    String? value, {
    required int defaultValue,
    required String variableName,
  }) {
    if (value == null || value.trim().isEmpty) return defaultValue;
    final int? parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      throw FormatException(
        '$variableName deve ser um número inteiro positivo.',
      );
    }
    return parsed;
  }
}
