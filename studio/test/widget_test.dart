import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototype_foundry_studio/app/foundry_app.dart';

void main() {
  testWidgets('generates and interacts with the local receipt prototype', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const FoundryApp());

    expect(find.text('PROTOTYPE FOUNDRY'), findsOneWidget);
    await tester.tap(find.text('Comprovante de pagamento'));
    await tester.pumpAndSettle();

    expect(find.text('Pagamento confirmado'), findsOneWidget);
    expect(find.text('R\$ 250,00'), findsOneWidget);
    await tester.ensureVisible(find.text('Compartilhar comprovante'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compartilhar comprovante'));
    await tester.pump();
    expect(
        find.textContaining('Ação capturada: share_receipt'), findsOneWidget);
  });

  testWidgets('switches the generation agent without rebuilding the app', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const FoundryApp());

    await tester.tap(find.byKey(const Key('agent-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OpenCode'));
    await tester.pumpAndSettle();

    expect(find.text('OPENCODE'), findsWidgets);
    expect(find.text('MOTOR LOCAL'), findsNothing);
  });

  testWidgets('saves revisions, compares them and exports a Flutter draft', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const FoundryApp());

    await tester.tap(find.text('Comprovante de pagamento'));
    await tester.pumpAndSettle();
    expect(find.text('REV 01'), findsOneWidget);
    expect(find.byKey(const Key('preview-phone')), findsOneWidget);

    await tester.tap(find.byKey(const Key('viewport-tablet')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('preview-tablet')), findsOneWidget);

    await tester.tap(find.text('Hipótese de onboarding'));
    await tester.pumpAndSettle();
    expect(find.text('REV 02'), findsOneWidget);

    await tester.tap(find.byKey(const Key('export-draft-button')));
    await tester.pumpAndSettle();
    expect(find.text('Rascunho Flutter para revisão'), findsOneWidget);
    expect(find.byKey(const Key('export-source')), findsOneWidget);
    expect(find.textContaining('class ProductHypothesisDraft'), findsOneWidget);
    await tester.tap(find.text('FECHAR'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('review-workspace-button')));
    await tester.pumpAndSettle();
    expect(find.text('Mesa de revisão local'), findsOneWidget);
    expect(find.text('REVISÕES · 2'), findsWidgets);

    await tester.tap(find.byKey(const Key('compare-revision-1')));
    await tester.pumpAndSettle();
    expect(find.text('Comparando revisão 2 com 1'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('review-comment-field')),
      'Validar o conteúdo com design.',
    );
    await tester.tap(find.byKey(const Key('add-review-comment-button')));
    await tester.pumpAndSettle();
    expect(find.text('• Validar o conteúdo com design.'), findsOneWidget);
  });
}
