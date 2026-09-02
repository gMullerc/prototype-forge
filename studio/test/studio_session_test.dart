import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prototype_agent/prototype_agent.dart';
import 'package:prototype_flutter/prototype_flutter.dart';
import 'package:prototype_material_catalog/prototype_material_catalog.dart';
import 'package:prototype_material_exporter/prototype_material_exporter.dart';
import 'package:prototype_runtime/prototype_runtime.dart';
import 'package:prototype_workspace/prototype_workspace.dart';
import 'package:prototype_foundry_studio/application/studio_session.dart';

void main() {
  test('cancels a pending generation and ignores its late response', () async {
    final Completer<void> release = Completer<void>();
    final FlutterPrototypeCatalog catalog = createMaterialPrototypeCatalog();
    final _MemoryRepository repository = _MemoryRepository();
    final StudioSession session = StudioSession(
      agents: <PrototypeAgent>[_SlowAgent(release)],
      initialAgentId: 'slow',
      engine: PrototypeEngine(catalog: catalog.runtimeCatalog),
      workspace: PrototypeWorkspace(repository: repository),
      exporter: const MaterialDraftExporter(),
    );
    addTearDown(session.dispose);
    await session.initialize();

    final Future<void> generation = session.sendPrompt('Crie uma tela');
    expect(session.canCancelGeneration, isTrue);

    session.cancelGeneration();
    expect(session.canCancelGeneration, isFalse);
    expect(session.current.status, StudioGenerationStatus.idle);
    expect(
      session.current.messages.last.text,
      'Geração cancelada. O briefing continua disponível para nova tentativa.',
    );

    release.complete();
    await generation;

    expect(session.current.status, StudioGenerationStatus.idle);
    expect(repository.projects, isEmpty);
  });

  test('exports and imports the local workspace as a versioned backup',
      () async {
    final FlutterPrototypeCatalog catalog = createMaterialPrototypeCatalog();
    final StudioSession session = StudioSession(
      agents: <PrototypeAgent>[_SlowAgent(Completer<void>()..complete())],
      initialAgentId: 'slow',
      engine: PrototypeEngine(catalog: catalog.runtimeCatalog),
      workspace: PrototypeWorkspace(repository: _MemoryRepository()),
      exporter: const MaterialDraftExporter(),
    );
    addTearDown(session.dispose);
    await session.initialize();

    await session.importWorkspaceJson(
      jsonEncode(<String, Object?>{
        'format': 'prototype-forge.workspace',
        'version': 1,
        'projects': <Object?>[
          <String, Object?>{
            'id': 'project-bank',
            'name': 'Jornada bancária',
            'createdAt': '2026-09-02T10:00:00.000Z',
            'updatedAt': '2026-09-02T10:00:00.000Z',
            'revisions': <Object?>[
              <String, Object?>{
                'id': 'revision-1',
                'number': 1,
                'createdAt': '2026-09-02T10:00:00.000Z',
                'brief': 'Tela inicial do banco',
                'rawContract': '''
{
  "specVersion": "1.0",
  "screen": {
    "id": "bank-home",
    "title": "Início da conta",
    "root": {"id": "root", "type": "Divider"}
  }
}
''',
                'screenId': 'bank-home',
                'screenTitle': 'Início da conta',
              },
            ],
            'comments': <Object?>[],
          },
        ],
      }),
    );

    expect(session.current.activeProject?.name, 'Jornada bancária');
    expect(session.current.selectedRevision?.screenTitle, 'Início da conta');
    expect(session.current.status, StudioGenerationStatus.ready);

    final Map<String, Object?> backup =
        jsonDecode(session.exportWorkspaceJson()) as Map<String, Object?>;
    expect(backup['format'], 'prototype-forge.workspace');
    expect(backup['version'], 1);
    expect(backup['projects'], hasLength(1));
  });
}

class _SlowAgent implements PrototypeAgent {
  _SlowAgent(this.release);

  final Completer<void> release;

  @override
  String get id => 'slow';

  @override
  String get label => 'Agente lento';

  @override
  Future<String> generate(PrototypeBrief brief) async {
    await release.future;
    return '''
{
  "specVersion": "1.0",
  "screen": {
    "id": "screen",
    "title": "Tela",
    "root": {"id": "root", "type": "Divider"}
  }
}
''';
  }
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
