import 'package:prototype_local_gateway/domain/prototype_provider.dart';
import 'package:prototype_local_gateway/infrastructure/opencode/json_http_transport.dart';
import 'package:prototype_local_gateway/infrastructure/opencode/opencode_api_client.dart';
import 'package:prototype_local_gateway/infrastructure/opencode/opencode_configuration.dart';
import 'package:prototype_local_gateway/infrastructure/opencode/opencode_host.dart';
import 'package:test/test.dart';

void main() {
  test('isolates OpenCode request details and parses text JSON', () async {
    final _FakeOpenCodeHost host = _FakeOpenCodeHost();
    final _FakeJsonTransport transport = _FakeJsonTransport();
    final OpenCodeApiClient client = OpenCodeApiClient(
      configuration: const OpenCodeConfiguration(
        executable: 'opencode',
        host: '127.0.0.1',
        port: 4096,
        workspaceDirectory: 'workspace',
        providerId: 'openai',
        modelId: 'gpt-5.4-mini',
      ),
      host: host,
      transport: transport,
    );

    final ProviderGenerationOutput result = await client.generate(
      ProviderGenerationInput(
        userPrompt: 'Crie uma tela',
        systemPrompt: 'Retorne JSON',
        outputSchema: <String, Object?>{'type': 'object'},
      ),
    );

    expect(result.conversationId, 'ses_test');
    expect(result.document['specVersion'], '1.0');
    expect(host.ensureCalls, 1);
    final Map<String, Object?> sessionBody = transport.bodies.first;
    expect(sessionBody, <String, Object?>{'title': 'Prototype Foundry'});
    final Map<String, Object?> promptBody = transport.bodies.last;
    expect(
      promptBody['format'],
      containsPair('type', 'json_schema'),
    );
    expect(
      (promptBody['format'] as Map<String, Object?>)['schema'],
      containsPair('type', 'object'),
    );
    final Map<String, Object?> transportSchema = (promptBody['format']
        as Map<String, Object?>)['schema']! as Map<String, Object?>;
    expect(
      transportSchema['properties'],
      containsPair('specVersion', containsPair('type', 'string')),
    );
    expect(
      transportSchema['properties'],
      containsPair('screen', containsPair('type', 'object')),
    );
    expect(
      (promptBody['format'] as Map<String, Object?>).containsKey('retryCount'),
      isFalse,
    );
    expect(promptBody['tools'], containsPair('bash', false));
  });

  test('reads structured output returned by OpenCode', () async {
    final OpenCodeApiClient client = OpenCodeApiClient(
      configuration: _configuration,
      host: _FakeOpenCodeHost(),
      transport: _FakeJsonTransport(structured: true),
    );

    final ProviderGenerationOutput result = await client.generate(
      const ProviderGenerationInput(
        userPrompt: 'Crie uma tela',
        systemPrompt: 'Retorne JSON',
        outputSchema: <String, Object?>{'type': 'object'},
      ),
    );

    expect(result.document['screen'], isA<Map<Object?, Object?>>());
  });

  test('classifies structured output failures as invalid responses', () async {
    final OpenCodeApiClient client = OpenCodeApiClient(
      configuration: _configuration,
      host: _FakeOpenCodeHost(),
      transport: _FakeJsonTransport(structuredError: true),
    );

    expect(
      () => client.generate(
        const ProviderGenerationInput(
          userPrompt: 'Crie uma tela',
          systemPrompt: 'Retorne JSON',
          outputSchema: <String, Object?>{'type': 'object'},
        ),
      ),
      throwsA(
        isA<ProviderGenerationException>().having(
          (ProviderGenerationException error) => error.code,
          'code',
          'provider_response_invalid',
        ),
      ),
    );
  });

  test('classifies transport timeout as a provider timeout', () async {
    final OpenCodeApiClient client = OpenCodeApiClient(
      configuration: _configuration,
      host: _FakeOpenCodeHost(),
      transport: _FakeJsonTransport(timeoutError: true),
    );

    expect(
      () => client.generate(
        const ProviderGenerationInput(
          userPrompt: 'Crie uma tela',
          systemPrompt: 'Retorne JSON',
          outputSchema: <String, Object?>{'type': 'object'},
        ),
      ),
      throwsA(
        isA<ProviderGenerationException>().having(
          (ProviderGenerationException error) => error.code,
          'code',
          'provider_timeout',
        ),
      ),
    );
  });

  test('reads the generation timeout from the environment', () {
    final OpenCodeConfiguration configuration =
        OpenCodeConfiguration.fromEnvironment(
      const <String, String>{
        'PROTOTYPE_OPENCODE_MODEL': 'openai/gpt-5.4',
        'PROTOTYPE_OPENCODE_TIMEOUT_SECONDS': '42',
      },
    );

    expect(configuration.generationTimeout, const Duration(seconds: 42));
  });
}

const OpenCodeConfiguration _configuration = OpenCodeConfiguration(
  executable: 'opencode',
  host: '127.0.0.1',
  port: 4096,
  workspaceDirectory: 'workspace',
  providerId: 'openai',
  modelId: 'gpt-5.4-mini',
);

class _FakeOpenCodeHost implements OpenCodeHost {
  int ensureCalls = 0;

  @override
  Future<void> close() async {}

  @override
  Future<void> ensureReady() async => ensureCalls++;

  @override
  Future<ProviderHealth> health() async =>
      const ProviderHealth(available: true);
}

class _FakeJsonTransport implements JsonHttpTransport {
  _FakeJsonTransport({
    this.structured = false,
    this.structuredError = false,
    this.timeoutError = false,
  });

  final bool structured;
  final bool structuredError;
  final bool timeoutError;
  final List<Map<String, Object?>> bodies = <Map<String, Object?>>[];

  @override
  Future<Object?> send({
    required String method,
    required Uri uri,
    Object? body,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    if (timeoutError) {
      throw const JsonHttpException(
        code: 'timeout',
        message: 'timeout',
      );
    }
    if (body is Map<String, Object?>) bodies.add(body);
    if (uri.path == '/session') {
      return <String, Object?>{'id': 'ses_test'};
    }
    if (structured) {
      return <String, Object?>{
        'info': <String, Object?>{
          'structured': <String, Object?>{
            'specVersion': '1.0',
            'screen': <String, Object?>{
              'id': 'a',
              'title': 'A',
              'root': <String, Object?>{
                'id': 'root',
                'type': 'Divider',
              },
            },
          },
        },
        'parts': <Object?>[],
      };
    }
    if (structuredError) {
      return <String, Object?>{
        'info': <String, Object?>{
          'error': <String, Object?>{
            'name': 'StructuredOutputError',
            'data': <String, Object?>{
              'message': 'invalid',
              'retries': 2,
            },
          },
        },
        'parts': <Object?>[],
      };
    }
    return <String, Object?>{
      'info': <String, Object?>{},
      'parts': <Object?>[
        <String, Object?>{
          'type': 'text',
          'text':
              '{"specVersion":"1.0","screen":{"id":"a","title":"A","root":{"id":"root","type":"Divider"}}}',
        },
      ],
    };
  }
}
