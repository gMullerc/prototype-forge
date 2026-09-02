import 'package:prototype_export/prototype_export.dart';
import 'package:prototype_spec/prototype_spec.dart';

class MaterialDraftExporter implements PrototypeExporter {
  const MaterialDraftExporter();

  @override
  String get id => 'flutter-material-draft';

  @override
  String get label => 'Flutter Material';

  @override
  PrototypeExportArtifact export(PrototypeDocument document) {
    final String className = '${_pascalCase(document.screen.id)}Draft';
    final String fileName = '${_snakeCase(document.screen.id)}_draft.dart';
    final String root = _exportNode(document.screen.root, 5);
    return PrototypeExportArtifact(
      fileName: fileName,
      language: 'dart',
      source:
          '''// Generated deterministically from Prototype Spec ${document.specVersion}.
// Review actions, navigation and product state before production use.
import 'package:flutter/material.dart';

class $className extends StatelessWidget {
  const $className({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child:
$root,
        ),
      ),
    );
  }
}
''',
    );
  }

  String _exportNode(PrototypeNode node, int level) {
    return switch (node.type) {
      'Column' => _exportColumn(node, level),
      'Row' => _exportRow(node, level),
      'List' => _exportList(node, level),
      'Text' => _exportText(node, level),
      'Icon' => _exportIcon(node, level),
      'Divider' => '${_indent(level)}const Divider(height: 1)',
      'Card' => _exportCard(node, level),
      'Button' => _exportButton(node, level),
      _ => throw UnsupportedError(
          'Material exporter does not support component ${node.type}.',
        ),
    };
  }

  String _exportColumn(PrototypeNode node, int level) {
    final num gap = _number(node, 'gap', 12);
    return '''${_indent(level)}Column(
${_indent(level + 1)}mainAxisSize: MainAxisSize.min,
${_indent(level + 1)}crossAxisAlignment: ${_crossAxis(node.props['align'])},
${_children(node.children, level + 1, gap: gap, vertical: true)}
${_indent(level)})''';
  }

  String _exportRow(PrototypeNode node, int level) {
    final num gap = _number(node, 'gap', 12);
    return '''${_indent(level)}Wrap(
${_indent(level + 1)}spacing: ${_num(gap)},
${_indent(level + 1)}runSpacing: ${_num(gap)},
${_indent(level + 1)}crossAxisAlignment: WrapCrossAlignment.center,
${_children(node.children, level + 1)}
${_indent(level)})''';
  }

  String _exportList(PrototypeNode node, int level) {
    final num gap = _number(node, 'gap', 10);
    return '''${_indent(level)}Column(
${_indent(level + 1)}mainAxisSize: MainAxisSize.min,
${_indent(level + 1)}crossAxisAlignment: CrossAxisAlignment.stretch,
${_children(node.children, level + 1, gap: gap, vertical: true)}
${_indent(level)})''';
  }

  String _exportText(PrototypeNode node, int level) {
    final String text = _string(node.props['text']);
    final String variant = _string(node.props['variant'], fallback: 'body');
    final String align = switch (node.props['align']) {
      'center' => 'TextAlign.center',
      'end' => 'TextAlign.end',
      _ => 'TextAlign.start',
    };
    final String baseStyle = switch (variant) {
      'display' => 'Theme.of(context).textTheme.displaySmall',
      'title' => 'Theme.of(context).textTheme.titleLarge',
      'label' => 'Theme.of(context).textTheme.labelLarge',
      'caption' => 'Theme.of(context).textTheme.bodySmall',
      _ => 'Theme.of(context).textTheme.bodyLarge',
    };
    final String? color = switch (node.props['tone']) {
      'muted' => 'Theme.of(context).colorScheme.onSurfaceVariant',
      'success' => 'const Color(0xFF176B46)',
      'danger' => 'Theme.of(context).colorScheme.error',
      _ => null,
    };
    final bool emphasized = variant == 'display' || variant == 'title';
    final List<String> changes = <String>[
      if (color != null) 'color: $color',
      if (emphasized) 'fontWeight: FontWeight.w700',
      'height: 1.25',
    ];
    return '''${_indent(level)}Text(
${_indent(level + 1)}${_literal(text)},
${_indent(level + 1)}textAlign: $align,
${_indent(level + 1)}style: $baseStyle?.copyWith(${changes.join(', ')}),
${_indent(level)})''';
  }

  String _exportIcon(PrototypeNode node, int level) {
    final String icon = _icon(_string(node.props['name']));
    final String? color = _toneColor(node.props['tone']);
    return '''${_indent(level)}Icon(
${_indent(level + 1)}$icon,
${color == null ? '' : '${_indent(level + 1)}color: $color,\n'}${_indent(level + 1)}size: 24,
${_indent(level)})''';
  }

