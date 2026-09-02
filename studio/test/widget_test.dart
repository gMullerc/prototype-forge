import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototype_agent/prototype_agent.dart';
import 'package:prototype_material_catalog/prototype_material_catalog.dart';
import 'package:prototype_material_exporter/prototype_material_exporter.dart';
import 'package:prototype_runtime/prototype_runtime.dart';
import 'package:prototype_tool_discovery/prototype_tool_discovery.dart';
import 'package:prototype_workspace/prototype_workspace.dart';
import 'package:prototype_foundry_studio/app/foundry_app.dart';
import 'package:prototype_foundry_studio/application/studio_session.dart';
import 'package:prototype_foundry_studio/infrastructure/local_prototype_agent.dart';
import 'package:prototype_foundry_studio/infrastructure/workspace_transfer/workspace_transfer.dart';
import 'package:prototype_foundry_studio/presentation/foundry_theme.dart';
import 'package:prototype_foundry_studio/presentation/studio_page.dart';

void main() {
  testWidgets('generates and interacts with the local receipt prototype', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const FoundryApp());

    expect(find.text('PROTOTYPE FOUNDRY'), findsOneWidget);
    await tester.tap(find.text('Comprovante de pagamento'));
    await tester.pumpAndSettle();

    expect(find.text('Pagamento confirmado'), findsOneWidget);
    expect(find.text('R\$ 250,00'), findsOneWidget);
    await tester.ensureVisible(find.text('Compartilhar comprovante'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compartilhar comprovante'));
    await tester.pump();
    expect(
        find.textContaining('Ação capturada: share_receipt'), findsOneWidget);
  });

  testWidgets('switches the generation agent without rebuilding the app', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const FoundryApp());

    await tester.tap(find.byKey(const Key('agent-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OpenCode'));
    await tester.pumpAndSettle();

    expect(find.text('OPENCODE'), findsWidgets);
    expect(find.text('MOTOR LOCAL'), findsNothing);
  });

  testWidgets('saves revisions, compares them and exports a Flutter draft', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const FoundryApp());

    await tester.tap(find.text('Comprovante de pagamento'));
    await tester.pumpAndSettle();
    expect(find.text('REV 01'), findsOneWidget);
    expect(find.byKey(const Key('preview-phone')), findsOneWidget);

    await tester.tap(find.byKey(const Key('viewport-tablet')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('preview-tablet')), findsOneWidget);

    await tester.tap(find.text('Hipótese de onboarding'));
    await tester.pumpAndSettle();
    expect(find.text('REV 02'), findsOneWidget);

    await tester.tap(find.byKey(const Key('export-draft-button')));
    await tester.pumpAndSettle();
    expect(find.text('Rascunho Flutter para revisão'), findsOneWidget);
    expect(find.byKey(const Key('export-source')), findsOneWidget);
    expect(find.textContaining('class ProductHypothesisDraft'), findsOneWidget);
    await tester.tap(find.text('FECHAR'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('review-workspace-button')));
    await tester.pumpAndSettle();
    expect(find.text('Mesa de revisão local'), findsOneWidget);
    expect(find.text('REVISÕES · 2'), findsWidgets);

    await tester.tap(find.byKey(const Key('compare-revision-1')));
    await tester.pumpAndSettle();
    expect(find.text('Comparando revisão 2 com 1'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('review-comment-field')),
      'Validar o conteúdo com design.',
    );
    await tester.tap(find.byKey(const Key('add-review-comment-button')));
    await tester.pumpAndSettle();
    expect(find.text('• Validar o conteúdo com design.'), findsOneWidget);
  });

  testWidgets('offers versioned workspace backup actions', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final catalog = createMaterialPrototypeCatalog();
    final StudioSession session = StudioSession(
      agents: <PrototypeAgent>[LocalPrototypeAgent()],
      initialAgentId: 'local-contract',
      engine: PrototypeEngine(catalog: catalog.runtimeCatalog),
      workspace: PrototypeWorkspace(repository: _MemoryRepository()),
      exporter: const MaterialDraftExporter(),
    );
    final _MemoryWorkspaceTransfer transfer = _MemoryWorkspaceTransfer();
    final _MemoryToolDiscovery toolDiscovery = _MemoryToolDiscovery();
    addTearDown(session.dispose);
    await session.initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFoundryTheme(),
        home: StudioPage(
          session: session,
          catalog: catalog,
          workspaceTransfer: transfer,
          toolDiscovery: toolDiscovery,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('tool-discovery-button')));
    await tester.pumpAndSettle();
    expect(find.text('Ferramentas deste computador'), findsOneWidget);
    expect(find.text('OpenCode'), findsOneWidget);
    expect(find.text('DETECTADA'), findsOneWidget);
    await tester.tap(find.text('FECHAR'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('workspace-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Exportar backup'), findsOneWidget);
    expect(find.text('Importar backup'), findsOneWidget);

    await tester.tap(find.text('Exportar backup'));
    await tester.pumpAndSettle();
    expect(transfer.downloaded, isNotNull);
    expect(find.text('Backup do workspace exportado.'), findsOneWidget);

    transfer.source = transfer.downloaded;
    await tester.tap(find.byKey(const Key('workspace-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Importar backup'));
    await tester.pumpAndSettle();
    expect(find.text('Backup importado com sucesso.'), findsOneWidget);
  });
}

class _MemoryWorkspaceTransfer implements WorkspaceTransfer {
  String? downloaded;
  String? source;

  @override
  Future<void> downloadText({
    required String filename,
    required String contents,
  }) async {
    downloaded = contents;
  }

  @override
  Future<String?> pickText() async => source;
}

class _MemoryToolDiscovery implements ToolDiscovery {
  @override
  Future<List<DiscoveredTool>> discover() async => <DiscoveredTool>[
        const DiscoveredTool(
          definition: ToolDefinition(
            id: 'opencode',
            label: 'OpenCode',
            executable: 'opencode',
            capabilities: <String>['agent', 'prototype-generation'],
          ),
          availability: ToolAvailability.available,
          version: '1.18.26',
        ),
        const DiscoveredTool(
          definition: ToolDefinition(
            id: 'codex-cli',
            label: 'OpenAI Codex CLI',
            executable: 'codex',
            capabilities: <String>['agent'],
          ),
          availability: ToolAvailability.notFound,
        ),
      ];
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
