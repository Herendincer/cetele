import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';

/// Dashboard'da gösterilen finansal özet (KPI) kartı.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.amountInLira,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final double amountInLira;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final int kurus = CurrencyHelper.liraToKurus(amountInLira);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyHelper.formatFromKurus(kurus),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimaryColor,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
