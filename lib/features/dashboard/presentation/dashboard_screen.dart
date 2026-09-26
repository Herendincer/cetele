import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_helper.dart';
import '../../cash_bank/presentation/create_transaction_screen.dart';
import '../../cash_bank/presentation/mock_cash_data.dart';
import '../../cash_bank/presentation/models/account_model.dart';
import '../../cash_bank/presentation/models/cash_transaction_model.dart';
import '../../invoices/presentation/create_invoice_screen.dart';
import '../../invoices/presentation/invoice_details_screen.dart';
import '../../invoices/presentation/models/invoice_type.dart';
import 'controllers/dashboard_controller.dart';
import 'dashboard_mock_data.dart';
import 'models/dashboard_metrics.dart';
import 'models/recent_activity_entry.dart';
import 'widgets/income_expense_chart.dart';
import 'widgets/kpi_card.dart';
import 'widgets/quick_action_bar.dart';
import 'widgets/recent_activity_tile.dart';

/// Paraşüt tarzı genel durum (ana) ekranı.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _openCreateSalesInvoice(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreateInvoiceScreen(initialType: InvoiceType.sales),
      ),
    );
    ref.read(dashboardControllerProvider.notifier).refresh();
  }

  Future<void> _openAddExpense(BuildContext context, WidgetRef ref) async {
    await _openCreateTransaction(context, ref, CashTransactionType.payment);
  }

  Future<void> _openQuickCollection(BuildContext context, WidgetRef ref) async {
    await _openCreateTransaction(context, ref, CashTransactionType.collection);
  }

  Future<void> _openCreateTransaction(
    BuildContext context,
    WidgetRef ref,
    CashTransactionType type,
  ) async {
    final CashTransactionModel? result = await Navigator.of(context).push<CashTransactionModel>(
      MaterialPageRoute(
        builder: (_) => CreateTransactionScreen(accounts: mockAccounts, initialType: type),
      ),
    );
    if (result == null) return;

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
    ref.read(dashboardControllerProvider.notifier).refresh();
  }

  void _openActivity(BuildContext context, RecentActivityEntry activity) {
    if (activity.kind == RecentActivityKind.invoice) {
      final invoice = activity.invoiceOrNull;
      if (invoice == null) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => InvoiceDetailsScreen(invoice: invoice)),
      );
      return;
    }

    final transaction = activity.transactionOrNull;
    if (transaction == null) return;
    _showTransactionDetails(context, transaction);
  }

  void _showTransactionDetails(BuildContext context, CashTransactionModel transaction) {
    final dateFormat = DateFormat('d MMM yyyy', 'tr_TR');
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(transaction.type.label, style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 12),
              _DetailRow(label: 'Cari', value: transaction.contactName),
              _DetailRow(label: 'Hesap', value: transaction.accountName),
              _DetailRow(
                label: 'Tutar',
                value: CurrencyHelper.formatFromKurus(
                  CurrencyHelper.liraToKurus(transaction.amount),
                ),
              ),
              _DetailRow(label: 'Tarih', value: dateFormat.format(transaction.date)),
              if (transaction.description.isNotEmpty)
                _DetailRow(label: 'Açıklama', value: transaction.description),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isWide = MediaQuery.sizeOf(context).width >= 900;
    final AsyncValue<DashboardMetrics> metricsAsync = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Genel Durum')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(dashboardControllerProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QuickActionBar(
                  onCreateSalesInvoice: () => _openCreateSalesInvoice(context, ref),
                  onAddExpense: () => _openAddExpense(context, ref),
                  onQuickCollection: () => _openQuickCollection(context, ref),
                ),
                const SizedBox(height: 20),
                metricsAsync.when(
                  data: (metrics) => _DashboardMetricsSection(metrics: metrics, isWide: isWide),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stackTrace) => _DashboardErrorCard(
                    message: '$error',
                    onRetry: () => ref.read(dashboardControllerProvider.notifier).refresh(),
                  ),
                ),
                const SizedBox(height: 24),
              Text(
                'Son Hareketler',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (final activity
                          in DashboardMockData.recentActivities) ...[
                        RecentActivityTile(
                          activity: activity,
                          onTap: () => _openActivity(context, activity),
                        ),
                        if (activity != DashboardMockData.recentActivities.last)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardMetricsSection extends StatelessWidget {
  const _DashboardMetricsSection({required this.metrics, required this.isWide});

  final DashboardMetrics metrics;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final double net = metrics.monthlyNet;
    final Color netColor = net >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isWide ? 1.4 : 1.15,
          children: [
            KpiCard(
              label: 'Nakit & Banka',
              amountInLira: metrics.cashAndBankBalance,
              icon: Icons.account_balance_wallet_outlined,
              accentColor: AppTheme.primaryColor,
            ),
            KpiCard(
              label: 'Tahsil Edilecekler',
              amountInLira: metrics.totalReceivables,
              icon: Icons.call_received_rounded,
              accentColor: AppTheme.incomeColor,
            ),
            KpiCard(
              label: 'Ödenecekler',
              amountInLira: metrics.totalPayables,
              icon: Icons.call_made_rounded,
              accentColor: AppTheme.expenseColor,
            ),
            KpiCard(
              label: 'Bu Ayki Net Durum',
              amountInLira: net,
              icon: net >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              accentColor: netColor,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Gelir / Gider Karşılaştırması', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    _LegendDot(color: AppTheme.incomeColor, label: 'Gelir'),
                    SizedBox(width: 16),
                    _LegendDot(color: AppTheme.expenseColor, label: 'Gider'),
                  ],
                ),
                const SizedBox(height: 12),
                IncomeExpenseChart(months: metrics.monthlySeries),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardErrorCard extends StatelessWidget {
  const _DashboardErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.error_outline_rounded, color: AppTheme.expenseColor),
                SizedBox(width: 8),
                Text('Veriler yüklenemedi'),
              ],
            ),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}