import 'package:flutter/widgets.dart';
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
}
