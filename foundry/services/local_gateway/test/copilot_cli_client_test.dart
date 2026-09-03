import 'package:prototype_local_gateway/domain/prototype_provider.dart';
import 'package:prototype_local_gateway/infrastructure/copilot/copilot_cli_client.dart';
import 'package:prototype_local_gateway/infrastructure/copilot/copilot_configuration.dart';
import 'package:prototype_local_gateway/infrastructure/copilot/copilot_process_runner.dart';
import 'package:test/test.dart';

void main() {
  test('generates a contract through Copilot programmatic mode', () async {
    final _FakeCopilotRunner runner = _FakeCopilotRunner(
      const CopilotProcessResult(
        exitCode: 0,
        stdout: '''
Here is the requested contract:
{"specVersion":"1.0","screen":{"id":"screen","title":"Tela","root":{"id":"root","type":"Divider"}}}
''',
        stderr: '',
      ),
    );
    final CopilotCliClient client = _client(runner);

    final ProviderGenerationOutput output = await client.generate(
      const ProviderGenerationInput(
        userPrompt: 'Crie uma tela de pagamento',
        systemPrompt: 'Use apenas o contrato aprovado.',
        outputSchema: <String, Object?>{},
      ),
    );

    expect(output.document['specVersion'], '1.0');
    expect(output.conversationId, startsWith('copilot-'));
    expect(runner.arguments, contains('-p'));
    expect(runner.arguments, contains('--allow-all-tools'));
    expect(runner.arguments, contains('--disable-builtin-mcps'));
    expect(runner.arguments, contains('shell,write,read,url,memory'));
    expect(
      runner.arguments[runner.arguments.indexOf('-p') + 1],
      contains('Output contract schema:'),
    );
  });

  test('turns authentication failures into a safe provider diagnostic',
      () async {
    final CopilotCliClient client = _client(
      _FakeCopilotRunner(
        const CopilotProcessResult(
          exitCode: 1,
          stdout: '',
          stderr: 'Please log in before using Copilot CLI.',
        ),
      ),
    );

    await expectLater(
      client.generate(_input),
      throwsA(
        isA<ProviderGenerationException>().having(
          (ProviderGenerationException error) => error.code,
          'code',
          'provider_not_authenticated',
        ),
      ),
    );
  });

  test('rejects output that is not a contract object', () async {
    final CopilotCliClient client = _client(
      _FakeCopilotRunner(
        const CopilotProcessResult(
          exitCode: 0,
          stdout: 'Não consegui gerar JSON.',
          stderr: '',
        ),
      ),
    );

    await expectLater(
      client.generate(_input),
      throwsA(
        isA<ProviderGenerationException>().having(
          (ProviderGenerationException error) => error.code,
          'code',
          'provider_response_invalid',
        ),
      ),
    );
  });

  test('reports the installed Copilot version through health', () async {
    final CopilotCliClient client = _client(
      _FakeCopilotRunner(
        const CopilotProcessResult(
          exitCode: 0,
          stdout: '0.0.369-0\n',
          stderr: '',
        ),
      ),
    );

    final ProviderHealth health = await client.health();

    expect(health.available, isTrue);
    expect(health.version, '0.0.369-0');
  });
}

const ProviderGenerationInput _input = ProviderGenerationInput(
  userPrompt: 'Crie uma tela',
  systemPrompt: 'Use apenas componentes registrados.',
  outputSchema: <String, Object?>{},
);

CopilotCliClient _client(_FakeCopilotRunner runner) => CopilotCliClient(
      configuration: const CopilotConfiguration(
        executable: 'copilot',
        workspaceDirectory: '.',
        model: 'gpt-5.1-codex',
      ),
      runner: runner,
    );

class _FakeCopilotRunner implements CopilotProcessRunner {
  _FakeCopilotRunner(this.result);

  final CopilotProcessResult result;
  List<String> arguments = const <String>[];

  @override
  Future<CopilotProcessResult> run({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    required Duration timeout,
  }) async {
    this.arguments = arguments;
    return result;
  }

  @override
  Future<void> close() async {}
}
