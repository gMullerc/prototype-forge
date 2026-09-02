import 'package:prototype_spec/prototype_spec.dart';

class PrototypeExportArtifact {
  const PrototypeExportArtifact({
    required this.fileName,
    required this.language,
    required this.source,
  });

  final String fileName;
  final String language;
  final String source;
}

abstract interface class PrototypeExporter {
  String get id;

  String get label;

  PrototypeExportArtifact export(PrototypeDocument document);
}
