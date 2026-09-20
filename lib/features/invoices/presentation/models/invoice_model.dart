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
  });

  final String description;
  final double quantity;
  final double unitPrice;
  final double vatRate;
  final double discountPercent;

  double get subtotal => quantity * unitPrice;
  double get discountAmount => subtotal * (discountPercent / 100);
  double get afterDiscount => (subtotal - discountAmount).clamp(0, double.infinity);
  double get vatAmount => afterDiscount * (vatRate / 100);
  double get total => afterDiscount + vatAmount;
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
  });

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

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalDiscount => items.fold(0.0, (sum, item) => sum + item.discountAmount);
  double get totalVat => items.fold(0.0, (sum, item) => sum + item.vatAmount);
  double get grandTotal => items.fold(0.0, (sum, item) => sum + item.total);
}
