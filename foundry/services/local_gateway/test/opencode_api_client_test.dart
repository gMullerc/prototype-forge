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
        modelId: 'gpt-5.6-luna',
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
    expect(promptBody.containsKey('format'), isFalse);
    expect(promptBody['system'], 'Retorne JSON');
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

  test('reads a clarification envelope returned by OpenCode', () async {
    final OpenCodeApiClient client = OpenCodeApiClient(
      configuration: _configuration,
      host: _FakeOpenCodeHost(),
      transport: _FakeJsonTransport(clarification: true),
    );

    final ProviderGenerationOutput result = await client.generate(
      const ProviderGenerationInput(
        userPrompt: 'Crie uma tela',
        systemPrompt: 'Retorne uma pergunta JSON',
        outputSchema: <String, Object?>{'type': 'object'},
      ),
    );

    expect(result.isClarification, isTrue);
    expect(result.clarification?.question, contains('editar'));
    expect(result.clarification?.options, <String>[
      'Somente criar',
      'Criar e editar',
    ]);
  });

  test('recovers completed text from the session when POST omits it', () async {
    final OpenCodeApiClient client = OpenCodeApiClient(
      configuration: _configuration,
      host: _FakeOpenCodeHost(),
      transport: _FakeJsonTransport(requiresSessionRecovery: true),
    );

    final ProviderGenerationOutput result = await client.generate(
      const ProviderGenerationInput(
        userPrompt: 'Crie uma tela',
        systemPrompt: 'Retorne JSON',
        outputSchema: <String, Object?>{'type': 'object'},
      ),
    );

    expect(result.document['specVersion'], '1.0');
  });

  test('classifies structured output failures as invalid responses', () async {
    final OpenCodeApiClient client = OpenCodeApiClient(
      configuration: _configuration,
      host: _FakeOpenCodeHost(),
      transport: _FakeJsonTransport(structuredError: true),
    );

    await expectLater(
      client.generate(
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

  test('recovers a completed turn when OpenCode reports a structured error',
      () async {
    final OpenCodeApiClient client = OpenCodeApiClient(
      configuration: _configuration,
      host: _FakeOpenCodeHost(),
      transport: _FakeJsonTransport(structuredErrorWithRecovery: true),
    );

    final ProviderGenerationOutput result = await client.generate(
      const ProviderGenerationInput(
        userPrompt: 'Crie uma tela',
        systemPrompt: 'Retorne JSON',
        outputSchema: <String, Object?>{'type': 'object'},
      ),
    );

    expect(result.document['specVersion'], '1.0');
  });

  test('classifies transport timeout as a provider timeout', () async {
    final _FakeJsonTransport transport = _FakeJsonTransport(timeoutError: true);
    final OpenCodeApiClient client = OpenCodeApiClient(
      configuration: _configuration,
      host: _FakeOpenCodeHost(),
      transport: transport,
    );

    await expectLater(
      client.generate(
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
    expect(
      transport.uris.any((Uri uri) => uri.path.endsWith('/abort')),
      isTrue,
    );
  });

  test('recovers a completed turn before aborting after a transport timeout',
      () async {
    final _FakeJsonTransport transport = _FakeJsonTransport(
      timeoutError: true,
      timeoutRecovery: true,
    );
    final OpenCodeApiClient client = OpenCodeApiClient(
      configuration: _configuration,
      host: _FakeOpenCodeHost(),
      transport: transport,
    );

    final ProviderGenerationOutput result = await client.generate(
      const ProviderGenerationInput(
        userPrompt: 'Crie uma tela',
        systemPrompt: 'Retorne JSON',
        outputSchema: <String, Object?>{'type': 'object'},
      ),
    );

    expect(result.document['specVersion'], '1.0');
    expect(
      transport.uris.any((Uri uri) => uri.path.endsWith('/abort')),
      isFalse,
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

  test('uses GPT-5.6 Luna when no model override is provided', () {
    final OpenCodeConfiguration configuration =
        OpenCodeConfiguration.fromEnvironment(const <String, String>{});

    expect(configuration.model, 'openai/gpt-5.6-luna');
  });
}

const OpenCodeConfiguration _configuration = OpenCodeConfiguration(
  executable: 'opencode',
  host: '127.0.0.1',
  port: 4096,
  workspaceDirectory: 'workspace',
  providerId: 'openai',
  modelId: 'gpt-5.6-luna',
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
    this.timeoutRecovery = false,
    this.structuredErrorWithRecovery = false,
    this.requiresSessionRecovery = false,
    this.clarification = false,
  });

  final bool structured;
  final bool structuredError;
  final bool timeoutError;
  final bool timeoutRecovery;
  final bool structuredErrorWithRecovery;
  final bool requiresSessionRecovery;
  final bool clarification;
  final List<Map<String, Object?>> bodies = <Map<String, Object?>>[];
  final List<Uri> uris = <Uri>[];

  @override
  Future<Object?> send({
    required String method,
    required Uri uri,
    Object? body,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    uris.add(uri);
    if (timeoutError && method == 'POST' && uri.path.endsWith('/message')) {
      throw const JsonHttpException(
        code: 'timeout',
        message: 'timeout',
      );
    }
    if (body is Map<String, Object?>) bodies.add(body);
    if (uri.path == '/session') {
      return <String, Object?>{'id': 'ses_test'};
    }
    if (uri.path.endsWith('/abort')) return true;
    if (structuredErrorWithRecovery &&
        method == 'POST' &&
        uri.path.endsWith('/message')) {
      return <String, Object?>{
        'info': <String, Object?>{
          'error': <String, Object?>{
            'name': 'StructuredOutputError',
          },
        },
        'parts': <Object?>[],
      };
    }
    if ((requiresSessionRecovery ||
            timeoutRecovery ||
            structuredErrorWithRecovery) &&
        method == 'GET') {
      return <Object?>[
        <String, Object?>{
          'info': <String, Object?>{'role': 'assistant'},
          'parts': <Object?>[
            <String, Object?>{
              'type': 'text',
              'text':
                  '{"specVersion":"1.0","screen":{"id":"a","title":"A","root":{"id":"root","type":"Divider"}}}',
            },
          ],
        },
      ];
    }
    if (requiresSessionRecovery) {
      return <String, Object?>{
        'info': <String, Object?>{},
        'parts': <Object?>[],
      };
    }
    if (clarification) {
      return <String, Object?>{
        'info': <String, Object?>{},
        'parts': <Object?>[
          <String, Object?>{
            'type': 'text',
            'text':
                '{"type":"clarification","question":"A tela deve permitir editar registros?","options":["Somente criar","Criar e editar"]}',
          },
        ],
      };
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
