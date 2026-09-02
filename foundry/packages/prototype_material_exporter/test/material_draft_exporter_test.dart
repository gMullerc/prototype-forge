import 'package:prototype_material_exporter/prototype_material_exporter.dart';
import 'package:prototype_spec/prototype_spec.dart';
import 'package:test/test.dart';

void main() {
  test('exports readable deterministic Flutter without runtime dependencies',
      () {
    const String source = '''
{
  "specVersion": "1.0",
  "screen": {
    "id": "payment-receipt",
    "title": "Payment receipt",
    "root": {
      "id": "root",
      "type": "Column",
      "props": {"gap": 16, "align": "stretch"},
      "children": [
        {"id": "title", "type": "Text", "props": {"text": "Payment complete", "variant": "title"}},
        {"id": "share", "type": "Button", "props": {"label": "Share receipt", "action": "share_receipt", "icon": "share"}}
      ]
    }
  }
}
''';
    final PrototypeDocument document =
        const PrototypeSpecDecoder().decode(source);
    const MaterialDraftExporter exporter = MaterialDraftExporter();

    final first = exporter.export(document);
    final second = exporter.export(document);

    expect(first.fileName, 'payment_receipt_draft.dart');
    expect(first.source, second.source);
    expect(first.source, contains('class PaymentReceiptDraft'));
    expect(first.source, contains("'Payment complete'"));
    expect(first.source, contains('FilledButton.icon('));
    expect(first.source, contains("TODO(prototype): handle 'share_receipt'"));
    expect(first.source, isNot(contains('prototype_runtime')));
  });

  test('escapes user-visible strings as Dart literals', () {
    final PrototypeDocument document = PrototypeDocument(
      specVersion: '1.0',
      screen: PrototypeScreen(
        id: 'quote',
        title: 'Quote',
        root: PrototypeNode(
          id: 'root',
          type: 'Text',
          props: <String, Object?>{'text': r"PM's $value"},
        ),
      ),
    );

    final String output = const MaterialDraftExporter().export(document).source;
    expect(output, contains(r"PM\'s \$value"));
  });

  test('exports the realistic Material catalog components deterministically',
      () {
    final PrototypeDocument document = PrototypeDocument(
      specVersion: '1.0',
      screen: PrototypeScreen(
        id: 'bank-home',
        title: 'Bank home',
        root: PrototypeNode(
          id: 'root',
          type: 'Column',
          children: <PrototypeNode>[
            PrototypeNode(
              id: 'profile',
              type: 'Avatar',
              props: const <String, Object?>{
                'name': 'Marina Souza',
                'initials': 'MS',
              },
            ),
            PrototypeNode(
              id: 'status',
              type: 'Badge',
              props: const <String, Object?>{
                'label': 'Ativa',
                'tone': 'success',
              },
            ),
            PrototypeNode(
              id: 'email',
              type: 'TextField',
              props: const <String, Object?>{
                'label': 'E-mail',
                'keyboard': 'email',
              },
            ),
            PrototypeNode(
              id: 'notice',
              type: 'Notice',
              props: const <String, Object?>{
                'title': 'Acesso seguro',
                'message': 'Sua conta está protegida.',
                'tone': 'info',
              },
            ),
            PrototypeNode(
              id: 'balance',
              type: 'Metric',
              props: const <String, Object?>{
                'label': 'Saldo',
                'value': 'R\$ 8.450,32',
              },
            ),
            PrototypeNode(
              id: 'transaction',
              type: 'ListItem',
              props: const <String, Object?>{
                'label': 'Mercado Aurora',
                'trailing': '- R\$ 128,40',
                'action': 'open_transaction',
              },
            ),
          ],
        ),
      ),
    );

    final String output = const MaterialDraftExporter().export(document).source;

    expect(output, contains('CircleAvatar('));
    expect(output, contains('Tooltip('));
    expect(output, contains('TextFormField('));
    expect(output, contains('InputDecoration('));
    expect(output, contains('Card('));
    expect(output, contains('ListTile('));
    expect(output, contains("TODO(prototype): handle 'open_transaction'"));
  });
}
