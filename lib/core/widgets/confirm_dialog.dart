import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Geri dönüşü olmayan (silme vb.) işlemler öncesi kullanıcıdan onay alan
/// standart uygulama diyaloğu.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = 'Vazgeç',
  String confirmLabel = 'Sil',
  bool isDestructive = true,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor:
                isDestructive ? AppTheme.expenseColor : AppTheme.primaryColor,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
