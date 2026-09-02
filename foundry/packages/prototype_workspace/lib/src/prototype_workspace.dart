import 'project_models.dart';
import 'project_repository.dart';

typedef WorkspaceClock = DateTime Function();
typedef WorkspaceIdFactory = String Function(String prefix, DateTime time);

class PrototypeWorkspace {
  PrototypeWorkspace({
    required PrototypeProjectRepository repository,
    WorkspaceClock? clock,
    WorkspaceIdFactory? idFactory,
  })  : _repository = repository,
        _clock = clock ?? DateTime.now,
        _idFactory = idFactory ?? _defaultId;

  final PrototypeProjectRepository _repository;
  final WorkspaceClock _clock;
  final WorkspaceIdFactory _idFactory;
  List<PrototypeProject> _projects = <PrototypeProject>[];
  String? _activeProjectId;

  List<PrototypeProject> get projects =>
      List<PrototypeProject>.unmodifiable(_projects);

  String? get activeProjectId => _activeProjectId;

  PrototypeProject? get activeProject {
    final String? id = _activeProjectId;
    if (id == null) return null;
    return projectById(id);
  }

  Future<void> initialize() async {
    _projects = List<PrototypeProject>.from(await _repository.loadProjects());
    _projects.sort(
      (PrototypeProject left, PrototypeProject right) =>
          right.updatedAt.compareTo(left.updatedAt),
    );
    _activeProjectId = _projects.isEmpty ? null : _projects.first.id;
  }

  PrototypeProject? projectById(String id) {
    for (final PrototypeProject project in _projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  Future<PrototypeProject> createProject(String name) async {
    final String normalized = name.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(name, 'name', 'O nome não pode ser vazio.');
    }
    final DateTime now = _clock();
    final PrototypeProject project = PrototypeProject(
      id: _idFactory('project', now),
      name: normalized,
      createdAt: now,
      updatedAt: now,
    );
    final List<PrototypeProject> next = <PrototypeProject>[
      project,
      ..._projects,
    ];
    await _persist(next);
    _projects = next;
    _activeProjectId = project.id;
    return project;
  }

  bool selectProject(String id) {
    if (projectById(id) == null) return false;
    _activeProjectId = id;
    return true;
  }

  Future<PrototypeRevision> captureRevision({
    required String brief,
    required String rawContract,
    required String screenId,
    required String screenTitle,
  }) async {
    PrototypeProject project = activeProject ?? _implicitProject(screenTitle);
    final DateTime now = _clock();
    final PrototypeRevision revision = PrototypeRevision(
      id: _idFactory('revision', now),
      number: project.revisions.length + 1,
      createdAt: now,
      brief: brief.trim(),
      rawContract: rawContract,
      screenId: screenId,
      screenTitle: screenTitle,
    );
    project = project.copyWith(
      updatedAt: now,
      revisions: <PrototypeRevision>[...project.revisions, revision],
    );
    final List<PrototypeProject> next = _replacing(project);
    await _persist(next);
    _projects = next;
    _activeProjectId = project.id;
    return revision;
  }

  Future<PrototypeReviewComment> addComment({
    required String projectId,
    required String revisionId,
    required String text,
  }) async {
    final String normalized = text.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
          text, 'text', 'O comentário não pode ser vazio.');
    }
    final PrototypeProject? current = projectById(projectId);
    if (current == null) {
      throw StateError('Projeto não encontrado: $projectId');
    }
    if (!current.revisions.any(
      (PrototypeRevision revision) => revision.id == revisionId,
    )) {
      throw StateError('Revisão não encontrada: $revisionId');
    }
    final DateTime now = _clock();
    final PrototypeReviewComment comment = PrototypeReviewComment(
      id: _idFactory('comment', now),
      revisionId: revisionId,
      text: normalized,
      createdAt: now,
    );
    final PrototypeProject updated = current.copyWith(
      updatedAt: now,
      comments: <PrototypeReviewComment>[...current.comments, comment],
    );
    final List<PrototypeProject> next = _replacing(updated);
    await _persist(next);
    _projects = next;
    return comment;
  }

  PrototypeProject _implicitProject(String screenTitle) {
    final DateTime now = _clock();
    final PrototypeProject project = PrototypeProject(
      id: _idFactory('project', now),
      name: screenTitle.trim().isEmpty ? 'Novo protótipo' : screenTitle.trim(),
      createdAt: now,
      updatedAt: now,
    );
    return project;
  }

  List<PrototypeProject> _replacing(PrototypeProject replacement) =>
      <PrototypeProject>[
        replacement,
        for (final PrototypeProject project in _projects)
          if (project.id != replacement.id) project,
      ];

  Future<void> _persist(List<PrototypeProject> projects) =>
      _repository.saveProjects(List<PrototypeProject>.unmodifiable(projects));

  static String _defaultId(String prefix, DateTime time) =>
      '$prefix-${time.microsecondsSinceEpoch}';
}
