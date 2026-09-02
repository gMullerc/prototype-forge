import 'dart:async';

import 'package:prototype_agent/prototype_agent.dart';
import 'package:prototype_export/prototype_export.dart';
import 'package:prototype_runtime/prototype_runtime.dart';
import 'package:prototype_workspace/prototype_workspace.dart';

import '../domain/studio_message.dart';

enum StudioGenerationStatus {
  idle,
  generating,
  ready,
  invalid,
  failed,
}

const Object _unset = Object();

class StudioState {
  StudioState({
    required this.status,
    required List<StudioMessage> messages,
    required this.snapshot,
    List<PrototypeProject> projects = const <PrototypeProject>[],
    this.activeProjectId,
    this.selectedRevisionId,
    this.workspaceReady = false,
  })  : messages = List<StudioMessage>.unmodifiable(messages),
        projects = List<PrototypeProject>.unmodifiable(projects);

  factory StudioState.initial() => StudioState(
        status: StudioGenerationStatus.idle,
        messages: const <StudioMessage>[
          StudioMessage(
            role: StudioMessageRole.assistant,
            text:
                'Descreva uma hipótese de produto. Eu vou compor uma tela usando apenas o contrato aprovado.',
          ),
        ],
        snapshot: const PrototypeSnapshot.idle(),
      );

  final StudioGenerationStatus status;
  final List<StudioMessage> messages;
  final PrototypeSnapshot snapshot;
  final List<PrototypeProject> projects;
  final String? activeProjectId;
  final String? selectedRevisionId;
  final bool workspaceReady;

  PrototypeProject? get activeProject {
    final String? id = activeProjectId;
    if (id == null) return null;
    for (final PrototypeProject project in projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  PrototypeRevision? get selectedRevision {
    final PrototypeProject? project = activeProject;
    final String? id = selectedRevisionId;
    if (project == null || id == null) return null;
    for (final PrototypeRevision revision in project.revisions) {
      if (revision.id == id) return revision;
    }
    return null;
  }

  StudioState copyWith({
    StudioGenerationStatus? status,
    List<StudioMessage>? messages,
    PrototypeSnapshot? snapshot,
    List<PrototypeProject>? projects,
    Object? activeProjectId = _unset,
    Object? selectedRevisionId = _unset,
    bool? workspaceReady,
  }) {
    return StudioState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      snapshot: snapshot ?? this.snapshot,
      projects: projects ?? this.projects,
      activeProjectId: identical(activeProjectId, _unset)
          ? this.activeProjectId
          : activeProjectId as String?,
      selectedRevisionId: identical(selectedRevisionId, _unset)
          ? this.selectedRevisionId
          : selectedRevisionId as String?,
      workspaceReady: workspaceReady ?? this.workspaceReady,
    );
  }
}

class StudioSession {
  StudioSession({
    required Iterable<PrototypeAgent> agents,
    required String initialAgentId,
    required PrototypeEngine engine,
    required PrototypeWorkspace workspace,
    required PrototypeExporter exporter,
  })  : _agents = <String, PrototypeAgent>{
          for (final PrototypeAgent agent in agents) agent.id: agent,
        },
        _selectedAgentId = initialAgentId,
        _engine = engine,
        _workspace = workspace,
        _exporter = exporter,
        _state = StudioState.initial() {
    if (_agents.isEmpty) {
      throw ArgumentError('Ao menos um agente precisa ser registrado.');
    }
    if (!_agents.containsKey(initialAgentId)) {
      throw ArgumentError('Agente inicial não registrado: $initialAgentId.');
    }
  }

  final Map<String, PrototypeAgent> _agents;
  String _selectedAgentId;
  final PrototypeEngine _engine;
  final PrototypeWorkspace _workspace;
  final PrototypeExporter _exporter;
  final StreamController<StudioState> _states =
      StreamController<StudioState>.broadcast();
  StudioState _state;
  bool _disposed = false;
  bool _initialized = false;
  String? _lastPrompt;

