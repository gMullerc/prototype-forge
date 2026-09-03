enum PrototypeFeedbackTone {
  info,
  success,
  warning,
  error,
}

class PrototypeFeedback {
  const PrototypeFeedback({
    required this.message,
    this.tone = PrototypeFeedbackTone.info,
  });

  final String message;
  final PrototypeFeedbackTone tone;
}

class PrototypeInteractionState {
  PrototypeInteractionState({
    Map<String, Object?> values = const <String, Object?>{},
    Map<String, String> errors = const <String, String>{},
    this.feedback,
  })  : values = Map<String, Object?>.unmodifiable(values),
        errors = Map<String, String>.unmodifiable(errors);

  final Map<String, Object?> values;
  final Map<String, String> errors;
  final PrototypeFeedback? feedback;
}

class PrototypeActionResult {
  const PrototypeActionResult({
    required this.recognized,
    required this.validationPassed,
    required this.state,
  });

  final bool recognized;
  final bool validationPassed;
  final PrototypeInteractionState state;
}
