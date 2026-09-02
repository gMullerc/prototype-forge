import 'package:prototype_agent/prototype_agent.dart';
import 'package:test/test.dart';

void main() {
  test('keeps providers behind one minimal generation port', () async {
    const PrototypeAgent agent = _FakeAgent();

    expect(agent.id, 'fake');
    expect(
      await agent.generate(const PrototypeBrief(text: 'briefing')),
      'briefing',
    );
  });
}

class _FakeAgent implements PrototypeAgent {
  const _FakeAgent();

  @override
  String get id => 'fake';

  @override
  String get label => 'Fake';

  @override
  Future<String> generate(PrototypeBrief brief) async => brief.text;
}
