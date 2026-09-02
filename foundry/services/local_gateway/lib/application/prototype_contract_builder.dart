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
    final Map<String, Object?> documentSchema = _documentSchema(catalog);
    final Map<String, Object?> outputSchema = _responseSchema(documentSchema);
    final String componentGuide =
        catalog.components.map(_componentGuide).join('\n');
    return PrototypeGenerationContract(
      systemPrompt: <String>[
        'Você é um agente de prototipação de produto.',
        'Retorne somente um objeto JSON, sem markdown ou texto externo. Ele pode ser uma pergunta de esclarecimento ou um contrato Prototype Spec 1.1.',
        'Para esclarecer o briefing, use exatamente {"type":"clarification","question":"...","options":["..."]}. Faça no máximo uma pergunta por rodada e só pergunte quando a resposta mudar a solução.',
        'Quando houver informação suficiente, use exatamente {"type":"contract","document":{...}} e coloque o Prototype Spec 1.1 dentro de document.',
        'A forma do documento é obrigatória: document.screen deve ser {"id":"...","title":"...","root":{...}}. Nunca coloque type diretamente em screen; type só aparece nos nós dentro de screen.root ou children.',
        'Esqueleto mínimo válido: {"type":"contract","document":{"specVersion":"1.1","interaction":{"initialState":{},"actions":[]},"screen":{"id":"tela","title":"Título","root":{"id":"root","type":"Column","children":[]}}}}.',
        'Componha a interface exclusivamente com os componentes e propriedades registrados.',
        'Não execute ferramentas, não leia nem altere arquivos e não produza código Dart, HTML ou JavaScript.',
        'Use textos claros em português e IDs únicos, curtos e descritivos.',
        'Não peça confirmação sobre detalhes pequenos. Quando o briefing omitir detalhes pequenos, escolha padrões razoáveis; use clarification somente para decisões que mudam significativamente o produto.',
        'Para escolhas, prefira botões visíveis: sexo pode usar Masculino, Feminino e Outro; decisões booleanas podem usar Sim e Não.',
        'A estrutura é: specVersion, screen, interaction; cada nó usa id, type, props opcional, interaction opcional e children quando aceitar filhos.',
        'O id do componente em screen.root deve ser exatamente "root".',
        'Todo campo editável deve usar node.interaction.valueKey e declarar seu valor inicial em interaction.initialState.',
        'Use node.interaction.required e validations para validar campos; tipos disponíveis: cpf, cnpj e minAge. minAge exige value numérico, por exemplo {"type":"minAge","value":18}.',
        'Use visibleWhen para conteúdo condicional e selectedWhen para indicar opções selecionadas.',
        'Botões continuam usando props.action; declare uma ação com o mesmo nome em interaction.actions.',
        'interaction.actions é uma lista no formato {"name":"nome_da_acao","effects":[...]}.',
        'Efeitos permitidos: setValue, toggleValue, reset, validate e showMessage.',
        'Exemplo de efeito: {"type":"setValue","key":"employee","value":true}.',
        'Exemplo de binding: "interaction":{"valueKey":"cpf","required":true,"validations":[{"type":"cpf"}]}.',
        'Exemplo de condição: "interaction":{"visibleWhen":{"key":"employee","equals":true}}.',
        'reset restaura todo o initialState e não usa key; para limpar apenas um campo, use setValue com value vazio.',
        'Toda ação que o usuário precisa disparar deve estar ligada ao props.action de um Button ou ListItem visível. Formulários devem terminar com um botão de envio.',
        'Em ações de envio, aplique validate antes de showMessage. A mensagem de sucesso só será exibida quando a validação passar.',
        'Não use reticências, comentários, markdown ou texto antes/depois do objeto JSON.',
        'Respeite literalmente os valores permitidos no catálogo: não invente valores de enumeração. Em Metric, tone só pode ser default, success ou danger; warning só pode ser usado onde o catálogo listar warning.',
        'Componentes disponíveis:',
        componentGuide,
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
        'specVersion': <String, Object?>{'const': '1.1'},
        'interaction': _interactionSchema(),
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
      'required': <String>['specVersion', 'interaction', 'screen'],
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

  Map<String, Object?> _responseSchema(Map<String, Object?> documentSchema) {
    return <String, Object?>{
      'oneOf': <Object?>[
        <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{
            'type': <String, Object?>{'const': 'clarification'},
            'question': _nonEmptyString(),
            'options': <String, Object?>{
              'type': 'array',
              'items': _nonEmptyString(),
              'maxItems': 4,
            },
          },
          'required': <String>['type', 'question'],
          'additionalProperties': false,
        },
        <String, Object?>{
          'type': 'object',
          'properties': <String, Object?>{
            'type': <String, Object?>{'const': 'contract'},
            'document': documentSchema,
          },
          'required': <String>['type', 'document'],
          'additionalProperties': false,
        },
      ],
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
      'interaction': _nodeInteractionSchema(),
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

  Map<String, Object?> _interactionSchema() => <String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{
          'initialState': <String, Object?>{
            'type': 'object',
            'additionalProperties': _scalarSchema(),
          },
          'actions': <String, Object?>{
            'type': 'array',
            'maxItems': 60,
            'items': <String, Object?>{
              'type': 'object',
              'properties': <String, Object?>{
                'name': _nonEmptyString(),
                'effects': <String, Object?>{
                  'type': 'array',
                  'minItems': 1,
                  'maxItems': 8,
                  'items': _effectSchema(),
                },
              },
              'required': <String>['name', 'effects'],
              'additionalProperties': false,
            },
          },
        },
        'required': <String>['initialState', 'actions'],
        'additionalProperties': false,
      };

  Map<String, Object?> _effectSchema() => <String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{
          'type': <String, Object?>{
            'type': 'string',
            'enum': <String>[
              'setValue',
              'toggleValue',
              'reset',
              'validate',
              'showMessage',
            ],
          },
          'key': _nonEmptyString(),
          'value': _scalarSchema(),
          'message': _nonEmptyString(),
          'tone': <String, Object?>{
            'type': 'string',
            'enum': <String>['info', 'success', 'warning', 'error'],
          },
        },
        'required': <String>['type'],
        'additionalProperties': false,
      };

  Map<String, Object?> _nodeInteractionSchema() => <String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{
          'valueKey': _nonEmptyString(),
          'required': <String, Object?>{'type': 'boolean'},
          'visibleWhen': _conditionSchema(),
          'selectedWhen': _conditionSchema(),
          'validations': <String, Object?>{
            'type': 'array',
            'maxItems': 6,
            'items': <String, Object?>{
              'type': 'object',
              'properties': <String, Object?>{
                'type': <String, Object?>{
                  'type': 'string',
                  'enum': <String>['cpf', 'cnpj', 'minAge'],
                },
                'value': <String, Object?>{'type': 'number'},
              },
              'required': <String>['type'],
              'additionalProperties': false,
            },
          },
        },
        'additionalProperties': false,
      };

  Map<String, Object?> _conditionSchema() => <String, Object?>{
        'type': 'object',
        'properties': <String, Object?>{
          'key': _nonEmptyString(),
          'equals': _scalarSchema(),
        },
        'required': <String>['key', 'equals'],
        'additionalProperties': false,
      };

  Map<String, Object?> _scalarSchema() => <String, Object?>{
        'oneOf': <Object?>[
          <String, Object?>{'type': 'string'},
          <String, Object?>{'type': 'number'},
          <String, Object?>{'type': 'boolean'},
          <String, Object?>{'type': 'null'},
        ],
      };

  Map<String, Object?> _nonEmptyString() => <String, Object?>{
        'type': 'string',
        'minLength': 1,
        'maxLength': 160,
      };
}
