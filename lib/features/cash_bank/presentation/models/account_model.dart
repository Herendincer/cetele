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
  });

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
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
    );
  }
}
