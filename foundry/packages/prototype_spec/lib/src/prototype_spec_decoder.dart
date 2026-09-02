import 'dart:convert';

import 'prototype_document.dart';

class PrototypeSpecDecoder {
  const PrototypeSpecDecoder();

  static const String supportedVersion = '1.0';

  PrototypeDocument decode(String source) {
    final String payload = _extractJsonPayload(source);
    Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException catch (error) {
      throw PrototypeSpecException(r'$', 'Invalid JSON: ${error.message}');
    }

    final Map<String, Object?> root = _map(decoded, r'$');
    _onlyKeys(root, const <String>{'specVersion', 'screen'}, r'$');

    final String version = _string(root['specVersion'], r'$.specVersion');
    if (version != supportedVersion) {
      throw PrototypeSpecException(
        r'$.specVersion',
        'Unsupported version "$version". Expected "$supportedVersion".',
      );
    }

    final Map<String, Object?> screenMap = _map(root['screen'], r'$.screen');
    _onlyKeys(
      screenMap,
      const <String>{'id', 'title', 'root'},
      r'$.screen',
    );

    return PrototypeDocument(
      specVersion: version,
      screen: PrototypeScreen(
        id: _nonEmptyString(screenMap['id'], r'$.screen.id'),
        title: _nonEmptyString(screenMap['title'], r'$.screen.title'),
        root: _node(screenMap['root'], r'$.screen.root'),
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

  PrototypeNode _node(Object? value, String path) {
    final Map<String, Object?> map = _map(value, path);
    _onlyKeys(map, const <String>{'id', 'type', 'props', 'children'}, path);

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
      children: <PrototypeNode>[
        for (int index = 0; index < children.length; index++)
          _node(children[index], '$path.children[$index]'),
      ],
    );
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

  void _onlyKeys(Map<String, Object?> map, Set<String> allowed, String path) {
    for (final String key in map.keys) {
      if (!allowed.contains(key)) {
        throw PrototypeSpecException('$path.$key', 'Unknown field "$key".');
      }
    }
  }
}
