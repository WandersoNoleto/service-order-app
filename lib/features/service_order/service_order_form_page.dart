import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../core/formatting/region_format.dart';
import '../../core/preferences/app_preferences.dart';
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

  bool _dirty = false;
  bool _saving = false;

  bool get _isEditing => widget.initialOrder != null;

  /// Regional format (Settings) for money typed in this form.
  RegionFormat get _format => widget.dependencies.preferences.format;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
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

  void _addItem() =>
      _set(() => _items.add(_ItemFields(null, _onChanged, _format)));

  void _removeItem(_ItemFields item) {
    _set(() => _items.remove(item));
    // Its text fields are still on screen until the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => item.dispose());
  }

  int get _partsTotalCents =>
      _items.fold(0, (sum, item) => sum + (item.toItem()?.totalCents ?? 0));

  int get _laborCents => _format.parseMoney(_labor.text) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
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
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPopBlocked();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_isEditing ? l10n.editOrderTitle : l10n.newOrderTitle)),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FormSection(
                title: l10n.sectionOrder,
                children: [
                  _field(_orderNumber, l10n.orderNumberField),
                ],
              ),
              FormSection(
                title: l10n.sectionCustomer,
                children: [
                  _field(_customerName, l10n.customer),
                  _field(_customerDocument, l10n.customerDocument),
                  _field(_customerAddress, l10n.address),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(flex: 3, child: _field(_customerCity, l10n.city)),
                      Expanded(child: _field(_customerState, l10n.state)),
                    ],
                  ),
                  Row(
                    spacing: 12,
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
              ),
              FormSection(
                title: l10n.sectionServiceCall,
                children: [
                  _field(_invoiceNumber, l10n.invoice),
                  YesNoField(
                    label: l10n.warranty,
                    value: _underWarranty,
                    onChanged: (v) => _set(() => _underWarranty = v),
                  ),
                  DateField(
                    label: l10n.calledAt,
                    value: _calledAt,
                    onChanged: (v) => _set(() => _calledAt = v),
                  ),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: DateField(
                          label: l10n.scheduledFor,
                          value: _scheduledFor,
                          onChanged: (v) => _set(() => _scheduledFor = v),
                        ),
                      ),
                      Expanded(
                        child: TimeField(
                          label: l10n.scheduledTime,
                          value: _scheduledTime,
                          onChanged: (v) => _set(() => _scheduledTime = v),
                        ),
                      ),
                    ],
                  ),
                  DateField(
                    label: l10n.installedAt,
                    value: _installedAt,
                    onChanged: (v) => _set(() => _installedAt = v),
                  ),
                ],
              ),
              FormSection(
                title: l10n.sectionServicesPerformed,
                children: [
                  _field(
                    _servicesPerformed,
                    l10n.description,
                    lines: 4,
                    maxLength: ServiceOrder.servicesPerformedMaxLength,
                  ),
                ],
              ),
              FormSection(
                title: l10n.sectionParts,
                children: [
                  for (final (index, item) in _items.indexed)
                    _ItemCard(
                      key: ObjectKey(item),
                      index: index,
                      fields: item,
                      onRemove: () => _removeItem(item),
                    ),
                  OutlinedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addPart),
                  ),
                ],
              ),
              FormSection(
                title: l10n.sectionValues,
                children: [
                  _TotalRow(label: l10n.partsTotal, cents: _partsTotalCents),
                  _field(
                    _labor,
                    l10n.laborField(_format.currencySymbol),
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (text) => validateMoney(text, _format, l10n),
                  ),
                  _TotalRow(
                    label: l10n.total,
                    cents: _partsTotalCents + _laborCents,
                    emphasized: true,
                  ),
                ],
              ),
              FormSection(
                title: l10n.sectionNotes,
                children: [
                  _field(
                    _notes,
                    l10n.notes,
                    lines: 3,
                    maxLength: ServiceOrder.notesMaxLength,
                  ),
                ],
              ),
              FormSection(
                title: l10n.sectionConclusion,
                children: [
                  YesNoField(
                    label: l10n.equipmentOkQuestion,
                    value: _equipmentOk,
                    onChanged: (v) => _set(() => _equipmentOk = v),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? l10n.saving : l10n.saveOrder),
            ),
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
    FormFieldValidator<String>? validator,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: lines > 1 ? TextInputType.multiline : keyboard,
      textCapitalization: TextCapitalization.sentences,
      minLines: lines,
      maxLines: lines > 1 ? null : 1,
      validator: validator,
      // Shows a "120/300" counter and stops typing at the PDF limit.
      maxLength: maxLength,
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

  /// A row the user added but never filled is dropped on save.
  bool get isBlank =>
      code.text.trim().isEmpty &&
      description.text.trim().isEmpty &&
      unitPrice.text.trim().isEmpty;

  /// Null while quantity or price are invalid.
  ServiceOrderItem? toItem() {
    final qty = int.tryParse(quantity.text.trim());
    final price = format.parseMoney(unitPrice.text);
    if (qty == null || price == null) return null;

    return ServiceOrderItem(
      quantity: qty,
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

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.index,
    required this.fields,
    required this.onRemove,
  });

  final int index;
  final _ItemFields fields;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = fields.toItem()?.totalCents;

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
        child: Column(
          spacing: 8,
          children: [
            Row(
              children: [
                Expanded(child: Text(l10n.partNumber(index + 1))),
                IconButton(
                  tooltip: l10n.removePart,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                spacing: 8,
                children: [
                  TextFormField(
                    controller: fields.description,
                    decoration: InputDecoration(labelText: l10n.partName),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: fields.quantity,
                          decoration:
                              InputDecoration(labelText: l10n.quantityShort),
                          keyboardType: TextInputType.number,
                          validator: (text) {
                            final qty = int.tryParse(text?.trim() ?? '');
                            return qty == null || qty <= 0
                                ? l10n.invalidQuantity
                                : null;
                          },
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: fields.code,
                          decoration: InputDecoration(labelText: l10n.code),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: fields.unitPrice,
                          decoration: InputDecoration(
                            labelText: l10n.unitPriceField(
                              fields.format.currencySymbol,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (text) =>
                              validateMoney(text, fields.format, l10n),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          total == null
                              ? '—'
                              : l10n.lineTotal(fields.format.money(total)),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.cents,
    this.emphasized = false,
  });

  final String label;
  final int cents;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = emphasized ? textTheme.titleMedium : textTheme.bodyLarge;

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(context.format.money(cents), style: style),
      ],
    );
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
