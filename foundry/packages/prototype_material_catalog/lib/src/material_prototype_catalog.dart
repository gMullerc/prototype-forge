import 'package:flutter/material.dart';
import 'package:prototype_flutter/prototype_flutter.dart';
import 'package:prototype_runtime/prototype_runtime.dart';
import 'package:prototype_spec/prototype_spec.dart';

FlutterPrototypeCatalog createMaterialPrototypeCatalog({
  Iterable<FlutterComponentFactory> additionalFactories =
      const <FlutterComponentFactory>[],
}) =>
    FlutterPrototypeCatalog(<FlutterComponentFactory>[
      FlutterComponentFactory(
        contract: ComponentContract(
          type: 'Column',
          allowsChildren: true,
          properties: _layoutProperties,
        ),
        builder: _buildColumn,
      ),
      FlutterComponentFactory(
        contract: ComponentContract(
          type: 'Row',
          allowsChildren: true,
          properties: _layoutProperties,
        ),
        builder: _buildRow,
      ),
      FlutterComponentFactory(
        contract: ComponentContract(
          type: 'List',
          allowsChildren: true,
          properties: _layoutProperties,
        ),
        builder: _buildList,
      ),
      FlutterComponentFactory(
        contract: ComponentContract(
          type: 'Text',
          properties: const <String, PropertyContract>{
            'text': PropertyContract(
              type: PrototypePropertyType.string,
              required: true,
            ),
            'variant': PropertyContract(
              type: PrototypePropertyType.string,
              allowedValues: <Object>[
                'display',
                'title',
                'body',
                'label',
                'caption',
              ],
            ),
            'tone': PropertyContract(
              type: PrototypePropertyType.string,
              allowedValues: <Object>['default', 'muted', 'success', 'danger'],
            ),
            'align': PropertyContract(
              type: PrototypePropertyType.string,
              allowedValues: <Object>['start', 'center', 'end'],
            ),
          },
        ),
        builder: _buildText,
      ),
      FlutterComponentFactory(
        contract: ComponentContract(
          type: 'Icon',
          properties: const <String, PropertyContract>{
            'name': PropertyContract(
              type: PrototypePropertyType.string,
              required: true,
              allowedValues: <Object>[
                'check',
                'share',
                'receipt',
                'arrow',
                'clock',
                'person',
                'close',
                'calendar',
                'email',
                'home',
                'info',
                'lock',
                'wallet',
              ],
            ),
            'tone': PropertyContract(
              type: PrototypePropertyType.string,
              allowedValues: <Object>['default', 'muted', 'success', 'danger'],
            ),
          },
        ),
        builder: _buildIcon,
      ),
      FlutterComponentFactory(
        contract: ComponentContract(type: 'Divider'),
        builder: _buildDivider,
      ),
      FlutterComponentFactory(
        contract: ComponentContract(
          type: 'Card',
          allowsChildren: true,
          properties: const <String, PropertyContract>{
            'tone': PropertyContract(
              type: PrototypePropertyType.string,
              allowedValues: <Object>['surface', 'emphasis', 'success'],
            ),
            'padding': PropertyContract(type: PrototypePropertyType.number),
          },
        ),
        builder: _buildCard,
      ),
      FlutterComponentFactory(
        contract: ComponentContract(
          type: 'Button',
          properties: const <String, PropertyContract>{
            'label': PropertyContract(
              type: PrototypePropertyType.string,
              required: true,
            ),
            'action': PropertyContract(
              type: PrototypePropertyType.string,
              required: true,
            ),
            'style': PropertyContract(
              type: PrototypePropertyType.string,
              allowedValues: <Object>['primary', 'secondary', 'quiet'],
            ),
            'icon': PropertyContract(
              type: PrototypePropertyType.string,
              allowedValues: <Object>[
                'check',
                'share',
                'receipt',
                'arrow',
                'clock',
                'person',
                'close',
                'calendar',
                'email',
                'home',
                'info',
                'lock',
                'wallet',
              ],
            ),
            'payload': PropertyContract(type: PrototypePropertyType.object),
          },
        ),
        builder: _buildButton,
      ),
      FlutterComponentFactory(
        contract: ComponentContract(
          type: 'Avatar',
          properties: const <String, PropertyContract>{
            'name': PropertyContract(
              type: PrototypePropertyType.string,
              required: true,
            ),
            'initials': PropertyContract(type: PrototypePropertyType.string),
            'tone': PropertyContract(
              type: PrototypePropertyType.string,
              allowedValues: <Object>['brand', 'neutral', 'success'],
            ),
            'size': PropertyContract(type: PrototypePropertyType.number),
          },
        ),
        builder: _buildAvatar,
      ),
      FlutterComponentFactory(
        contract: ComponentContract(
          type: 'Badge',
          properties: const <String, PropertyContract>{
            'label': PropertyContract(
              type: PrototypePropertyType.string,
              required: true,
            ),
            'tone': PropertyContract(
              type: PrototypePropertyType.string,
              allowedValues: <Object>[
                'default',
                'info',
                'success',
                'warning',
                'danger',
              ],
            ),
          },
        ),
        builder: _buildBadge,
      ),
      FlutterComponentFactory(
        contract: ComponentContract(
          type: 'TextField',
          properties: const <String, PropertyContract>{
            'label': PropertyContract(
              type: PrototypePropertyType.string,
              required: true,
            ),
            'placeholder': PropertyContract(type: PrototypePropertyType.string),
            'value': PropertyContract(type: PrototypePropertyType.string),
            'helper': PropertyContract(type: PrototypePropertyType.string),
            'keyboard': PropertyContract(
              type: PrototypePropertyType.string,
              allowedValues: <Object>[
                'text',
                'email',
                'password',
                'number',
              ],
            ),
          },
        ),
        builder: _buildTextField,
      ),
      FlutterComponentFactory(
        contract: ComponentContract(
          type: 'Notice',
          properties: const <String, PropertyContract>{
            'title': PropertyContract(
              type: PrototypePropertyType.string,
              required: true,
            ),
            'message': PropertyContract(
              type: PrototypePropertyType.string,
              required: true,
            ),
            'tone': PropertyContract(
              type: PrototypePropertyType.string,
              allowedValues: <Object>[
                'info',
                'success',
                'warning',
                'danger',
              ],
            ),
            'icon': PropertyContract(
              type: PrototypePropertyType.string,
              allowedValues: <Object>[
                'check',
                'clock',
                'close',
                'info',
                'lock',
              ],
            ),
          },
        ),
        builder: _buildNotice,
      ),
      FlutterComponentFactory(
        contract: ComponentContract(
          type: 'Metric',
          properties: const <String, PropertyContract>{
            'label': PropertyContract(
              type: PrototypePropertyType.string,
              required: true,
            ),
            'value': PropertyContract(
              type: PrototypePropertyType.string,
              required: true,
            ),
            'trend': PropertyContract(type: PrototypePropertyType.string),
            'tone': PropertyContract(
              type: PrototypePropertyType.string,
              allowedValues: <Object>['default', 'success', 'danger'],
            ),
          },
        ),
        builder: _buildMetric,
      ),
      FlutterComponentFactory(
        contract: ComponentContract(
          type: 'ListItem',
          properties: const <String, PropertyContract>{
            'label': PropertyContract(
              type: PrototypePropertyType.string,
              required: true,
            ),
            'supporting': PropertyContract(type: PrototypePropertyType.string),
            'trailing': PropertyContract(type: PrototypePropertyType.string),
            'icon': PropertyContract(
              type: PrototypePropertyType.string,
              allowedValues: <Object>[
                'arrow',
                'calendar',
                'clock',
                'home',
                'person',
                'receipt',
                'wallet',
              ],
            ),
            'action': PropertyContract(type: PrototypePropertyType.string),
          },
        ),
        builder: _buildListItem,
      ),
      ...additionalFactories,
    ]);