  String _exportCard(PrototypeNode node, int level) {
    final num padding = _number(node, 'padding', 20);
    final String background = switch (node.props['tone']) {
      'emphasis' => 'Theme.of(context).colorScheme.primaryContainer',
      'success' => 'const Color(0xFFE0F4E8)',
      _ => 'Theme.of(context).colorScheme.surface',
    };
    return '''${_indent(level)}Container(
${_indent(level + 1)}width: double.infinity,
${_indent(level + 1)}padding: const EdgeInsets.all(${_num(padding)}),
${_indent(level + 1)}decoration: BoxDecoration(
${_indent(level + 2)}color: $background,
${_indent(level + 2)}borderRadius: BorderRadius.circular(18),
${_indent(level + 2)}border: Border.all(
${_indent(level + 3)}color: Theme.of(context).colorScheme.outlineVariant,
${_indent(level + 2)}),
${_indent(level + 1)}),
${_indent(level + 1)}child: Column(
${_indent(level + 2)}mainAxisSize: MainAxisSize.min,
${_indent(level + 2)}crossAxisAlignment: CrossAxisAlignment.stretch,
${_children(node.children, level + 2, gap: 12, vertical: true)}
${_indent(level + 1)}),
${_indent(level)})''';
  }

  String _exportButton(PrototypeNode node, int level) {
    final String label = _string(node.props['label']);
    final String action = _string(node.props['action']);
    final String style = _string(node.props['style'], fallback: 'primary');
    final String widget = switch (style) {
      'secondary' => 'OutlinedButton',
      'quiet' => 'TextButton',
      _ => 'FilledButton',
    };
    final Object? iconValue = node.props['icon'];
    final bool hasIcon = iconValue is String;
    final String constructor = hasIcon ? '$widget.icon' : widget;
    return '''${_indent(level)}$constructor(
${_indent(level + 1)}onPressed: () {
${_indent(level + 2)}// TODO(prototype): handle ${_literal(action)}.
${_indent(level + 1)}},
${hasIcon ? '${_indent(level + 1)}icon: Icon(${_icon(iconValue)}),\n' : ''}${_indent(level + 1)}${hasIcon ? 'label' : 'child'}: Text(${_literal(label)}),
${_indent(level)})''';
  }

  String _children(
    List<PrototypeNode> nodes,
    int level, {
    num? gap,
    bool vertical = false,
  }) {
    final List<String> children = <String>[];
    for (int index = 0; index < nodes.length; index++) {
      if (index > 0 && gap != null) {
        children.add(
          '${_indent(level + 1)}const SizedBox(${vertical ? 'height' : 'width'}: ${_num(gap)})',
        );
      }
      children.add(_exportNode(nodes[index], level + 1));
    }
    return '''${_indent(level)}children: <Widget>[
${children.map((String child) => '$child,').join('\n')}
${_indent(level)}],''';
  }

  String _crossAxis(Object? value) => switch (value) {
        'center' => 'CrossAxisAlignment.center',
        'end' => 'CrossAxisAlignment.end',
        'stretch' => 'CrossAxisAlignment.stretch',
        _ => 'CrossAxisAlignment.start',
      };

  String? _toneColor(Object? value) => switch (value) {
        'muted' => 'Theme.of(context).colorScheme.onSurfaceVariant',
        'success' => 'const Color(0xFF176B46)',
        'danger' => 'Theme.of(context).colorScheme.error',
        _ => null,
      };

  String _icon(String value) => switch (value) {
        'check' => 'Icons.check_circle_outline',
        'share' => 'Icons.ios_share_outlined',
        'receipt' => 'Icons.receipt_long_outlined',
        'arrow' => 'Icons.arrow_forward',
        'clock' => 'Icons.schedule_outlined',
        'person' => 'Icons.person_outline',
        'close' => 'Icons.close',
        _ => 'Icons.circle_outlined',
      };

  num _number(PrototypeNode node, String name, num fallback) =>
      node.props[name] is num ? node.props[name]! as num : fallback;

  String _string(Object? value, {String fallback = ''}) =>
      value is String ? value : fallback;

  String _indent(int level) => '  ' * level;

  String _num(num value) => value is int ? '$value' : value.toString();

  String _literal(String value) =>
      "'${value.replaceAll('\\', '\\\\').replaceAll("'", "\\'").replaceAll(r'$', r'\$').replaceAll('\n', r'\n')}'";

  String _pascalCase(String value) {
    final List<String> parts = value
        .split(RegExp('[^A-Za-z0-9]+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    final String result = parts
        .map((String part) =>
            '${part.substring(0, 1).toUpperCase()}${part.substring(1)}')
        .join();
    if (result.isEmpty) return 'Prototype';
    return RegExp(r'^[0-9]').hasMatch(result) ? 'Prototype$result' : result;
  }

  String _snakeCase(String value) {
    final String result = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return result.isEmpty ? 'prototype' : result;
  }
}
