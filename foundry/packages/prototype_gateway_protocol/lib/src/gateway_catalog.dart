import 'gateway_protocol.dart';

enum GatewayPropertyType {
  string,
  number,
  boolean,
  object,
  list;

  static GatewayPropertyType parse(Object? value) {
    for (final GatewayPropertyType type in GatewayPropertyType.values) {
      if (type.name == value) return type;
    }
    throw GatewayProtocolException('Tipo de propriedade inválido: $value.');
  }
}

class GatewayPropertyContract {
  GatewayPropertyContract({
    required this.type,
    this.required = false,
    List<Object?> allowedValues = const <Object?>[],
  }) : allowedValues = List<Object?>.unmodifiable(allowedValues);

  factory GatewayPropertyContract.fromJson(Object? value) {
    final Map<String, Object?> json = gatewayMap(value, 'property');
    final Object? requiredValue = json['required'];
    if (requiredValue != null && requiredValue is! bool) {
      throw const GatewayProtocolException(
        'property.required precisa ser booleano.',
      );
    }
    final Object? allowed = json['allowedValues'];
    if (allowed != null && allowed is! List<Object?>) {
      throw const GatewayProtocolException(
        'property.allowedValues precisa ser uma lista.',
      );
    }
    return GatewayPropertyContract(
      type: GatewayPropertyType.parse(json['type']),
      required: requiredValue as bool? ?? false,
      allowedValues: allowed as List<Object?>? ?? const <Object?>[],
    );
  }

  final GatewayPropertyType type;
  final bool required;
  final List<Object?> allowedValues;

  Map<String, Object?> toJson() => <String, Object?>{
        'type': type.name,
        'required': required,
        if (allowedValues.isNotEmpty) 'allowedValues': allowedValues,
      };
}

class GatewayComponentContract {
  GatewayComponentContract({
    required this.type,
    this.allowsChildren = false,
    Map<String, GatewayPropertyContract> properties =
        const <String, GatewayPropertyContract>{},
  }) : properties = Map<String, GatewayPropertyContract>.unmodifiable(
          properties,
        );

  factory GatewayComponentContract.fromJson(Object? value) {
    final Map<String, Object?> json = gatewayMap(value, 'component');
    final Object? allowsChildrenValue = json['allowsChildren'];
    if (allowsChildrenValue != null && allowsChildrenValue is! bool) {
      throw const GatewayProtocolException(
        'component.allowsChildren precisa ser booleano.',
      );
    }
    final Map<String, Object?> propertiesJson = gatewayMap(
        json['properties'] ?? const <String, Object?>{}, 'properties');
    return GatewayComponentContract(
      type: gatewayString(json, 'type'),
      allowsChildren: allowsChildrenValue as bool? ?? false,
      properties: <String, GatewayPropertyContract>{
        for (final MapEntry<String, Object?> entry in propertiesJson.entries)
          entry.key: GatewayPropertyContract.fromJson(entry.value),
      },
    );
  }

  final String type;
  final bool allowsChildren;
  final Map<String, GatewayPropertyContract> properties;

  Map<String, Object?> toJson() => <String, Object?>{
        'type': type,
        'allowsChildren': allowsChildren,
        'properties': <String, Object?>{
          for (final MapEntry<String, GatewayPropertyContract> entry
              in properties.entries)
            entry.key: entry.value.toJson(),
        },
      };
}

class GatewayCatalogContract {
  GatewayCatalogContract(Iterable<GatewayComponentContract> components)
      : components = List<GatewayComponentContract>.unmodifiable(components) {
    if (this.components.isEmpty) {
      throw const GatewayProtocolException(
        'O catálogo precisa ter ao menos um componente.',
      );
    }
    final Set<String> types = <String>{};
    for (final GatewayComponentContract component in this.components) {
      if (!types.add(component.type)) {
        throw GatewayProtocolException(
          'Componente duplicado no catálogo: ${component.type}.',
        );
      }
    }
  }

  factory GatewayCatalogContract.fromJson(Object? value) {
    final Map<String, Object?> json = gatewayMap(value, 'catalog');
    final Object? componentsValue = json['components'];
    if (componentsValue is! List<Object?>) {
      throw const GatewayProtocolException(
        'catalog.components precisa ser uma lista.',
      );
    }
    return GatewayCatalogContract(
      componentsValue.map(GatewayComponentContract.fromJson),
    );
  }

  final List<GatewayComponentContract> components;

  Map<String, Object?> toJson() => <String, Object?>{
        'components': <Object?>[
          for (final GatewayComponentContract component in components)
            component.toJson(),
        ],
      };
}
