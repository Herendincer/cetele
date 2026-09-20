import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Dashboard üstünde yer alan hızlı aksiyon butonları.
class QuickActionBar extends StatelessWidget {
  const QuickActionBar({
    super.key,
    required this.onCreateSalesInvoice,
    required this.onAddExpense,
    required this.onQuickCollection,
  });

  final VoidCallback onCreateSalesInvoice;
  final VoidCallback onAddExpense;
  final VoidCallback onQuickCollection;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _QuickActionButton(
            label: 'Satış Faturası Oluştur',
            icon: Icons.receipt_long_outlined,
            color: AppTheme.primaryColor,
            onTap: onCreateSalesInvoice,
          ),
          const SizedBox(width: 12),
          _QuickActionButton(
            label: 'Masraf/Gider Ekle',
            icon: Icons.remove_circle_outline,
            color: AppTheme.expenseColor,
            onTap: onAddExpense,
          ),
          const SizedBox(width: 12),
          _QuickActionButton(
            label: 'Hızlı Tahsilat Al',
            icon: Icons.add_card_outlined,
            color: AppTheme.incomeColor,
            onTap: onQuickCollection,
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
