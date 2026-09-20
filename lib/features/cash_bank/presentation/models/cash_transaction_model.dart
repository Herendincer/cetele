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
  });

  final String id;
  final CashTransactionType type;
  final String contactName;
  final String accountId;
  final String accountName;
  final double amount;
  final DateTime date;
  final String description;
}
