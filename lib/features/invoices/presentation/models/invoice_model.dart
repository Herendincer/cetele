import 'invoice_type.dart';

/// Fatura durumu.
enum InvoiceStatus { draft, approved, paid, cancelled }

extension InvoiceStatusLabel on InvoiceStatus {
  String get label => switch (this) {
    InvoiceStatus.draft => 'Taslak',
    InvoiceStatus.approved => 'Onaylandı',
    InvoiceStatus.paid => 'Ödendi',
    InvoiceStatus.cancelled => 'İptal',
  };
}

/// Bir faturanın kalıcı (kaydedilmiş) tek bir satırı.
class InvoiceItemModel {
  const InvoiceItemModel({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.vatRate = 20,
    this.discountPercent = 0,
    this.storedTotal,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> row) =>
      InvoiceItemModel(
        description: row['description'] as String,
        quantity: (row['quantity'] as num).toDouble(),
        unitPrice: (row['unit_price'] as num).toDouble(),
        vatRate: (row['vat_rate'] as num).toDouble(),
        discountPercent: (row['discount_percent'] as num?)?.toDouble() ?? 0,
        storedTotal: (row['line_total'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'description': description,
    'quantity': quantity,
    'unit_price': unitPrice,
    'vat_rate': vatRate,
    'discount_percent': discountPercent,
  };

  final double? storedTotal;
  final String description;
  final double quantity;
  final double unitPrice;
  final double vatRate;
  final double discountPercent;

  double get subtotal => quantity * unitPrice;
  double get discountAmount => subtotal * (discountPercent / 100);
  double get afterDiscount =>
      (subtotal - discountAmount).clamp(0, double.infinity);
  double get vatAmount => afterDiscount * (vatRate / 100);
  double get total =>
      storedTotal ??
      double.parse((afterDiscount + vatAmount).toStringAsFixed(2));
}

/// Kaydedilmiş satış/alış faturası.
class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.number,
    required this.type,
    required this.contactName,
    required this.issueDate,
    this.status = InvoiceStatus.draft,
    this.dueDate,
    this.contactTaxNumber = '',
    this.contactAddress = '',
    this.contactPhone = '',
    this.items = const [],
    this.notes = '',
    this.contactId,
    this.storedSubtotal,
    this.storedVat,
    this.storedGrandTotal,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> row) {
    final contact = row['contacts'] as Map?;
    return InvoiceModel(
      id: row['id'] as String,
      number: row['invoice_number'] as String,
      type: InvoiceType.values.byName(row['type'] as String),
      status: InvoiceStatus.values.byName(row['status'] as String),
      contactId: row['contact_id'] as String?,
      contactName: contact?['name'] as String? ?? 'Cari belirtilmemiş',
      contactTaxNumber: contact?['tax_number'] as String? ?? '',
      contactAddress: contact?['address'] as String? ?? '',
      contactPhone: contact?['phone'] as String? ?? '',
      issueDate: DateTime.parse(row['issue_date'] as String),
      dueDate: row['due_date'] == null
          ? null
          : DateTime.parse(row['due_date'] as String),
      items: (row['invoice_items'] as List)
          .map(
            (item) => InvoiceItemModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      notes: row['notes'] as String? ?? '',
      storedSubtotal: (row['subtotal'] as num).toDouble(),
      storedVat: (row['vat_amount'] as num).toDouble(),
      storedGrandTotal: (row['total_amount'] as num).toDouble(),
    );
  }

  final String? contactId;
  final double? storedSubtotal;
  final double? storedVat;
  final double? storedGrandTotal;
  final String id;
  final String number;
  final InvoiceType type;
  final String contactName;
  final DateTime issueDate;
  final InvoiceStatus status;
  final DateTime? dueDate;
  final String contactTaxNumber;
  final String contactAddress;
  final String contactPhone;
  final List<InvoiceItemModel> items;
  final String notes;

  double get subtotal =>
      storedSubtotal ?? items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalDiscount =>
      items.fold(0.0, (sum, item) => sum + item.discountAmount);
  double get totalVat =>
      storedVat ?? items.fold(0.0, (sum, item) => sum + item.vatAmount);
  double get grandTotal =>
      storedGrandTotal ?? items.fold(0.0, (sum, item) => sum + item.total);
}
