import 'package:flutter/material.dart';
import 'package:prototype_runtime/prototype_runtime.dart';

import 'foundry_theme.dart';

class ContractRejectionPanel extends StatelessWidget {
  const ContractRejectionPanel({
    super.key,
    required this.issues,
    required this.onRetry,
    required this.onViewContract,
  });

  final List<ValidationIssue> issues;
  final VoidCallback onRetry;
  final VoidCallback onViewContract;

  @override
  Widget build(BuildContext context) {
    final List<ValidationIssue> ordered = List<ValidationIssue>.from(issues)
      ..sort(
        (ValidationIssue left, ValidationIssue right) =>
            left.priority.index.compareTo(right.priority.index),
      );
    return Container(
      key: const Key('contract-rejection-panel'),
      constraints: const BoxConstraints(maxWidth: 700, maxHeight: 680),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EC),
        border: Border.all(color: FoundryColors.orange, width: 1.4),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: FoundryColors.orange.withOpacity(0.12),
            offset: const Offset(7, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: FoundryColors.orange,
                    border: Border.all(color: FoundryColors.ink),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.rule_folder_outlined, size: 21),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Contrato bloqueado antes do preview',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        ordered.length == 1
                            ? 'Encontramos 1 incompatibilidade. Nada inválido foi renderizado.'
                            : 'Encontramos ${ordered.length} incompatibilidades. Nada inválido foi renderizado.',
                        style: const TextStyle(
                          color: FoundryColors.muted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: FoundryColors.orange),
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.all(18),
              shrinkWrap: true,
              itemCount: ordered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) =>
                  _IssueCard(issue: ordered[index], index: index + 1),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFE3D9),
              border: Border(top: BorderSide(color: FoundryColors.orange)),
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: <Widget>[
                TextButton.icon(
                  onPressed: onViewContract,
                  icon: const Icon(Icons.data_object, size: 17),
                  label: const Text('VER CONTRATO'),
                ),
                FilledButton.icon(
                  key: const Key('retry-contract-button'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('GERAR NOVAMENTE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue, required this.index});

  final ValidationIssue issue;
  final int index;

  @override
  Widget build(BuildContext context) {
    final String? target = switch ((issue.componentId, issue.propertyName)) {
      (final String id, final String property) => '$id · $property',
      (final String id, null) => id,
      (null, final String property) => property,
      _ => null,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FoundryColors.paperLight,
        border: Border.all(color: FoundryColors.ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                color: _priorityColor(issue.priority),
                child: Text(
                  '${index.toString().padLeft(2, '0')} · ${issue.code.toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              if (target != null) ...<Widget>[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    target,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Consolas',
                      fontSize: 10,
                      color: FoundryColors.blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 11),
          Text(issue.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 7),
          Text(issue.suggestion, style: const TextStyle(height: 1.4)),
          if (issue.expected != null ||
              issue.receivedValue != null) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: <Widget>[
                if (issue.receivedValue != null)
                  _Fact(label: 'RECEBIDO', value: issue.receivedValue!),
                if (issue.expected != null)
                  _Fact(label: 'ESPERADO', value: issue.expected!),
              ],
            ),
          ],
          const SizedBox(height: 9),
          Text(
            '${issue.path} · ${issue.message}',
            style: const TextStyle(
              fontFamily: 'Consolas',
              fontSize: 9,
              color: FoundryColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(ValidationIssuePriority priority) => switch (priority) {
        ValidationIssuePriority.critical => FoundryColors.orange,
        ValidationIssuePriority.high => const Color(0xFFFFCDBD),
        ValidationIssuePriority.medium => const Color(0xFFFFE3D9),
      };
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: '$label  ',
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: FoundryColors.orange,
              ),
            ),
            TextSpan(text: value, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
