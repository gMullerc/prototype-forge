class PrototypeActionEvent {
  PrototypeActionEvent({
    required this.name,
    required this.componentId,
    Map<String, Object?> payload = const <String, Object?>{},
  }) : payload = Map<String, Object?>.unmodifiable(payload);

  final String name;
  final String componentId;
  final Map<String, Object?> payload;
}
