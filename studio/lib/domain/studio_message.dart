enum StudioMessageRole {
  user,
  assistant,
  system,
  error,
}

class StudioMessage {
  const StudioMessage({required this.role, required this.text});

  final StudioMessageRole role;
  final String text;
}
