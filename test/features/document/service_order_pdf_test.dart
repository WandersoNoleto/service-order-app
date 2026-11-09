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

/// Any image works as a sample logo; the generic app icon is in the repo.
const _sampleLogo = 'assets/icon/app_icon.png';

const _company = ClientConfig(
  channel: '',
  companyName: 'Oficina Exemplo',
  companyDocument: '00.000.000/0001-00',
  companyPhone: '(00) 00000-0000',
  companyAddress: 'Rua Exemplo, 100 - Centro',
  companyCity: 'Cidade Exemplo',
  companyState: 'UF',
  companyResponsible: 'Fulano de Tal',
  brandColor: Color(0xFF508D6B),
  logoAsset: '',
);

/// Company with nothing filled in: the PDF header must simply stay empty.
const _blankCompany = ClientConfig(
  channel: '',
  companyName: '',
  companyDocument: '',
  companyPhone: '',
  companyAddress: '',
  companyCity: '',
  companyState: '',
  companyResponsible: '',
  brandColor: Color(0xFF508D6B),
  logoAsset: '',
);

ServiceOrder _order({int parts = 2}) => ServiceOrder(
      id: 1,
      orderNumber: '0001',
      responsibleName: 'Fulano de Tal',
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
    final logo = File(_sampleLogo);

    assets = PdfAssets(
      regular: font(PdfAssets.regularFontAsset),
      bold: font(PdfAssets.boldFontAsset),
      logo: logo.existsSync() ? pw.MemoryImage(logo.readAsBytesSync()) : null,
    );
    Directory(_previewDir).createSync(recursive: true);
  });

  Future<int> buildAndSave(
    ServiceOrder order,
    String fileName, {
    ClientConfig company = _company,
    bool withLogo = true,
  }) async {
    final document = buildServiceOrderDocument(
      order: order,
      company: CompanyProfile(defaults: company),
      assets: withLogo ? assets : assets.withLogo(null),
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

  test('no logo and no company data leaves the header blank', () async {
    final pages = await buildAndSave(
      _order(),
      'os_blank_company.pdf',
      company: _blankCompany,
      withLogo: false,
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
