import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_helper.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import 'create_account_screen.dart';
import 'create_transaction_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_content.dart';
import '../data/transactions_repository.dart';
import 'controllers/cash_bank_controller.dart';
import 'models/account_model.dart';
import 'models/cash_transaction_model.dart';

/// Kasa ve banka hesaplarının bakiyelerini ve para hareketlerini gösteren
/// ekran.
class CashBankScreen extends ConsumerStatefulWidget {
  const CashBankScreen({super.key});

  @override
  ConsumerState<CashBankScreen> createState() => _CashBankScreenState();
}

class _CashBankScreenState extends ConsumerState<CashBankScreen> {
  Future<void> _openCreateTransaction(CashTransactionType type) async {
    await Navigator.of(context).push<CashTransactionModel>(
      MaterialPageRoute(
        builder: (_) => CreateTransactionScreen(initialType: type),
      ),
    );
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

    await Navigator.of(context).push<AccountModel>(
      MaterialPageRoute(
        builder: (_) => CreateAccountScreen(initialType: chosenType),
      ),
    );
  }

  Future<void> _deleteAccount(AccountModel account) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Hesabı Sil',
      message: 'Bu hesabı silmek istediğinize emin misiniz? Hesaba bağlı hareketler etkilenebilir.',
      confirmLabel: 'Sil',
    );
    if (!confirmed || !mounted) return;
    final ok = await ref
        .read(cashBankControllerProvider.notifier)
        .deleteAccount(account.id);
    if (!mounted) return;
    if (ok) {
      AppSnackBar.showSuccess(context, 'Hesap silindi');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Hesap silinemedi. Bağlı hareketleri olan hesaplar silinemez.',
          ),
          action: SnackBarAction(
            label: 'Tekrar dene',
            onPressed: () => _deleteAccount(account),
          ),
        ),
      );
    }
  }

  Future<void> _deleteTransaction(CashTransactionModel transaction) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Hareketi Sil',
      message: 'Bu para hareketini silmek istediğinize emin misiniz? Bakiye yeniden hesaplanacaktır.',
      confirmLabel: 'Sil',
    );
    if (!confirmed || !mounted) return;

    final ok = await ref
        .read(cashBankControllerProvider.notifier)
        .deleteTransaction(transaction.id);
    if (!mounted) return;
    if (ok) {
      AppSnackBar.showSuccess(context, 'Hareket silindi, bakiye güncellendi');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hareket silinemedi'),
          action: SnackBarAction(
            label: 'Tekrar dene',
            onPressed: () => _deleteTransaction(transaction),
          ),
        ),
      );
    }
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
      body: AsyncContent<List<AccountModel>>(
        value: ref.watch(accountsProvider),
        onRetry: () {
          ref.invalidate(transactionsProvider);
          ref.invalidate(accountsProvider);
        },
        data: (accounts) => AsyncContent<List<CashTransactionModel>>(
          value: ref.watch(transactionsProvider),
          onRetry: () => ref.invalidate(transactionsProvider),
          data: (transactions) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: AppTheme.primaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Toplam Nakit & Banka Varlığı',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyHelper.formatFromKurus(
                          CurrencyHelper.liraToKurus(
                            accounts.fold<double>(
                                  0,
                                  (sum, a) => sum + a.balance,
                                ) +
                                transactions
                                    .where((t) => t.accountId.isEmpty)
                                    .fold<double>(
                                      0,
                                      (sum, t) =>
                                          sum +
                                          (t.type ==
                                                  CashTransactionType.collection
                                              ? t.amount
                                              : -t.amount),
                                    ),
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
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
                      onPressed: () => _openCreateTransaction(
                        CashTransactionType.collection,
                      ),
                      icon: const Icon(
                        Icons.call_received_rounded,
                        color: AppTheme.incomeColor,
                      ),
                      label: const Text('Tahsilat Al'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openCreateTransaction(CashTransactionType.payment),
                      icon: const Icon(
                        Icons.call_made_rounded,
                        color: AppTheme.expenseColor,
                      ),
                      label: const Text('Ödeme Yap'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Hesaplar', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (accounts.isEmpty) const Text('Henüz kasa/banka hesabı yok'),
              for (final account in accounts) ...[
                Card(
                  child: ListTile(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CreateAccountScreen(existingAccount: account),
                      ),
                    ),
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
                    title: Text(
                      account.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Son işlem: ${dateFormat.format(account.lastTransactionDate)}',
                    ),
                    trailing: SizedBox(
                      width: 145,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Text(
                              CurrencyHelper.formatFromKurus(
                                CurrencyHelper.liraToKurus(account.balance),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
              Text(
                'Son Hareketler',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('Henüz para hareketi yok')),
                )
              else
                for (final transaction in transactions) ...[
                  Card(
                    child: ListTile(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CreateTransactionScreen(
                            existingTransaction: transaction,
                          ),
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            (transaction.type == CashTransactionType.collection
                                    ? AppTheme.incomeColor
                                    : AppTheme.expenseColor)
                                .withValues(alpha: 0.12),
                        foregroundColor:
                            transaction.type == CashTransactionType.collection
                            ? AppTheme.incomeColor
                            : AppTheme.expenseColor,
                        child: Icon(
                          transaction.type == CashTransactionType.collection
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                        ),
                      ),
                      title: Text(
                        transaction.contactName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${transaction.accountName} · ${dateFormat.format(transaction.date)}'
                        '${transaction.description.isEmpty ? '' : ' · ${transaction.description}'}',
                      ),
                      trailing: SizedBox(
                        width: 145,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Text(
                                '${transaction.type == CashTransactionType.collection ? '+' : '-'}'
                                '${CurrencyHelper.formatFromKurus(CurrencyHelper.liraToKurus(transaction.amount))}',
                                style: TextStyle(
                                  color:
                                      transaction.type ==
                                          CashTransactionType.collection
                                      ? AppTheme.incomeColor
                                      : AppTheme.expenseColor,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
