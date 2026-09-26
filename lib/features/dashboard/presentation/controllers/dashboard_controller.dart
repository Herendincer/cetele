import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/data_providers.dart';
import '../../../contacts/presentation/controllers/contacts_controller.dart';
import '../../../contacts/presentation/models/contact_model.dart';
import '../../../cash_bank/data/transactions_repository.dart';
import '../../../cash_bank/presentation/controllers/cash_bank_controller.dart';
import '../../../cash_bank/presentation/models/account_model.dart';
import '../../../cash_bank/presentation/models/cash_transaction_model.dart';
import '../../../invoices/presentation/controllers/invoices_controller.dart';
import '../../../invoices/presentation/models/invoice_model.dart';
import '../models/dashboard_metrics.dart';
import '../models/monthly_financials.dart';
import '../models/recent_activity_entry.dart';

/// Ortak veri provider'ları oturum değişiminde ve her yazma sonrasında yenilenir.
class DashboardController extends AsyncNotifier<DashboardMetrics> {
  @override
  Future<DashboardMetrics> build() async {
    final values = await Future.wait<Object>([
      ref.watch(contactsProvider.future),
      ref.watch(accountsProvider.future),
      ref.watch(transactionsProvider.future),
    ]);
    final contacts = values[0] as List<ContactModel>;
    final accounts = values[1] as List<AccountModel>;
    final transactions = values[2] as List<CashTransactionModel>;
    double receivables = 0;
    double payables = 0;
    for (final contact in contacts) {
      if (contact.balance > 0) {
        receivables += contact.balance;
      } else {
        payables -= contact.balance;
      }
    }
    // Hesaba henüz bağlanmamış eski hareketler de toplam varlığa dahildir.
    double cashAndBankBalance = accounts.fold(
      0,
      (sum, account) => sum + account.openingBalance,
    );
    for (final transaction in transactions) {
      cashAndBankBalance += transaction.type == CashTransactionType.collection
          ? transaction.amount
          : -transaction.amount;
    }
    return DashboardMetrics(
      totalReceivables: receivables,
      totalPayables: payables,
      cashAndBankBalance: cashAndBankBalance,
      monthlySeries: _buildMonthlySeries([
        for (final transaction in transactions)
          {
            'amount': transaction.amount,
            'direction': transaction.type == CashTransactionType.collection
                ? 'in'
                : 'out',
            'transaction_date': transaction.date.toIso8601String(),
          },
      ]),
    );
  }

  Future<void> refresh() async {
    ref.read(dataRevisionProvider.notifier).refresh();
    try {
      await future;
    } catch (_) {
      // Hata AsyncValue üzerinden ekrandaki tekrar deneme alanında gösterilir.
    }
  }

  List<MonthlyFinancials> _buildMonthlySeries(List transactionRows) {
    final DateTime now = DateTime.now();
    final List<DateTime> months = [
      for (int i = 5; i >= 0; i--) DateTime(now.year, now.month - i, 1),
    ];
    final Map<String, double> incomeByMonth = {
      for (final m in months) _monthKey(m): 0,
    };
    final Map<String, double> expenseByMonth = {
      for (final m in months) _monthKey(m): 0,
    };
    for (final row in transactionRows) {
      final map = row as Map;
      final date = DateTime.parse(map['transaction_date'] as String);
      final key = _monthKey(DateTime(date.year, date.month));
      if (!incomeByMonth.containsKey(key)) continue;
      final amount = (map['amount'] as num?)?.toDouble() ?? 0;
      if (map['direction'] == 'in') {
        incomeByMonth[key] = incomeByMonth[key]! + amount;
      } else {
        expenseByMonth[key] = expenseByMonth[key]! + amount;
      }
    }
    final DateFormat labelFormat = DateFormat('MMM', 'tr_TR');
    return [
      for (final month in months)
        MonthlyFinancials(
          monthLabel: labelFormat.format(month),
          income: incomeByMonth[_monthKey(month)]!,
          expense: expenseByMonth[_monthKey(month)]!,
        ),
    ];
  }

  String _monthKey(DateTime month) => '${month.year}-${month.month}';
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardMetrics>(
      DashboardController.new,
    );

class RecentActivities extends AsyncNotifier<List<RecentActivityEntry>> {
  @override
  Future<List<RecentActivityEntry>> build() async {
    final values = await Future.wait<Object>([
      ref.watch(invoicesProvider.future),
      ref.watch(transactionsProvider.future),
    ]);
    final entries = [
      for (final invoice in values[0] as List<InvoiceModel>)
        RecentActivityEntry.invoice(invoice),
      for (final transaction in values[1] as List<CashTransactionModel>)
        RecentActivityEntry.transaction(transaction),
    ];
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries.take(5).toList();
  }
}

final recentActivitiesProvider =
    AsyncNotifierProvider<RecentActivities, List<RecentActivityEntry>>(
      RecentActivities.new,
    );
