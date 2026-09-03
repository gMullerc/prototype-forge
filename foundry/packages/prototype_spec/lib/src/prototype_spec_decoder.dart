import 'dart:convert';

import 'prototype_document.dart';

class PrototypeSpecDecoder {
  const PrototypeSpecDecoder();

  static const String supportedVersion = '1.1';
  static const Set<String> supportedVersions = <String>{'1.0', '1.1'};

  PrototypeDocument decode(String source) {
    final String payload = _extractJsonPayload(source);
    Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException catch (error) {
      throw PrototypeSpecException(r'$', 'Invalid JSON: ${error.message}');
    }

    final Map<String, Object?> root = _map(decoded, r'$');
    final String version = _string(root['specVersion'], r'$.specVersion');
    if (!supportedVersions.contains(version)) {
      throw PrototypeSpecException(
        r'$.specVersion',
        'Unsupported version "$version". Expected 1.0 or 1.1.',
      );
    }

    final bool supportsInteraction = version == '1.1';
    _onlyKeys(
      root,
      <String>{
        'specVersion',
        'screen',
        if (supportsInteraction) 'interaction',
      },
      r'$',
    );

    final Map<String, Object?> screenMap = _map(root['screen'], r'$.screen');
    _onlyKeys(
      screenMap,
      const <String>{'id', 'title', 'root'},
      r'$.screen',
    );

    return PrototypeDocument(
      specVersion: version,
      interaction: root['interaction'] == null
          ? null
          : _interaction(root['interaction'], r'$.interaction'),
      screen: PrototypeScreen(
        id: _nonEmptyString(screenMap['id'], r'$.screen.id'),
        title: _nonEmptyString(screenMap['title'], r'$.screen.title'),
        root: _node(
          screenMap['root'],
          r'$.screen.root',
          supportsInteraction: supportsInteraction,
        ),
      ),
    );
  }

