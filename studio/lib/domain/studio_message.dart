enum StudioMessageRole {
  user,
  assistant,
  system,
  error,
}

class StudioMessage {
  const StudioMessage({
    required this.role,
    required this.text,
    this.options = const <String>[],
  });

  final StudioMessageRole role;
  final String text;
  final List<String> options;
}
