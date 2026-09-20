import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_helper.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import 'create_account_screen.dart';
import 'create_transaction_screen.dart';
import 'mock_cash_data.dart';
import 'models/account_model.dart';
import 'models/cash_transaction_model.dart';

/// Kasa ve banka hesaplarının bakiyelerini ve para hareketlerini gösteren
/// ekran.
class CashBankScreen extends StatefulWidget {
  const CashBankScreen({super.key});

  @override
  State<CashBankScreen> createState() => _CashBankScreenState();
}

class _CashBankScreenState extends State<CashBankScreen> {
  double get _totalBalance =>
      mockAccounts.fold(0.0, (sum, account) => sum + account.balance);

  List<CashTransactionModel> get _sortedTransactions {
    final list = List<CashTransactionModel>.from(mockCashTransactions);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> _openCreateTransaction(CashTransactionType type) async {
    final CashTransactionModel? result = await Navigator.of(context).push<CashTransactionModel>(
      MaterialPageRoute(
        builder: (_) => CreateTransactionScreen(accounts: mockAccounts, initialType: type),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      final int accountIndex = mockAccounts.indexWhere((a) => a.id == result.accountId);
      if (accountIndex != -1) {
        final AccountModel account = mockAccounts[accountIndex];
        final double delta = result.type == CashTransactionType.collection
            ? result.amount
            : -result.amount;
        mockAccounts[accountIndex] = account.copyWith(
          balance: account.balance + delta,
          lastTransactionDate: result.date,
        );
      }
      mockCashTransactions.add(result);
    });
  }

  Future<void> _openCreateAccount() async {
    final AccountType? chosenType = await showModalBottomSheet<AccountType>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.savings_outlined),
              title: const Text('Nakit Kasa'),
              onTap: () => Navigator.of(sheetContext).pop(AccountType.cash),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: const Text('Banka Hesabı'),
              onTap: () => Navigator.of(sheetContext).pop(AccountType.bank),
            ),
          ],
        ),
      ),
    );
    if (chosenType == null || !mounted) return;

    final AccountModel? created = await Navigator.of(context).push<AccountModel>(
      MaterialPageRoute(builder: (_) => CreateAccountScreen(initialType: chosenType)),
    );
    if (created == null) return;
    setState(() => mockAccounts.add(created));
  }

  Future<void> _deleteAccount(AccountModel account) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Hesabı Sil',
      message:
          'Bu hesabı silmek istediğinize emin misiniz? Hesaba bağlı hareketler etkilenebilir.',
      confirmLabel: 'Sil',
    );
    if (!confirmed || !mounted) return;
    setState(() {
      mockAccounts.removeWhere((a) => a.id == account.id);
      mockCashTransactions.removeWhere((t) => t.accountId == account.id);
    });
    if (mounted) AppSnackBar.showSuccess(context, 'Hesap silindi');
  }

  Future<void> _deleteTransaction(CashTransactionModel transaction) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Hareketi Sil',
      message: 'Bu para hareketini silmek istediğinize emin misiniz? Bakiye yeniden hesaplanacaktır.',
      confirmLabel: 'Sil',
    );
    if (!confirmed || !mounted) return;

    setState(() {
      final int accountIndex = mockAccounts.indexWhere((a) => a.id == transaction.accountId);
      if (accountIndex != -1) {
        final AccountModel account = mockAccounts[accountIndex];
        final double delta = transaction.type == CashTransactionType.collection
            ? -transaction.amount
            : transaction.amount;
        mockAccounts[accountIndex] = account.copyWith(balance: account.balance + delta);
      }
      mockCashTransactions.removeWhere((t) => t.id == transaction.id);
    });
    if (mounted) AppSnackBar.showSuccess(context, 'Hareket silindi, bakiye güncellendi');
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy', 'tr_TR');

    return Scaffold(
      appBar: AppBar(title: const Text('Kasa & Banka')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateAccount,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Hesap Ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppTheme.primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Toplam Nakit & Banka Varlığı', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyHelper.formatFromKurus(CurrencyHelper.liraToKurus(_totalBalance)),
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openCreateTransaction(CashTransactionType.collection),
                  icon: const Icon(Icons.call_received_rounded, color: AppTheme.incomeColor),
                  label: const Text('Tahsilat Al'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openCreateTransaction(CashTransactionType.payment),
                  icon: const Icon(Icons.call_made_rounded, color: AppTheme.expenseColor),
                  label: const Text('Ödeme Yap'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Hesaplar', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final account in mockAccounts) ...[
            Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    account.type == AccountType.cash
                        ? Icons.savings_outlined
                        : Icons.account_balance_outlined,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                title: Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Son işlem: ${dateFormat.format(account.lastTransactionDate)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CurrencyHelper.formatFromKurus(CurrencyHelper.liraToKurus(account.balance)),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      tooltip: 'Hesabı sil',
                      icon: const Icon(Icons.delete_outline),
                      color: AppTheme.expenseColor,
                      onPressed: () => _deleteAccount(account),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          Text('Son Hareketler', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_sortedTransactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Henüz para hareketi yok')),
            )
          else
            for (final transaction in _sortedTransactions) ...[
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (transaction.type == CashTransactionType.collection
                            ? AppTheme.incomeColor
                            : AppTheme.expenseColor)
                        .withValues(alpha: 0.12),
                    foregroundColor: transaction.type == CashTransactionType.collection
                        ? AppTheme.incomeColor
                        : AppTheme.expenseColor,
                    child: Icon(
                      transaction.type == CashTransactionType.collection
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                    ),
                  ),
                  title: Text(transaction.contactName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${transaction.accountName} · ${dateFormat.format(transaction.date)}'
                    '${transaction.description.isEmpty ? '' : ' · ${transaction.description}'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${transaction.type == CashTransactionType.collection ? '+' : '-'}'
                        '${CurrencyHelper.formatFromKurus(CurrencyHelper.liraToKurus(transaction.amount))}',
                        style: TextStyle(
                          color: transaction.type == CashTransactionType.collection
                              ? AppTheme.incomeColor
                              : AppTheme.expenseColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Hareketi sil',
                        icon: const Icon(Icons.delete_outline),
                        color: AppTheme.expenseColor,
                        onPressed: () => _deleteTransaction(transaction),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

