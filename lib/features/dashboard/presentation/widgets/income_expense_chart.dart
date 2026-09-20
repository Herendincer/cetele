import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../models/monthly_financials.dart';

/// Aylık gelir/gider karşılaştırma çubuk grafiği.
class IncomeExpenseChart extends StatelessWidget {
  const IncomeExpenseChart({super.key, required this.months});

  final List<MonthlyFinancials> months;

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Grafik için yeterli veri yok')),
      );
    }

    final double maxValue = months
        .expand((m) => [m.income, m.expense])
        .fold(0.0, (max, value) => value > max ? value : max);
    final double maxY = maxValue <= 0 ? 100 : maxValue * 1.2;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final int index = value.toInt();
                  if (index < 0 || index >= months.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      months[index].monthLabel,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < months.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: months[i].income,
                    color: AppTheme.incomeColor,
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: months[i].expense,
                    color: AppTheme.expenseColor,
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
