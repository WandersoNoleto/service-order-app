import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:service_order_app/app/app.dart';
import 'package:service_order_app/core/config/client_config.dart';

const _config = ClientConfig(
  channel: '',
  companyName: 'Empresa Teste',
  companyDocument: '',
  companyPhone: '',
  brandColor: Color(0xFF1B1B1B),
  logoAsset: '',
);

void main() {
  testWidgets('starts on history and switches to settings', (tester) async {
    await tester.pumpWidget(const ServiceOrderApp(config: _config));

    expect(find.text('Nenhuma OS emitida ainda'), findsOneWidget);

    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();

    expect(find.text('Empresa Teste'), findsOneWidget);
  });

  testWidgets('"Criar" opens the form without the bottom bar', (tester) async {
    await tester.pumpWidget(const ServiceOrderApp(config: _config));

    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Nova OS'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
