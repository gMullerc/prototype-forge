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
  });
}
