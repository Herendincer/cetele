import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';

/// Ara toplam, iskonto, KDV ve genel toplamı gösteren finansal özet kartı.
/// Fatura oluşturma ve fatura detay ekranlarında ortak kullanılır.
class InvoiceSummaryCard extends StatelessWidget {
  const InvoiceSummaryCard({
    super.key,
    required this.subtotal,
    required this.totalDiscount,
    required this.totalVat,
    required this.grandTotal,
  });

  final double subtotal;
  final double totalDiscount;
  final double totalVat;
  final double grandTotal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finansal Özet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Ara Toplam', amount: subtotal),
            _SummaryRow(
              label: 'Toplam İskonto',
              amount: -totalDiscount,
              color: AppTheme.expenseColor,
            ),
            _SummaryRow(label: 'KDV Toplamı', amount: totalVat),
            const Divider(height: 20),
            _SummaryRow(
              label: 'Genel Toplam',
              amount: grandTotal,
              isEmphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.amount,
    this.color,
    this.isEmphasized = false,
  });

  final String label;
  final double amount;
  final Color? color;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    final int kurus = CurrencyHelper.liraToKurus(amount);
    final String sign = amount < 0 ? '-' : '';
    final String formatted = CurrencyHelper.formatFromKurus(kurus.abs());

    final TextStyle style = TextStyle(
      fontSize: isEmphasized ? 18 : 14,
      fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w500,
      color:
          color ??
          (isEmphasized
              ? AppTheme.textPrimaryColor
              : AppTheme.textSecondaryColor),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: style,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text('$sign$formatted', style: style),
            ),
          ),
        ],
      ),
    );
  }
}
