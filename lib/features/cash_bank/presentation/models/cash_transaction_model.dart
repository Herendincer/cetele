/// Para hareketi türü: müşteriden tahsilat veya tedarikçiye/masrafa ödeme.
enum CashTransactionType { collection, payment }

extension CashTransactionTypeLabel on CashTransactionType {
  String get label => switch (this) {
    CashTransactionType.collection => 'Tahsilat',
    CashTransactionType.payment => 'Ödeme',
  };
}

/// Kasa/banka hesabına bağlı bir para hareketi.
class CashTransactionModel {
  const CashTransactionModel({
    required this.id,
    required this.type,
    required this.contactName,
    required this.accountId,
    required this.accountName,
    required this.amount,
    required this.date,
    this.description = '',
    this.contactId,
    this.invoiceId,
    this.accountType = 'cash',
  });

  factory CashTransactionModel.fromJson(
    Map<String, dynamic> row,
  ) => CashTransactionModel(
    id: row['id'] as String,
    type: row['direction'] == 'in'
        ? CashTransactionType.collection
        : CashTransactionType.payment,
    contactId: row['contact_id'] as String?,
    invoiceId: row['invoice_id'] as String?,
    accountType: row['account_type'] as String,
    contactName:
        (row['contacts'] as Map?)?['name'] as String? ?? 'Cari belirtilmemiş',
    accountId: row['account_id'] as String? ?? '',
    accountName:
        (row['accounts'] as Map?)?['name'] as String? ?? 'Hesap belirtilmemiş',
    amount: (row['amount'] as num).toDouble(),
    date: DateTime.parse(row['transaction_date'] as String),
    description: row['description'] as String? ?? '',
  );

  final String? contactId;
  final String? invoiceId;
  final String accountType;
  final String id;
  final CashTransactionType type;
  final String contactName;
  final String accountId;
  final String accountName;
  final double amount;
  final DateTime date;
  final String description;
}
