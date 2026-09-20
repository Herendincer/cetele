import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';
import '../models/recent_activity_entry.dart';

/// Son fatura ve kasa hareketlerini listeleyen satır.
class RecentActivityTile extends StatelessWidget {
  const RecentActivityTile({super.key, required this.activity, this.onTap});

  final RecentActivityEntry activity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color =
        activity.isIncome ? AppTheme.incomeColor : AppTheme.expenseColor;
    final int kurus = CurrencyHelper.liraToKurus(activity.amount);
    final String sign = activity.isIncome ? '+' : '-';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          activity.isIncome
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        activity.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${activity.subtitle} · ${DateFormat('d MMM', 'tr_TR').format(activity.date)}',
      ),
      trailing: Text(
        '$sign${CurrencyHelper.formatFromKurus(kurus)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
