import 'dart:convert';

import '../../domain/prototype_provider.dart';
import 'copilot_configuration.dart';
import 'copilot_process_runner.dart';

class CopilotCliClient {
  CopilotCliClient({
    required CopilotConfiguration configuration,
    required CopilotProcessRunner runner,
  })  : _configuration = configuration,
        _runner = runner;

  final CopilotConfiguration _configuration;
  final CopilotProcessRunner _runner;

  Future<void> close() => _runner.close();

  Future<ProviderHealth> health() async {
    try {
      final CopilotProcessResult result = await _runner.run(
        executable: _configuration.executable,
        arguments: const <String>['--version'],
        workingDirectory: _configuration.workspaceDirectory,
        timeout: const Duration(seconds: 2),
      );
      if (result.exitCode == 0) {
        return ProviderHealth(
          available: true,
          version: _firstLine(result.stdout) ?? _firstLine(result.stderr),
        );
      }
      return const ProviderHealth(
        available: false,
        message: 'Copilot CLI não respondeu ao comando de versão.',
      );
    } on CopilotProcessTimeout {
      return const ProviderHealth(
        available: false,
        message: 'Copilot CLI excedeu o tempo de diagnóstico.',
      );
    } on Object {
      return const ProviderHealth(
        available: false,
        message: 'Copilot CLI não está disponível neste computador.',
      );
    }
  }

  Future<ProviderGenerationOutput> generate(
    ProviderGenerationInput input,
  ) async {
    final CopilotProcessResult result;
    try {
      result = await _runner.run(
        executable: _configuration.executable,
        arguments: _generationArguments(input),
        workingDirectory: _configuration.workspaceDirectory,
        timeout: _configuration.generationTimeout,
      );
    } on CopilotProcessTimeout {
      throw ProviderGenerationException(
        code: 'provider_timeout',
        message:
            'O Copilot CLI não respondeu dentro de ${_configuration.generationTimeout.inSeconds} segundos.',
      );
    } on Object {
      throw const ProviderGenerationException(
        code: 'provider_failure',
        message: 'Não foi possível iniciar o Copilot CLI.',
      );
    }

    if (result.exitCode != 0) {
      throw _failureFor(result);
    }
    final String output = result.stdout.trim();
    if (output.isEmpty) {
      throw _invalidResponse();
    }
    try {
      return ProviderGenerationOutput(
        conversationId: input.conversationId ??
            'copilot-${DateTime.now().microsecondsSinceEpoch}',
        document: _decodeDocument(output),
      );
    } on Object {
      throw _invalidResponse();
    }
  }

  List<String> _generationArguments(ProviderGenerationInput input) {
    final String prompt = '''
You are the Prototype Foundry contract composer. Return exactly one JSON object and no markdown, explanation or extra text.

${input.systemPrompt}

Product manager briefing:
${input.userPrompt}

Output contract schema:
${jsonEncode(input.outputSchema)}
''';
    return <String>[
      '-p',
      prompt,
      '-s',
      '--no-color',
      '--no-custom-instructions',
      '--disable-builtin-mcps',
      '--allow-all-tools',
      '--deny-tool',
      'shell,write,read,url,memory',
      if (_configuration.model != null) ...<String>[
        '--model',
        _configuration.model!,
      ],
    ];
  }

  ProviderGenerationException _failureFor(CopilotProcessResult result) {
    final String diagnostic =
        '${result.stdout}\n${result.stderr}'.toLowerCase();
    if (diagnostic.contains('log in') ||
        diagnostic.contains('login') ||
        diagnostic.contains('authenticate')) {
      return const ProviderGenerationException(
        code: 'provider_not_authenticated',
        message:
            'O Copilot CLI está instalado, mas não está autenticado. Faça login no próprio Copilot CLI e tente novamente.',
      );
    }
    return const ProviderGenerationException(
      code: 'provider_failure',
      message: 'O Copilot CLI retornou um erro durante a geração.',
    );
  }

  ProviderGenerationException _invalidResponse() {
    return const ProviderGenerationException(
      code: 'provider_response_invalid',
      message:
          'O Copilot CLI respondeu, mas não produziu um contrato JSON válido.',
    );
  }

  Map<String, Object?> _decodeDocument(String output) {
    final String normalized = _normalizeTextJson(output);
    final Object? decoded = jsonDecode(normalized);
    if (decoded is! Map<Object?, Object?>) {
      throw const FormatException('O contrato não é um objeto JSON.');
    }
    return <String, Object?>{
      for (final MapEntry<Object?, Object?> entry in decoded.entries)
        if (entry.key is String) entry.key! as String: entry.value,
    };
  }

  String _normalizeTextJson(String text) {
    String normalized = text
        .replaceFirst(RegExp(r'^\s*```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```\s*$'), '')
        .trim();
    final int start = normalized.indexOf('{');
    if (start > 0) normalized = normalized.substring(start);
    final int end = _balancedObjectEnd(normalized);
    if (end >= 0 && end < normalized.length - 1) {
      normalized = normalized.substring(0, end + 1);
    }
    return normalized;
  }

  int _balancedObjectEnd(String value) {
    int depth = 0;
    bool inString = false;
    bool escaped = false;
    for (int index = 0; index < value.length; index++) {
      final String character = value[index];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (character == '\\') {
          escaped = true;
        } else if (character == '"') {
          inString = false;
        }
        continue;
      }
      if (character == '"') {
        inString = true;
      } else if (character == '{') {
        depth++;
      } else if (character == '}') {
        depth--;
        if (depth == 0) return index;
      }
    }
    return -1;
  }

  String? _firstLine(String value) {
    final String line = value.trim().split(RegExp(r'\r?\n')).first.trim();
    return line.isEmpty ? null : line;
  }
}