const Map<String, PropertyContract> _layoutProperties =
    <String, PropertyContract>{
  'gap': PropertyContract(type: PrototypePropertyType.number),
  'align': PropertyContract(
    type: PrototypePropertyType.string,
    allowedValues: <Object>['start', 'center', 'end', 'stretch'],
  ),
};

Widget _buildColumn(PrototypeRenderContext context, PrototypeNode node) {
  final double gap = _number(node, 'gap', 12);
  final List<Widget> children = context.buildChildren();
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: _crossAxis(node.props['align'] as String?),
    children: _spaced(children, gap, Axis.vertical),
  );
}

Widget _buildRow(PrototypeRenderContext context, PrototypeNode node) {
  final double gap = _number(node, 'gap', 12);
  return Wrap(
    spacing: gap,
    runSpacing: gap,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: context.buildChildren(),
  );
}

Widget _buildList(PrototypeRenderContext context, PrototypeNode node) {
  final double gap = _number(node, 'gap', 10);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: _spaced(context.buildChildren(), gap, Axis.vertical),
  );
}

Widget _buildText(PrototypeRenderContext context, PrototypeNode node) {
  return Builder(
    builder: (BuildContext buildContext) {
      final ThemeData theme = Theme.of(buildContext);
      final String variant = node.props['variant'] as String? ?? 'body';
      final TextStyle? base = switch (variant) {
        'display' => theme.textTheme.displaySmall,
        'title' => theme.textTheme.titleLarge,
        'label' => theme.textTheme.labelLarge,
        'caption' => theme.textTheme.bodySmall,
        _ => theme.textTheme.bodyLarge,
      };
      return Text(
        node.props['text']! as String,
        textAlign: _textAlign(node.props['align'] as String?),
        style: base?.copyWith(
          color: _toneColor(theme, node.props['tone'] as String?),
          fontWeight: variant == 'display' || variant == 'title'
              ? FontWeight.w700
              : null,
          height: 1.25,
        ),
      );
    },
  );
}

