import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototype_agent/prototype_agent.dart';
import 'package:prototype_material_catalog/prototype_material_catalog.dart';
import 'package:prototype_material_exporter/prototype_material_exporter.dart';
import 'package:prototype_runtime/prototype_runtime.dart';
import 'package:prototype_workspace/prototype_workspace.dart';
import 'package:prototype_foundry_studio/application/studio_session.dart';
import 'package:prototype_foundry_studio/presentation/foundry_theme.dart';
import 'package:prototype_foundry_studio/presentation/studio_page.dart';

void main() {
  testWidgets('explains which component caused a contract rejection', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final catalog = createMaterialPrototypeCatalog();
    final StudioSession session = StudioSession(
      agents: const <PrototypeAgent>[_InvalidContractAgent()],
      initialAgentId: 'invalid-fixture',
      engine: PrototypeEngine(catalog: catalog.runtimeCatalog),
      workspace: PrototypeWorkspace(repository: _MemoryRepository()),
      exporter: const MaterialDraftExporter(),
    );
    addTearDown(session.dispose);
    await session.initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFoundryTheme(),
        home: StudioPage(session: session, catalog: catalog),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('prompt-field')),
      'Crie uma tela inicial',
    );
    await tester.tap(find.byKey(const Key('send-prompt-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('contract-rejection-panel')), findsOneWidget);
    expect(
      find.text('O componente inicial não é a raiz esperada'),
      findsOneWidget,
    );
    expect(find.text('wrong-root · id'), findsNothing);
    expect(find.text('wrong-root'), findsWidgets);
    expect(find.textContaining('Defina o id do primeiro componente'),
        findsOneWidget);
    expect(
      find.textContaining('ESPERADO', findRichText: true),
      findsOneWidget,
    );
    expect(find.byKey(const Key('retry-contract-button')), findsOneWidget);
  });
}

class _InvalidContractAgent implements PrototypeAgent {
  const _InvalidContractAgent();

  @override
  String get id => 'invalid-fixture';

  @override
  String get label => 'Fixture inválida';

  @override
  Future<String> generate(PrototypeBrief brief) async => '''
{
  "specVersion": "1.0",
  "screen": {
    "id": "home",
    "title": "Home",
    "root": {
      "id": "wrong-root",
      "type": "Column",
      "children": []
    }
  }
}
''';
}

class _MemoryRepository implements PrototypeProjectRepository {
  List<PrototypeProject> projects = <PrototypeProject>[];

  @override
  Future<List<PrototypeProject>> loadProjects() async => projects;

  @override
  Future<void> saveProjects(List<PrototypeProject> projects) async {
    this.projects = List<PrototypeProject>.from(projects);
  }
}
