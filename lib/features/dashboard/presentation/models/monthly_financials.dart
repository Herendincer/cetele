/// Aylık gelir/gider grafiğinde kullanılan tek bir ayın özeti.
class MonthlyFinancials {
  const MonthlyFinancials({
    required this.monthLabel,
    required this.income,
    required this.expense,
  });

  final String monthLabel;
  final double income;
  final double expense;
}
