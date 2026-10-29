import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:service_order_app/app/app.dart';
import 'package:service_order_app/features/service_order/data/service_order.dart';
import 'package:service_order_app/features/settings/data/company_profile.dart';
import 'package:service_order_app/features/update/app_version.dart';
import 'package:service_order_app/features/update/update_checker.dart';
import 'package:service_order_app/features/update/update_installer.dart';

import 'fakes.dart';

const _order = ServiceOrder(orderNumber: '0007', customerName: 'Dr. Pedro');

void main() {
  testWidgets('starts on history and switches to settings', (tester) async {
    await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma OS emitida ainda'), findsOneWidget);

    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();

    expect(find.text('Empresa Teste'), findsOneWidget);
    expect(find.text('Responsável: Valdejane'), findsOneWidget);
  });

  testWidgets('"Criar" opens the form without the bottom bar', (tester) async {
    await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Nova OS'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('saving a new order opens its preview, then lists it',
      (tester) async {
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

    // Preview of the new order.
    expect(find.text('Nova OS'), findsNothing);
    expect(find.text('Enviar PDF'), findsOneWidget);
    expect(find.text('OS 0001'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('OS 0001'), findsOneWidget);
    expect(find.textContaining('Clínica Sorriso'), findsOneWidget);
  });

  testWidgets('preview actions share and print the order', (tester) async {
    final deps = fakeDependencies();
    await deps.orders.create(_order);
    final documents = deps.documents as FakeServiceOrderDocuments;

    await tester.pumpWidget(ServiceOrderApp(dependencies: deps));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OS 0007'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Imagem'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Imprimir'));
    await tester.pumpAndSettle();

    expect(documents.sharedPdfs.single.orderNumber, '0007');
    expect(documents.sharedImages.single.orderNumber, '0007');
    expect(documents.printed.single.orderNumber, '0007');
  });

  testWidgets('deleting from the preview removes the order', (tester) async {
    final deps = fakeDependencies();
    await deps.orders.create(_order);

    await tester.pumpWidget(ServiceOrderApp(dependencies: deps));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OS 0007'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma OS emitida ainda'), findsOneWidget);
  });

  testWidgets('leaving an edited form asks before discarding', (tester) async {
    await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Cliente'), 'X');
    // Rebuild so PopScope sees canPop = false before tapping back.
    await tester.pump();

    // pageBack() looks for the English "Back" tooltip; the app is pt-BR.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Descartar alterações?'), findsOneWidget);

    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.text('Nova OS'), findsNothing);
    expect(find.text('Nenhuma OS emitida ainda'), findsOneWidget);
  });

  Future<void> openCompanyForm(WidgetTester tester) async {
    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
  }

  testWidgets('company data can be edited from settings', (tester) async {
    await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
    await tester.pumpAndSettle();
    await openCompanyForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Telefone / WhatsApp'),
      '(99) 91234-5678',
    );
    // Last field: below the fold in the 800x600 test screen, and ListView
    // only builds what is on screen.
    final responsible = find.widgetWithText(TextFormField, 'Responsável');
    await tester.scrollUntilVisible(
      responsible,
      200,
      scrollable: find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    await tester.enterText(responsible, 'Valdejane Souza');
    await tester.pump();
    expect(find.text('Padrão: Valdejane'), findsOneWidget);

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Dados da empresa'), findsNothing);
    expect(find.text('(99) 91234-5678'), findsOneWidget);
    expect(find.text('Responsável: Valdejane Souza'), findsOneWidget);
  });

  testWidgets('company name is required', (tester) async {
    await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
    await tester.pumpAndSettle();
    await openCompanyForm(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome da empresa'), '');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe o nome da empresa'), findsOneWidget);
    expect(find.text('Dados da empresa'), findsOneWidget);
  });

  testWidgets('a field can be restored to its default', (tester) async {
    await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
    await tester.pumpAndSettle();
    await openCompanyForm(tester);

    final name = find.widgetWithText(TextFormField, 'Nome da empresa');
    await tester.enterText(name, 'Outra Empresa');
    await tester.pump();
    await tester.tap(find.byTooltip('Restaurar padrão'));
    await tester.pump();

    expect(find.text('Empresa Teste'), findsOneWidget);
    expect(find.textContaining('Padrão:'), findsNothing);
  });

  testWidgets('picked logo is saved with the company data', (tester) async {
    final deps = fakeDependencies();
    (deps.logos as FakeLogoStorage).nextPick = 'logo_new.png';

    await tester.pumpWidget(ServiceOrderApp(dependencies: deps));
    await tester.pumpAndSettle();
    await openCompanyForm(tester);

    await tester.tap(find.text('Trocar logo'));
    await tester.pumpAndSettle();
    expect(find.text('Usar logo padrão'), findsOneWidget);

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final profile = await deps.settings.companyProfile(deps.config);
    expect(profile.customLogoFile, 'logo_new.png');
  });

  testWidgets('reset restores all company data', (tester) async {
    final deps = fakeDependencies();
    await deps.settings.saveCompanyFields(
      deps.config,
      {CompanyField.name: 'Outra Empresa'},
    );

    await tester.pumpWidget(ServiceOrderApp(dependencies: deps));
    await tester.pumpAndSettle();
    await openCompanyForm(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restaurar tudo para o padrão'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restaurar'));
    await tester.pumpAndSettle();

    expect(find.text('Empresa Teste'), findsOneWidget);
  });

  testWidgets('the PDF uses the edited company data', (tester) async {
    final deps = fakeDependencies();
    await deps.orders.create(_order);
    await deps.settings.saveCompanyFields(
      deps.config,
      {CompanyField.phone: '(99) 91234-5678'},
    );

    await tester.pumpWidget(ServiceOrderApp(dependencies: deps));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OS 0007'));
    await tester.pumpAndSettle();

    final documents = deps.documents as FakeServiceOrderDocuments;
    expect(documents.builtFor.single.companyPhone, '(99) 91234-5678');
  });

  group('auto-update', () {
    final update = AvailableUpdate(
      version: const AppVersion(1, 0, 1),
      tag: 'v1.0.1',
      notes: 'New history layout',
      apkUrl: Uri.parse('https://example.com/app.apk'),
    );

    testWidgets('offers a newer version on startup and installs it',
        (tester) async {
      final deps = fakeDependencies();
      (deps.updates as FakeUpdateChecker).nextUpdate = update;

      await tester.pumpWidget(ServiceOrderApp(dependencies: deps));
      await tester.pumpAndSettle();

      expect(find.text('Nova versão disponível'), findsOneWidget);
      expect(find.textContaining('v1.0.1'), findsOneWidget);

      // Release notes stay collapsed until "Release notes" is tapped.
      expect(find.text('New history layout'), findsNothing);
      await tester.tap(find.text('Release notes'));
      await tester.pump();
      expect(find.text('New history layout'), findsOneWidget);

      await tester.tap(find.text('Atualizar'));
      await tester.pumpAndSettle();

      expect((deps.installer as FakeUpdateInstaller).installed.single.tag, 'v1.0.1');
      expect(find.text('Baixando atualização'), findsNothing);
    });

    testWidgets('"Depois" closes the dialog without installing', (tester) async {
      final deps = fakeDependencies();
      (deps.updates as FakeUpdateChecker).nextUpdate = update;

      await tester.pumpWidget(ServiceOrderApp(dependencies: deps));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Depois'));
      await tester.pumpAndSettle();

      expect(find.text('Nova versão disponível'), findsNothing);
      expect((deps.installer as FakeUpdateInstaller).installed, isEmpty);
    });

    testWidgets('install errors are shown to the user', (tester) async {
      final deps = fakeDependencies();
      (deps.updates as FakeUpdateChecker).nextUpdate = update;
      (deps.installer as FakeUpdateInstaller).events = const [
        InstallFailed('Falha ao baixar a atualização.'),
      ];

      await tester.pumpWidget(ServiceOrderApp(dependencies: deps));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atualizar'));
      await tester.pumpAndSettle();

      expect(find.text('Falha ao baixar a atualização.'), findsOneWidget);
    });

    testWidgets('settings shows the version and checks manually',
        (tester) async {
      await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Configurações'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Versão 1.0.0'),
        200,
        scrollable: find
            .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
            .first,
      );
      await tester.tap(find.text('Verificar atualizações'));
      await tester.pumpAndSettle();

      expect(find.text('Você já está na versão mais recente.'), findsOneWidget);
    });
  });
}
