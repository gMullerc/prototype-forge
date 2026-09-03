import '../../domain/prototype_provider.dart';
import 'copilot_cli_client.dart';

class CopilotPrototypeProvider implements PrototypeProvider {
  const CopilotPrototypeProvider({required CopilotCliClient client})
      : _client = client;

  final CopilotCliClient _client;

  @override
  String get id => 'copilot';

  @override
  Future<ProviderHealth> health() => _client.health();

  @override
  Future<ProviderGenerationOutput> generate(
    ProviderGenerationInput input,
  ) =>
      _client.generate(input);

  @override
  Future<void> close() => _client.close();
}
