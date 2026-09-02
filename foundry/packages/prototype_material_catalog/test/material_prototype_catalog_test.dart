import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototype_flutter/prototype_flutter.dart';
import 'package:prototype_material_catalog/prototype_material_catalog.dart';
import 'package:prototype_runtime/prototype_runtime.dart';

void main() {
  testWidgets('renders a validated receipt and emits its action', (
    WidgetTester tester,
  ) async {
    const String source = '''
{
  "specVersion": "1.0",
  "screen": {
    "id": "receipt",
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
    final PrototypeSnapshot snapshot = PrototypeEngine(
      catalog: createMaterialPrototypeCatalog().runtimeCatalog,
    ).load(source);
    PrototypeActionEvent? received;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrototypeSurface(
            document: snapshot.document!,
            catalog: createMaterialPrototypeCatalog(),
            onAction: (PrototypeActionEvent event) => received = event,
          ),
        ),
      ),
    );

    expect(find.text('Payment complete'), findsOneWidget);
    await tester.tap(find.text('Share receipt'));
    expect(received?.name, 'share_receipt');
    expect(received?.componentId, 'share');
  });
}
