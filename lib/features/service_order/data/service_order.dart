/// One service order (OS), mirroring the client's paper template.
///
/// Every field is filled by the user; nothing is inferred. Money is stored
/// in cents to avoid floating point errors.
class ServiceOrder {
  const ServiceOrder({
    this.id,
    this.orderNumber = '',
    this.responsibleName = '',
    this.customerName = '',
    this.customerDocument = '',
    this.customerAddress = '',
    this.customerCity = '',
    this.customerState = '',
    this.customerContact = '',
    this.customerZip = '',
    this.invoiceNumber = '',
    this.underWarranty,
    this.calledAt,
    this.scheduledFor,
    this.scheduledTime,
    this.installedAt,
    this.servicesPerformed = '',
    this.notes = '',
    this.laborCents = 0,
    this.equipmentOk,
    this.pdfPath,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  /// Null until the order is saved.
  final int? id;

  /// "ORDEM DE SERVIÇO: nº" — typed by the user.
  final String orderNumber;

  /// Snapshot of the responsible name at the time the order was saved,
  /// so changing it in settings does not rewrite old orders.
  final String responsibleName;

  // Customer
  final String customerName;
  final String customerDocument;
  final String customerAddress;
  final String customerCity;
  final String customerState;
  final String customerContact;
  final String customerZip;

  // Service call
  final String invoiceNumber;

  /// Null means neither "Sim" nor "Não" was checked.
  final bool? underWarranty;
  final DateTime? calledAt;
  final DateTime? scheduledFor;

  /// "HH:mm".
  final String? scheduledTime;
  final DateTime? installedAt;

  final String servicesPerformed;
  final String notes;
  final int laborCents;

  /// "O equipamento foi consertado e revisado…" — null when unchecked.
  final bool? equipmentOk;

  /// Last generated PDF, if any.
  final String? pdfPath;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<ServiceOrderItem> items;

  int get partsTotalCents =>
      items.fold(0, (sum, item) => sum + item.totalCents);

  int get totalCents => partsTotalCents + laborCents;

  Map<String, Object?> toMap() => {
        'order_number': orderNumber,
        'responsible_name': responsibleName,
        'customer_name': customerName,
        'customer_document': customerDocument,
        'customer_address': customerAddress,
        'customer_city': customerCity,
        'customer_state': customerState,
        'customer_contact': customerContact,
        'customer_zip': customerZip,
        'invoice_number': invoiceNumber,
        'under_warranty': _boolToDb(underWarranty),
        'called_at': _dateToDb(calledAt),
        'scheduled_for': _dateToDb(scheduledFor),
        'scheduled_time': scheduledTime,
        'installed_at': _dateToDb(installedAt),
        'services_performed': servicesPerformed,
        'notes': notes,
        'labor_cents': laborCents,
        'equipment_ok': _boolToDb(equipmentOk),
        'pdf_path': pdfPath,
      };

  factory ServiceOrder.fromMap(
    Map<String, Object?> map, {
    List<ServiceOrderItem> items = const [],
  }) {
    return ServiceOrder(
      id: map['id'] as int,
      orderNumber: map['order_number'] as String,
      responsibleName: map['responsible_name'] as String,
      customerName: map['customer_name'] as String,
      customerDocument: map['customer_document'] as String,
      customerAddress: map['customer_address'] as String,
      customerCity: map['customer_city'] as String,
      customerState: map['customer_state'] as String,
      customerContact: map['customer_contact'] as String,
      customerZip: map['customer_zip'] as String,
      invoiceNumber: map['invoice_number'] as String,
      underWarranty: _boolFromDb(map['under_warranty']),
      calledAt: _dateFromDb(map['called_at']),
      scheduledFor: _dateFromDb(map['scheduled_for']),
      scheduledTime: map['scheduled_time'] as String?,
      installedAt: _dateFromDb(map['installed_at']),
      servicesPerformed: map['services_performed'] as String,
      notes: map['notes'] as String,
      laborCents: map['labor_cents'] as int,
      equipmentOk: _boolFromDb(map['equipment_ok']),
      pdfPath: map['pdf_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      items: items,
    );
  }
}

/// One row of the parts table ("Quant. | Código | Nome da peça | Valor").
class ServiceOrderItem {
  const ServiceOrderItem({
    this.quantity = 1,
    this.code = '',
    this.description = '',
    this.unitPriceCents = 0,
  });

  final int quantity;
  final String code;
  final String description;
  final int unitPriceCents;

  int get totalCents => quantity * unitPriceCents;

  Map<String, Object?> toMap({required int orderId, required int position}) => {
        'order_id': orderId,
        'position': position,
        'quantity': quantity,
        'code': code,
        'description': description,
        'unit_price_cents': unitPriceCents,
      };

  factory ServiceOrderItem.fromMap(Map<String, Object?> map) {
    return ServiceOrderItem(
      quantity: map['quantity'] as int,
      code: map['code'] as String,
      description: map['description'] as String,
      unitPriceCents: map['unit_price_cents'] as int,
    );
  }
}

int? _boolToDb(bool? value) => value == null ? null : (value ? 1 : 0);

bool? _boolFromDb(Object? value) => value == null ? null : value == 1;

/// Dates are stored as "yyyy-MM-dd" (no time, no timezone).
String? _dateToDb(DateTime? value) =>
    value?.toIso8601String().substring(0, 10);

DateTime? _dateFromDb(Object? value) =>
    value == null ? null : DateTime.parse(value as String);
