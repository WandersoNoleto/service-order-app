import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:service_order_app/core/config/client_config.dart';
import 'package:service_order_app/features/document/pdf_assets.dart';
import 'package:service_order_app/features/document/service_order_documents.dart';
import 'package:service_order_app/features/document/service_order_pdf.dart';
import 'package:service_order_app/features/service_order/data/service_order.dart';
import 'package:service_order_app/features/settings/data/company_profile.dart';

/// Sample PDFs are written here so the layout can be checked by eye.
const _previewDir = 'build/pdf_preview';

/// Uses the real client logo when the private repo is present.
const _valLogo = 'clients/private/val/branding/logo.jpeg';

const _company = ClientConfig(
  channel: 'val',
  companyName: 'AC Serviços',
  companyDocument: '35.183.961/0001-63',
  companyPhone: '(99) 98456-4555',
  companyAddress: 'Rua Sá Sobrinho, 26 - Centro',
  companyCity: 'São João dos Patos',
  companyState: 'MA',
  companyResponsible: 'Valdejane',
  brandColor: Color(0xFF1F5FBF),
  logoAsset: _valLogo,
);

ServiceOrder _order({int parts = 2}) => ServiceOrder(
      id: 1,
      orderNumber: '0001',
      responsibleName: 'Valdejane',
      customerName: 'Clínica Sorriso — Dr. João',
      customerDocument: '12.345.678/0001-90',
      customerAddress: 'Av. Getúlio Vargas, 1500, sala 3',
      customerCity: 'Floriano',
      customerState: 'PI',
      customerContact: '(89) 99999-0000',
      customerZip: '64800-000',
      invoiceNumber: '123',
      underWarranty: false,
      calledAt: DateTime(2026, 10, 20),
      scheduledFor: DateTime(2026, 10, 22),
      scheduledTime: '14:30',
      installedAt: DateTime(2026, 10, 22),
      servicesPerformed:
          'Troca dos rolamentos e das lâminas do cabeçote. Lubrificação geral.',
      notes: 'Cliente orientado sobre a limpeza diária do equipamento.',
      laborCents: 10000,
      equipmentOk: true,
      items: [
        for (var i = 0; i < parts; i++)
          ServiceOrderItem(
            quantity: 2,
            code: '36${i.toString().padLeft(2, '0')}',
            description: i.isEven ? 'Rolamentos 3604' : 'Lâminas do cabeçote',
            unitPriceCents: i.isEven ? 8000 : 6000,
          ),
      ],
    );

void main() {
  late PdfAssets assets;

  setUpAll(() {
    pw.Font font(String path) =>
        pw.Font.ttf(ByteData.sublistView(File(path).readAsBytesSync()));
    final logo = File(_valLogo);

    assets = PdfAssets(
      regular: font(PdfAssets.regularFontAsset),
      bold: font(PdfAssets.boldFontAsset),
      logo: logo.existsSync() ? pw.MemoryImage(logo.readAsBytesSync()) : null,
    );
    Directory(_previewDir).createSync(recursive: true);
  });

  Future<int> buildAndSave(ServiceOrder order, String fileName) async {
    final document = buildServiceOrderDocument(
      order: order,
      company: const CompanyProfile(defaults: _company),
      assets: assets,
    );
    final bytes = await document.save();
    File('$_previewDir/$fileName').writeAsBytesSync(bytes);
    return document.document.pdfPageList.pages.length;
  }

  test('a typical order fits on one page', () async {
    expect(await buildAndSave(_order(), 'os_typical.pdf'), 1);
  });

  test('an empty order (all fields blank) still renders', () async {
    final pages = await buildAndSave(
      const ServiceOrder(id: 2),
      'os_empty.pdf',
    );
    expect(pages, 1);
  });

  test('a long parts list continues on the next page', () async {
    expect(await buildAndSave(_order(parts: 40), 'os_long.pdf'), 2);
  });

  test('a very long parts list keeps paginating', () async {
    expect(await buildAndSave(_order(parts: 90), 'os_very_long.pdf'), greaterThan(2));
  });

  test('text outside Latin-1 does not break the font', () async {
    final order = ServiceOrder(
      id: 3,
      customerName: 'Aspas “curvas” – travessão … e emoji',
      notes: '“Teste” — ok',
    );
    expect(await buildAndSave(order, 'os_unicode.pdf'), 1);
  });

  test('file names are ASCII and include number and customer', () {
    expect(fileBaseName(_order()), 'OS_0001_Clinica_Sorriso_Dr_Joao');
    expect(fileBaseName(const ServiceOrder(id: 9)), 'OS_9');
  });
}
