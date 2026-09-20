import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Başarılı/başarısız işlemler sonrası gösterilen standart bilgilendirme
/// çubukları.
class AppSnackBar {
  AppSnackBar._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, color: AppTheme.incomeColor, icon: Icons.check_circle_outline);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message: message, color: AppTheme.expenseColor, icon: Icons.error_outline);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color color,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
  }
}
