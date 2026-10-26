import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../core/formatting/formatters.dart';
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
  late final _labor = _text(_moneyText(_initial.laborCents));

  late bool? _underWarranty = _initial.underWarranty;
  late DateTime? _calledAt = _initial.calledAt;
  late DateTime? _scheduledFor = _initial.scheduledFor;
  late String? _scheduledTime = _initial.scheduledTime;
  late DateTime? _installedAt = _initial.installedAt;
  late bool? _equipmentOk = _initial.equipmentOk;

  late final List<_ItemFields> _items = [
    for (final item in _initial.items) _ItemFields(item, _onChanged),
  ];

  bool _dirty = false;
  bool _saving = false;

  bool get _isEditing => widget.initialOrder != null;

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

  void _addItem() => _set(() => _items.add(_ItemFields(null, _onChanged)));

  void _removeItem(_ItemFields item) {
    _set(() => _items.remove(item));
    // Its text fields are still on screen until the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => item.dispose());
  }

  int get _partsTotalCents =>
      _items.fold(0, (sum, item) => sum + (item.toItem()?.totalCents ?? 0));

  int get _laborCents => parseCents(_labor.text) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final deps = widget.dependencies;
    final responsible = _isEditing
        ? _initial.responsibleName
        : await deps.settings.responsibleName(
            fallback: deps.config.companyResponsible,
          );

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

  /// Back button with unsaved changes asks before discarding them.
  Future<void> _onPopBlocked() async {
    final discard = await _confirm(
      title: 'Descartar alterações?',
      message: 'O que você preencheu não foi salvo.',
      action: 'Descartar',
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
            child: const Text('Cancelar'),
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
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPopBlocked();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Editar OS' : 'Nova OS')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FormSection(
                title: 'Ordem de serviço',
                children: [
                  _field(_orderNumber, 'Nº da OS'),
                ],
              ),
              FormSection(
                title: 'Cliente',
                children: [
                  _field(_customerName, 'Cliente'),
                  _field(_customerDocument, 'CPF/CNPJ'),
                  _field(_customerAddress, 'Endereço'),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(flex: 3, child: _field(_customerCity, 'Cidade')),
                      Expanded(child: _field(_customerState, 'Estado')),
                    ],
                  ),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: _field(
                          _customerContact,
                          'Contato',
                          keyboard: TextInputType.phone,
                        ),
                      ),
                      Expanded(
                        child: _field(
                          _customerZip,
                          'CEP',
                          keyboard: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              FormSection(
                title: 'Atendimento',
                children: [
                  _field(_invoiceNumber, 'N.F.'),
                  YesNoField(
                    label: 'Garantia',
                    value: _underWarranty,
                    onChanged: (v) => _set(() => _underWarranty = v),
                  ),
                  DateField(
                    label: 'Chamado',
                    value: _calledAt,
                    onChanged: (v) => _set(() => _calledAt = v),
                  ),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: DateField(
                          label: 'Marcado p/',
                          value: _scheduledFor,
                          onChanged: (v) => _set(() => _scheduledFor = v),
                        ),
                      ),
                      Expanded(
                        child: TimeField(
                          label: 'Horário',
                          value: _scheduledTime,
                          onChanged: (v) => _set(() => _scheduledTime = v),
                        ),
                      ),
                    ],
                  ),
                  DateField(
                    label: 'Instalado em',
                    value: _installedAt,
                    onChanged: (v) => _set(() => _installedAt = v),
                  ),
                ],
              ),
              FormSection(
                title: 'Serviços executados',
                children: [
                  _field(_servicesPerformed, 'Descrição', lines: 4),
                ],
              ),
              FormSection(
                title: 'Peças',
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
                    label: const Text('Adicionar peça'),
                  ),
                ],
              ),
              FormSection(
                title: 'Valores',
                children: [
                  _TotalRow(label: 'Total peças', cents: _partsTotalCents),
                  _field(
                    _labor,
                    'Serviço (R\$)',
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: validateMoney,
                  ),
                  _TotalRow(
                    label: 'TOTAL',
                    cents: _partsTotalCents + _laborCents,
                    emphasized: true,
                  ),
                ],
              ),
              FormSection(
                title: 'Observações',
                children: [_field(_notes, 'Observações', lines: 3)],
              ),
              FormSection(
                title: 'Conclusão',
                children: [
                  YesNoField(
                    label: 'O equipamento foi consertado e revisado, estando '
                        'em perfeitas condições de funcionamento?',
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
              label: Text(_saving ? 'Salvando…' : 'Salvar OS'),
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
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: lines > 1 ? TextInputType.multiline : keyboard,
      textCapitalization: TextCapitalization.sentences,
      minLines: lines,
      maxLines: lines > 1 ? null : 1,
      validator: validator,
    );
  }
}

/// Text controllers for one row of the parts table.
class _ItemFields {
  _ItemFields(ServiceOrderItem? item, VoidCallback onChanged)
      : quantity = TextEditingController(text: '${item?.quantity ?? 1}'),
        code = TextEditingController(text: item?.code ?? ''),
        description = TextEditingController(text: item?.description ?? ''),
        unitPrice = TextEditingController(
          text: item == null ? '' : _moneyText(item.unitPriceCents),
        ) {
    for (final controller in _all) {
      _onTextChanged(controller, onChanged);
    }
  }

  final TextEditingController quantity;
  final TextEditingController code;
  final TextEditingController description;
  final TextEditingController unitPrice;

  List<TextEditingController> get _all => [quantity, code, description, unitPrice];

  /// A row the user added but never filled is dropped on save.
  bool get isBlank =>
      code.text.trim().isEmpty &&
      description.text.trim().isEmpty &&
      unitPrice.text.trim().isEmpty;

  /// Null while quantity or price are invalid.
  ServiceOrderItem? toItem() {
    final qty = int.tryParse(quantity.text.trim());
    final price = parseCents(unitPrice.text);
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
                Expanded(child: Text('Peça ${index + 1}')),
                IconButton(
                  tooltip: 'Remover peça',
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
                    decoration: const InputDecoration(labelText: 'Nome da peça'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: fields.quantity,
                          decoration: const InputDecoration(labelText: 'Quant.'),
                          keyboardType: TextInputType.number,
                          validator: (text) {
                            final qty = int.tryParse(text?.trim() ?? '');
                            return qty == null || qty <= 0 ? 'Inválida' : null;
                          },
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: fields.code,
                          decoration: const InputDecoration(labelText: 'Código'),
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
                          decoration: const InputDecoration(
                            labelText: 'Valor unit. (R\$)',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: validateMoney,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          total == null ? '—' : 'Total: R\$ ${formatCents(total)}',
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
        Text('R\$ ${formatCents(cents)}', style: style),
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

/// Initial text for a money field: empty instead of "0,00".
String _moneyText(int cents) => cents == 0 ? '' : formatCents(cents);
