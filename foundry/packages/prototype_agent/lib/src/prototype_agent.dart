class PrototypeBrief {
  const PrototypeBrief({required this.text});

  final String text;
}

abstract interface class PrototypeAgent {
  String get id;
  String get label;

  Future<String> generate(PrototypeBrief brief);
}

/// Optional conversational capability for agents that can refine a briefing
/// before producing a contract.
abstract interface class PrototypeConversationalAgent {
  Future<PrototypeAgentTurn> respond(PrototypeBrief brief);
}

class PrototypeAgentTurn {
  const PrototypeAgentTurn.contract({required this.document})
      : question = null,
        options = const <String>[];

  const PrototypeAgentTurn.clarification({
    required this.question,
    this.options = const <String>[],
  }) : document = null;

  final String? document;
  final String? question;
  final List<String> options;

  bool get isClarification => question != null;
}
