import 'package:flutter/material.dart';
import 'package:prototype_flutter/prototype_flutter.dart';
import 'package:prototype_runtime/prototype_runtime.dart';
import 'package:prototype_spec/prototype_spec.dart';

FlutterPrototypeCatalog createMaterialPrototypeCatalog() =>
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
              ],
            ),
            'payload': PropertyContract(type: PrototypePropertyType.object),
          },
        ),
        builder: _buildButton,
      ),
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
      final Widget child = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (iconName != null) ...<Widget>[
            Icon(_icon(iconName), size: 18),
            const SizedBox(width: 8),
          ],
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