  String _extractJsonPayload(String source) {
    final String trimmed = source.trim();
    if (trimmed.isEmpty) {
      throw const PrototypeSpecException(r'$', 'The response is empty.');
    }

    final RegExp fenced = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      caseSensitive: false,
    );
    final RegExpMatch? match = fenced.firstMatch(trimmed);
    return (match == null ? trimmed : match.group(1)!).trim();
  }

  PrototypeNode _node(
    Object? value,
    String path, {
    required bool supportsInteraction,
  }) {
    final Map<String, Object?> map = _map(value, path);
    _onlyKeys(
      map,
      <String>{
        'id',
        'type',
        'props',
        'children',
        if (supportsInteraction) 'interaction',
      },
      path,
    );

    final Object? rawProps = map['props'];
    final Map<String, Object?> props = rawProps == null
        ? const <String, Object?>{}
        : _map(rawProps, '$path.props');

    final Object? rawChildren = map['children'];
    final List<Object?> children = rawChildren == null
        ? const <Object?>[]
        : _list(rawChildren, '$path.children');

    return PrototypeNode(
      id: _nonEmptyString(map['id'], '$path.id'),
      type: _nonEmptyString(map['type'], '$path.type'),
      props: props,
      interaction: map['interaction'] == null
          ? null
          : _nodeInteraction(map['interaction'], '$path.interaction'),
      children: <PrototypeNode>[
        for (int index = 0; index < children.length; index++)
          _node(
            children[index],
            '$path.children[$index]',
            supportsInteraction: supportsInteraction,
          ),
      ],
    );
  }

  PrototypeInteractionSpec _interaction(Object? value, String path) {
    final Map<String, Object?> map = _map(value, path);
    _onlyKeys(map, const <String>{'initialState', 'actions'}, path);
    final Map<String, Object?> initialState = map['initialState'] == null
        ? const <String, Object?>{}
        : _map(map['initialState'], '$path.initialState');
    for (final MapEntry<String, Object?> entry in initialState.entries) {
      _scalar(entry.value, '$path.initialState.${entry.key}');
    }
    final List<Object?> actions = map['actions'] == null
        ? const <Object?>[]
        : _list(map['actions'], '$path.actions');
    final List<PrototypeActionDefinition> definitions =
        <PrototypeActionDefinition>[];
    final Set<String> names = <String>{};
    for (int index = 0; index < actions.length; index++) {
      final String actionPath = '$path.actions[$index]';
      final Map<String, Object?> action = _map(actions[index], actionPath);
      _onlyKeys(action, const <String>{'name', 'effects'}, actionPath);
      final String name = _nonEmptyString(action['name'], '$actionPath.name');
      if (!names.add(name)) {
        throw PrototypeSpecException(
          '$actionPath.name',
          'Duplicate interaction action "$name".',
        );
      }
      final List<Object?> effects =
          _list(action['effects'], '$actionPath.effects');
      if (effects.isEmpty) {
        throw PrototypeSpecException(
          '$actionPath.effects',
          'An interaction action needs at least one effect.',
        );
      }
      definitions.add(
        PrototypeActionDefinition(
          name: name,
          effects: <PrototypeEffect>[
            for (int effectIndex = 0;
                effectIndex < effects.length;
                effectIndex++)
              _effect(
                effects[effectIndex],
                '$actionPath.effects[$effectIndex]',
              ),
          ],
        ),
      );
    }
    return PrototypeInteractionSpec(
      initialState: initialState,
      actions: definitions,
    );
  }

  PrototypeEffect _effect(Object? value, String path) {
    final Map<String, Object?> map = _map(value, path);
    _onlyKeys(
      map,
      const <String>{'type', 'key', 'value', 'message', 'tone'},
      path,
    );
    final String type = _nonEmptyString(map['type'], '$path.type');
    const Set<String> supported = <String>{
      'setValue',
      'toggleValue',
      'reset',
      'validate',
      'showMessage',
    };
    if (!supported.contains(type)) {
      throw PrototypeSpecException(
        '$path.type',
        'Unsupported interaction effect "$type".',
      );
    }
    final String? key = map['key'] == null
        ? null
        : _nonEmptyString(map['key'], '$path.key');
    if ((type == 'setValue' || type == 'toggleValue') && key == null) {
      throw PrototypeSpecException('$path.key', 'Effect "$type" needs a key.');
    }
    if (map.containsKey('value')) _scalar(map['value'], '$path.value');
    final String? message = map['message'] == null
        ? null
        : _nonEmptyString(map['message'], '$path.message');
    if (type == 'showMessage' && message == null) {
      throw PrototypeSpecException(
        '$path.message',
        'Effect "showMessage" needs a message.',
      );
    }
    final String? tone = map['tone'] == null
        ? null
        : _nonEmptyString(map['tone'], '$path.tone');
    if (tone != null &&
        !const <String>{'info', 'success', 'warning', 'error'}.contains(tone)) {
      throw PrototypeSpecException('$path.tone', 'Unsupported message tone.');
    }
    return PrototypeEffect(
      type: type,
      key: key,
      value: map['value'],
      message: message,
      tone: tone,
    );
  }

  PrototypeNodeInteraction _nodeInteraction(Object? value, String path) {
    final Map<String, Object?> map = _map(value, path);
    _onlyKeys(
      map,
      const <String>{
        'valueKey',
        'required',
        'visibleWhen',
        'selectedWhen',
        'validations',
      },
      path,
    );
    final Object? requiredValue = map['required'];
    if (requiredValue != null && requiredValue is! bool) {
      throw PrototypeSpecException('$path.required', 'Expected a boolean.');
    }
    final List<Object?> validations = map['validations'] == null
        ? const <Object?>[]
        : _list(map['validations'], '$path.validations');
    return PrototypeNodeInteraction(
      valueKey: map['valueKey'] == null
          ? null
          : _nonEmptyString(map['valueKey'], '$path.valueKey'),
      required: requiredValue as bool? ?? false,
      visibleWhen: map['visibleWhen'] == null
          ? null
          : _condition(map['visibleWhen'], '$path.visibleWhen'),
      selectedWhen: map['selectedWhen'] == null
          ? null
          : _condition(map['selectedWhen'], '$path.selectedWhen'),
      validations: <PrototypeValidationRule>[
        for (int index = 0; index < validations.length; index++)
          _validation(validations[index], '$path.validations[$index]'),
      ],
    );
  }

  PrototypeStateCondition _condition(Object? value, String path) {
    final Map<String, Object?> map = _map(value, path);
    _onlyKeys(map, const <String>{'key', 'equals'}, path);
    if (!map.containsKey('equals')) {
      throw PrototypeSpecException('$path.equals', 'Condition needs a value.');
    }
    _scalar(map['equals'], '$path.equals');
    return PrototypeStateCondition(
      key: _nonEmptyString(map['key'], '$path.key'),
      equals: map['equals'],
    );
  }

  PrototypeValidationRule _validation(Object? value, String path) {
    final Map<String, Object?> map = _map(value, path);
    _onlyKeys(map, const <String>{'type', 'value'}, path);
    final String type = _nonEmptyString(map['type'], '$path.type');
    if (!const <String>{'cpf', 'cnpj', 'minAge'}.contains(type)) {
      throw PrototypeSpecException(
        '$path.type',
        'Unsupported validation "$type".',
      );
    }
    if (type == 'minAge' && map['value'] is! num) {
      throw PrototypeSpecException(
        '$path.value',
        'Validation "minAge" needs a numeric value.',
      );
    }
    return PrototypeValidationRule(type: type, value: map['value']);
  }

  Map<String, Object?> _map(Object? value, String path) {
    if (value is! Map<Object?, Object?>) {
      throw PrototypeSpecException(path, 'Expected a JSON object.');
    }

    final Map<String, Object?> result = <String, Object?>{};
    for (final MapEntry<Object?, Object?> entry in value.entries) {
      if (entry.key is! String) {
        throw PrototypeSpecException(path, 'Object keys must be strings.');
      }
      result[entry.key! as String] = entry.value;
    }
    return result;
  }

  List<Object?> _list(Object? value, String path) {
    if (value is! List<Object?>) {
      throw PrototypeSpecException(path, 'Expected a JSON array.');
    }
    return value;
  }

  String _string(Object? value, String path) {
    if (value is! String) {
      throw PrototypeSpecException(path, 'Expected a string.');
    }
    return value;
  }

  String _nonEmptyString(Object? value, String path) {
    final String text = _string(value, path).trim();
    if (text.isEmpty) {
      throw PrototypeSpecException(path, 'The value cannot be empty.');
    }
    return text;
  }

  void _scalar(Object? value, String path) {
    if (value != null && value is! String && value is! num && value is! bool) {
      throw PrototypeSpecException(path, 'Expected a scalar JSON value.');
    }
  }

  void _onlyKeys(Map<String, Object?> map, Set<String> allowed, String path) {
    for (final String key in map.keys) {
      if (!allowed.contains(key)) {
        throw PrototypeSpecException('$path.$key', 'Unknown field "$key".');
      }
    }
  }
}
