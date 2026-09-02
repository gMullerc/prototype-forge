import 'dart:async';

import 'package:prototype_agent/prototype_agent.dart';
import 'package:prototype_runtime/prototype_runtime.dart';

import '../domain/studio_message.dart';

enum StudioGenerationStatus {
  idle,
  generating,
  ready,
  invalid,
  failed,
}

class StudioState {
  StudioState({
    required this.status,
    required List<StudioMessage> messages,
    required this.snapshot,
  }) : messages = List<StudioMessage>.unmodifiable(messages);

  factory StudioState.initial() => StudioState(
        status: StudioGenerationStatus.idle,
        messages: const <StudioMessage>[
          StudioMessage(
            role: StudioMessageRole.assistant,
            text:
                'Descreva uma hipótese de produto. Eu vou compor uma tela usando apenas o contrato aprovado.',
          ),
        ],
        snapshot: const PrototypeSnapshot.idle(),
      );

  final StudioGenerationStatus status;
  final List<StudioMessage> messages;
  final PrototypeSnapshot snapshot;
}

class StudioSession {
  StudioSession({
    required Iterable<PrototypeAgent> agents,
    required String initialAgentId,
    required PrototypeEngine engine,
  })  : _agents = <String, PrototypeAgent>{
          for (final PrototypeAgent agent in agents) agent.id: agent,
        },
        _selectedAgentId = initialAgentId,
        _engine = engine,
        _state = StudioState.initial() {
    if (_agents.isEmpty) {
      throw ArgumentError('Ao menos um agente precisa ser registrado.');
    }
    if (!_agents.containsKey(initialAgentId)) {
      throw ArgumentError('Agente inicial não registrado: $initialAgentId.');
    }
  }

  final Map<String, PrototypeAgent> _agents;
  String _selectedAgentId;
  final PrototypeEngine _engine;
  final StreamController<StudioState> _states =
      StreamController<StudioState>.broadcast();
  StudioState _state;
  bool _disposed = false;

  StudioState get current => _state;
  Stream<StudioState> get states => _states.stream;
  List<PrototypeAgent> get agents =>
      List<PrototypeAgent>.unmodifiable(_agents.values);
  PrototypeAgent get agent => _agents[_selectedAgentId]!;

  bool selectAgent(String id) {
    if (_state.status == StudioGenerationStatus.generating ||
        !_agents.containsKey(id)) {
      return false;
    }
    if (_selectedAgentId == id) return true;
    _selectedAgentId = id;
    _emit(_state);
    return true;
  }

  Future<void> sendPrompt(String prompt) async {
    final String trimmed = prompt.trim();
    if (trimmed.isEmpty || _state.status == StudioGenerationStatus.generating) {
      return;
    }

    _emit(
      StudioState(
        status: StudioGenerationStatus.generating,
        messages: <StudioMessage>[
          ..._state.messages,
          StudioMessage(role: StudioMessageRole.user, text: trimmed),
        ],
        snapshot: _state.snapshot,
      ),
    );

    try {
      final String response = await agent.generate(
        PrototypeBrief(text: trimmed),
      );
      final PrototypeSnapshot snapshot = _engine.load(response);
      if (snapshot.status == PrototypeStatus.ready) {
        _emit(
          StudioState(
            status: StudioGenerationStatus.ready,
            messages: <StudioMessage>[
              ..._state.messages,
              const StudioMessage(
                role: StudioMessageRole.assistant,
                text:
                    'Contrato validado. A nova composição está pronta na prancheta.',
              ),
            ],
            snapshot: snapshot,
          ),
        );
      } else {
        _emit(
          StudioState(
            status: StudioGenerationStatus.invalid,
            messages: <StudioMessage>[
              ..._state.messages,
              StudioMessage(
                role: StudioMessageRole.error,
                text:
                    'O contrato foi rejeitado: ${snapshot.issues.first.message}',
              ),
            ],
            snapshot: snapshot,
          ),
        );
      }
    } catch (error) {
      _emit(
        StudioState(
          status: StudioGenerationStatus.failed,
          messages: <StudioMessage>[
            ..._state.messages,
            StudioMessage(
              role: StudioMessageRole.error,
              text: 'Não foi possível gerar o protótipo: $error',
            ),
          ],
          snapshot: _state.snapshot,
        ),
      );
    }
  }

  void recordAction({required String name, required String componentId}) {
    _emit(
      StudioState(
        status: _state.status,
        messages: <StudioMessage>[
          ..._state.messages,
          StudioMessage(
            role: StudioMessageRole.system,
            text: 'Ação capturada: $name · componente $componentId',
          ),
        ],
        snapshot: _state.snapshot,
      ),
    );
  }

  void _emit(StudioState next) {
    if (_disposed) return;
    _state = next;
    _states.add(next);
  }

  void dispose() {
    _disposed = true;
    _states.close();
  }
}
