import 'package:prototype_export/prototype_export.dart';
import 'package:prototype_spec/prototype_spec.dart';
import 'package:test/test.dart';

void main() {
  test('keeps exporter implementations behind a stable port', () {
    const PrototypeExporter exporter = _FixtureExporter();
    final PrototypeExportArtifact artifact = exporter.export(
      PrototypeDocument(
        specVersion: '1.0',
        screen: PrototypeScreen(
          id: 'fixture',
          title: 'Fixture',
          root: PrototypeNode(id: 'root', type: 'Text'),
        ),
      ),
    );

    expect(exporter.id, 'fixture');
    expect(artifact.fileName, 'fixture.dart');
    expect(artifact.language, 'dart');
  });
}

class _FixtureExporter implements PrototypeExporter {
  const _FixtureExporter();

  @override
  String get id => 'fixture';

  @override
  String get label => 'Fixture';

  @override
  PrototypeExportArtifact export(PrototypeDocument document) =>
      const PrototypeExportArtifact(
        fileName: 'fixture.dart',
        language: 'dart',
        source: 'class Fixture {}',
      );
}
