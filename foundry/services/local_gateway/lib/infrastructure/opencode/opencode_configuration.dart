import 'dart:io';

class OpenCodeConfiguration {
  const OpenCodeConfiguration({
    required this.executable,
    required this.host,
    required this.port,
    required this.workspaceDirectory,
    required this.providerId,
    required this.modelId,
    this.variant,
    this.generationTimeout = const Duration(seconds: 150),
  });

  factory OpenCodeConfiguration.fromEnvironment(
    Map<String, String> environment,
  ) {
    final String model =
        environment['PROTOTYPE_OPENCODE_MODEL'] ?? 'openai/gpt-5.6-luna';
    final int separator = model.indexOf('/');
    if (separator <= 0 || separator == model.length - 1) {
      throw FormatException(
        'PROTOTYPE_OPENCODE_MODEL deve usar provider/model: $model',
      );
    }
    final int generationTimeoutSeconds = _positiveInt(
      environment['PROTOTYPE_OPENCODE_TIMEOUT_SECONDS'],
      defaultValue: 150,
      variableName: 'PROTOTYPE_OPENCODE_TIMEOUT_SECONDS',
    );
    return OpenCodeConfiguration(
      executable: environment['PROTOTYPE_OPENCODE_EXECUTABLE'] ?? 'opencode',
      host: environment['PROTOTYPE_OPENCODE_HOST'] ?? '127.0.0.1',
      port: int.tryParse(environment['PROTOTYPE_OPENCODE_PORT'] ?? '') ?? 4096,
      workspaceDirectory:
          environment['PROTOTYPE_WORKSPACE'] ?? Directory.current.path,
      providerId: model.substring(0, separator),
      modelId: model.substring(separator + 1),
      variant: _nonEmpty(environment['PROTOTYPE_OPENCODE_VARIANT']),
      generationTimeout: Duration(seconds: generationTimeoutSeconds),
    );
  }

  final String executable;
  final String host;
  final int port;
  final String workspaceDirectory;
  final String providerId;
  final String modelId;
  final String? variant;
  final Duration generationTimeout;

  Uri get baseUri => Uri(scheme: 'http', host: host, port: port);

  String get model => '$providerId/$modelId';

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
          '$variableName deve ser um número inteiro positivo.');
    }
    return parsed;
  }
}
