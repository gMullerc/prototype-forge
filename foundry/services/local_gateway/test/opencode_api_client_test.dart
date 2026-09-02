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
    final Map<String, Object?> promptBody = transport.bodies.last;
    expect(promptBody['format'], <String, Object?>{'type': 'text'});
    expect(promptBody['tools'], containsPair('bash', false));
  });
}

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
  final List<Map<String, Object?>> bodies = <Map<String, Object?>>[];

  @override
  Future<Object?> send({
    required String method,
    required Uri uri,
    Object? body,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    if (body is Map<String, Object?>) bodies.add(body);
    if (uri.path == '/session') {
      return <String, Object?>{'id': 'ses_test'};
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
