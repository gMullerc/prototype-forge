import 'dart:convert';

import 'package:prototype_gateway_protocol/prototype_gateway_protocol.dart';

class PrototypeGenerationContract {
  const PrototypeGenerationContract({
    required this.systemPrompt,
    required this.outputSchema,
  });

  final String systemPrompt;
  final Map<String, Object?> outputSchema;
}

abstract interface class PrototypeContractBuilder {
  PrototypeGenerationContract build(GatewayCatalogContract catalog);
}

class PrototypeSpecContractBuilder implements PrototypeContractBuilder {
  const PrototypeSpecContractBuilder();

  @override
  PrototypeGenerationContract build(GatewayCatalogContract catalog) {
    final Map<String, Object?> outputSchema = _documentSchema(catalog);
    final String componentGuide =
        catalog.components.map(_componentGuide).join('\n');
    return PrototypeGenerationContract(
      systemPrompt: <String>[
        'Você é um agente de prototipação de produto.',
        'Retorne somente um documento Prototype Spec 1.0 que satisfaça o JSON Schema fornecido.',
        'Componha a interface exclusivamente com os componentes e propriedades registrados.',
        'Não execute ferramentas, não leia nem altere arquivos e não produza código Dart, HTML ou JavaScript.',
        'Use textos claros em português e IDs únicos, curtos e descritivos.',
        'Componentes disponíveis:',
        componentGuide,
        'JSON Schema de referência obrigatório:',
        jsonEncode(outputSchema),
      ].join('\n'),
      outputSchema: outputSchema,
    );
  }

  String _componentGuide(GatewayComponentContract component) {
    final String properties = component.properties.entries.map(
      (MapEntry<String, GatewayPropertyContract> entry) {
        final GatewayPropertyContract property = entry.value;
        final String required = property.required ? ', obrigatório' : '';
        final String values = property.allowedValues.isEmpty
            ? ''
            : ', valores: ${property.allowedValues.join(' | ')}';
        return '${entry.key}: ${property.type.name}$required$values';
      },
    ).join('; ');
    final String children =
        component.allowsChildren ? 'aceita filhos' : 'sem filhos';
    return '- ${component.type} ($children)${properties.isEmpty ? '' : ': $properties'}';
  }

  Map<String, Object?> _documentSchema(GatewayCatalogContract catalog) {
    return <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{
        'specVersion': <String, Object?>{'const': '1.0'},
        'screen': <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{
            'id': _nonEmptyString(),
            'title': _nonEmptyString(),
            'root': <String, Object?>{'\$ref': '#/\$defs/node'},
          },
          'required': <String>['id', 'title', 'root'],
          'additionalProperties': false,
        },
      },
      'required': <String>['specVersion', 'screen'],
      'additionalProperties': false,
      '\$defs': <String, Object?>{
        'node': <String, Object?>{
          'oneOf': <Object?>[
            for (final GatewayComponentContract component in catalog.components)
              _componentSchema(component),
          ],
        },
      },
    };
  }

  Map<String, Object?> _componentSchema(
    GatewayComponentContract component,
  ) {
    final List<String> requiredProperties = component.properties.entries
        .where(
          (MapEntry<String, GatewayPropertyContract> entry) =>
              entry.value.required,
        )
        .map((MapEntry<String, GatewayPropertyContract> entry) => entry.key)
        .toList(growable: false);
    final Map<String, Object?> properties = <String, Object?>{
      'id': _nonEmptyString(),
      'type': <String, Object?>{'const': component.type},
      'props': <String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{
          for (final MapEntry<String, GatewayPropertyContract> entry
              in component.properties.entries)
            entry.key: _propertySchema(entry.value),
        },
        if (requiredProperties.isNotEmpty) 'required': requiredProperties,
        'additionalProperties': false,
      },
      if (component.allowsChildren)
        'children': <String, Object?>{
          'type': 'array',
          'items': <String, Object?>{'\$ref': '#/\$defs/node'},
          'maxItems': 40,
        },
    };
    return <String, Object?>{
      'type': 'object',
      'properties': properties,
      'required': <String>[
        'id',
        'type',
        if (requiredProperties.isNotEmpty) 'props',
      ],
      'additionalProperties': false,
    };
  }

  Map<String, Object?> _propertySchema(GatewayPropertyContract property) {
    final Map<String, Object?> schema = switch (property.type) {
      GatewayPropertyType.string => <String, Object?>{'type': 'string'},
      GatewayPropertyType.number => <String, Object?>{'type': 'number'},
      GatewayPropertyType.boolean => <String, Object?>{'type': 'boolean'},
      GatewayPropertyType.object => <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      GatewayPropertyType.list => <String, Object?>{
          'type': 'array',
          'items': <String, Object?>{},
        },
    };
    if (property.allowedValues.isNotEmpty) {
      schema['enum'] = property.allowedValues;
    }
    return schema;
  }

  Map<String, Object?> _nonEmptyString() => <String, Object?>{
        'type': 'string',
        'minLength': 1,
        'maxLength': 160,
      };
}
