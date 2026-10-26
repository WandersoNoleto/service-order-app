import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/config/client_config.dart';
import '../../core/formatting/formatters.dart';
import '../service_order/data/service_order.dart';
import 'pdf_assets.dart';

/// Builds the A4 service order following the client's paper template.
///
/// Page breaks: only the parts table may continue on the next page (its
/// column header repeats). The closing block (notes, totals, signatures,
/// "equipment ok") is kept together.
pw.Document buildServiceOrderDocument({
  required ServiceOrder order,
  required ClientConfig company,
  required PdfAssets assets,
}) {
  final style = _Style(company);
  final baseTheme = pw.ThemeData.withFont(base: assets.regular, bold: assets.bold);
  final theme = baseTheme.copyWith(
    defaultTextStyle: baseTheme.defaultTextStyle.copyWith(
      fontSize: _Style.textSize,
    ),
  );
  final document = pw.Document(
    title: 'Ordem de Serviço ${order.orderNumber}',
    author: company.companyName,
  );

  document.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 20),
        theme: theme,
        // Without an explicit white background, the page images exported
        // for "share as image" come out transparent.
        buildBackground: (_) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Container(color: PdfColors.white),
        ),
      ),
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          : _continuationHeader(order, company, style),
      footer: _footer,
      build: (context) => [
        _companyHeader(order, company, assets, style),
        pw.SizedBox(height: 8),
        _titleBox(order, style),
        _customerGrid(order, style),
        _serviceCallGrid(order, style),
        pw.SizedBox(height: 8),
        _servicesPerformed(order, style),
        pw.SizedBox(height: 8),
        _partsTable(order, style),
        // A Container is not splittable, so this whole block moves to the
        // next page if it does not fit.
        pw.Container(child: _closingBlock(order, style)),
      ],
    ),
  );

  return document;
}

Future<Uint8List> buildServiceOrderPdf({
  required ServiceOrder order,
  required ClientConfig company,
  required PdfAssets assets,
}) {
  return buildServiceOrderDocument(
    order: order,
    company: company,
    assets: assets,
  ).save();
}

/// Minimum rows in the parts table, like the paper form.
const _minPartRows = 7;

class _Style {
  _Style(ClientConfig company)
      : brand = PdfColor.fromInt(company.brandColor.toARGB32()),
        // Darker version of the brand color for the table header (navy-like).
        tableHeader =
            PdfColor.fromInt(company.brandColor.toARGB32()).shade(1.1);

  static const textSize = 9.5;
  static const labelSize = 8.0;
  static const line = pw.BorderSide(width: 0.7);

  final PdfColor brand;
  final PdfColor tableHeader;

  pw.TextStyle get label => const pw.TextStyle(fontSize: labelSize);
  pw.TextStyle get value =>
      pw.TextStyle(fontSize: textSize, fontWeight: pw.FontWeight.bold);
}

// ---------------------------------------------------------------------------
// Header

