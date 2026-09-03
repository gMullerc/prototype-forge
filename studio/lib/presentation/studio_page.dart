import 'dart:async';

import 'package:flutter/material.dart';
import 'package:prototype_agent/prototype_agent.dart';
import 'package:prototype_export/prototype_export.dart';
import 'package:prototype_flutter/prototype_flutter.dart';
import 'package:prototype_runtime/prototype_runtime.dart';
import 'package:prototype_tool_discovery/prototype_tool_discovery.dart';
import 'package:prototype_workspace/prototype_workspace.dart';

import '../application/studio_session.dart';
import '../domain/studio_message.dart';
import '../infrastructure/workspace_transfer/workspace_transfer.dart';
import 'contract_rejection_panel.dart';
import 'export_draft_dialog.dart';
import 'foundry_theme.dart';
import 'review_workspace_dialog.dart';

enum _PreviewViewport {
  phone(width: 390, radius: 28, padding: 28),
  tablet(width: 720, radius: 18, padding: 34),
  desktop(width: 1040, radius: 5, padding: 38);

  const _PreviewViewport({
    required this.width,
    required this.radius,
    required this.padding,
  });

  final double width;
  final double radius;
  final double padding;
}

class StudioPage extends StatefulWidget {
  const StudioPage({
    super.key,
    required this.session,
    required this.catalog,
    this.workspaceTransfer,
    this.toolDiscovery,
  });

  final StudioSession session;
  final FlutterPrototypeCatalog catalog;
  final WorkspaceTransfer? workspaceTransfer;
  final ToolDiscovery? toolDiscovery;

  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _messagesController = ScrollController();
  late StudioState _state = widget.session.current;
  StreamSubscription<StudioState>? _subscription;
  _PreviewViewport _viewport = _PreviewViewport.phone;
  PrototypeSurfaceMode _surfaceMode = PrototypeSurfaceMode.interactive;
  late final WorkspaceTransfer _workspaceTransfer =
      widget.workspaceTransfer ?? createWorkspaceTransfer();

