import 'models/account_model.dart';
import 'models/cash_transaction_model.dart';

/// Demo amaçlı kasa/banka hesapları ve para hareketleri (Supabase
/// entegrasyonu tamamlanana kadar). Kasa & Banka ekranı ve dashboard bu
/// veriyi paylaşır.
final List<AccountModel> mockAccounts = [
  AccountModel(
    id: 'a1',
    name: 'Merkez Kasa',
    type: AccountType.cash,
    balance: 14250.75,
    lastTransactionDate: DateTime(2026, 9, 16),
  ),
  AccountModel(
    id: 'a2',
    name: 'Garanti BBVA - Vadesiz',
    type: AccountType.bank,
    balance: 132400.00,
    lastTransactionDate: DateTime(2026, 9, 17),
  ),
  AccountModel(
    id: 'a3',
    name: 'İş Bankası - Vadesiz',
    type: AccountType.bank,
    balance: 37600.00,
    lastTransactionDate: DateTime(2026, 9, 15),
  ),
];

final List<CashTransactionModel> mockCashTransactions = [
  CashTransactionModel(
    id: 't1',
    type: CashTransactionType.collection,
    contactName: 'Aslan Tekstil Ltd. Şti.',
    accountId: 'a2',
    accountName: 'Garanti BBVA - Vadesiz',
    amount: 18500,
    date: DateTime(2026, 9, 17),
    description: 'Fatura tahsilatı',
  ),
  CashTransactionModel(
    id: 't2',
    type: CashTransactionType.collection,
    contactName: 'Yıldız Elektronik',
    accountId: 'a3',
    accountName: 'İş Bankası - Vadesiz',
    amount: 7250,
    date: DateTime(2026, 9, 15),
    description: 'Hızlı tahsilat',
  ),
  CashTransactionModel(
    id: 't3',
    type: CashTransactionType.payment,
    contactName: 'Deniz Lojistik A.Ş.',
    accountId: 'a2',
    accountName: 'Garanti BBVA - Vadesiz',
    amount: 9840,
    date: DateTime(2026, 9, 13),
    description: 'Alış faturası ödemesi',
  ),
  CashTransactionModel(
    id: 't4',
    type: CashTransactionType.payment,
    contactName: 'Ofis Kirası',
    accountId: 'a1',
    accountName: 'Merkez Kasa',
    amount: 640.50,
    date: DateTime(2026, 9, 14),
    description: 'Kırtasiye masrafı',
  ),
];
