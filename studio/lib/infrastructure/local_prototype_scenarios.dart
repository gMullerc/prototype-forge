typedef LocalPrototypeDocumentBuilder = Map<String, Object?> Function(
  String brief,
);

class LocalPrototypeScenario {
  const LocalPrototypeScenario({
    required this.id,
    required this.keywords,
    required this.builder,
  });

  final String id;
  final List<String> keywords;
  final LocalPrototypeDocumentBuilder builder;

  bool matches(String brief) {
    final String normalized = brief.trim().toLowerCase();
    return keywords.any(
      (String keyword) => normalized.contains(keyword.toLowerCase()),
    );
  }
}

class LocalPrototypeScenarioRegistry {
  const LocalPrototypeScenarioRegistry({
    required this.scenarios,
    required this.fallback,
  });

  final List<LocalPrototypeScenario> scenarios;
  final LocalPrototypeDocumentBuilder fallback;

  LocalPrototypeScenario? match(String brief) {
    for (final LocalPrototypeScenario scenario in scenarios) {
      if (scenario.matches(brief)) return scenario;
    }
    return null;
  }

  Map<String, Object?> build(String brief) =>
      (match(brief)?.builder ?? fallback)(brief);
}
