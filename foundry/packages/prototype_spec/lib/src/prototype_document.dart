class PrototypeDocument {
  const PrototypeDocument({
    required this.specVersion,
    required this.screen,
    this.interaction,
  });

  final String specVersion;
  final PrototypeScreen screen;
  final PrototypeInteractionSpec? interaction;
}

class PrototypeScreen {
  const PrototypeScreen({
    required this.id,
    required this.title,
    required this.root,
  });

  final String id;
  final String title;
  final PrototypeNode root;
}

class PrototypeNode {
  PrototypeNode({
    required this.id,
    required this.type,
    Map<String, Object?> props = const <String, Object?>{},
    List<PrototypeNode> children = const <PrototypeNode>[],
    this.interaction,
  })  : props = Map<String, Object?>.unmodifiable(props),
        children = List<PrototypeNode>.unmodifiable(children);

  final String id;
  final String type;
  final Map<String, Object?> props;
  final List<PrototypeNode> children;
  final PrototypeNodeInteraction? interaction;
}

class PrototypeInteractionSpec {
  PrototypeInteractionSpec({
    Map<String, Object?> initialState = const <String, Object?>{},
    List<PrototypeActionDefinition> actions =
        const <PrototypeActionDefinition>[],
  })  : initialState = Map<String, Object?>.unmodifiable(initialState),
        actions = List<PrototypeActionDefinition>.unmodifiable(actions);

  final Map<String, Object?> initialState;
  final List<PrototypeActionDefinition> actions;

  PrototypeActionDefinition? actionFor(String name) {
    for (final PrototypeActionDefinition action in actions) {
      if (action.name == name) return action;
    }
    return null;
  }
}

class PrototypeActionDefinition {
  PrototypeActionDefinition({
    required this.name,
    required List<PrototypeEffect> effects,
  }) : effects = List<PrototypeEffect>.unmodifiable(effects);

  final String name;
  final List<PrototypeEffect> effects;
}

class PrototypeEffect {
  const PrototypeEffect({
    required this.type,
    this.key,
    this.value,
    this.message,
    this.tone,
  });

  final String type;
  final String? key;
  final Object? value;
  final String? message;
  final String? tone;
}

class PrototypeNodeInteraction {
  PrototypeNodeInteraction({
    this.valueKey,
    this.required = false,
    this.visibleWhen,
    this.selectedWhen,
    List<PrototypeValidationRule> validations =
        const <PrototypeValidationRule>[],
  }) : validations = List<PrototypeValidationRule>.unmodifiable(validations);

  final String? valueKey;
  final bool required;
  final PrototypeStateCondition? visibleWhen;
  final PrototypeStateCondition? selectedWhen;
  final List<PrototypeValidationRule> validations;
}

class PrototypeStateCondition {
  const PrototypeStateCondition({required this.key, required this.equals});

  final String key;
  final Object? equals;
}

class PrototypeValidationRule {
  const PrototypeValidationRule({required this.type, this.value});

  final String type;
  final Object? value;
}

class PrototypeSpecException implements Exception {
  const PrototypeSpecException(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => 'PrototypeSpecException($path): $message';
}