Widget _buildIcon(PrototypeRenderContext context, PrototypeNode node) {
  return Builder(
    builder: (BuildContext buildContext) => Icon(
      _icon(node.props['name']! as String),
      color: _toneColor(
        Theme.of(buildContext),
        node.props['tone'] as String?,
      ),
      size: 24,
    ),
  );
}

Widget _buildDivider(PrototypeRenderContext context, PrototypeNode node) {
  return const Divider(height: 1);
}

Widget _buildCard(PrototypeRenderContext context, PrototypeNode node) {
  return Builder(
    builder: (BuildContext buildContext) {
      final ThemeData theme = Theme.of(buildContext);
      final String tone = node.props['tone'] as String? ?? 'surface';
      final Color background = switch (tone) {
        'emphasis' => theme.colorScheme.primaryContainer,
        'success' => const Color(0xFFE0F4E8),
        _ => theme.colorScheme.surface,
      };
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(_number(node, 'padding', 20)),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _spaced(context.buildChildren(), 12, Axis.vertical),
        ),
      );
    },
  );
}

Widget _buildButton(PrototypeRenderContext context, PrototypeNode node) {
  return Builder(
    builder: (BuildContext buildContext) {
      final String label = node.props['label']! as String;
      final String style = node.props['style'] as String? ?? 'primary';
      final String? iconName = node.props['icon'] as String?;
      final Widget child = Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: <Widget>[
          if (iconName != null) Icon(_icon(iconName), size: 18),
          Text(label),
        ],
      );
      final VoidCallback onPressed = () {
        context.dispatchAction(
          PrototypeActionEvent(
            name: node.props['action']! as String,
            componentId: node.id,
            payload: _payload(node.props['payload']),
          ),
        );
      };

      return switch (style) {
        'secondary' => OutlinedButton(onPressed: onPressed, child: child),
        'quiet' => TextButton(onPressed: onPressed, child: child),
        _ => FilledButton(onPressed: onPressed, child: child),
      };
    },
  );
}

