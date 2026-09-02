import '../../domain/prototype_provider.dart';
import 'opencode_api_client.dart';
import 'opencode_host.dart';

class OpenCodePrototypeProvider implements PrototypeProvider {
  OpenCodePrototypeProvider({
    required OpenCodeHost host,
    required OpenCodeApiClient client,
  })  : _host = host,
        _client = client;

  final OpenCodeHost _host;
  final OpenCodeApiClient _client;

  @override
  String get id => 'opencode';

  @override
  Future<ProviderHealth> health() => _host.health();

  @override
  Future<ProviderGenerationOutput> generate(
    ProviderGenerationInput input,
  ) =>
      _client.generate(input);

  @override
  Future<void> close() => _host.close();
}
