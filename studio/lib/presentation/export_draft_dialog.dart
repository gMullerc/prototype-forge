import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prototype_export/prototype_export.dart';

import 'foundry_theme.dart';

class ExportDraftDialog extends StatefulWidget {
  const ExportDraftDialog({
    super.key,
    required this.artifact,
    required this.exporterLabel,
  });

  final PrototypeExportArtifact artifact;
  final String exporterLabel;

  @override
  State<ExportDraftDialog> createState() => _ExportDraftDialogState();
}

class _ExportDraftDialogState extends State<ExportDraftDialog> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 18, 17),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    color: FoundryColors.blue,
                    child: const Icon(Icons.code, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Rascunho Flutter para revisão',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${widget.exporterLabel} · ${widget.artifact.fileName}',
                          style: const TextStyle(
                            fontFamily: 'Consolas',
                            fontSize: 10,
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
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
              color: const Color(0xFFFFE7B8),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.rate_review_outlined, size: 18),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Este arquivo é um rascunho determinístico. Revise ações, estado e navegação antes de usar em produção.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                key: const Key('export-source'),
                margin: const EdgeInsets.all(18),
                padding: const EdgeInsets.all(18),
                color: FoundryColors.ink,
                child: SingleChildScrollView(
                  child: SelectableText(
                    widget.artifact.source,
                    style: const TextStyle(
                      fontFamily: 'Consolas',
                      color: Color(0xFFE7F4EA),
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('FECHAR'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const Key('copy-export-button'),
                    onPressed: _copy,
                    icon: Icon(_copied ? Icons.check : Icons.copy, size: 17),
                    label: Text(_copied ? 'COPIADO' : 'COPIAR CÓDIGO'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.artifact.source));
    if (mounted) setState(() => _copied = true);
  }
}
