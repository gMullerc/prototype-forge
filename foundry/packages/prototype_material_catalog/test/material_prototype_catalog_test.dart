import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototype_flutter/prototype_flutter.dart';
import 'package:prototype_material_catalog/prototype_material_catalog.dart';
import 'package:prototype_spec/prototype_spec.dart';
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

  testWidgets('renders realistic banking components and emits list actions', (
    WidgetTester tester,
  ) async {
    const String source = '''
{
  "specVersion": "1.0",
  "screen": {
    "id": "bank-home",
    "title": "Bank home",
    "root": {
      "id": "root",
      "type": "Column",
      "props": {"gap": 12},
      "children": [
        {"id": "profile", "type": "Avatar", "props": {"name": "Marina Souza", "initials": "MS"}},
        {"id": "status", "type": "Badge", "props": {"label": "Ativa", "tone": "success"}},
        {"id": "email", "type": "TextField", "props": {"label": "E-mail", "keyboard": "email"}},
        {"id": "notice", "type": "Notice", "props": {"title": "Acesso seguro", "message": "Sua conta está protegida.", "tone": "info"}},
        {"id": "balance", "type": "Metric", "props": {"label": "Saldo", "value": "R\$ 8.450,32", "tone": "success"}},
        {"id": "transaction", "type": "ListItem", "props": {"label": "Mercado Aurora", "trailing": "- R\$ 128,40", "action": "open_transaction"}}
      ]
    }
  }
}
''';
    final FlutterPrototypeCatalog catalog = createMaterialPrototypeCatalog();
    final PrototypeSnapshot snapshot = PrototypeEngine(
      catalog: catalog.runtimeCatalog,
    ).load(source);
    PrototypeActionEvent? received;

    expect(snapshot.status, PrototypeStatus.ready);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PrototypeSurface(
              document: snapshot.document!,
              catalog: catalog,
              onAction: (PrototypeActionEvent event) => received = event,
            ),
          ),
        ),
      ),
    );

    expect(find.text('MS'), findsOneWidget);
    expect(find.text('Ativa'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Acesso seguro'), findsOneWidget);
    expect(find.text('R\$ 8.450,32'), findsOneWidget);
    await tester.tap(find.text('Mercado Aurora'));
    expect(received?.name, 'open_transaction');
    expect(received?.componentId, 'transaction');
  });

  testWidgets('edits values, validates and toggles conditional components', (
    WidgetTester tester,
  ) async {
    const String source = '''
{
  "specVersion": "1.1",
  "interaction": {
    "initialState": {"name": "", "employee": false, "salary": ""},
    "actions": [
      {"name": "employee_yes", "effects": [{"type": "setValue", "key": "employee", "value": true}]},
      {"name": "employee_no", "effects": [{"type": "setValue", "key": "employee", "value": false}]},
      {"name": "save", "effects": [{"type": "validate"}, {"type": "showMessage", "tone": "success", "message": "Cadastro salvo."}]}
    ]
  },
  "screen": {
    "id": "person",
    "title": "Cadastro",
    "root": {
      "id": "root",
      "type": "Column",
      "children": [
        {"id": "name", "type": "TextField", "props": {"label": "Nome"}, "interaction": {"valueKey": "name", "required": true}},
        {"id": "yes", "type": "Button", "props": {"label": "Sim", "action": "employee_yes"}, "interaction": {"selectedWhen": {"key": "employee", "equals": true}}},
        {"id": "no", "type": "Button", "props": {"label": "Não", "action": "employee_no"}, "interaction": {"selectedWhen": {"key": "employee", "equals": false}}},
        {"id": "employee-fields", "type": "Column", "interaction": {"visibleWhen": {"key": "employee", "equals": true}}, "children": [
          {"id": "salary", "type": "TextField", "props": {"label": "Salário", "keyboard": "number"}, "interaction": {"valueKey": "salary", "required": true}}
        ]},
        {"id": "save", "type": "Button", "props": {"label": "Salvar", "action": "save"}}
      ]
    }
  }
}
''';
    final FlutterPrototypeCatalog catalog = createMaterialPrototypeCatalog();
    final PrototypeSnapshot snapshot =
        PrototypeEngine(catalog: catalog.runtimeCatalog).load(source);

    expect(snapshot.status, PrototypeStatus.ready);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PrototypeSurface(
              document: snapshot.document!,
              catalog: catalog,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Salário'), findsNothing);
    await tester.enterText(find.byType(TextFormField), 'Maria');
    await tester.tap(find.text('Sim'));
    await tester.pump();
    expect(find.text('Salário'), findsOneWidget);

    await tester.tap(find.text('Salvar'));
    await tester.pump();
    expect(find.text('Campo obrigatório.'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Salário'), '5000');
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    expect(find.text('Cadastro salvo.'), findsOneWidget);

    await tester.tap(find.text('Não'));
    await tester.pump();
    expect(find.text('Salário'), findsNothing);
  });

  test('accepts additional factories without changing the Material catalog',
      () {
    final FlutterComponentFactory customFactory = FlutterComponentFactory(
      contract: ComponentContract(type: 'CompanyHeader'),
      builder: (PrototypeRenderContext context, PrototypeNode node) =>
          const SizedBox(),
    );
    final FlutterPrototypeCatalog catalog = createMaterialPrototypeCatalog(
      additionalFactories: <FlutterComponentFactory>[customFactory],
    );

    expect(catalog.factoryFor('CompanyHeader'), same(customFactory));
    expect(catalog.runtimeCatalog.contractFor('CompanyHeader'), isNotNull);
  });
}