pw.Widget _companyHeader(
  ServiceOrder order,
  ClientConfig company,
  PdfAssets assets,
  _Style style,
) {
  final logo = assets.logo;
  final location = [
    if (company.companyCity.isNotEmpty)
      [company.companyCity, company.companyState]
          .where((part) => part.isNotEmpty)
          .join('-')
          .toUpperCase(),
    if (company.companyDocument.isNotEmpty) 'CNPJ: ${company.companyDocument}',
  ].join('  |  ');

  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Expanded(
        flex: 2,
        child: logo != null
            ? pw.Container(
                height: 72,
                alignment: pw.Alignment.centerLeft,
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              )
            : pw.Text(
                company.companyName,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: style.brand,
                ),
              ),
      ),
      pw.SizedBox(width: 12),
      pw.Expanded(
        flex: 3,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            if (company.companyPhone.isNotEmpty)
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    company.companyPhone,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: style.brand,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.SvgImage(svg: _whatsAppIcon, width: 16, height: 16),
                ],
              ),
            if (location.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              pw.Text(location, style: style.value),
            ],
            if (company.companyAddress.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(company.companyAddress, style: style.label),
            ],
            if (order.responsibleName.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.RichText(
                text: pw.TextSpan(
                  text: 'Responsável: ',
                  style: const pw.TextStyle(fontSize: _Style.textSize),
                  children: [
                    pw.TextSpan(
                      text: order.responsibleName.toUpperCase(),
                      style: style.value,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

/// Compact line shown at the top of page 2 onwards.
pw.Widget _continuationHeader(
  ServiceOrder order,
  ClientConfig company,
  _Style style,
) {
  final number = order.orderNumber.isEmpty ? '' : ' · OS ${order.orderNumber}';
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 8),
    padding: const pw.EdgeInsets.only(bottom: 4),
    decoration: const pw.BoxDecoration(border: pw.Border(bottom: _Style.line)),
    child: pw.Text(
      '${company.companyName}$number · continuação',
      style: style.value,
    ),
  );
}

/// Page counter, shown only when the order has more than one page.
/// The height is always reserved so the layout does not shift.
pw.Widget _footer(pw.Context context) {
  return pw.Container(
    height: 12,
    alignment: pw.Alignment.bottomRight,
    child: context.pagesCount > 1
        ? pw.Text(
            'Página ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: _Style.labelSize),
          )
        : null,
  );
}

// ---------------------------------------------------------------------------
// Boxes above the parts table

pw.Widget _titleBox(ServiceOrder order, _Style style) {
  return _grid([
    [
      _Cell(
        flex: 1,
        height: 34,
        child: pw.Center(
          child: pw.Text(
            'ASSISTÊNCIA TÉCNICA',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ),
      _Cell(
        flex: 1,
        height: 34,
        // Label and number on one line: two stacked lines plus spacing do
        // not fit in the 34pt box, and the overflowing line is not drawn.
        child: pw.RichText(
          text: pw.TextSpan(
            text: 'ORDEM DE SERVIÇO: ',
            style: const pw.TextStyle(fontSize: 8.5),
            children: [
              pw.TextSpan(
                text: order.orderNumber,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    ],
  ], top: true);
}

pw.Widget _customerGrid(ServiceOrder order, _Style style) {
  return _grid([
    [
      _Cell.field('Cliente', order.customerName, style, flex: 3),
      _Cell.field('CPF/CNPJ', order.customerDocument, style, flex: 2),
    ],
    [_Cell.field('Endereço', order.customerAddress, style)],
    [
      _Cell.field('Cidade', order.customerCity, style, flex: 3),
      _Cell.field('Estado', order.customerState, style, flex: 1),
      _Cell.field('Contato', order.customerContact, style, flex: 2),
    ],
  ]);
}

/// The 6-column block: CEP/N.F. | Garantia | Chamado | Marcado p/ |
/// Horário | Instalado em — labels on top, values below.
pw.Widget _serviceCallGrid(ServiceOrder order, _Style style) {
  pw.Widget header(String text) =>
      pw.Center(child: pw.Text(text, style: style.label));
  pw.Widget value(String text) =>
      pw.Center(child: pw.Text(text, style: style.value));

  return _grid([
    [
      _Cell.field('CEP', order.customerZip, style, flex: 2),
      _Cell(flex: 2, child: header('Garantia')),
      _Cell(flex: 2, child: header('Chamado')),
      _Cell(flex: 2, child: header('Marcado p/')),
      _Cell(flex: 2, child: header('Horário')),
      _Cell(flex: 2, child: header('Instalado em')),
    ],
    [
      _Cell.field('N.F.', order.invoiceNumber, style, flex: 2),
      _Cell(flex: 2, child: pw.Center(child: _yesNo(order.underWarranty))),
      _Cell(flex: 2, child: value(formatDate(order.calledAt))),
      _Cell(flex: 2, child: value(formatDate(order.scheduledFor))),
      _Cell(flex: 2, child: value(order.scheduledTime ?? '')),
      _Cell(flex: 2, child: value(formatDate(order.installedAt))),
    ],
  ]);
}

pw.Widget _servicesPerformed(ServiceOrder order, _Style style) {
  return pw.Container(
    width: double.infinity,
    constraints: const pw.BoxConstraints(minHeight: 56),
    padding: const pw.EdgeInsets.all(5),
    decoration: pw.BoxDecoration(border: pw.Border.all(width: _Style.line.width)),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Serviços Executados', style: style.label),
        pw.SizedBox(height: 3),
        pw.Text(order.servicesPerformed, maxLines: 20),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Parts table

const _partColumns = {
  0: pw.FlexColumnWidth(0.9),
  1: pw.FlexColumnWidth(1.2),
  2: pw.FlexColumnWidth(4),
  3: pw.FlexColumnWidth(1.4),
  4: pw.FlexColumnWidth(1.4),
};

pw.Widget _partsTable(ServiceOrder order, _Style style) {
  pw.Widget headerCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: _Style.labelSize + 0.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      );

  pw.Widget cell(String text, {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Container(
        constraints: const pw.BoxConstraints(minHeight: 15),
        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: pw.Text(text, textAlign: align),
      );

  final rows = [
    for (final item in order.items)
      pw.TableRow(
        children: [
          cell(item.quantity.toString().padLeft(2, '0'), align: pw.TextAlign.center),
          cell(item.code),
          cell(item.description),
          cell(formatCents(item.unitPriceCents), align: pw.TextAlign.right),
          cell(formatCents(item.totalCents), align: pw.TextAlign.right),
        ],
      ),
    for (var i = order.items.length; i < _minPartRows; i++)
      pw.TableRow(children: List.generate(5, (_) => cell(''))),
  ];

  return pw.Table(
    border: pw.TableBorder.all(width: _Style.line.width),
    columnWidths: _partColumns,
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
    children: [
      pw.TableRow(
        repeat: true,
        decoration: pw.BoxDecoration(color: style.tableHeader),
        children: [
          headerCell('Quant.'),
          headerCell('Código'),
          headerCell('NOME DA PEÇA'),
          headerCell('Valor Unitário'),
          headerCell('Valor Total'),
        ],
      ),
      ...rows,
    ],
  );
}

// ---------------------------------------------------------------------------
// Closing block

pw.Widget _closingBlock(ServiceOrder order, _Style style) {
  pw.Widget totalRow(String label, int cents, {bool emphasized = false}) {
    final textStyle = emphasized
        ? pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)
        : style.value;
    return pw.Container(
      height: 24,
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: _Style.line)),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Container(
              alignment: pw.Alignment.centerLeft,
              padding: const pw.EdgeInsets.symmetric(horizontal: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: _Style.line),
              ),
              child: pw.Text(label, style: textStyle),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              alignment: pw.Alignment.centerRight,
              padding: const pw.EdgeInsets.symmetric(horizontal: 4),
              child: pw.Text(formatCents(cents), style: textStyle),
            ),
          ),
        ],
      ),
    );
  }

  // Same proportions as the last two columns of the parts table.
  const totalsFlex = 28;
  const notesFlex = 9 + 12 + 40;

  return pw.Column(
    children: [
      pw.Container(
        decoration: const pw.BoxDecoration(
          border: pw.Border(left: _Style.line, right: _Style.line),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: notesFlex,
              child: pw.Container(
                height: 72,
                padding: const pw.EdgeInsets.all(5),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(right: _Style.line, bottom: _Style.line),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Observações:', style: style.label),
                    pw.SizedBox(height: 3),
                    pw.Text(order.notes, maxLines: 5),
                  ],
                ),
              ),
            ),
            pw.Expanded(
              flex: totalsFlex,
              child: pw.Column(
                children: [
                  totalRow('TOTAL PÇ', order.partsTotalCents),
                  totalRow('SERVIÇO', order.laborCents),
                  totalRow('TOTAL', order.totalCents, emphasized: true),
                ],
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 24),
      pw.Table(
        border: pw.TableBorder.all(width: _Style.line.width),
        columnWidths: const {
          0: pw.FlexColumnWidth(3),
          1: pw.FlexColumnWidth(2),
          2: pw.FlexColumnWidth(1.7),
          3: pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            children: [
              for (final label in ['VISTO', 'DATA', 'TÉCNICO', 'CLIENTE'])
                pw.Padding(
                  padding: const pw.EdgeInsets.all(3),
                  child: pw.Text(label, textAlign: pw.TextAlign.center),
                ),
            ],
          ),
          // Left blank: signed and dated by hand.
          pw.TableRow(children: List.generate(4, (_) => pw.SizedBox(height: 34))),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: pw.BoxDecoration(border: pw.Border.all(width: _Style.line.width)),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                'O equipamento foi consertado e revisado, estando em perfeitas '
                'condições de funcionamento',
              ),
            ),
            pw.SizedBox(width: 8),
            _yesNo(order.equipmentOk),
          ],
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Building blocks

/// "☐ Sim ☐ Não", drawn as boxes instead of font glyphs.
pw.Widget _yesNo(bool? value) {
  pw.Widget option(String label, bool checked) => pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: 9,
            height: 9,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.7)),
            child: checked
                ? pw.Text(
                    'X',
                    style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                  )
                : null,
          ),
          pw.SizedBox(width: 3),
          pw.Text(label),
        ],
      );

  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      option('Sim', value == true),
      pw.SizedBox(width: 8),
      option('Não', value == false),
    ],
  );
}

