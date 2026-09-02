import 'package:prototype_workspace/prototype_workspace.dart';
import 'package:test/test.dart';

void main() {
  test('captures immutable revisions and restores them from the repository',
      () async {
    final _MemoryRepository repository = _MemoryRepository();
    final List<DateTime> times = <DateTime>[
      DateTime.utc(2026, 9, 1, 10),
      DateTime.utc(2026, 9, 1, 10, 1),
      DateTime.utc(2026, 9, 1, 10, 2),
    ];
    final PrototypeWorkspace workspace = PrototypeWorkspace(
      repository: repository,
      clock: () => times.removeAt(0),
      idFactory: (String prefix, DateTime time) => '$prefix-${time.minute}',
    );
    await workspace.initialize();

    final PrototypeRevision first = await workspace.captureRevision(
      brief: 'Primeira hipótese',
      rawContract: '{"revision":1}',
      screenId: 'home',
      screenTitle: 'Home',
    );
    final PrototypeRevision second = await workspace.captureRevision(
      brief: 'Segunda hipótese',
      rawContract: '{"revision":2}',
      screenId: 'home',
      screenTitle: 'Home refinada',
    );

    expect(first.number, 1);
    expect(second.number, 2);
    expect(workspace.projects.single.revisions.first.rawContract,
        '{"revision":1}');

    final PrototypeWorkspace restored = PrototypeWorkspace(
      repository: repository,
    );
    await restored.initialize();
    expect(restored.projects.single.revisions, hasLength(2));
  });

  test('attaches review comments to a specific revision', () async {
    final _MemoryRepository repository = _MemoryRepository();
    final PrototypeWorkspace workspace = PrototypeWorkspace(
      repository: repository,
      idFactory: (String prefix, DateTime time) =>
          '$prefix-${repository.saved.length}',
    );
    await workspace.initialize();
    final PrototypeRevision revision = await workspace.captureRevision(
      brief: 'Tela inicial',
      rawContract: '{}',
      screenId: 'home',
      screenTitle: 'Home',
    );

    await workspace.addComment(
      projectId: workspace.activeProject!.id,
      revisionId: revision.id,
      text: '  Validar o saldo oculto com design.  ',
    );

    expect(workspace.activeProject!.comments.single.text,
        'Validar o saldo oculto com design.');
    expect(workspace.activeProject!.comments.single.revisionId, revision.id);
  });

  test('serializes project data without losing revisions or comments', () {
    final DateTime now = DateTime.utc(2026, 9, 1);
    final PrototypeProject project = PrototypeProject(
      id: 'project-1',
      name: 'Banco',
      createdAt: now,
      updatedAt: now,
      revisions: <PrototypeRevision>[
        PrototypeRevision(
          id: 'revision-1',
          number: 1,
          createdAt: now,
          brief: 'Home',
          rawContract: '{}',
          screenId: 'home',
          screenTitle: 'Home',
        ),
      ],
      comments: <PrototypeReviewComment>[
        PrototypeReviewComment(
          id: 'comment-1',
          revisionId: 'revision-1',
          text: 'Revisar',
          createdAt: now,
        ),
      ],
    );

    final PrototypeProject restored =
        PrototypeProject.fromJson(project.toJson());
    expect(restored.name, 'Banco');
    expect(restored.revisions.single.screenId, 'home');
    expect(restored.comments.single.text, 'Revisar');
  });

  test('does not publish a revision when local persistence fails', () async {
    final _MemoryRepository repository = _MemoryRepository();
    final PrototypeWorkspace workspace = PrototypeWorkspace(
      repository: repository,
    );
    await workspace.initialize();
    repository.failWrites = true;

    await expectLater(
      workspace.captureRevision(
        brief: 'Falha local',
        rawContract: '{}',
        screenId: 'failure',
        screenTitle: 'Failure',
      ),
      throwsStateError,
    );
    expect(workspace.projects, isEmpty);
    expect(workspace.activeProject, isNull);
  });
}

class _MemoryRepository implements PrototypeProjectRepository {
  List<PrototypeProject> saved = <PrototypeProject>[];
  bool failWrites = false;

  @override
  Future<List<PrototypeProject>> loadProjects() async =>
      List<PrototypeProject>.from(saved);

  @override
  Future<void> saveProjects(List<PrototypeProject> projects) async {
    if (failWrites) throw StateError('Storage unavailable');
    saved = List<PrototypeProject>.from(projects);
  }
}
