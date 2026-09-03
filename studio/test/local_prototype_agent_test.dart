import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prototype_agent/prototype_agent.dart';
import 'package:prototype_foundry_studio/infrastructure/local_prototype_agent.dart';
import 'package:prototype_foundry_studio/infrastructure/local_prototype_scenarios.dart';

void main() {
  final LocalPrototypeAgent agent = LocalPrototypeAgent();

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

  test('creates an interactive person registration scenario', () async {
    final Map<String, Object?> document = await _decode(
      agent.generate(
        const PrototypeBrief(
          text: 'Crie um cadastro de pessoas com CPF e CNPJ',
        ),
      ),
    );

    expect(document['specVersion'], '1.1');
    expect(document['interaction'], isA<Map<String, Object?>>());
    expect(_containsType(document, 'TextField'), isTrue);
    expect(
      jsonEncode(document),
      allOf(contains('visibleWhen'), contains('save_person')),
    );
  });

  test('allows a scenario to be added without changing the agent', () async {
    final LocalPrototypeAgent configurableAgent = LocalPrototypeAgent(
      scenarioRegistry: LocalPrototypeScenarioRegistry(
        scenarios: <LocalPrototypeScenario>[
          LocalPrototypeScenario(
            id: 'checkout',
            keywords: const <String>['checkout'],
            builder: (_) => <String, Object?>{
              'specVersion': '1.0',
              'screen': <String, Object?>{
                'id': 'checkout',
                'title': 'Checkout',
                'root': <String, Object?>{
                  'id': 'root',
                  'type': 'Divider',
                },
              },
            },
          ),
        ],
        fallback: (_) => <String, Object?>{
          'specVersion': '1.0',
          'screen': <String, Object?>{
            'id': 'fallback',
            'title': 'Fallback',
            'root': <String, Object?>{
              'id': 'root',
              'type': 'Divider',
            },
          },
        },
      ),
    );

    final Map<String, Object?> document = await _decode(
      configurableAgent.generate(const PrototypeBrief(text: 'Fluxo checkout')),
    );

    expect(
      (document['screen']! as Map<String, Object?>)['title'],
      'Checkout',
    );
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
