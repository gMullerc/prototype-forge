import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prototype_agent/prototype_agent.dart';
import 'package:prototype_foundry_studio/infrastructure/local_prototype_agent.dart';

void main() {
  const LocalPrototypeAgent agent = LocalPrototypeAgent();

  test('creates a realistic account access scenario', () async {
    final Map<String, Object?> document = await _decode(
      agent.generate(
        const PrototypeBrief(text: 'Tela de login com senha'),
      ),
    );

    expect(document['screen'], isA<Map<String, Object?>>());
    expect(_containsType(document, 'Avatar'), isTrue);
    expect(_containsType(document, 'Notice'), isTrue);
    expect(_containsType(document, 'TextField'), isTrue);
    expect(_containsType(document, 'Button'), isTrue);
  });

  test('creates a realistic banking home scenario', () async {
    final Map<String, Object?> document = await _decode(
      agent.generate(
        const PrototypeBrief(text: 'Tela inicial de um banco com saldo'),
      ),
    );

    expect(_containsText(document, 'Saldo disponível'), isTrue);
    expect(_containsText(document, 'Movimentações recentes'), isTrue);
    expect(_containsType(document, 'Metric'), isTrue);
    expect(_containsType(document, 'ListItem'), isTrue);
  });
}

Future<Map<String, Object?>> _decode(Future<String> source) async {
  return (jsonDecode(await source) as Map<Object?, Object?>).map(
    (Object? key, Object? value) => MapEntry(key! as String, value),
  );
}

bool _containsType(Object? value, String expected) {
  if (value is Map<Object?, Object?>) {
    if (value['type'] == expected) return true;
    return value.values.any((Object? child) => _containsType(child, expected));
  }
  if (value is List<Object?>) {
    return value.any((Object? child) => _containsType(child, expected));
  }
  return false;
}

bool _containsText(Object? value, String expected) {
  if (value is Map<Object?, Object?>) {
    if (value['text'] == expected) return true;
    return value.values.any((Object? child) => _containsText(child, expected));
  }
  if (value is List<Object?>) {
    return value.any((Object? child) => _containsText(child, expected));
  }
  return false;
}
