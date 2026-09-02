enum PrototypePropertyType {
  string,
  number,
  boolean,
  object,
  list,
}

class PropertyContract {
  const PropertyContract({
    required this.type,
    this.required = false,
    this.allowedValues = const <Object>[],
  });

  final PrototypePropertyType type;
  final bool required;
  final List<Object> allowedValues;

  bool accepts(Object? value) {
    if (value == null) return !required;
    final bool hasExpectedType = switch (type) {
      PrototypePropertyType.string => value is String,
      PrototypePropertyType.number => value is num,
      PrototypePropertyType.boolean => value is bool,
      PrototypePropertyType.object => value is Map<Object?, Object?>,
      PrototypePropertyType.list => value is List<Object?>,
    };
    if (!hasExpectedType) return false;
    return allowedValues.isEmpty || allowedValues.contains(value);
  }
}

class ComponentContract {
  ComponentContract({
    required this.type,
    this.allowsChildren = false,
    Map<String, PropertyContract> properties =
        const <String, PropertyContract>{},
  }) : properties = Map<String, PropertyContract>.unmodifiable(properties);

  final String type;
  final bool allowsChildren;
  final Map<String, PropertyContract> properties;
}

class PrototypeCatalog {
  PrototypeCatalog(Iterable<ComponentContract> contracts)
      : _contracts = <String, ComponentContract>{
          for (final ComponentContract contract in contracts)
            contract.type: contract,
        };

  final Map<String, ComponentContract> _contracts;

  Iterable<ComponentContract> get contracts => _contracts.values;

  ComponentContract? contractFor(String type) => _contracts[type];
}
