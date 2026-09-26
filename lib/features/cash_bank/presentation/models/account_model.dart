/// Kasa (nakit) veya banka hesabı türü.
enum AccountType { cash, bank }

extension AccountTypeLabel on AccountType {
  String get label => switch (this) {
    AccountType.cash => 'Nakit Kasa',
    AccountType.bank => 'Banka Hesabı',
  };
}

/// Kasa/banka hesabı verisi.
class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.lastTransactionDate,
    this.openingBalance = 0,
  });

  factory AccountModel.fromJson(Map<String, dynamic> row) {
    final opening = (row['opening_balance'] as num).toDouble() / 100;
    return AccountModel(
      id: row['id'] as String,
      name: row['name'] as String,
      type: AccountType.values.byName(row['type'] as String),
      balance: opening,
      openingBalance: opening,
      lastTransactionDate: DateTime.parse(row['created_at'] as String),
    );
  }

  final double openingBalance;
  final String id;
  final String name;
  final AccountType type;
  final double balance;
  final DateTime lastTransactionDate;

  AccountModel copyWith({double? balance, DateTime? lastTransactionDate}) {
    return AccountModel(
      id: id,
      name: name,
      type: type,
      balance: balance ?? this.balance,
      openingBalance: openingBalance,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
    );
  }
}
