class PrototypeDocument {
  const PrototypeDocument({
    required this.specVersion,
    required this.screen,
  });

  final String specVersion;
  final PrototypeScreen screen;
}

class PrototypeScreen {
  const PrototypeScreen({
    required this.id,
    required this.title,
    required this.root,
  });

  final String id;
  final String title;
  final PrototypeNode root;
}

class PrototypeNode {
  PrototypeNode({
    required this.id,
    required this.type,
    Map<String, Object?> props = const <String, Object?>{},
    List<PrototypeNode> children = const <PrototypeNode>[],
  })  : props = Map<String, Object?>.unmodifiable(props),
        children = List<PrototypeNode>.unmodifiable(children);

  final String id;
  final String type;
  final Map<String, Object?> props;
  final List<PrototypeNode> children;
}

class PrototypeSpecException implements Exception {
  const PrototypeSpecException(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => 'PrototypeSpecException($path): $message';
}
