import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:service_order_app/app/app.dart';
import 'package:service_order_app/app/brand_bottom_bar.dart';
import 'package:service_order_app/core/preferences/app_preferences.dart';
import 'package:service_order_app/features/service_order/data/service_order.dart';
import 'package:service_order_app/features/service_order/service_order_form_page.dart';
import 'package:service_order_app/features/settings/data/company_profile.dart';
import 'package:service_order_app/features/update/app_version.dart';
import 'package:service_order_app/features/update/update_checker.dart';
import 'package:service_order_app/features/update/update_installer.dart';

import 'fakes.dart';

const _order = ServiceOrder(orderNumber: '0007', customerName: 'Dr. Pedro');

void main() {
  testWidgets('English interface with US formats', (tester) async {
    final deps = fakeDependencies(
      language: LanguagePreference.english,
      region: RegionPreference.unitedStates,
    );
    await deps.orders.create(
      const ServiceOrder(
        orderNumber: '0042',
        items: [ServiceOrderItem(quantity: 1, unitPriceCents: 123456)],
      ),
    );

    await tester.pumpWidget(ServiceOrderApp(dependencies: deps));
    await tester.pumpAndSettle();

    expect(find.text('Orders'), findsWidgets);
    expect(find.text('New order'), findsOneWidget);
    expect(find.text('\$1,234.56'), findsWidgets);
    expect(find.textContaining('No customer'), findsOneWidget);
  });

  testWidgets('language changes immediately from settings', (tester) async {
    final deps = fakeDependencies();
    await deps.orders.create(_order);

    await tester.pumpWidget(ServiceOrderApp(dependencies: deps));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Idioma'),
      200,
      scrollable: find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    await tester.tap(find.text('Idioma'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Language'), findsOneWidget);

    // The PDF follows the new language too.
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('0007'));
    await tester.pumpAndSettle();
    final documents = deps.documents as FakeServiceOrderDocuments;
    expect(documents.builtInLanguage.last, 'en');
  });

  testWidgets('example company follows the app language', (tester) async {
    final deps = fakeDependencies(sampleCompany: true);

    await tester.pumpWidget(ServiceOrderApp(dependencies: deps));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();

    expect(find.text('Empresa Exemplo'), findsOneWidget);
    expect(find.textContaining('Fulano de Tal'), findsOneWidget);

    await deps.preferences.setLanguage(LanguagePreference.english);
    await tester.pumpAndSettle();

    expect(find.text('Example Company'), findsOneWidget);
    expect(find.textContaining('John Doe'), findsOneWidget);
    expect(find.text('Empresa Exemplo'), findsNothing);
  });

  testWidgets('edited company data is kept in any language', (tester) async {
    final deps = fakeDependencies(sampleCompany: true);
    await deps.settings.saveCompanyFields(
      deps.companyDefaults,
      {CompanyField.name: 'Oficina do João'},
    );

    await tester.pumpWidget(ServiceOrderApp(dependencies: deps));
    await tester.pumpAndSettle();
    await deps.preferences.setLanguage(LanguagePreference.english);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Oficina do João'), findsOneWidget);
    expect(find.textContaining('John Doe'), findsOneWidget);
  });

  testWidgets('starts on history and switches to settings', (tester) async {
    await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma ordem de serviço emitida ainda'), findsOneWidget);

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();

    expect(find.text('Empresa Teste'), findsOneWidget);
    expect(find.textContaining('Fulano de Tal'), findsOneWidget);
  });

  testWidgets('history is split in sections by day', (tester) async {
    final deps = fakeDependencies();
    final orders = deps.orders as FakeServiceOrderRepository;
    orders.clock = DateTime(2020, 5, 10, 9, 30);
    await orders.create(const ServiceOrder(orderNumber: '0001'));
    orders.clock = DateTime(2020, 5, 12, 14, 5);
    await orders.create(const ServiceOrder(orderNumber: '0002'));
    await orders.create(const ServiceOrder(orderNumber: '0003'));

    await tester.pumpWidget(ServiceOrderApp(dependencies: deps));
    await tester.pumpAndSettle();

    expect(find.text('12 de maio de 2020'), findsOneWidget);
    expect(find.text('10 de maio de 2020'), findsOneWidget);
    expect(find.textContaining('14:05'), findsNWidgets(2));

    // Newest day first, its orders under it.
    final newestHeader = tester.getTopLeft(find.text('12 de maio de 2020')).dy;
    final olderHeader = tester.getTopLeft(find.text('10 de maio de 2020')).dy;
    final order3 = tester.getTopLeft(find.textContaining('0003')).dy;
    final order1 = tester.getTopLeft(find.textContaining('0001')).dy;
    expect(newestHeader < order3, isTrue);
    expect(order3 < olderHeader, isTrue);
    expect(olderHeader < order1, isTrue);
  });

  testWidgets('day header stays pinned while its orders scroll', (tester) async {
    final deps = fakeDependencies();
    final orders = deps.orders as FakeServiceOrderRepository;
    orders.clock = DateTime(2020, 5, 10, 9);
    await orders.create(const ServiceOrder(orderNumber: '0001'));
    orders.clock = DateTime(2020, 5, 12, 9);
    for (var i = 2; i <= 20; i++) {
      await orders.create(ServiceOrder(orderNumber: i.toString().padLeft(4, '0')));
    }

    await tester.pumpWidget(ServiceOrderApp(dependencies: deps));
    await tester.pumpAndSettle();

    // Summary, search and filters scroll away first; then the header sticks
    // to the top.
    await tester.drag(find.textContaining('0019'), const Offset(0, -220));
    await tester.pumpAndSettle();

    final header = find.text('12 de maio de 2020');
    final headerBefore = tester.getTopLeft(header).dy;
    final itemBefore = tester.getTopLeft(find.textContaining('0016')).dy;

    // Scroll inside the 12 May group: the orders move, its header doesn't.
    await tester.drag(find.textContaining('0019'), const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.textContaining('0016')).dy,
      lessThan(itemBefore - 150),
    );
    expect(header, findsOneWidget);
    expect(tester.getTopLeft(header).dy, headerBefore);
  });

  testWidgets('"Nova ordem" in the bottom bar works from the settings tab',
      (tester) async {
    await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Criar ordem de serviço'));
    await tester.pumpAndSettle();

    expect(find.byType(ServiceOrderFormPage), findsOneWidget);

    // Leaving without saving lands on the history tab.
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma ordem de serviço emitida ainda'), findsOneWidget);
  });

  // The customer is a summary row on the form, edited in a sheet.
  Future<void> setCustomer(WidgetTester tester, String name) async {
    await tester.tap(find.text('Cliente não informado'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Cliente'), name);
    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();
  }

  // The number lives in a chip on the form's top bar, edited in a dialog.
  Future<void> setOrderNumber(WidgetTester tester, String number) async {
    await tester.tap(find.byTooltip('Nº da ordem de serviço'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nº da ordem de serviço'),
      number,
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
  }

  testWidgets('duplicated order number asks before saving', (tester) async {
    final deps = fakeDependencies();
    await deps.orders.create(_order); // nº 0007, Dr. Pedro

    await tester.pumpWidget(ServiceOrderApp(dependencies: deps));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova ordem'));
    await tester.pumpAndSettle();

    await setOrderNumber(tester, '0007');
    await tester.tap(find.text('Revisar e gerar PDF'));
    await tester.pumpAndSettle();

    expect(find.text('Número já usado'), findsOneWidget);
    expect(find.textContaining('de Dr. Pedro'), findsOneWidget);

    // Cancel keeps the form open.
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(ServiceOrderFormPage), findsOneWidget);

    // Saving anyway is allowed.
    await tester.tap(find.text('Revisar e gerar PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar mesmo assim'));
    await tester.pumpAndSettle();
    expect(find.byType(ServiceOrderFormPage), findsNothing);
    expect((await deps.orders.list(query: '0007')), hasLength(2));
  });

  testWidgets('company form asks before discarding changes', (tester) async {
    await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar'));
    await tester.pumpAndSettle();

    // No changes: back leaves right away.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Dados da empresa'), findsNothing);

    await tester.tap(find.byTooltip('Editar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome da empresa'),
      'Outra Empresa',
    );
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Descartar alterações?'), findsOneWidget);
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.text('Dados da empresa'), findsNothing);
    expect(find.text('Empresa Teste'), findsOneWidget);
  });

  testWidgets('"Nova ordem" opens the form without the bottom bar', (tester) async {
    await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova ordem'));
    await tester.pumpAndSettle();

    expect(find.byType(ServiceOrderFormPage), findsOneWidget);
    expect(find.byType(BrandBottomBar), findsNothing);
  });

  testWidgets('saving a new order opens its preview, then lists it',
      (tester) async {
    await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova ordem'));
    await tester.pumpAndSettle();

    await setOrderNumber(tester, '0001');
    await setCustomer(tester, 'Clínica Sorriso');
    await tester.tap(find.text('Revisar e gerar PDF'));
    await tester.pumpAndSettle();

    // Preview of the new order.
    expect(find.byType(ServiceOrderFormPage), findsNothing);
    expect(find.text('Enviar PDF'), findsOneWidget);
    expect(find.text('Ordem de serviço 0001'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('0001'), findsOneWidget);
    expect(find.textContaining('Clínica Sorriso'), findsOneWidget);
  });

  testWidgets('preview actions share and print the order', (tester) async {
    final deps = fakeDependencies();
    await deps.orders.create(_order);
    final documents = deps.documents as FakeServiceOrderDocuments;

    await tester.pumpWidget(ServiceOrderApp(dependencies: deps));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('0007'));
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

    await tester.tap(find.textContaining('0007'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma ordem de serviço emitida ainda'), findsOneWidget);
  });

  testWidgets('leaving an edited form asks before discarding', (tester) async {
    await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova ordem'));
    await tester.pumpAndSettle();
    await setCustomer(tester, 'X');
    // Rebuild so PopScope sees canPop = false before tapping back.
    await tester.pump();

    // pageBack() looks for the English "Back" tooltip; the app is pt-BR.
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('Descartar alterações?'), findsOneWidget);

    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.byType(ServiceOrderFormPage), findsNothing);
    expect(find.text('Nenhuma ordem de serviço emitida ainda'), findsOneWidget);
  });

  Future<void> openCompanyForm(WidgetTester tester) async {
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar'));
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
    await tester.enterText(responsible, 'Fulano Souza');
    await tester.pump();
    // A filled field shows no default hint, only the restore button.
    expect(find.textContaining('Padrão:'), findsNothing);
    expect(find.byTooltip('Restaurar padrão'), findsWidgets);

    await tester.enterText(responsible, '');
    await tester.pump();
    expect(find.text('Padrão: Fulano de Tal'), findsOneWidget);
    await tester.enterText(responsible, 'Fulano Souza');
    await tester.pump();

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Dados da empresa'), findsNothing);
    expect(find.textContaining('(99) 91234-5678'), findsOneWidget);
    expect(find.textContaining('Fulano Souza'), findsOneWidget);
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
    expect(find.text('Remover logo'), findsOneWidget);

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
    await tester.tap(find.textContaining('0007'));
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
        InstallFailed(InstallFailure.download),
      ];

      await tester.pumpWidget(ServiceOrderApp(dependencies: deps));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atualizar'));
      await tester.pumpAndSettle();

      expect(find.text(
        'Falha ao baixar a atualização. Verifique a internet e tente de novo.',
      ), findsOneWidget);
    });

    testWidgets('settings shows the version and checks manually',
        (tester) async {
      await tester.pumpWidget(ServiceOrderApp(dependencies: fakeDependencies()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajustes'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Versão 1.0.0'),
        200,
        scrollable: find
            .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
            .first,
      );
      // Built below the fold: bring the button into view before tapping.
      await tester.ensureVisible(find.text('Verificar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verificar'));
      await tester.pumpAndSettle();

      expect(find.text('Você já está na versão mais recente.'), findsOneWidget);
    });
  });
}
