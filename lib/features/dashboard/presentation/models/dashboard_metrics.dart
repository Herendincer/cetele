import 'monthly_financials.dart';

/// Dashboard'da gösterilen, Supabase'den hesaplanan finansal özet verileri.
class DashboardMetrics {
  const DashboardMetrics({
    required this.totalReceivables,
    required this.totalPayables,
    required this.cashAndBankBalance,
    required this.monthlySeries,
  });

  /// Carilerden tahsil edilecek toplam alacak (pozitif cari bakiyeler).
  final double totalReceivables;

  /// Carilere ödenecek toplam borç (negatif cari bakiyelerin mutlağı).
  final double totalPayables;

  /// Tüm kasa/banka hareketlerinden hesaplanan net bakiye.
  final double cashAndBankBalance;

  /// Son 6 aya ait gelir/gider serisi (grafik için).
  final List<MonthlyFinancials> monthlySeries;

  double get monthlyNet {
    if (monthlySeries.isEmpty) return 0;
    final current = monthlySeries.last;
    return current.income - current.expense;
  }
}