  @override
  void initState() {
    super.initState();
    _subscription = widget.session.states.listen((StudioState state) {
      if (!mounted) return;
      setState(() => _state = state);
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (_messagesController.hasClients) {
          _messagesController.animateTo(
            _messagesController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _promptController.dispose();
    _messagesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: _BlueprintGrid()),
          SafeArea(
            child: Column(
              children: <Widget>[
                _Header(
                  state: _state,
                  agentLabel: widget.session.agent.label,
                  onOpenTools:
                      widget.toolDiscovery == null ? null : _showToolInventory,
                ),
                _ProjectBar(
                  state: _state,
                  onSelectProject: widget.session.selectProject,
                  onCreateProject: _createProject,
                  onOpenReview: _showReviewWorkspace,
                  onExportWorkspace: _exportWorkspace,
                  onImportWorkspace: _importWorkspace,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      if (constraints.maxWidth < 900) {
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          children: <Widget>[
                            SizedBox(height: 520, child: _buildBriefingPanel()),
                            const SizedBox(height: 16),
                            SizedBox(height: 720, child: _buildCanvas()),
                          ],
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            SizedBox(width: 400, child: _buildBriefingPanel()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildCanvas()),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showToolInventory() async {
    final ToolDiscovery? discovery = widget.toolDiscovery;
    if (discovery == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _ToolInventoryDialog(discovery: discovery),
    );
  }

  Widget _buildBriefingPanel() {
    return _FramedPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _PanelHeading(
            index: '01',
            eyebrow: 'BRIEFING',
            title: 'Nova hipótese',
            trailing: _AgentSelector(
              agents: widget.session.agents,
              selectedId: widget.session.agent.id,
              enabled: _state.status != StudioGenerationStatus.generating,
              onSelected: widget.session.selectAgent,
            ),
          ),
          const Divider(height: 1, color: FoundryColors.ink),
          Expanded(
            child: ListView.separated(
              controller: _messagesController,
              padding: const EdgeInsets.all(18),
              itemCount: _state.messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (BuildContext context, int index) => _MessageCard(
                message: _state.messages[index],
                onOptionSelected: (String option) {
                  widget.session.sendPrompt(option);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: <Widget>[
                _Suggestion(
                  label: 'Comprovante de pagamento',
                  onTap: () => _useSuggestion(
                    'Crie um comprovante de pagamento para Marina Souza no valor de R\$ 250,00.',
                  ),
                ),
                _Suggestion(
                  label: 'Hipótese de onboarding',
                  onTap: () => _useSuggestion(
                    'Crie uma hipótese de onboarding para novos clientes.',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    key: const Key('prompt-field'),
                    controller: _promptController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Descreva a tela, o fluxo ou a hipótese…',
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                SizedBox(
                  width: 52,
                  height: 52,
                  child: FilledButton(
                    key: const Key('send-prompt-button'),
                    onPressed:
                        _state.status == StudioGenerationStatus.generating
                            ? widget.session.cancelGeneration
                            : _sendPrompt,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: FoundryColors.orange,
                      foregroundColor: FoundryColors.ink,
                    ),
                    child: _state.status == StudioGenerationStatus.generating
                        ? const Icon(Icons.stop_rounded, size: 22)
                        : const Icon(Icons.arrow_upward, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return _FramedPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _PanelHeading(
            index: '02',
            eyebrow: 'PRANCHETA',
            title:
                _state.snapshot.document?.screen.title ?? 'Superfície validada',
            trailing: _state.selectedRevision == null
                ? null
                : _RevisionBadge(revision: _state.selectedRevision!),
          ),
          const Divider(height: 1, color: FoundryColors.ink),
          _CanvasToolbar(
            viewport: _viewport,
            mode: _surfaceMode,
            canReview: _state.activeProject?.revisions.isNotEmpty ?? false,
            canExport: _state.snapshot.status == PrototypeStatus.ready,
            canViewContract: _state.snapshot.rawResponse.isNotEmpty,
            onViewportChanged: (_PreviewViewport value) =>
                setState(() => _viewport = value),
            onModeChanged: (PrototypeSurfaceMode value) =>
                setState(() => _surfaceMode = value),
            onReview: _showReviewWorkspace,
            onExport: _showExport,
            onViewContract: _showContract,
          ),
          const Divider(height: 1, color: FoundryColors.ink),
          Expanded(
            child: Container(
              color: const Color(0xFFE2DDCF),
              padding: const EdgeInsets.all(24),
              child: Center(child: _buildSurfaceState()),
            ),
          ),
          _CanvasFooter(state: _state, mode: _surfaceMode),
        ],
      ),
    );
  }

  Widget _buildSurfaceState() {
    final PrototypeSnapshot snapshot = _state.snapshot;
    if (_state.status == StudioGenerationStatus.generating) {
      return const _EmptyCanvas(
        icon: Icons.architecture,
        title: 'Compondo o contrato…',
        description:
            'O motor está organizando componentes e propriedades. Toque no botão laranja para cancelar.',
      );
    }
    if (_state.status == StudioGenerationStatus.awaitingClarification &&
        snapshot.document == null) {
      return const _EmptyCanvas(
        icon: Icons.forum_outlined,
        title: 'Aguardando sua resposta',
        description:
            'Responda à pergunta no briefing para que o agente conclua a composição.',
      );
    }
    if (snapshot.status == PrototypeStatus.invalid) {
      return ContractRejectionPanel(
        issues: snapshot.issues,
        onRetry: widget.session.retryLastPrompt,
        onViewContract: _showContract,
      );
    }
    if (snapshot.document == null) {
      return const _EmptyCanvas(
        icon: Icons.grid_view_outlined,
        title: 'A prancheta está livre',
        description: 'Envie um briefing para iniciar a primeira composição.',
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double targetWidth = constraints.maxWidth < _viewport.width
            ? constraints.maxWidth
            : _viewport.width;
        return AnimatedContainer(
          key: Key('preview-${_viewport.name}'),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: targetWidth,
          constraints: const BoxConstraints(maxHeight: 720),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F5),
            borderRadius: BorderRadius.circular(_viewport.radius),
            border: Border.all(color: FoundryColors.ink, width: 1.4),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: FoundryColors.ink.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(8, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(_viewport.padding),
            child: Theme(
              data: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF176B51),
                  brightness: Brightness.light,
                ),
              ),
              child: PrototypeSurface(
                document: snapshot.document!,
                catalog: widget.catalog,
                mode: _surfaceMode,
                onAction: (PrototypeActionEvent event) {
                  if (_surfaceMode == PrototypeSurfaceMode.inspect) {
                    widget.session.recordAction(
                      name: event.name,
                      componentId: event.componentId,
                    );
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _useSuggestion(String prompt) {
    _promptController.text = prompt;
    _sendPrompt();
  }

  void _sendPrompt() {
    final String prompt = _promptController.text;
    _promptController.clear();
    widget.session.sendPrompt(prompt);
  }

  void _showReviewWorkspace() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => ReviewWorkspaceDialog(
        session: widget.session,
        catalog: widget.catalog,
      ),
    );
  }

  void _showExport() {
    final PrototypeExportArtifact artifact =
        widget.session.exportCurrentDraft();
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => ExportDraftDialog(
        artifact: artifact,
        exporterLabel: widget.session.exporterLabel,
      ),
    );
  }

  Future<void> _createProject() async {
    final TextEditingController controller = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Novo projeto local'),
        content: TextField(
          key: const Key('quick-project-name-field'),
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ex.: Jornada de fatura'),
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
    }
  }

  Future<void> _exportWorkspace() async {
    try {
      await _workspaceTransfer.downloadText(
        filename: 'prototype-foundry-workspace.json',
        contents: widget.session.exportWorkspaceJson(),
      );
      if (mounted) {
        _showWorkspaceMessage('Backup do workspace exportado.');
      }
    } on Object catch (error) {
      if (mounted) _showWorkspaceMessage('Não foi possível exportar: $error');
    }
  }

  Future<void> _importWorkspace() async {
    try {
      final String? source = await _workspaceTransfer.pickText();
      if (source == null) return;
      await widget.session.importWorkspaceJson(source);
      if (mounted) _showWorkspaceMessage('Backup importado com sucesso.');
    } on FormatException catch (error) {
      if (mounted) _showWorkspaceMessage('Backup inválido: ${error.message}');
    } on Object catch (error) {
      if (mounted) _showWorkspaceMessage('Não foi possível importar: $error');
    }
  }

  void _showWorkspaceMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showContract() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 680),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'PROTOTYPE SPEC / 1.0',
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    color: FoundryColors.ink,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _state.snapshot.rawResponse,
                        style: const TextStyle(
                          fontFamily: 'Consolas',
                          color: Color(0xFFE7F4EA),
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('FECHAR'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectBar extends StatelessWidget {
  const _ProjectBar({
    required this.state,
    required this.onSelectProject,
    required this.onCreateProject,
    required this.onOpenReview,
    required this.onExportWorkspace,
    required this.onImportWorkspace,
  });

  final StudioState state;
  final ValueChanged<String> onSelectProject;
  final VoidCallback onCreateProject;
  final VoidCallback onOpenReview;
  final Future<void> Function() onExportWorkspace;
  final Future<void> Function() onImportWorkspace;

  @override
  Widget build(BuildContext context) {
    final PrototypeProject? project = state.activeProject;
    final bool generationInProgress =
        state.status == StudioGenerationStatus.generating;
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFE8E1D2),
        border: Border.symmetric(
          horizontal: BorderSide(color: FoundryColors.ink),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: <Widget>[
            const Icon(Icons.folder_open_outlined, size: 17),
            const SizedBox(width: 7),
            const Text(
              'PROJETO',
              style: TextStyle(
                fontFamily: 'Consolas',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 9),
            SizedBox(
              width: 230,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const Key('project-selector'),
                  value: project?.id,
                  isExpanded: true,
                  hint: const Text(
                    'Criado na primeira geração',
                    style: TextStyle(fontSize: 11),
                  ),
                  items: <DropdownMenuItem<String>>[
                    for (final PrototypeProject item in state.projects)
                      DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(
                          item.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                  onChanged: generationInProgress
                      ? null
                      : (String? value) {
                          if (value != null) onSelectProject(value);
                        },
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              key: const Key('quick-new-project-button'),
              onPressed: generationInProgress ? null : onCreateProject,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('NOVO'),
            ),
            const SizedBox(width: 5),
            TextButton.icon(
              key: const Key('review-workspace-button'),
              onPressed:
                  project?.revisions.isNotEmpty ?? false ? onOpenReview : null,
              icon: const Icon(Icons.history, size: 16),
              label: Text(
                project == null
                    ? 'REVISÕES'
                    : 'REVISÕES · ${project.revisions.length}',
              ),
            ),
            PopupMenuButton<String>(
              key: const Key('workspace-menu'),
              tooltip: 'Backup do workspace local',
              onSelected: (String action) {
                if (action == 'export') {
                  unawaited(onExportWorkspace());
                } else {
                  unawaited(onImportWorkspace());
                }
              },
              itemBuilder: (BuildContext context) =>
                  const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'export',
                  child: Text('Exportar backup'),
                ),
                PopupMenuItem<String>(
                  value: 'import',
                  child: Text('Importar backup'),
                ),
              ],
              icon: const Icon(Icons.more_horiz, size: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: FoundryColors.success),
              ),
              child: const Text(
                'LOCAL',
                style: TextStyle(
                  fontFamily: 'Consolas',
                  color: FoundryColors.success,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CanvasToolbar extends StatelessWidget {
  const _CanvasToolbar({
    required this.viewport,
    required this.mode,
    required this.canReview,
    required this.canExport,
    required this.canViewContract,
    required this.onViewportChanged,
    required this.onModeChanged,
    required this.onReview,
    required this.onExport,
    required this.onViewContract,
  });

  final _PreviewViewport viewport;
  final PrototypeSurfaceMode mode;
  final bool canReview;
  final bool canExport;
  final bool canViewContract;
  final ValueChanged<_PreviewViewport> onViewportChanged;
  final ValueChanged<PrototypeSurfaceMode> onModeChanged;
  final VoidCallback onReview;
  final VoidCallback onExport;
  final VoidCallback onViewContract;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 47,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: <Widget>[
            const Text(
              'VIEWPORT',
              style: TextStyle(
                fontFamily: 'Consolas',
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: FoundryColors.muted,
              ),
            ),
            const SizedBox(width: 7),
            for (final _PreviewViewport item in _PreviewViewport.values)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _ViewportButton(
                  viewport: item,
                  selected: item == viewport,
                  onPressed: () => onViewportChanged(item),
                ),
              ),
            const SizedBox(width: 10),
            Container(width: 1, height: 22, color: FoundryColors.line),
            const SizedBox(width: 8),
            const Text(
              'MODO',
              style: TextStyle(
                fontFamily: 'Consolas',
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: FoundryColors.muted,
              ),
            ),
            const SizedBox(width: 7),
            _SurfaceModeButton(
              key: const Key('surface-mode-interactive'),
              label: 'INTERAGIR',
              icon: Icons.touch_app_outlined,
              selected: mode == PrototypeSurfaceMode.interactive,
              onPressed: () => onModeChanged(PrototypeSurfaceMode.interactive),
            ),
            const SizedBox(width: 4),
            _SurfaceModeButton(
              key: const Key('surface-mode-inspect'),
              label: 'INSPECIONAR',
              icon: Icons.manage_search_outlined,
              selected: mode == PrototypeSurfaceMode.inspect,
              onPressed: () => onModeChanged(PrototypeSurfaceMode.inspect),
            ),
            const SizedBox(width: 10),
            Container(width: 1, height: 22, color: FoundryColors.line),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: canReview ? onReview : null,
              icon: const Icon(Icons.compare_outlined, size: 16),
              label: const Text('REVISAR'),
            ),
            TextButton.icon(
              key: const Key('export-draft-button'),
              onPressed: canExport ? onExport : null,
              icon: const Icon(Icons.code, size: 16),
              label: const Text('EXPORTAR DART'),
            ),
            TextButton.icon(
              onPressed: canViewContract ? onViewContract : null,
              icon: const Icon(Icons.data_object, size: 16),
              label: const Text('CONTRATO'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceModeButton extends StatelessWidget {
  const _SurfaceModeButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: selected ? FoundryColors.ink : Colors.transparent,
        foregroundColor: selected ? Colors.white : FoundryColors.ink,
        side: const BorderSide(color: FoundryColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }
}

class _ViewportButton extends StatelessWidget {
  const _ViewportButton({
    required this.viewport,
    required this.selected,
    required this.onPressed,
  });

  final _PreviewViewport viewport;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final IconData icon = switch (viewport) {
      _PreviewViewport.phone => Icons.phone_android,
      _PreviewViewport.tablet => Icons.tablet_mac,
      _PreviewViewport.desktop => Icons.desktop_windows_outlined,
    };
    return IconButton(
      key: Key('viewport-${viewport.name}'),
      tooltip: switch (viewport) {
        _PreviewViewport.phone => 'Celular',
        _PreviewViewport.tablet => 'Tablet',
        _PreviewViewport.desktop => 'Desktop',
      },
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: selected ? FoundryColors.ink : Colors.transparent,
        foregroundColor: selected ? Colors.white : FoundryColors.ink,
        side: const BorderSide(color: FoundryColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      icon: Icon(icon, size: 15),
    );
  }
}

class _RevisionBadge extends StatelessWidget {
  const _RevisionBadge({required this.revision});

  final PrototypeRevision revision;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      color: const Color(0xFFFFE7B8),
      child: Text(
        'REV ${revision.number.toString().padLeft(2, '0')}',
        style: const TextStyle(
          fontFamily: 'Consolas',
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.agentLabel,
    this.onOpenTools,
  });

  final StudioState state;
  final String agentLabel;
  final VoidCallback? onOpenTools;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: FoundryColors.orange,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.gesture, color: FoundryColors.ink),
          ),
          const SizedBox(width: 13),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'PROTOTYPE FOUNDRY',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Contract-first product lab',
                style: TextStyle(fontSize: 11, letterSpacing: 0.8),
              ),
            ],
          ),
          const Spacer(),
          if (MediaQuery.of(context).size.width > 700) ...<Widget>[
            const _Stamp(label: 'SPEC 1.1', color: FoundryColors.blue),
            const SizedBox(width: 8),
            _Stamp(label: agentLabel.toUpperCase(), color: FoundryColors.ink),
            const SizedBox(width: 8),
          ],
          IconButton(
            key: const Key('tool-discovery-button'),
            onPressed: onOpenTools,
            tooltip: 'Ferramentas disponíveis neste computador',
            icon: const Icon(Icons.devices_other_outlined, size: 18),
          ),
          const SizedBox(width: 4),
          _StatusMark(status: state.status),
        ],
      ),
    );
  }
}

class _ToolInventoryDialog extends StatefulWidget {
  const _ToolInventoryDialog({required this.discovery});

  final ToolDiscovery discovery;

  @override
  State<_ToolInventoryDialog> createState() => _ToolInventoryDialogState();
}

class _ToolInventoryDialogState extends State<_ToolInventoryDialog> {
  List<DiscoveredTool> _tools = const <DiscoveredTool>[];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<DiscoveredTool> tools = await widget.discovery.discover();
      if (!mounted) return;
      setState(() {
        _tools = tools;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ferramentas deste computador'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'A detecção consulta apenas executáveis acessíveis no PATH. '
              'Tokens, keychains e arquivos de credenciais não são lidos.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (_loading && _tools.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ToolInventoryError(error: _error!, onRetry: _refresh)
            else ...<Widget>[
              for (final DiscoveredTool tool in _tools)
                _ToolInventoryRow(tool: tool),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton.icon(
          onPressed: _loading ? null : _refresh,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('ATUALIZAR'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('FECHAR'),
        ),
      ],
    );
  }
}

class _ToolInventoryRow extends StatelessWidget {
  const _ToolInventoryRow({required this.tool});

  final DiscoveredTool tool;

  @override
  Widget build(BuildContext context) {
    final bool available = tool.availability == ToolAvailability.available;
    final bool failed = tool.availability == ToolAvailability.probeError;
    final Color color = available
        ? FoundryColors.success
        : failed
            ? FoundryColors.orange
            : FoundryColors.muted;
    final String state = available
        ? 'DETECTADA'
        : failed
            ? 'ERRO NO PROBE'
            : 'NÃO INSTALADA';
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            available
                ? Icons.check_circle_outline
                : failed
                    ? Icons.warning_amber_outlined
                    : Icons.radio_button_unchecked,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: Text(tool.definition.label)),
                    Text(
                      state,
                      style: TextStyle(
                        color: color,
                        fontFamily: 'Consolas',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tool.version ??
                      (available
                          ? tool.diagnostic ?? 'Executável acessível no PATH.'
                          : 'Comando: ${tool.definition.executable}'),
                  style: const TextStyle(
                    color: FoundryColors.muted,
                    fontSize: 11,
                  ),
                ),
                if (!available && tool.definition.setupHint != null)
                  Text(
                    'Configuração manual: ${tool.definition.setupHint}',
                    style: const TextStyle(
                      color: FoundryColors.muted,
                      fontFamily: 'Consolas',
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolInventoryError extends StatelessWidget {
  const _ToolInventoryError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Icon(Icons.cloud_off_outlined, size: 28),
        const SizedBox(height: 8),
        const Text(
          'Não foi possível consultar o gateway local.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: FoundryColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 10),
        TextButton(onPressed: onRetry, child: const Text('TENTAR NOVAMENTE')),
      ],
    );
  }
}

class _AgentSelector extends StatelessWidget {
  const _AgentSelector({
    required this.agents,
    required this.selectedId,
    required this.enabled,
    required this.onSelected,
  });

  final List<PrototypeAgent> agents;
  final String selectedId;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final PrototypeAgent selected = agents.firstWhere(
      (PrototypeAgent agent) => agent.id == selectedId,
    );
    return PopupMenuButton<String>(
      key: const Key('agent-selector'),
      enabled: enabled,
      tooltip: 'Selecionar motor de geração',
      onSelected: onSelected,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        for (final PrototypeAgent agent in agents)
          PopupMenuItem<String>(
            value: agent.id,
            child: Row(
              children: <Widget>[
                Icon(
                  agent.id == selectedId
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 17,
                  color: agent.id == selectedId
                      ? FoundryColors.orange
                      : FoundryColors.ink,
                ),
                const SizedBox(width: 9),
                Text(agent.label),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: FoundryColors.ink),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.hub_outlined, size: 15),
            const SizedBox(width: 6),
            Text(
              selected.label.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.expand_more, size: 16),
          ],
        ),
      ),
    );
  }
}

class _FramedPanel extends StatelessWidget {
  const _FramedPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: FoundryColors.paperLight,
        border: Border.all(color: FoundryColors.ink, width: 1.4),
        borderRadius: BorderRadius.circular(4),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: FoundryColors.ink.withOpacity(0.08),
            offset: const Offset(4, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PanelHeading extends StatelessWidget {
  const _PanelHeading({
    required this.index,
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  final String index;
  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: FoundryColors.ink),
              shape: BoxShape.circle,
            ),
            child: Text(
              index,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  eyebrow,
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    color: FoundryColors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.onOptionSelected,
  });

  final StudioMessage message;
  final ValueChanged<String> onOptionSelected;

  @override
  Widget build(BuildContext context) {
    final bool user = message.role == StudioMessageRole.user;
    final bool error = message.role == StudioMessageRole.error;
    final bool system = message.role == StudioMessageRole.system;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: user
              ? FoundryColors.ink
              : error
                  ? const Color(0xFFFFE1D8)
                  : system
                      ? const Color(0xFFDDE6FA)
                      : const Color(0xFFE8E1D2),
          border: Border.all(
            color: error ? FoundryColors.orange : FoundryColors.ink,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
            bottomLeft: Radius.circular(user ? 3 : 14),
            bottomRight: Radius.circular(user ? 14 : 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              message.text,
              style: TextStyle(
                color: user ? Colors.white : FoundryColors.ink,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (message.options.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final String option in message.options)
                    OutlinedButton(
                      onPressed: () => onOptionSelected(option),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FoundryColors.ink,
                        side: const BorderSide(color: FoundryColors.ink),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                      child: Text(option),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: FoundryColors.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}

class _CanvasFooter extends StatelessWidget {
  const _CanvasFooter({required this.state, required this.mode});

  final StudioState state;
  final PrototypeSurfaceMode mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: FoundryColors.ink)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.lock_outline, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              state.status == StudioGenerationStatus.awaitingClarification
                  ? 'Aguardando resposta do briefing'
                  : mode == PrototypeSurfaceMode.interactive
                      ? 'Interação declarativa local · nenhuma execução de código'
                      : 'Inspeção de eventos · nenhuma execução de código',
              style: const TextStyle(fontSize: 10),
            ),
          ),
          Text(
            state.selectedRevision == null
                ? 'SEM REVISÃO'
                : '${state.activeProject?.name.toUpperCase()} · REV ${state.selectedRevision!.number.toString().padLeft(2, '0')}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Consolas',
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCanvas extends StatelessWidget {
  const _EmptyCanvas({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: FoundryColors.orange,
            shape: BoxShape.circle,
            border: Border.all(color: FoundryColors.ink, width: 1.4),
          ),
          child: Icon(icon, size: 30),
        ),
        const SizedBox(height: 20),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 7),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: FoundryColors.muted),
        ),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.018,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: color, width: 1.4)),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontFamily: 'Consolas',
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _StatusMark extends StatelessWidget {
  const _StatusMark({required this.status});

  final StudioGenerationStatus status;

  @override
  Widget build(BuildContext context) {
    final bool working = status == StudioGenerationStatus.generating;
    final bool waiting = status == StudioGenerationStatus.awaitingClarification;
    final bool failed = status == StudioGenerationStatus.failed ||
        status == StudioGenerationStatus.invalid;
    final Color color = failed
        ? FoundryColors.orange
        : working || waiting
            ? FoundryColors.blue
            : FoundryColors.success;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: FoundryColors.ink),
      ),
    );
  }
}

class _BlueprintGrid extends StatelessWidget {
  const _BlueprintGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint minor = Paint()
      ..color = FoundryColors.line.withOpacity(0.28)
      ..strokeWidth = 0.7;
    const double step = 24;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minor);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