  StudioState get current => _state;
  Stream<StudioState> get states => _states.stream;
  List<PrototypeAgent> get agents =>
      List<PrototypeAgent>.unmodifiable(_agents.values);
  PrototypeAgent get agent => _agents[_selectedAgentId]!;
  String get exporterLabel => _exporter.label;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _workspace.initialize();
      final PrototypeProject? project = _workspace.activeProject;
      final PrototypeRevision? revision =
          project == null || project.revisions.isEmpty
              ? null
              : project.revisions.last;
      final PrototypeSnapshot snapshot = revision == null
          ? const PrototypeSnapshot.idle()
          : _engine.load(revision.rawContract);
      _emit(
        _state.copyWith(
          status: _statusFor(snapshot),
          snapshot: snapshot,
          projects: _workspace.projects,
          activeProjectId: project?.id,
          selectedRevisionId: revision?.id,
          workspaceReady: true,
        ),
      );
    } on Object catch (error) {
      _emit(
        _state.copyWith(
          messages: <StudioMessage>[
            ..._state.messages,
            StudioMessage(
              role: StudioMessageRole.error,
              text: 'Não foi possível carregar os projetos locais: $error',
            ),
          ],
          workspaceReady: true,
        ),
      );
    }
  }

  bool selectAgent(String id) {
    if (_state.status == StudioGenerationStatus.generating ||
        !_agents.containsKey(id)) {
      return false;
    }
    if (_selectedAgentId == id) return true;
    _selectedAgentId = id;
    _emit(_state);
    return true;
  }

  Future<void> sendPrompt(String prompt) async {
    final String trimmed = prompt.trim();
    if (trimmed.isEmpty || _state.status == StudioGenerationStatus.generating) {
      return;
    }
    _lastPrompt = trimmed;

    _emit(
      _state.copyWith(
        status: StudioGenerationStatus.generating,
        messages: <StudioMessage>[
          ..._state.messages,
          StudioMessage(role: StudioMessageRole.user, text: trimmed),
        ],
      ),
    );

    try {
      final String response = await agent.generate(
        PrototypeBrief(text: trimmed),
      );
      final PrototypeSnapshot snapshot = _engine.load(response);
      if (snapshot.status == PrototypeStatus.ready) {
        final PrototypeRevision? revision =
            await _captureRevision(trimmed, snapshot);
        _emit(
          _state.copyWith(
            status: StudioGenerationStatus.ready,
            messages: <StudioMessage>[
              ..._state.messages,
              StudioMessage(
                role: StudioMessageRole.assistant,
                text: revision == null
                    ? 'Contrato validado. A composição está pronta, mas não pôde ser salva localmente.'
                    : 'Contrato validado. Revisão ${revision.number} salva localmente e pronta para revisão.',
              ),
            ],
            snapshot: snapshot,
            projects: _workspace.projects,
            activeProjectId: _workspace.activeProjectId,
            selectedRevisionId: revision?.id,
          ),
        );
      } else {
        _emit(
          _state.copyWith(
            status: StudioGenerationStatus.invalid,
            messages: <StudioMessage>[
              ..._state.messages,
              StudioMessage(
                role: StudioMessageRole.error,
                text: snapshot.issues.length == 1
                    ? 'O contrato foi rejeitado em 1 ponto. A prancheta mostra como corrigir.'
                    : 'O contrato foi rejeitado em ${snapshot.issues.length} pontos. A prancheta mostra cada correção.',
              ),
            ],
            snapshot: snapshot,
          ),
        );
      }
    } on Object catch (error) {
      _emit(
        _state.copyWith(
          status: StudioGenerationStatus.failed,
          messages: <StudioMessage>[
            ..._state.messages,
            StudioMessage(
              role: StudioMessageRole.error,
              text:
                  'O agente ${agent.label} ficou indisponível durante a geração. Verifique o serviço e tente novamente. Detalhes: $error',
            ),
          ],
        ),
      );
    }
  }

  Future<void> retryLastPrompt() async {
    final String? prompt = _lastPrompt;
    if (prompt != null) await sendPrompt(prompt);
  }

  Future<void> createProject(String name) async {
    final PrototypeProject project = await _workspace.createProject(name);
    _emit(
      _state.copyWith(
        status: StudioGenerationStatus.idle,
        messages: <StudioMessage>[
          ..._state.messages,
          StudioMessage(
            role: StudioMessageRole.system,
            text: 'Projeto local criado: ${project.name}',
          ),
        ],
        snapshot: const PrototypeSnapshot.idle(),
        projects: _workspace.projects,
        activeProjectId: project.id,
        selectedRevisionId: null,
      ),
    );
  }

  bool selectProject(String id) {
    if (!_workspace.selectProject(id)) return false;
    final PrototypeProject project = _workspace.activeProject!;
    final PrototypeRevision? revision =
        project.revisions.isEmpty ? null : project.revisions.last;
    final PrototypeSnapshot snapshot = revision == null
        ? const PrototypeSnapshot.idle()
        : _engine.load(revision.rawContract);
    _emit(
      _state.copyWith(
        status: _statusFor(snapshot),
        snapshot: snapshot,
        projects: _workspace.projects,
        activeProjectId: project.id,
        selectedRevisionId: revision?.id,
      ),
    );
    return true;
  }

  bool selectRevision({
    required String projectId,
    required String revisionId,
  }) {
    final PrototypeProject? project = _workspace.projectById(projectId);
    if (project == null) return false;
    PrototypeRevision? selected;
    for (final PrototypeRevision revision in project.revisions) {
      if (revision.id == revisionId) selected = revision;
    }
    if (selected == null) return false;
    _workspace.selectProject(projectId);
    final PrototypeSnapshot snapshot = _engine.load(selected.rawContract);
    _emit(
      _state.copyWith(
        status: _statusFor(snapshot),
        snapshot: snapshot,
        projects: _workspace.projects,
        activeProjectId: projectId,
        selectedRevisionId: revisionId,
      ),
    );
    return true;
  }

  PrototypeSnapshot snapshotForRevision(PrototypeRevision revision) =>
      _engine.load(revision.rawContract);

  Future<void> addComment(String text) async {
    final PrototypeProject? project = _state.activeProject;
    final PrototypeRevision? revision = _state.selectedRevision;
    if (project == null || revision == null) return;
    await _workspace.addComment(
      projectId: project.id,
      revisionId: revision.id,
      text: text,
    );
    _emit(_state.copyWith(projects: _workspace.projects));
  }

  PrototypeExportArtifact exportCurrentDraft() {
    final document = _state.snapshot.document;
    if (_state.snapshot.status != PrototypeStatus.ready || document == null) {
      throw StateError('Selecione uma revisão válida antes de exportar.');
    }
    return _exporter.export(document);
  }

  void recordAction({required String name, required String componentId}) {
    _emit(
      _state.copyWith(
        messages: <StudioMessage>[
          ..._state.messages,
          StudioMessage(
            role: StudioMessageRole.system,
            text: 'Ação capturada: $name · componente $componentId',
          ),
        ],
      ),
    );
  }

  Future<PrototypeRevision?> _captureRevision(
    String brief,
    PrototypeSnapshot snapshot,
  ) async {
    final document = snapshot.document!;
    try {
      return await _workspace.captureRevision(
        brief: brief,
        rawContract: snapshot.rawResponse,
        screenId: document.screen.id,
        screenTitle: document.screen.title,
      );
    } on Object {
      return null;
    }
  }

  StudioGenerationStatus _statusFor(PrototypeSnapshot snapshot) =>
      switch (snapshot.status) {
        PrototypeStatus.ready => StudioGenerationStatus.ready,
        PrototypeStatus.invalid => StudioGenerationStatus.invalid,
        PrototypeStatus.idle => StudioGenerationStatus.idle,
      };

  void _emit(StudioState next) {
    if (_disposed) return;
    _state = next;
    _states.add(next);
  }

  void dispose() {
    _disposed = true;
    _states.close();
  }
}
