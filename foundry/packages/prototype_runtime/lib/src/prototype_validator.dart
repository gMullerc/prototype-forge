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

class ValidationIssue {
  const ValidationIssue({
    required this.code,
    required this.path,
    required this.message,
  });

  final String code;
  final String path;
  final String message;

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
          ),
        );
      } else {
        if (!contract.allowsChildren && node.children.isNotEmpty) {
          issues.add(
            ValidationIssue(
              code: 'children_not_allowed',
              path: '$path.children',
              message: '${node.type} does not accept children.',
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
              ),
            );
          } else if (isPresent &&
              !property.value.accepts(node.props[property.key])) {
            issues.add(
              ValidationIssue(
                code: 'invalid_property',
                path: '$path.props.${property.key}',
                message: 'Property "${property.key}" has an invalid value.',
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
        const ValidationIssue(
          code: 'invalid_root_id',
          path: r'$.screen.root.id',
          message: 'The root component id must be "root".',
        ),
      );
    }
    return List<ValidationIssue>.unmodifiable(issues);
  }
}
