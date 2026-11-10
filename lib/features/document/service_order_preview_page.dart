import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../l10n/app_localizations.dart';
import '../service_order/data/service_order.dart';
import '../service_order/service_order_form_page.dart';

enum _MenuAction { delete }

/// Main screen of one order: shows the generated document and its actions
/// (share PDF, share image, print, edit, delete).
class ServiceOrderPreviewPage extends StatefulWidget {
  const ServiceOrderPreviewPage({
    super.key,
    required this.dependencies,
    required this.orderId,
  });

  final AppDependencies dependencies;
  final int orderId;

  @override
  State<ServiceOrderPreviewPage> createState() =>
      _ServiceOrderPreviewPageState();
}

class _ServiceOrderPreviewPageState extends State<ServiceOrderPreviewPage> {
  ServiceOrder? _order;
  Uint8List? _pdf;

  /// One PNG per page; shown on screen and used for "share as image".
  List<Uint8List>? _pages;
  Object? _error;
  bool _busy = false;

  AppDependencies get _deps => widget.dependencies;

  /// Translations for the app language. Looked up from the preferences (not
  /// the context) because the PDF starts building in initState.
  AppLocalizations get _l10n => lookupAppLocalizations(_deps.preferences.locale);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _pages = null;
      _error = null;
    });

    try {
      final order = await _deps.orders.findById(widget.orderId);
      if (order == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      final company = await _deps.settings.companyProfile(_deps.companyDefaults);
      final pdf = await _deps.documents.buildPdf(
        order,
        company,
        l10n: _l10n,
        format: _deps.preferences.format,
      );
      final pages = await _deps.documents.renderPages(pdf);
      if (!mounted) return;
      setState(() {
        _order = order;
        _pdf = pdf;
        _pages = pages;
      });
    } catch (error) {
      // Layout problems in the pdf package are Errors, not Exceptions.
      if (mounted) setState(() => _error = error);
    }
  }

  /// Runs a share/print action, blocking the buttons while it runs.
  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.couldNotComplete('$error'))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final savedId = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => ServiceOrderFormPage(
          dependencies: _deps,
          initialOrder: _order,
        ),
      ),
    );
    if (savedId != null) await _load();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.deleteOrderTitle),
        content: Text(_l10n.deleteOrderMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_l10n.delete),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;

    await _deps.orders.delete(widget.orderId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final l10n = AppLocalizations.of(context);
    final number = order == null || order.orderNumber.isEmpty
        ? l10n.orderTitle
        : l10n.orderTitleWithNumber(order.orderNumber);
    final ready = _pdf != null && _pages != null && !_busy;

    return Scaffold(
      appBar: AppBar(
        title: Text(number),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: order == null || _busy ? null : _edit,
          ),
          PopupMenuButton<_MenuAction>(
            // onSelected runs after the menu closes, so the dialog is safe.
            onSelected: (action) => switch (action) {
              _MenuAction.delete => _delete(),
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _MenuAction.delete,
                child: Text(l10n.delete),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            spacing: 8,
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: ready
                      ? () => _run(
                            () => _deps.documents.sharePdf(
                              order!,
                              _pdf!,
                              prefix: l10n.pdfFilePrefix,
                            ),
                          )
                      : null,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l10n.sendPdf),
                ),
              ),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: ready
                      ? () => _run(
                            () => _deps.documents.shareImages(
                              order!,
                              _pages!,
                              prefix: l10n.pdfFilePrefix,
                            ),
                          )
                      : null,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(l10n.image),
                ),
              ),
              IconButton.filledTonal(
                tooltip: l10n.print,
                onPressed: ready
                    ? () => _run(
                          () => _deps.documents.printPdf(
                            order!,
                            _pdf!,
                            prefix: l10n.pdfFilePrefix,
                          ),
                        )
                    : null,
                icon: const Icon(Icons.print_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Text(
                _l10n.documentError('$_error'),
                textAlign: TextAlign.center,
              ),
              OutlinedButton(onPressed: _load, child: Text(_l10n.tryAgain)),
            ],
          ),
        ),
      );
    }

    final pages = _pages;
    if (pages == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: pages.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        // Pinch to zoom on each page.
        itemBuilder: (_, index) => InteractiveViewer(
          maxScale: 4,
          child: Material(
            elevation: 2,
            child: Image.memory(pages[index], gaplessPlayback: true),
          ),
        ),
      ),
    );
  }
}
