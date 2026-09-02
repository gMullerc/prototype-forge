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
      'Avatar' => _exportAvatar(node, level),
      'Badge' => _exportBadge(node, level),
      'TextField' => _exportTextField(node, level),
      'Notice' => _exportNotice(node, level),
      'Metric' => _exportMetric(node, level),
      'ListItem' => _exportListItem(node, level),
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

  String _exportAvatar(PrototypeNode node, int level) {
    final String name = _string(node.props['name']);
    final String initials =
        _string(node.props['initials'], fallback: _initials(name));
    final num size = _number(node, 'size', 22);
    return '''${_indent(level)}Tooltip(
${_indent(level + 1)}message: ${_literal(name)},
${_indent(level + 1)}child: CircleAvatar(
${_indent(level + 2)}radius: ${_num(size)},
${_indent(level + 2)}child: Text(${_literal(initials.toUpperCase())}),
${_indent(level + 1)}),
${_indent(level)})''';
  }

  String _exportBadge(PrototypeNode node, int level) {
    final String tone = _string(node.props['tone'], fallback: 'default');
    return '''${_indent(level)}Container(
${_indent(level + 1)}padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
${_indent(level + 1)}decoration: BoxDecoration(
${_indent(level + 2)}color: ${_badgeBackground(tone)},
${_indent(level + 2)}borderRadius: BorderRadius.circular(999),
${_indent(level + 1)}),
${_indent(level + 1)}child: Text(
${_indent(level + 2)}${_literal(_string(node.props['label']))},
${_indent(level + 2)}style: TextStyle(
${_indent(level + 3)}color: ${_badgeForeground(tone)},
${_indent(level + 3)}fontSize: 12,
${_indent(level + 3)}fontWeight: FontWeight.w700,
${_indent(level + 2)}),
${_indent(level + 1)}),
${_indent(level)})''';
  }

  String _exportTextField(PrototypeNode node, int level) {
    final String keyboard = _string(node.props['keyboard'], fallback: 'text');
    final String? value = node.props['value'] as String?;
    final String? placeholder = node.props['placeholder'] as String?;
    final String? helper = node.props['helper'] as String?;
    return '''${_indent(level)}TextFormField(
${_indent(level + 1)}initialValue: ${value == null ? 'null' : _literal(value)},
${_indent(level + 1)}readOnly: true,
${_indent(level + 1)}obscureText: ${keyboard == 'password'},
${_indent(level + 1)}keyboardType: ${_keyboardType(keyboard)},
${_indent(level + 1)}decoration: InputDecoration(
${_indent(level + 2)}labelText: ${_literal(_string(node.props['label']))},
${_indent(level + 2)}hintText: ${placeholder == null ? 'null' : _literal(placeholder)},
${_indent(level + 2)}helperText: ${helper == null ? 'null' : _literal(helper)},
${_indent(level + 1)}),
${_indent(level)})''';
  }

  String _exportNotice(PrototypeNode node, int level) {
    final String tone = _string(node.props['tone'], fallback: 'info');
    final String icon = _string(
      node.props['icon'],
      fallback: switch (tone) {
        'success' => 'check',
        'danger' => 'close',
        _ => 'info',
      },
    );
    return '''${_indent(level)}Container(
${_indent(level + 1)}padding: const EdgeInsets.all(16),
${_indent(level + 1)}decoration: BoxDecoration(
${_indent(level + 2)}color: ${_noticeBackground(tone)},
${_indent(level + 2)}borderRadius: BorderRadius.circular(14),
${_indent(level + 1)}),
${_indent(level + 1)}child: Row(
${_indent(level + 2)}crossAxisAlignment: CrossAxisAlignment.start,
${_indent(level + 2)}children: <Widget>[
${_indent(level + 3)}Icon(${_icon(icon)}, color: ${_noticeForeground(tone)}, size: 20),
${_indent(level + 3)}const SizedBox(width: 12),
${_indent(level + 3)}Expanded(
${_indent(level + 4)}child: Column(
${_indent(level + 5)}crossAxisAlignment: CrossAxisAlignment.start,
${_indent(level + 5)}children: <Widget>[
${_indent(level + 6)}Text(
${_indent(level + 7)}${_literal(_string(node.props['title']))},
${_indent(level + 7)}style: TextStyle(fontWeight: FontWeight.w700, color: ${_noticeForeground(tone)}),
${_indent(level + 6)}),
${_indent(level + 6)}const SizedBox(height: 4),
${_indent(level + 6)}Text(
${_indent(level + 7)}${_literal(_string(node.props['message']))},
${_indent(level + 7)}style: TextStyle(color: ${_noticeForeground(tone)}, height: 1.3),
${_indent(level + 6)}),
${_indent(level + 5)}],
${_indent(level + 4)}),
${_indent(level + 3)}),
${_indent(level + 2)}],
${_indent(level + 1)}),
${_indent(level)})''';
  }

  String _exportMetric(PrototypeNode node, int level) {
    final String tone = _string(node.props['tone'], fallback: 'default');
    final String? trend = node.props['trend'] as String?;
    return '''${_indent(level)}Card(
${_indent(level + 1)}margin: EdgeInsets.zero,
${_indent(level + 1)}child: Padding(
${_indent(level + 2)}padding: const EdgeInsets.all(18),
${_indent(level + 2)}child: Column(
${_indent(level + 3)}crossAxisAlignment: CrossAxisAlignment.start,
${_indent(level + 3)}children: <Widget>[
${_indent(level + 4)}Text(${_literal(_string(node.props['label']))}, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
${_indent(level + 4)}const SizedBox(height: 8),
${_indent(level + 4)}Text(${_literal(_string(node.props['value']))}, style: TextStyle(color: ${_metricAccent(tone)}, fontSize: 22, fontWeight: FontWeight.w700)),
${trend == null || trend.isEmpty ? '' : '${_indent(level + 4)}const SizedBox(height: 6),\n${_indent(level + 4)}Text(${_literal(trend)}, style: TextStyle(color: ${_metricAccent(tone)})),\n'}${_indent(level + 3)}],
${_indent(level + 2)}),
${_indent(level + 1)}),
${_indent(level)})''';
  }

  String _exportListItem(PrototypeNode node, int level) {
    final String? icon = node.props['icon'] as String?;
    final String? supporting = node.props['supporting'] as String?;
    final String? trailing = node.props['trailing'] as String?;
    final String? action = node.props['action'] as String?;
    return '''${_indent(level)}ListTile(
${_indent(level + 1)}contentPadding: EdgeInsets.zero,
${icon == null ? '' : '${_indent(level + 1)}leading: Icon(${_icon(icon)}),\n'}${_indent(level + 1)}title: Text(${_literal(_string(node.props['label']))}),
${supporting == null ? '' : '${_indent(level + 1)}subtitle: Text(${_literal(supporting)}),\n'}${trailing == null ? '' : '${_indent(level + 1)}trailing: Text(${_literal(trailing)}, style: const TextStyle(fontWeight: FontWeight.w700)),\n'}${action == null || action.isEmpty ? '' : '''${_indent(level + 1)}onTap: () {
${_indent(level + 2)}// TODO(prototype): handle ${_literal(action)}.
${_indent(level + 1)}},
'''}${_indent(level)})''';
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

  String _badgeBackground(String tone) => switch (tone) {
        'info' => 'Theme.of(context).colorScheme.secondaryContainer',
        'success' => 'Theme.of(context).colorScheme.tertiaryContainer',
        'warning' => 'const Color(0xFFFFE7B8)',
        'danger' => 'Theme.of(context).colorScheme.errorContainer',
        _ => 'Theme.of(context).colorScheme.surfaceContainerHighest',
      };

  String _badgeForeground(String tone) => switch (tone) {
        'info' => 'Theme.of(context).colorScheme.onSecondaryContainer',
        'success' => 'Theme.of(context).colorScheme.onTertiaryContainer',
        'warning' => 'const Color(0xFF6B4300)',
        'danger' => 'Theme.of(context).colorScheme.onErrorContainer',
        _ => 'Theme.of(context).colorScheme.onSurfaceVariant',
      };

  String _noticeBackground(String tone) => switch (tone) {
        'success' => 'Theme.of(context).colorScheme.tertiaryContainer',
        'warning' => 'const Color(0xFFFFF4D6)',
        'danger' => 'Theme.of(context).colorScheme.errorContainer',
        _ => 'Theme.of(context).colorScheme.secondaryContainer',
      };

  String _noticeForeground(String tone) => switch (tone) {
        'success' => 'Theme.of(context).colorScheme.onTertiaryContainer',
        'warning' => 'const Color(0xFF6B4300)',
        'danger' => 'Theme.of(context).colorScheme.onErrorContainer',
        _ => 'Theme.of(context).colorScheme.onSecondaryContainer',
      };

  String _metricAccent(String tone) => switch (tone) {
        'success' => 'Theme.of(context).colorScheme.tertiary',
        'danger' => 'Theme.of(context).colorScheme.error',
        _ => 'Theme.of(context).colorScheme.primary',
      };

  String _keyboardType(String keyboard) => switch (keyboard) {
        'email' => 'TextInputType.emailAddress',
        'number' => 'TextInputType.number',
        'password' => 'TextInputType.visiblePassword',
        _ => 'TextInputType.text',
      };

  String _icon(String value) => switch (value) {
        'check' => 'Icons.check_circle_outline',
        'share' => 'Icons.ios_share_outlined',
        'receipt' => 'Icons.receipt_long_outlined',
        'arrow' => 'Icons.arrow_forward',
        'clock' => 'Icons.schedule_outlined',
        'person' => 'Icons.person_outline',
        'close' => 'Icons.close',
        'calendar' => 'Icons.calendar_today_outlined',
        'email' => 'Icons.email_outlined',
        'home' => 'Icons.home_outlined',
        'info' => 'Icons.info_outline',
        'lock' => 'Icons.lock_outline',
        'wallet' => 'Icons.account_balance_wallet_outlined',
        _ => 'Icons.circle_outlined',
      };

  num _number(PrototypeNode node, String name, num fallback) =>
      node.props[name] is num ? node.props[name]! as num : fallback;

  String _string(Object? value, {String fallback = ''}) =>
      value is String ? value : fallback;

  String _indent(int level) => '  ' * level;

  String _num(num value) => value is int ? '$value' : value.toString();

  String _literal(String value) =>
      "'${value.replaceAll('\\', '\\\\').replaceAll("'", "\\'").replaceAll(r'$', r'\$').replaceAll('\n', r'\n').replaceAll('\r', r'\r').replaceAll('\t', r'\t')}'";

  String _initials(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1);
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}';
  }

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
