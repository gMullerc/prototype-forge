import 'package:prototype_runtime/prototype_runtime.dart';
import 'package:test/test.dart';

void main() {
  final PrototypeCatalog catalog = PrototypeCatalog(<ComponentContract>[
    ComponentContract(type: 'Column', allowsChildren: true),
    ComponentContract(
      type: 'Text',
      properties: const <String, PropertyContract>{
        'text': PropertyContract(
          type: PrototypePropertyType.string,
          required: true,
        ),
      },
    ),
  ]);

  test('accepts a document composed only from registered components', () {
    final PrototypeSnapshot snapshot =
        PrototypeEngine(catalog: catalog).load('''
{
  "specVersion": "1.0",
  "screen": {
    "id": "welcome",
    "title": "Welcome",
    "root": {
      "id": "root",
      "type": "Column",
      "children": [
        {"id": "title", "type": "Text", "props": {"text": "Hello"}}
      ]
    }
  }
}
''');

    expect(snapshot.status, PrototypeStatus.ready);
    expect(snapshot.issues, isEmpty);
  });

  test('rejects unknown components and duplicate ids', () {
    final PrototypeSnapshot snapshot =
        PrototypeEngine(catalog: catalog).load('''
{
  "specVersion": "1.0",
  "screen": {
    "id": "broken",
    "title": "Broken",
    "root": {
      "id": "root",
      "type": "Column",
      "children": [
        {"id": "root", "type": "Script", "props": {"source": "nope"}}
      ]
    }
  }
}
''');

    expect(snapshot.status, PrototypeStatus.invalid);
    expect(
      snapshot.issues.map((ValidationIssue issue) => issue.code),
      containsAll(<String>['duplicate_id', 'unknown_component']),
    );
    final ValidationIssue unknown = snapshot.issues.firstWhere(
      (ValidationIssue issue) => issue.code == 'unknown_component',
    );
    expect(unknown.componentId, 'root');
    expect(unknown.componentType, 'Script');
    expect(unknown.title, 'Componente indisponível no catálogo');
    expect(unknown.suggestion, isNotEmpty);
    expect(unknown.expected, contains('Column'));
  });

  test('describes the invalid property and accepted values', () {
    final PrototypeCatalog tokenCatalog = PrototypeCatalog(<ComponentContract>[
      ComponentContract(
        type: 'Text',
        properties: const <String, PropertyContract>{
          'tone': PropertyContract(
            type: PrototypePropertyType.string,
            allowedValues: <Object>['default', 'success'],
          ),
        },
      ),
    ]);
    final PrototypeSnapshot snapshot =
        PrototypeEngine(catalog: tokenCatalog).load('''
{
  "specVersion": "1.0",
  "screen": {
    "id": "feedback",
    "title": "Feedback",
    "root": {
      "id": "root",
      "type": "Text",
      "props": {"tone": "positive"}
    }
  }
}
''');

    final ValidationIssue issue = snapshot.issues.single;
    expect(issue.code, 'invalid_property');
    expect(issue.componentId, 'root');
    expect(issue.propertyName, 'tone');
    expect(issue.receivedValue, 'positive');
    expect(issue.expected, 'default, success');
  });

  test('turns decoder failures into actionable diagnostics', () {
    final PrototypeSnapshot snapshot =
        PrototypeEngine(catalog: catalog).load('{"specVersion": 1}');

    final ValidationIssue issue = snapshot.issues.single;
    expect(issue.code, 'decode_error');
    expect(issue.title, contains('Prototype Spec'));
    expect(issue.suggestion, isNotEmpty);
    expect(issue.priority, ValidationIssuePriority.critical);
  });
}