class _Cell {
  const _Cell({required this.child, this.flex = 1, this.height});

  /// "Label: value" on one line, as in the paper form.
  factory _Cell.field(String label, String value, _Style style, {int flex = 1}) {
    return _Cell(
      flex: flex,
      child: pw.RichText(
        maxLines: 2,
        text: pw.TextSpan(
          text: '$label: ',
          style: style.label,
          children: [pw.TextSpan(text: value, style: style.value)],
        ),
      ),
    );
  }

  final pw.Widget child;
  final int flex;
  final double? height;
}

/// Rows of bordered cells. Each row is a one-row table, so cells in a row
/// share the same height and rows can have different column splits.
/// Only the first row of a grid with [top] draws a top line; otherwise the
/// box above already provides it (no doubled lines).
pw.Widget _grid(List<List<_Cell>> rows, {bool top = false}) {
  return pw.Column(
    children: [
      for (final (index, row) in rows.indexed)
        pw.Table(
          border: pw.TableBorder(
            left: _Style.line,
            right: _Style.line,
            bottom: _Style.line,
            top: top && index == 0 ? _Style.line : pw.BorderSide.none,
            verticalInside: _Style.line,
          ),
          columnWidths: {
            for (final (column, cell) in row.indexed)
              column: pw.FlexColumnWidth(cell.flex.toDouble()),
          },
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
          children: [
            pw.TableRow(
              children: [
                for (final cell in row)
                  pw.Container(
                    height: cell.height,
                    constraints: cell.height == null
                        ? const pw.BoxConstraints(minHeight: 17)
                        : null,
                    alignment: pw.Alignment.centerLeft,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 3,
                    ),
                    child: cell.child,
                  ),
              ],
            ),
          ],
        ),
    ],
  );
}

/// Generic "phone in a green circle" icon next to the WhatsApp number.
const _whatsAppIcon = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="12" fill="#25D366"/>
  <path fill="#FFFFFF" transform="translate(4.2 4.2) scale(0.65)"
    d="M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z"/>
</svg>
''';
