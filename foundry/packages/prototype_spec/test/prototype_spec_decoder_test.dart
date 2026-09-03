import 'package:prototype_spec/prototype_spec.dart';
import 'package:test/test.dart';

void main() {
  const PrototypeSpecDecoder decoder = PrototypeSpecDecoder();

  test('decodes a valid nested document from a fenced block', () {
    final PrototypeDocument document = decoder.decode('''
Here is the prototype.
```json
{
  "specVersion": "1.0",
  "screen": {
    "id": "receipt",
    "title": "Payment receipt",
    "root": {
      "id": "root",
      "type": "Column",
      "children": [
        {
          "id": "title",
          "type": "Text",
          "props": {"text": "Payment complete", "variant": "title"}
        }
      ]
    }
  }
}
```
''');

    expect(document.screen.id, 'receipt');
    expect(document.screen.root.children.single.type, 'Text');
    expect(
      document.screen.root.children.single.props['text'],
      'Payment complete',
    );
  });

  test('rejects an unsupported version', () {
    expect(
      () => decoder.decode('''
{"specVersion":"2.0","screen":{"id":"x","title":"X","root":{"id":"root","type":"Column"}}}
'''),
      throwsA(isA<PrototypeSpecException>()),
    );
  });

  test('rejects unknown structural fields', () {
    expect(
      () => decoder.decode('''
{"specVersion":"1.0","unexpected":true,"screen":{"id":"x","title":"X","root":{"id":"root","type":"Column"}}}
'''),
      throwsA(
        isA<PrototypeSpecException>().having(
          (PrototypeSpecException error) => error.path,
          'path',
          r'$.unexpected',
        ),
      ),
    );
  });

  test('decodes interactive documents while keeping version 1.0 compatible', () {
    final PrototypeDocument document = decoder.decode('''
{
  "specVersion": "1.1",
  "interaction": {
    "initialState": {"employee": false, "name": ""},
    "actions": [
      {
        "name": "select_employee",
        "effects": [
          {"type": "setValue", "key": "employee", "value": true}
        ]
      }
    ]
  },
  "screen": {
    "id": "person",
    "title": "Person",
    "root": {
      "id": "root",
      "type": "Column",
      "children": [
        {
          "id": "name",
          "type": "TextField",
          "interaction": {"valueKey": "name", "required": true}
        },
        {
          "id": "employee-fields",
          "type": "Column",
          "interaction": {
            "visibleWhen": {"key": "employee", "equals": true}
          }
        }
      ]
    }
  }
}
''');

    expect(document.specVersion, '1.1');
    expect(document.interaction?.initialState['employee'], isFalse);
    expect(document.interaction?.actionFor('select_employee'), isNotNull);
    expect(
      document.screen.root.children.last.interaction?.visibleWhen?.key,
      'employee',
    );
  });

  test('does not accept interaction fields in version 1.0', () {
    expect(
      () => decoder.decode('''
{"specVersion":"1.0","interaction":{},"screen":{"id":"x","title":"X","root":{"id":"root","type":"Column"}}}
'''),
      throwsA(
        isA<PrototypeSpecException>().having(
          (PrototypeSpecException error) => error.path,
          'path',
          r'$.interaction',
        ),
      ),
    );
  });
}
