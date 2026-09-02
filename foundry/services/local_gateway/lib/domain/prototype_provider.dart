class ProviderHealth {
  const ProviderHealth({
    required this.available,
    this.version,
    this.message,
  });

  final bool available;
  final String? version;
  final String? message;
}

class ProviderGenerationInput {
  const ProviderGenerationInput({
    required this.userPrompt,
    required this.systemPrompt,
    required this.outputSchema,
    this.conversationId,
  });

  final String userPrompt;
  final String systemPrompt;
  final Map<String, Object?> outputSchema;
  final String? conversationId;
}

class ProviderGenerationOutput {
  const ProviderGenerationOutput({
    required this.conversationId,
    required this.document,
  });

  final String conversationId;
  final Map<String, Object?> document;
}

abstract interface class PrototypeProvider {
  String get id;

  Future<ProviderHealth> health();

  Future<ProviderGenerationOutput> generate(ProviderGenerationInput input);

  Future<void> close();
}

class PrototypeProviderRegistry {
  PrototypeProviderRegistry(Iterable<PrototypeProvider> providers)
      : _providers = <String, PrototypeProvider>{
          for (final PrototypeProvider provider in providers)
            provider.id: provider,
        } {
    if (_providers.isEmpty) {
      throw ArgumentError('Ao menos um provider precisa ser registrado.');
    }
  }

  final Map<String, PrototypeProvider> _providers;

  Iterable<PrototypeProvider> get providers => _providers.values;

  PrototypeProvider? find(String id) => _providers[id];

  Future<void> close() async {
    await Future.wait<void>(
      _providers.values.map((PrototypeProvider provider) => provider.close()),
    );
  }
}
