import 'dart:async';

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
