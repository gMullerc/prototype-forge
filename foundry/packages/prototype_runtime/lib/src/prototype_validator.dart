import 'package:prototype_spec/prototype_spec.dart';

import 'component_contract.dart';

class ValidationPolicy {
  const ValidationPolicy({
    this.maxComponents = 200,
    this.maxDepth = 30,
  });

  final int maxComponents;
  final int maxDepth;
}

enum ValidationIssuePriority {
  critical,
  high,
  medium,
}

class ValidationIssue {
  const ValidationIssue({
    required this.code,
    required this.path,
    required this.message,
    required this.title,
    required this.suggestion,
    this.priority = ValidationIssuePriority.high,
    this.componentId,
    this.componentType,
    this.propertyName,
    this.receivedValue,
    this.expected,
  });

  final String code;
  final String path;
  final String message;
  final String title;
  final String suggestion;
  final ValidationIssuePriority priority;
  final String? componentId;
  final String? componentType;
  final String? propertyName;
  final String? receivedValue;
  final String? expected;

  @override
  String toString() => '$code at $path: $message';
}

class PrototypeValidator {
  const PrototypeValidator({
    this.policy = const ValidationPolicy(),
  });

  final ValidationPolicy policy;

  List<ValidationIssue> validate(
    PrototypeDocument document,
    PrototypeCatalog catalog,
  ) {
    final List<ValidationIssue> issues = <ValidationIssue>[];
    final Set<String> ids = <String>{};
    int count = 0;

    void visit(PrototypeNode node, String path, int depth) {
      count += 1;
      if (count > policy.maxComponents) {
        issues.add(
          ValidationIssue(
            code: 'component_limit',
            path: path,
            message: 'The document exceeds ${policy.maxComponents} components.',
            title: 'A tela possui componentes demais',
            suggestion:
                'Divida a experiência em uma tela menor e solicite uma nova geração.',
            priority: ValidationIssuePriority.critical,
            componentId: node.id,
            componentType: node.type,
            expected: 'No máximo ${policy.maxComponents} componentes',
          ),
        );
        return;
      }

      if (depth > policy.maxDepth) {
        issues.add(
          ValidationIssue(
            code: 'depth_limit',
            path: path,
            message: 'The tree exceeds depth ${policy.maxDepth}.',
            title: 'A hierarquia da tela é profunda demais',
            suggestion:
                'Simplifique os agrupamentos e solicite uma composição com menos níveis.',
            priority: ValidationIssuePriority.critical,
            componentId: node.id,
            componentType: node.type,
            expected: 'No máximo ${policy.maxDepth} níveis',
          ),
        );
        return;
      }

      if (!ids.add(node.id)) {
        issues.add(
          ValidationIssue(
            code: 'duplicate_id',
            path: '$path.id',
            message: 'Component id "${node.id}" is duplicated.',
            title: 'Dois componentes usam o mesmo identificador',
            suggestion:
                'Peça ao agente para atribuir um id único a cada componente.',
            componentId: node.id,
            componentType: node.type,
            receivedValue: node.id,
            expected: 'Um id único em toda a tela',
          ),
        );
      }

      final ComponentContract? contract = catalog.contractFor(node.type);
      if (contract == null) {
        issues.add(
          ValidationIssue(
            code: 'unknown_component',
            path: '$path.type',
            message: 'Component type "${node.type}" is not in the catalog.',
            title: 'Componente indisponível no catálogo',
            suggestion:
                'Use um componente registrado ou descreva a intenção sem indicar um tipo específico.',
            componentId: node.id,
            componentType: node.type,
            receivedValue: node.type,
            expected: _joinedValues(
              catalog.contracts.map((ComponentContract item) => item.type),
            ),
          ),
        );
      } else {
        if (!contract.allowsChildren && node.children.isNotEmpty) {
          issues.add(
            ValidationIssue(
              code: 'children_not_allowed',
              path: '$path.children',
              message: '${node.type} does not accept children.',
              title: 'O componente não aceita conteúdo interno',
              suggestion:
                  'Mova os componentes filhos para um container compatível, como Column, Row ou Card.',
              componentId: node.id,
              componentType: node.type,
              expected: 'Nenhum componente filho',
            ),
          );
        }

        for (final String propertyName in node.props.keys) {
          if (!contract.properties.containsKey(propertyName)) {
            issues.add(
              ValidationIssue(
                code: 'unknown_property',
                path: '$path.props.$propertyName',
                message:
                    'Property "$propertyName" is not allowed on ${node.type}.',
                title: 'Propriedade não reconhecida',
                suggestion:
                    'Remova a propriedade ou use uma das propriedades aceitas pelo componente.',
                componentId: node.id,
                componentType: node.type,
                propertyName: propertyName,
                expected: _joinedValues(contract.properties.keys),
              ),
            );
          }
        }

        for (final MapEntry<String, PropertyContract> property
            in contract.properties.entries) {
          final bool isPresent = node.props.containsKey(property.key);
          if (property.value.required && !isPresent) {
            issues.add(
              ValidationIssue(
                code: 'required_property',
                path: '$path.props.${property.key}',
                message: 'Property "${property.key}" is required.',
                title: 'Propriedade obrigatória ausente',
                suggestion:
                    'Inclua a propriedade obrigatória e gere o contrato novamente.',
                componentId: node.id,
                componentType: node.type,
                propertyName: property.key,
                expected: _propertyExpectation(property.value),
              ),
            );
          } else if (isPresent &&
              !property.value.accepts(node.props[property.key])) {
            issues.add(
              ValidationIssue(
                code: 'invalid_property',
                path: '$path.props.${property.key}',
                message: 'Property "${property.key}" has an invalid value.',
                title: 'Valor de propriedade inválido',
                suggestion:
                    'Use um valor compatível com o contrato informado pelo catálogo.',
                componentId: node.id,
                componentType: node.type,
                propertyName: property.key,
                receivedValue: _safeValue(
                  node.props[property.key],
                  property.value,
                ),
                expected: _propertyExpectation(property.value),
              ),
            );
          }
        }
      }

      for (int index = 0; index < node.children.length; index++) {
        visit(node.children[index], '$path.children[$index]', depth + 1);
      }
    }

    visit(document.screen.root, r'$.screen.root', 1);
    if (document.screen.root.id != 'root') {
      issues.add(
        ValidationIssue(
          code: 'invalid_root_id',
          path: r'$.screen.root.id',
          message: 'The root component id must be "root".',
          title: 'O componente inicial não é a raiz esperada',
          suggestion:
              'Defina o id do primeiro componente como "root" e tente gerar novamente.',
          priority: ValidationIssuePriority.critical,
          componentId: document.screen.root.id,
          componentType: document.screen.root.type,
          receivedValue: document.screen.root.id,
          expected: 'root',
        ),
      );
    }
    return List<ValidationIssue>.unmodifiable(issues);
  }

  static String _propertyExpectation(PropertyContract contract) {
    if (contract.allowedValues.isNotEmpty) {
      return _joinedValues(contract.allowedValues);
    }
    return switch (contract.type) {
      PrototypePropertyType.string => 'Texto',
      PrototypePropertyType.number => 'Número',
      PrototypePropertyType.boolean => 'Verdadeiro ou falso',
      PrototypePropertyType.object => 'Objeto JSON',
      PrototypePropertyType.list => 'Lista JSON',
    };
  }

  static String? _safeValue(Object? value, PropertyContract contract) {
    if (contract.allowedValues.isEmpty || value == null) return null;
    if (value is! String && value is! num && value is! bool) return null;
    final String text = value.toString();
    return text.length <= 80 ? text : '${text.substring(0, 77)}...';
  }

  static String _joinedValues(Iterable<Object> values) {
    final List<String> items = values.map((Object value) => '$value').toList();
    return items.isEmpty ? 'Nenhum valor disponível' : items.join(', ');
  }
}
