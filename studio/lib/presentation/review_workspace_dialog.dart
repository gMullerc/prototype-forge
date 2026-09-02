import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prototype_flutter/prototype_flutter.dart';
import 'package:prototype_runtime/prototype_runtime.dart';
import 'package:prototype_workspace/prototype_workspace.dart';

import '../application/studio_session.dart';
import 'foundry_theme.dart';

class ReviewWorkspaceDialog extends StatefulWidget {
  const ReviewWorkspaceDialog({
    super.key,
    required this.session,
    required this.catalog,
  });

  final StudioSession session;
  final FlutterPrototypeCatalog catalog;

  @override
  State<ReviewWorkspaceDialog> createState() => _ReviewWorkspaceDialogState();
}

class _ReviewWorkspaceDialogState extends State<ReviewWorkspaceDialog> {
  final TextEditingController _commentController = TextEditingController();
  late StudioState _state = widget.session.current;
  StreamSubscription<StudioState>? _subscription;
  String? _comparisonRevisionId;

  @override
  void initState() {
    super.initState();
    _subscription = widget.session.states.listen((StudioState state) {
      if (!mounted) return;
      setState(() {
        _state = state;
        if (_comparisonRevisionId == state.selectedRevisionId) {
          _comparisonRevisionId = null;
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180, maxHeight: 790),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildHeader(),
            const Divider(height: 1, color: FoundryColors.ink),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  if (constraints.maxWidth < 820) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: <Widget>[
                        SizedBox(height: 310, child: _buildTimeline()),
                        const SizedBox(height: 14),
                        SizedBox(height: 560, child: _buildReviewArea()),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(width: 300, child: _buildTimeline()),
                      const VerticalDivider(
                        width: 1,
                        color: FoundryColors.ink,
                      ),
                      Expanded(child: _buildReviewArea()),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 17, 12, 16),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7B8),
              border: Border.all(color: FoundryColors.ink),
            ),
            child: const Icon(Icons.history, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Mesa de revisão local',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text(
                  'Revisões imutáveis · comparação visual · notas de decisão',
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 9,
                    color: FoundryColors.muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final PrototypeProject? project = _state.activeProject;
    final List<PrototypeRevision> revisions = project == null
        ? <PrototypeRevision>[]
        : project.revisions.reversed.toList();
    return Container(
      color: const Color(0xFFF1EBDD),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'PROJETO LOCAL',
            style: TextStyle(
              fontFamily: 'Consolas',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: FoundryColors.orange,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: const Key('review-project-selector'),
                  value: project?.id,
                  isExpanded: true,
                  hint: const Text('Nenhum projeto'),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  items: <DropdownMenuItem<String>>[
                    for (final PrototypeProject item in _state.projects)
                      DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(
                          item.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (String? id) {
                    if (id != null) widget.session.selectProject(id);
                  },
                ),
              ),
              const SizedBox(width: 7),
              IconButton.outlined(
                key: const Key('new-project-button'),
                tooltip: 'Novo projeto local',
                onPressed: _createProject,
                icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Text(
                'REVISÕES · ${revisions.length}',
                style: const TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              const Tooltip(
                message: 'Revisões salvas não são alteradas',
                child: Icon(Icons.lock_outline, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: revisions.isEmpty
                ? const Center(
                    child: Text(
                      'Gere uma tela para criar\na primeira revisão.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: FoundryColors.muted),
                    ),
                  )
                : ListView.separated(
                    itemCount: revisions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final PrototypeRevision revision = revisions[index];
                      return _RevisionTile(
                        revision: revision,
                        selected: revision.id == _state.selectedRevisionId,
                        comparing: revision.id == _comparisonRevisionId,
                        onOpen: () => widget.session.selectRevision(
                          projectId: project!.id,
                          revisionId: revision.id,
                        ),
                        onCompare: revision.id == _state.selectedRevisionId
                            ? null
                            : () => setState(
                                  () => _comparisonRevisionId =
                                      _comparisonRevisionId == revision.id
                                          ? null
                                          : revision.id,
                                ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewArea() {
    final PrototypeProject? project = _state.activeProject;
    final PrototypeRevision? selected = _state.selectedRevision;
    final PrototypeRevision? comparison =
        project == null ? null : _revisionById(project, _comparisonRevisionId);
    if (project == null || selected == null) {
      return const Center(
        child: Text(
          'Selecione uma revisão para iniciar a análise.',
          style: TextStyle(color: FoundryColors.muted),
        ),
      );
    }
    final List<PrototypeReviewComment> comments = project.comments
        .where(
          (PrototypeReviewComment comment) => comment.revisionId == selected.id,
        )
        .toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  comparison == null
                      ? 'Revisão ${selected.number} · ${selected.screenTitle}'
                      : 'Comparando revisão ${selected.number} com ${comparison.number}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (comparison != null)
                TextButton.icon(
                  onPressed: () => setState(() => _comparisonRevisionId = null),
                  icon: const Icon(Icons.close, size: 15),
                  label: const Text('ENCERRAR COMPARAÇÃO'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _RevisionPreview(
                    label: 'ATUAL · R${selected.number}',
                    revision: selected,
                    session: widget.session,
                    catalog: widget.catalog,
                  ),
                ),
                if (comparison != null) ...<Widget>[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RevisionPreview(
                      label: 'COMPARAÇÃO · R${comparison.number}',
                      revision: comparison,
                      session: widget.session,
                      catalog: widget.catalog,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 170),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E7),
              border: Border.all(color: FoundryColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'NOTAS DA REVISÃO · ${comments.length}',
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                if (comments.isNotEmpty)
                  Expanded(
                    child: ListView(
                      children: <Widget>[
                        for (final PrototypeReviewComment comment in comments)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '• ${comment.text}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  const Text(
                    'Nenhuma decisão registrada nesta revisão.',
                    style: TextStyle(
                      fontSize: 11,
                      color: FoundryColors.muted,
                    ),
                  ),
                const SizedBox(height: 7),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        key: const Key('review-comment-field'),
                        controller: _commentController,
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'Registre uma decisão ou dúvida…',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                        ),
                        onSubmitted: (_) => _addComment(),
                      ),
                    ),
                    const SizedBox(width: 7),
                    IconButton.filled(
                      key: const Key('add-review-comment-button'),
                      onPressed: _addComment,
                      icon: const Icon(Icons.arrow_upward, size: 17),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PrototypeRevision? _revisionById(
    PrototypeProject project,
    String? revisionId,
  ) {
    if (revisionId == null) return null;
    for (final PrototypeRevision revision in project.revisions) {
      if (revision.id == revisionId) return revision;
    }
    return null;
  }

  Future<void> _createProject() async {
    final TextEditingController controller = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Novo projeto local'),
        content: TextField(
          key: const Key('new-project-name-field'),
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ex.: Home do banco'),
          onSubmitted: (String value) => Navigator.of(context).pop(value),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('CRIAR'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      await widget.session.createProject(name);
      if (mounted) setState(() => _comparisonRevisionId = null);
    }
  }

  Future<void> _addComment() async {
    final String text = _commentController.text;
    if (text.trim().isEmpty) return;
    _commentController.clear();
    await widget.session.addComment(text);
  }
}

class _RevisionTile extends StatelessWidget {
  const _RevisionTile({
    required this.revision,
    required this.selected,
    required this.comparing,
    required this.onOpen,
    required this.onCompare,
  });

  final PrototypeRevision revision;
  final bool selected;
  final bool comparing;
  final VoidCallback onOpen;
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFFDDE6FA)
          : comparing
              ? const Color(0xFFFFE7B8)
              : FoundryColors.paperLight,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(11, 10, 6, 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected || comparing
                  ? FoundryColors.blue
                  : FoundryColors.line,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: FoundryColors.ink),
                ),
                child: Text(
                  '${revision.number}',
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      revision.screenTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _dateLabel(revision.createdAt),
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 8,
                        color: FoundryColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('compare-revision-${revision.number}'),
                tooltip: onCompare == null
                    ? 'Revisão aberta'
                    : comparing
                        ? 'Remover comparação'
                        : 'Comparar com a revisão aberta',
                onPressed: onCompare,
                icon: Icon(
                  comparing ? Icons.compare_arrows : Icons.compare_outlined,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _dateLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')} · '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

class _RevisionPreview extends StatelessWidget {
  const _RevisionPreview({
    required this.label,
    required this.revision,
    required this.session,
    required this.catalog,
  });

  final String label;
  final PrototypeRevision revision;
  final StudioSession session;
  final FlutterPrototypeCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final PrototypeSnapshot snapshot = session.snapshotForRevision(revision);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE2DDCF),
        border: Border.all(color: FoundryColors.ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: FoundryColors.ink,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Consolas',
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: snapshot.document == null
                ? const Center(child: Text('Revisão inválida'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Theme(
                        data: ThemeData(
                          useMaterial3: true,
                          colorScheme: ColorScheme.fromSeed(
                            seedColor: const Color(0xFF176B51),
                          ),
                        ),
                        child: PrototypeSurface(
                          document: snapshot.document!,
                          catalog: catalog,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