Widget _buildAvatar(PrototypeRenderContext context, PrototypeNode node) {
  return Builder(
    builder: (BuildContext buildContext) {
      final ThemeData theme = Theme.of(buildContext);
      final String name = node.props['name']! as String;
      final String initials =
          node.props['initials'] as String? ?? _initials(name);
      final String tone = node.props['tone'] as String? ?? 'brand';
      final double size = _number(node, 'size', 22);
      final Color background = switch (tone) {
        'success' => theme.colorScheme.tertiaryContainer,
        'neutral' => theme.colorScheme.surfaceContainerHighest,
        _ => theme.colorScheme.primaryContainer,
      };
      final Color foreground = switch (tone) {
        'success' => theme.colorScheme.onTertiaryContainer,
        'neutral' => theme.colorScheme.onSurfaceVariant,
        _ => theme.colorScheme.onPrimaryContainer,
      };
      return Tooltip(
        message: name,
        child: CircleAvatar(
          radius: size,
          backgroundColor: background,
          child: Text(
            initials.toUpperCase(),
            style: TextStyle(
              color: foreground,
              fontSize: size * 0.42,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildBadge(PrototypeRenderContext context, PrototypeNode node) {
  return Builder(
    builder: (BuildContext buildContext) {
      final ThemeData theme = Theme.of(buildContext);
      final String tone = node.props['tone'] as String? ?? 'default';
      final ({Color background, Color foreground}) colors = _badgeColors(
        theme,
        tone,
      );
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          node.props['label']! as String,
          style: TextStyle(
            color: colors.foreground,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    },
  );
}

Widget _buildTextField(PrototypeRenderContext context, PrototypeNode node) {
  final String keyboard = node.props['keyboard'] as String? ?? 'text';
  return TextFormField(
    initialValue: node.props['value'] as String?,
    readOnly: true,
    obscureText: keyboard == 'password',
    keyboardType: switch (keyboard) {
      'email' => TextInputType.emailAddress,
      'number' => TextInputType.number,
      'password' => TextInputType.visiblePassword,
      _ => TextInputType.text,
    },
    decoration: InputDecoration(
      labelText: node.props['label']! as String,
      hintText: node.props['placeholder'] as String?,
      helperText: node.props['helper'] as String?,
    ),
  );
}

Widget _buildNotice(PrototypeRenderContext context, PrototypeNode node) {
  return Builder(
    builder: (BuildContext buildContext) {
      final ThemeData theme = Theme.of(buildContext);
      final String tone = node.props['tone'] as String? ?? 'info';
      final ({Color background, Color foreground}) colors = _noticeColors(
        theme,
        tone,
      );
      final String iconName = node.props['icon'] as String? ??
          switch (tone) {
            'success' => 'check',
            'danger' => 'close',
            _ => 'info',
          };
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.foreground.withOpacity(0.24)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(_icon(iconName), color: colors.foreground, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    node.props['title']! as String,
                    style: TextStyle(
                      color: colors.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    node.props['message']! as String,
                    style: TextStyle(color: colors.foreground, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildMetric(PrototypeRenderContext context, PrototypeNode node) {
  return Builder(
    builder: (BuildContext buildContext) {
      final ThemeData theme = Theme.of(buildContext);
      final String tone = node.props['tone'] as String? ?? 'default';
      final Color accent = switch (tone) {
        'success' => theme.colorScheme.tertiary,
        'danger' => theme.colorScheme.error,
        _ => theme.colorScheme.primary,
      };
      final String? trend = node.props['trend'] as String?;
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                node.props['label']! as String,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                node.props['value']! as String,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (trend != null && trend.isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  trend,
                  style: theme.textTheme.bodySmall?.copyWith(color: accent),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildListItem(PrototypeRenderContext context, PrototypeNode node) {
  final String? iconName = node.props['icon'] as String?;
  final String action = node.props['action'] as String? ?? '';
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: iconName == null ? null : Icon(_icon(iconName)),
    title: Text(node.props['label']! as String),
    subtitle: node.props['supporting'] == null
        ? null
        : Text(node.props['supporting']! as String),
    trailing: node.props['trailing'] == null
        ? null
        : Text(
            node.props['trailing']! as String,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
    onTap: action.isEmpty
        ? null
        : () => context.dispatchAction(
              PrototypeActionEvent(name: action, componentId: node.id),
            ),
  );
}

({Color background, Color foreground}) _badgeColors(
  ThemeData theme,
  String tone,
) {
  return switch (tone) {
    'info' => (
        background: theme.colorScheme.secondaryContainer,
        foreground: theme.colorScheme.onSecondaryContainer,
      ),
    'success' => (
        background: theme.colorScheme.tertiaryContainer,
        foreground: theme.colorScheme.onTertiaryContainer,
      ),
    'warning' => (
        background: const Color(0xFFFFE7B8),
        foreground: const Color(0xFF6B4300),
      ),
    'danger' => (
        background: theme.colorScheme.errorContainer,
        foreground: theme.colorScheme.onErrorContainer,
      ),
    _ => (
        background: theme.colorScheme.surfaceContainerHighest,
        foreground: theme.colorScheme.onSurfaceVariant,
      ),
  };
}

({Color background, Color foreground}) _noticeColors(
  ThemeData theme,
  String tone,
) {
  return switch (tone) {
    'success' => (
        background: theme.colorScheme.tertiaryContainer,
        foreground: theme.colorScheme.onTertiaryContainer,
      ),
    'warning' => (
        background: const Color(0xFFFFF4D6),
        foreground: const Color(0xFF6B4300),
      ),
    'danger' => (
        background: theme.colorScheme.errorContainer,
        foreground: theme.colorScheme.onErrorContainer,
      ),
    _ => (
        background: theme.colorScheme.secondaryContainer,
        foreground: theme.colorScheme.onSecondaryContainer,
      ),
  };
}

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

double _number(PrototypeNode node, String name, double fallback) {
  return (node.props[name] as num?)?.toDouble() ?? fallback;
}

CrossAxisAlignment _crossAxis(String? align) {
  return switch (align) {
    'center' => CrossAxisAlignment.center,
    'end' => CrossAxisAlignment.end,
    'stretch' => CrossAxisAlignment.stretch,
    _ => CrossAxisAlignment.start,
  };
}

TextAlign _textAlign(String? align) {
  return switch (align) {
    'center' => TextAlign.center,
    'end' => TextAlign.end,
    _ => TextAlign.start,
  };
}

Color? _toneColor(ThemeData theme, String? tone) {
  return switch (tone) {
    'muted' => theme.colorScheme.onSurfaceVariant,
    'success' => const Color(0xFF176B46),
    'danger' => theme.colorScheme.error,
    _ => theme.colorScheme.onSurface,
  };
}

IconData _icon(String name) {
  return switch (name) {
    'check' => Icons.check_circle_outline,
    'share' => Icons.ios_share_outlined,
    'receipt' => Icons.receipt_long_outlined,
    'arrow' => Icons.arrow_forward,
    'clock' => Icons.schedule_outlined,
    'person' => Icons.person_outline,
    'close' => Icons.close,
    'calendar' => Icons.calendar_today_outlined,
    'email' => Icons.email_outlined,
    'home' => Icons.home_outlined,
    'info' => Icons.info_outline,
    'lock' => Icons.lock_outline,
    'wallet' => Icons.account_balance_wallet_outlined,
    _ => Icons.circle_outlined,
  };
}

List<Widget> _spaced(List<Widget> children, double gap, Axis axis) {
  final List<Widget> result = <Widget>[];
  for (int index = 0; index < children.length; index++) {
    if (index > 0) {
      result.add(
        axis == Axis.vertical ? SizedBox(height: gap) : SizedBox(width: gap),
      );
    }
    result.add(children[index]);
  }
  return result;
}

Map<String, Object?> _payload(Object? value) {
  if (value is! Map<Object?, Object?>) return const <String, Object?>{};
  return <String, Object?>{
    for (final MapEntry<Object?, Object?> entry in value.entries)
      if (entry.key is String) entry.key! as String: entry.value,
  };
}
