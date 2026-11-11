import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/brand_widgets.dart';
import '../../app/coming_soon.dart';
import '../../core/formatting/region_format.dart';
import '../../l10n/app_localizations.dart';
import 'data/service_order.dart';
import 'widgets/form_fields.dart';

/// Create or edit a service order. Pushed over the shell (no bottom bar).
///
/// Pops with the order id when saved, or null when the user leaves without
/// saving. Deleting lives on the preview screen.
class ServiceOrderFormPage extends StatefulWidget {
  const ServiceOrderFormPage({
    super.key,
    required this.dependencies,
    this.initialOrder,
  });

  final AppDependencies dependencies;

  /// Null when creating a new order.
  final ServiceOrder? initialOrder;

  @override
  State<ServiceOrderFormPage> createState() => _ServiceOrderFormPageState();
}

class _ServiceOrderFormPageState extends State<ServiceOrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <TextEditingController>[];

  late final ServiceOrder _initial = widget.initialOrder ?? const ServiceOrder();

  late final _orderNumber = _text(_initial.orderNumber);
  late final _customerName = _text(_initial.customerName);
  late final _customerDocument = _text(_initial.customerDocument);
  late final _customerAddress = _text(_initial.customerAddress);
  late final _customerCity = _text(_initial.customerCity);
  late final _customerState = _text(_initial.customerState);
  late final _customerContact = _text(_initial.customerContact);
  late final _customerZip = _text(_initial.customerZip);
  late final _invoiceNumber = _text(_initial.invoiceNumber);
  late final _servicesPerformed = _text(_initial.servicesPerformed);
  late final _notes = _text(_initial.notes);
  late final _labor = _text(_moneyText(_initial.laborCents, _format));

  late bool? _underWarranty = _initial.underWarranty;
  late DateTime? _calledAt = _initial.calledAt;
  late DateTime? _scheduledFor = _initial.scheduledFor;
  late String? _scheduledTime = _initial.scheduledTime;
  late DateTime? _installedAt = _initial.installedAt;
  late bool? _equipmentOk = _initial.equipmentOk;

  late final List<_ItemFields> _items = [
    for (final item in _initial.items) _ItemFields(item, _onChanged, _format),
  ];


  final _customerFocus = FocusNode();

  final _removedItems = <_ItemFields>[];

  /// One order per customer already served, newest first: suggestions for
  /// the customer field (there is no separate customer list).
  List<ServiceOrder> _knownCustomers = const [];

  // Anchors of the step shortcuts at the top.
  final _partsKey = GlobalKey();
  final _reviewKey = GlobalKey();

  bool _dirty = false;
  bool _saving = false;

  bool get _isEditing => widget.initialOrder != null;

  /// Regional format (Settings) for money typed in this form.
  RegionFormat get _format => widget.dependencies.preferences.format;

  @override
  void initState() {
    super.initState();
    _loadKnownCustomers();
  }

  @override
  void dispose() {
    _customerFocus.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final item in [..._items, ..._removedItems]) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadKnownCustomers() async {
    final orders = await widget.dependencies.orders.list();
    final seen = <String>{};
    final customers = [
      for (final order in orders)
        if (order.customerName.isNotEmpty &&
            seen.add(order.customerName.toLowerCase()))
          order,
    ];
    if (mounted) setState(() => _knownCustomers = customers);
  }

  /// Picking a suggestion fills the rest of the customer data.
  void _useCustomer(ServiceOrder from) {
    _customerDocument.text = from.customerDocument;
    _customerAddress.text = from.customerAddress;
    _customerCity.text = from.customerCity;
    _customerState.text = from.customerState;
    _customerContact.text = from.customerContact;
    _customerZip.text = from.customerZip;
    _customerFocus.unfocus();
    _onChanged();
  }

  TextEditingController _text(String initial) {
    final controller = TextEditingController(text: initial);
    _onTextChanged(controller, _onChanged);
    _controllers.add(controller);
    return controller;
  }

  /// Any edit marks the form as dirty and refreshes the live totals.
  void _onChanged() => setState(() => _dirty = true);

  void _set(VoidCallback change) {
    setState(() {
      change();
      _dirty = true;
    });
  }

  void _addItem() {
    final item = _ItemFields(null, _onChanged, _format);
    _set(() => _items.add(item));
    _editItem(item);
  }

  void _removeItem(_ItemFields item) {
    _set(() => _items.remove(item));
    // Its editor may still be closing: disposed with the page.
    _removedItems.add(item);
  }

  int get _partsTotalCents =>
      _items.fold(0, (sum, item) => sum + (item.toItem()?.totalCents ?? 0));

  int get _laborCents => _format.parseMoney(_labor.text) ?? 0;

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// The number is free text typed by the user; it lives in a chip on the
  /// top bar and is edited in a small dialog.
  Future<void> _editNumber() async {
    final l10n = AppLocalizations.of(context);
    var typed = _orderNumber.text;

    final number = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sectionOrder),
        content: TextFormField(
          initialValue: typed,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.orderNumberField),
          onChanged: (text) => typed = text,
          onFieldSubmitted: (text) => Navigator.of(context).pop(text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(typed),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (number != null) _orderNumber.text = number.trim();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.any((item) => !item.isBlank && item.toItem() == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).invalidAmount)),
      );
      return;
    }
    if (!await _confirmNumberIfDuplicated()) return;
    setState(() => _saving = true);

    final deps = widget.dependencies;
    final responsible = _isEditing
        ? _initial.responsibleName
        : (await deps.settings.companyProfile(deps.companyDefaults))
            .responsibleName;

    final order = ServiceOrder(
      id: _initial.id,
      orderNumber: _orderNumber.text.trim(),
      responsibleName: responsible,
      customerName: _customerName.text.trim(),
      customerDocument: _customerDocument.text.trim(),
      customerAddress: _customerAddress.text.trim(),
      customerCity: _customerCity.text.trim(),
      customerState: _customerState.text.trim(),
      customerContact: _customerContact.text.trim(),
      customerZip: _customerZip.text.trim(),
      invoiceNumber: _invoiceNumber.text.trim(),
      underWarranty: _underWarranty,
      calledAt: _calledAt,
      scheduledFor: _scheduledFor,
      scheduledTime: _scheduledTime,
      installedAt: _installedAt,
      servicesPerformed: _servicesPerformed.text.trim(),
      notes: _notes.text.trim(),
      laborCents: _laborCents,
      equipmentOk: _equipmentOk,
      pdfPath: _initial.pdfPath,
      items: [
        for (final item in _items)
          if (item.toItem() case final parsed? when !item.isBlank) parsed,
      ],
    );

    final int id;
    if (_isEditing) {
      await deps.orders.update(order);
      id = order.id!;
    } else {
      id = await deps.orders.create(order);
    }

    if (!mounted) return;
    Navigator.of(context).pop(id);
  }

  /// The number is typed by the user, so it may repeat. Warns, but lets the
  /// user save anyway (nothing is blocked or inferred). Returns false when
  /// the user cancels.
  Future<bool> _confirmNumberIfDuplicated() async {
    final number = _orderNumber.text.trim();
    if (number.isEmpty) return true;

    final other = await widget.dependencies.orders.findByNumber(
      number,
      exceptId: _initial.id,
    );
    if (other == null || !mounted) return true;

    final l10n = AppLocalizations.of(context);
    final message = other.customerName.isEmpty
        ? l10n.duplicateNumberMessage(number)
        : l10n.duplicateNumberMessageWithCustomer(number, other.customerName);
    return _confirm(
      title: l10n.duplicateNumberTitle,
      message: message,
      action: l10n.saveAnyway,
    );
  }

  /// Back button with unsaved changes asks before discarding them.
  Future<void> _onPopBlocked() async {
    final discard = await _confirm(
      title: AppLocalizations.of(context).discardChangesTitle,
      message: AppLocalizations.of(context).discardOrderMessage,
      action: AppLocalizations.of(context).discard,
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final number = _orderNumber.text.trim();
    // On wide screens the form stays in a readable column.
    final gutter =
        math.max(14.0, (MediaQuery.sizeOf(context).width - 720) / 2);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPopBlocked();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const CloseButton(),
          titleSpacing: 0,
          // Two lines of text: grows with the font size of the phone.
          toolbarHeight: math.max(
            kToolbarHeight,
            MediaQuery.textScalerOf(context).scale(40) + 16,
          ),
          title: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showComingSoon(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? l10n.editOrderTitle : l10n.newOrderTitle,
                  style: theme.textTheme.titleMedium,
                ),
                Text(l10n.draftNotSaved, style: muted),
              ],
            ),
          ),
          actions: [
            ActionChip(
              tooltip: l10n.orderNumberField,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Text(
                    number.isEmpty
                        ? l10n.orderNoNumber
                        : l10n.orderNumberShort(number),
                  ),
                  const Icon(Icons.edit_outlined, size: 14),
                ],
              ),
              labelStyle: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface,
              ),
              backgroundColor: Colors.transparent,
              shape: const StadiumBorder(),
              side: BorderSide(color: colors.outline, width: 0.5),
              visualDensity: VisualDensity.compact,
              onPressed: _editNumber,
            ),
            SizedBox(width: gutter),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 0),
              child: _Steps(
                steps: [
                  (
                    label: l10n.sectionCustomer,
                    done: _customerName.text.trim().isNotEmpty,
                    onTap: _editCustomer,
                  ),
                  (
                    label: l10n.stepService,
                    done: _servicesPerformed.text.trim().isNotEmpty,
                    onTap: _editService,
                  ),
                  (
                    label: l10n.sectionParts,
                    done: _items.any((item) => !item.isBlank),
                    onTap: () => _scrollTo(_partsKey),
                  ),
                  (
                    label: l10n.stepReview,
                    done: false,
                    onTap: () => _scrollTo(_reviewKey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _customerRow(l10n),
                            const Divider(height: 1),
                            _serviceRow(l10n),
                          ],
                        ),
                      ),
                      Padding(
                        key: _partsKey,
                        padding: const EdgeInsets.fromLTRB(2, 14, 2, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.partsAndMaterials,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text(l10n.itemsCount(_items.length), style: muted),
                          ],
                        ),
                      ),
                      Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final item in _items) ...[
                              _PartRow(
                                key: ObjectKey(item),
                                fields: item,
                                onTap: () => _editItem(item),
                              ),
                              const Divider(height: 1),
                            ],
                            InkWell(
                              onTap: _addItem,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                child: Row(
                                  spacing: 10,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      size: 18,
                                      color: colors.primary,
                                    ),
                                    Text(
                                      l10n.addPart,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(color: colors.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: _reviewKey,
                        controller: _labor,
                        decoration: InputDecoration(
                          labelText: l10n.laborField(_format.currencySymbol),
                          fillColor: colors.surface,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (text) => validateMoney(text, _format, l10n),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notes,
                        decoration: InputDecoration(
                          labelText: l10n.notes,
                          fillColor: colors.surface,
                        ),
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: null,
                        // Shows a "120/300" counter and stops at the PDF limit.
                        maxLength: ServiceOrder.notesMaxLength,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _TotalBar(
          gutter: gutter,
          breakdown: l10n.totalsBreakdown(
            _format.money(_partsTotalCents),
            _format.money(_laborCents),
          ),
          total: _format.money(_partsTotalCents + _laborCents),
          actionLabel: _saving ? l10n.saving : l10n.saveOrder,
          onAction: _saving ? null : _save,
        ),
      ),
    );
  }

  /// Customer in one line: initials, name and address. Tap to fill or change.
  Widget _customerRow(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final name = _customerName.text.trim();
    final cityState = [_customerCity.text.trim(), _customerState.text.trim()]
        .where((part) => part.isNotEmpty)
        .join('-');
    final address = [_customerAddress.text.trim(), cityState]
        .where((part) => part.isNotEmpty)
        .join(' · ');

    return _SummaryRow(
      leading: InitialsAvatar(name),
      title: name.isEmpty ? l10n.customerNotInformed : name,
      subtitle: address.isEmpty ? l10n.customerHint : address,
      trailing: Text(
        name.isEmpty ? l10n.add : l10n.change,
        style: theme.textTheme.labelMedium?.copyWith(color: colors.primary),
      ),
      onTap: _editCustomer,
    );
  }

  /// What was done and the service call details, in one line.
  Widget _serviceRow(AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;
    final service = _servicesPerformed.text.trim().split('\n').first;
    final day = _scheduledFor ?? _calledAt ?? _installedAt;
    final details = [
      if (day != null)
        [
          _format.date(day),
          if (_scheduledFor != null && _scheduledTime != null)
            _format.time(_scheduledTime!),
        ].join(', '),
      if (_underWarranty case final warranty?)
        warranty ? l10n.warranty : l10n.noWarranty,
      if (_invoiceNumber.text.trim().isNotEmpty)
        '${l10n.invoice} ${_invoiceNumber.text.trim()}',
    ].join(' · ');

    return _SummaryRow(
      leading: SizedBox(
        width: 34,
        child: Icon(Icons.build_outlined, size: 18, color: colors.onSurface),
      ),
      title: service.isEmpty ? l10n.sectionServicesPerformed : service,
      subtitle: details.isEmpty ? l10n.serviceCallHint : details,
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: colors.onSurfaceVariant,
      ),
      onTap: _editService,
    );
  }

  /// Editors open over the summary, in a sheet with a title and "Done".
  /// [fields] gets a callback to redraw the sheet after a change that is
  /// not a text edit (dates, yes/no).
  Future<T?> _showSheet<T>({
    required String title,
    required List<Widget> Function(BuildContext context, VoidCallback redraw)
        fields,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppLocalizations.of(context).done),
                  ),
                ],
              ),
              ...fields(context, () => setSheetState(() {})),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editCustomer() {
    final l10n = AppLocalizations.of(context);

    return _showSheet<void>(
      title: l10n.sectionCustomer,
      fields: (context, _) => [
        _customerNameField(l10n),
        _field(_customerDocument, l10n.customerDocument),
        _field(_customerAddress, l10n.address),
        Row(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _field(_customerCity, l10n.city)),
            Expanded(child: _field(_customerState, l10n.state)),
          ],
        ),
        Row(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                _customerContact,
                l10n.contact,
                keyboard: TextInputType.phone,
              ),
            ),
            Expanded(
              child: _field(
                _customerZip,
                l10n.zip,
                keyboard: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _editService() {
    final l10n = AppLocalizations.of(context);

    return _showSheet<void>(
      title: l10n.sectionServiceCall,
      fields: (context, redraw) {
        void change(VoidCallback change) {
          _set(change);
          redraw();
        }

        return [
          _field(
            _servicesPerformed,
            l10n.sectionServicesPerformed,
            lines: 3,
            maxLength: ServiceOrder.servicesPerformedMaxLength,
          ),
          _field(_invoiceNumber, l10n.invoice),
          YesNoField(
            label: l10n.warranty,
            value: _underWarranty,
            onChanged: (v) => change(() => _underWarranty = v),
          ),
          DateField(
            label: l10n.calledAt,
            value: _calledAt,
            onChanged: (v) => change(() => _calledAt = v),
          ),
          Row(
            spacing: 12,
            children: [
              Expanded(
                child: DateField(
                  label: l10n.scheduledFor,
                  value: _scheduledFor,
                  onChanged: (v) => change(() => _scheduledFor = v),
                ),
              ),
              Expanded(
                child: TimeField(
                  label: l10n.scheduledTime,
                  value: _scheduledTime,
                  onChanged: (v) => change(() => _scheduledTime = v),
                ),
              ),
            ],
          ),
          DateField(
            label: l10n.installedAt,
            value: _installedAt,
            onChanged: (v) => change(() => _installedAt = v),
          ),
          YesNoField(
            label: l10n.equipmentOkQuestion,
            value: _equipmentOk,
            onChanged: (v) => change(() => _equipmentOk = v),
          ),
        ];
      },
    );
  }

  /// Name, code and unit price of one part. The quantity is changed on the
  /// row itself.
  Future<void> _editItem(_ItemFields item) async {
    final l10n = AppLocalizations.of(context);

    final remove = await _showSheet<bool>(
      title: l10n.part,
      fields: (context, _) => [
        TextFormField(
          controller: item.description,
          autofocus: item.isBlank,
          decoration: InputDecoration(labelText: l10n.partName),
          textCapitalization: TextCapitalization.sentences,
        ),
        Row(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: item.code,
                decoration: InputDecoration(labelText: l10n.code),
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: item.unitPrice,
                decoration: InputDecoration(
                  labelText: l10n.unitPriceField(_format.currencySymbol),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (text) => validateMoney(text, _format, l10n),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.removePart),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ],
    );

    // A part added and left empty is not kept.
    if (!mounted) return;
    if ((remove ?? false) || item.isBlank) _removeItem(item);
  }

  /// Name field that suggests customers from previous orders.
  Widget _customerNameField(AppLocalizations l10n) {
    return RawAutocomplete<ServiceOrder>(
      textEditingController: _customerName,
      focusNode: _customerFocus,
      displayStringForOption: (order) => order.customerName,
      optionsBuilder: (value) {
        final term = value.text.trim().toLowerCase();
        return _knownCustomers
            .where(
              (order) =>
                  order.customerName.toLowerCase().contains(term) &&
                  order.customerName.toLowerCase() != term,
            )
            .take(5);
      },
      onSelected: _useCustomer,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(labelText: l10n.customer),
        textCapitalization: TextCapitalization.words,
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              for (final order in options)
                ListTile(
                  dense: true,
                  leading: InitialsAvatar(order.customerName),
                  title: Text(order.customerName),
                  subtitle: order.customerAddress.isEmpty
                      ? null
                      : Text(
                          order.customerAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  onTap: () => onSelected(order),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    int lines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: lines > 1 ? TextInputType.multiline : keyboard,
      textCapitalization: TextCapitalization.sentences,
      minLines: lines,
      maxLines: lines > 1 ? null : 1,
      // Shows a "120/300" counter and stops typing at the PDF limit.
      maxLength: maxLength,
    );
  }
}

/// Progress of the order: a bar and a label per part, filled when done.
/// Tapping one opens or scrolls to it; nothing is locked in sequence.
class _Steps extends StatelessWidget {
  const _Steps({required this.steps});

  final List<({String label, bool done, VoidCallback onTap})> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      spacing: 4,
      children: [
        for (final step in steps)
          Expanded(
            child: InkWell(
              onTap: step.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ColoredBox(
                    color: step.done ? colors.primary : colors.outlineVariant,
                    child: const SizedBox(height: 3),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      step.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: step.done
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                        fontWeight:
                            step.done ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Row of a summary card: leading, two lines of text and a trailing action.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          spacing: 10,
          children: [
            leading,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// One part in the list: name, "code · unit price", quantity stepper and
/// the line total. Tap to edit the part.
class _PartRow extends StatelessWidget {
  const _PartRow({super.key, required this.fields, required this.onTap});

  final _ItemFields fields;
  final VoidCallback onTap;

  void _setQuantity(int quantity) => fields.quantity.text = '$quantity';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final quantity = fields.quantityValue;
    final item = fields.toItem();
    final name = fields.description.text.trim();
    final details = [
      if (fields.code.text.trim().isNotEmpty) fields.code.text.trim(),
      if (item != null)
        l10n.unitPriceEach(fields.format.money(item.unitPriceCents)),
    ].join(' · ');

    Widget step(IconData icon, String tooltip, VoidCallback? onPressed) =>
        IconButton(
          tooltip: tooltip,
          icon: Icon(icon, size: 16),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(6),
          onPressed: onPressed,
        );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          spacing: 10,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? l10n.partName : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (details.isNotEmpty)
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: ShapeDecoration(
                shape: StadiumBorder(
                  side: BorderSide(color: colors.outline, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  step(
                    Icons.remove,
                    l10n.decreaseQuantity,
                    quantity > 1 ? () => _setQuantity(quantity - 1) : null,
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 18),
                    child: Text(
                      '$quantity',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  step(
                    Icons.add,
                    l10n.increaseQuantity,
                    () => _setQuantity(quantity + 1),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 58),
              child: Text(
                item == null ? '—' : fields.format.money(item.totalCents),
                textAlign: TextAlign.right,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: item == null ? colors.error : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fixed bar at the bottom: parts and labor in one line, then the total
/// and the main action.
class _TotalBar extends StatelessWidget {
  const _TotalBar({
    required this.gutter,
    required this.breakdown,
    required this.total,
    required this.actionLabel,
    required this.onAction,
  });

  final double gutter;
  final String breakdown;
  final String total;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Material(
      color: colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.outlineVariant, width: 0.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  breakdown,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: muted,
                ),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).orderTotal,
                            style: muted,
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              total,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: onAction,
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        iconAlignment: IconAlignment.end,
                        label: Text(actionLabel, textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Text controllers for one row of the parts table.
class _ItemFields {
  _ItemFields(ServiceOrderItem? item, VoidCallback onChanged, this.format)
      : quantity = TextEditingController(text: '${item?.quantity ?? 1}'),
        code = TextEditingController(text: item?.code ?? ''),
        description = TextEditingController(text: item?.description ?? ''),
        unitPrice = TextEditingController(
          text: item == null ? '' : _moneyText(item.unitPriceCents, format),
        ) {
    for (final controller in _all) {
      _onTextChanged(controller, onChanged);
    }
  }

  final TextEditingController quantity;
  final TextEditingController code;
  final TextEditingController description;
  final TextEditingController unitPrice;

  /// Regional format used to read the price typed by the user.
  final RegionFormat format;

  List<TextEditingController> get _all => [quantity, code, description, unitPrice];

  /// Changed only through the stepper, so it is always a valid number.
  int get quantityValue => int.tryParse(quantity.text) ?? 1;

  /// A row the user added but never filled is dropped on save.
  bool get isBlank =>
      code.text.trim().isEmpty &&
      description.text.trim().isEmpty &&
      unitPrice.text.trim().isEmpty;

  /// Null while the price is invalid.
  ServiceOrderItem? toItem() {
    final price = format.parseMoney(unitPrice.text);
    if (price == null) return null;

    return ServiceOrderItem(
      quantity: quantityValue,
      code: code.text.trim(),
      description: description.text.trim(),
      unitPriceCents: price,
    );
  }

  void dispose() {
    for (final controller in _all) {
      controller.dispose();
    }
  }
}

/// Calls [onChanged] only when the text changes. Controllers also notify on
/// cursor moves, which must not mark the form as edited.
void _onTextChanged(TextEditingController controller, VoidCallback onChanged) {
  var last = controller.text;
  controller.addListener(() {
    if (controller.text == last) return;
    last = controller.text;
    onChanged();
  });
}

/// Initial text for a money field: empty instead of "0,00" / "0.00".
String _moneyText(int cents, RegionFormat format) =>
    cents == 0 ? '' : format.amount(cents);
