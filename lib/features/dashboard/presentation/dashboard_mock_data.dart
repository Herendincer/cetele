import '../../cash_bank/presentation/mock_cash_data.dart';
import '../../cash_bank/presentation/models/cash_transaction_model.dart';
import '../../invoices/presentation/mock_invoice_data.dart';
import '../../invoices/presentation/models/invoice_model.dart';
import '../../invoices/presentation/models/invoice_type.dart';
import 'models/monthly_financials.dart';
import 'models/recent_activity_entry.dart';

/// Dashboard ekranında kullanılan finansal özet verileri. Diğer
/// modüllerdeki (fatura, kasa/banka) mock verilerden anlık olarak
/// hesaplanır; Supabase entegrasyonu tamamlandığında bu hesaplamalar
/// gerçek sorgularla değiştirilecektir.
class DashboardMockData {
  DashboardMockData._();

  /// Kasa ve banka hesaplarının toplam bakiyesi.
  static double get cashAndBankTotal =>
      mockAccounts.fold(0.0, (sum, account) => sum + account.balance);

  /// Ödenmemiş/iptal olmayan satış faturalarının toplamı (tahsil edilecek).
  static double get receivablesTotal => mockInvoices
      .where(
        (invoice) =>
            invoice.type == InvoiceType.sales &&
            invoice.status != InvoiceStatus.paid &&
            invoice.status != InvoiceStatus.cancelled,
      )
      .fold(0.0, (sum, invoice) => sum + invoice.grandTotal);

  /// Ödenmemiş/iptal olmayan alış faturalarının toplamı (ödenecek).
  static double get payablesTotal => mockInvoices
      .where(
        (invoice) =>
            invoice.type == InvoiceType.purchase &&
            invoice.status != InvoiceStatus.paid &&
            invoice.status != InvoiceStatus.cancelled,
      )
      .fold(0.0, (sum, invoice) => sum + invoice.grandTotal);

  /// Bu ay içindeki tahsilat toplamı.
  static double get monthlyIncome => mockCashTransactions
      .where((t) => t.type == CashTransactionType.collection && _isCurrentMonth(t.date))
      .fold(0.0, (sum, t) => sum + t.amount);

  /// Bu ay içindeki ödeme toplamı.
  static double get monthlyExpense => mockCashTransactions
      .where((t) => t.type == CashTransactionType.payment && _isCurrentMonth(t.date))
      .fold(0.0, (sum, t) => sum + t.amount);

  static double get monthlyNet => monthlyIncome - monthlyExpense;

  static bool _isCurrentMonth(DateTime date) {
    final DateTime now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// En güncel 5 fatura/kasa hareketini tek bir akış olarak döndürür.
  static List<RecentActivityEntry> get recentActivities {
    final List<RecentActivityEntry> entries = [
      for (final invoice in mockInvoices) RecentActivityEntry.invoice(invoice),
      for (final transaction in mockCashTransactions) RecentActivityEntry.transaction(transaction),
    ];
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries.take(5).toList();
  }

  /// Grafik için son 6 aylık örnek gelir/gider serisi (demo amaçlı).
  static const List<MonthlyFinancials> monthlySeries = [
    MonthlyFinancials(monthLabel: 'Nis', income: 68000, expense: 41000),
    MonthlyFinancials(monthLabel: 'May', income: 75500, expense: 38500),
    MonthlyFinancials(monthLabel: 'Haz', income: 82000, expense: 47000),
    MonthlyFinancials(monthLabel: 'Tem', income: 71000, expense: 52500),
    MonthlyFinancials(monthLabel: 'Ağu', income: 89000, expense: 44000),
    MonthlyFinancials(monthLabel: 'Eyl', income: 98750, expense: 41200),
  ];
}
