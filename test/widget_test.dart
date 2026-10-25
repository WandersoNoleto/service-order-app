import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:service_order_app/app/app.dart';

import 'fakes.dart';

void main() {
  testWidgets('starts on history and switches to settings', (tester) async {
    await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma OS emitida ainda'), findsOneWidget);

    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();

    expect(find.text('Empresa Teste'), findsOneWidget);
    expect(find.text('Valdejane'), findsOneWidget);
  });

  testWidgets('"Criar" opens the form without the bottom bar', (tester) async {
    await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Nova OS'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('saved order shows up in the history', (tester) async {
    await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nº da OS'), '0001');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cliente'),
      'Clínica Sorriso',
    );
    await tester.tap(find.text('Salvar OS'));
    await tester.pumpAndSettle();

    expect(find.text('Nova OS'), findsNothing);
    expect(find.text('OS 0001'), findsOneWidget);
    expect(find.textContaining('Clínica Sorriso'), findsOneWidget);
  });

  testWidgets('leaving an edited form asks before discarding', (tester) async {
    await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Cliente'), 'X');

    // pageBack() looks for the English "Back" tooltip; the app is pt-BR.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Descartar alterações?'), findsOneWidget);

    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.text('Nova OS'), findsNothing);
    expect(find.text('Nenhuma OS emitida ainda'), findsOneWidget);
  });

  testWidgets('responsible name can be edited in settings', (tester) async {
    await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Responsável'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Valdejane Souza');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Valdejane Souza'), findsOneWidget);
  });
}
