import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototype_flutter/prototype_flutter.dart';
import 'package:prototype_runtime/prototype_runtime.dart';
import 'package:prototype_spec/prototype_spec.dart';

void main() {
  testWidgets('renders a node through a registered component factory', (
    WidgetTester tester,
  ) async {
    final FlutterPrototypeCatalog catalog = FlutterPrototypeCatalog(
      <FlutterComponentFactory>[
        FlutterComponentFactory(
          contract: ComponentContract(
            type: 'Text',
            properties: const <String, PropertyContract>{
              'text': PropertyContract(
                type: PrototypePropertyType.string,
                required: true,
              ),
            },
          ),
          builder: (PrototypeRenderContext context, PrototypeNode node) =>
              Text(node.props['text']! as String),
        ),
      ],
    );
    final PrototypeDocument document = PrototypeDocument(
      specVersion: '1.0',
      screen: PrototypeScreen(
        id: 'hello',
        title: 'Hello',
        root: PrototypeNode(
          id: 'root',
          type: 'Text',
          props: const <String, Object?>{'text': 'Rendered by catalog'},
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PrototypeSurface(document: document, catalog: catalog),
      ),
    );

    expect(find.text('Rendered by catalog'), findsOneWidget);
  });
}
