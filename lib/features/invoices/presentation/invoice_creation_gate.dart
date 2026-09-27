import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_snackbar.dart';
import '../../subscription/presentation/paywall_screen.dart';
import 'controllers/invoice_creation_policy.dart';
import 'models/invoice_type.dart';

Future<void> showInvoiceLimitPaywall(BuildContext context) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PaywallScreen(limitReached: true),
      ),
    );

/// Tüm oluşturma girişleri aynı sunucu sayımını ve Türkçe hata akışını kullanır.
Future<bool> checkInvoiceCreationAllowed(
  BuildContext context,
  WidgetRef ref,
  InvoiceType type,
) async {
  try {
    await ref.read(invoiceCreationPolicyProvider).ensureAllowed(type);
    return context.mounted;
  } on SalesInvoiceLimitReached {
    if (context.mounted) await showInvoiceLimitPaywall(context);
    return false;
  } catch (_) {
    if (context.mounted) {
      AppSnackBar.showError(
        context,
        'Fatura hakkınız kontrol edilemedi. Lütfen tekrar deneyin.',
      );
    }
    return false;
  }
}
