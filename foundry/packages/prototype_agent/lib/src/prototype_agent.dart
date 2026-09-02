class PrototypeBrief {
  const PrototypeBrief({required this.text});

  final String text;
}

abstract interface class PrototypeAgent {
  String get id;
  String get label;

  Future<String> generate(PrototypeBrief brief);
}
