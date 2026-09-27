import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/services/subscription_service.dart';
import '../models/invoice_type.dart';
import 'invoice_usage_provider.dart';

class SalesInvoiceLimitReached implements Exception {
  const SalesInvoiceLimitReached();

  @override
  String toString() => 'Bu ay ücretsiz fatura hakkınız doldu';
}

class InvoiceCreationPolicy {
  InvoiceCreationPolicy(this.ref);
  final Ref ref;

  Future<void> ensureAllowed(InvoiceType type) async {
    if (type == InvoiceType.purchase) return;
    final userId = await requireSession(ref);
    final status = await ref.read(subscriptionStatusProvider.future);
    if (!ref.mounted) {
      throw StateError('Oturum değişti. Lütfen tekrar deneyin.');
    }
    if (status == SubscriptionStatus.pro) return;
    // Önbelleğe güvenme: diğer cihazdaki kayıtlar ve ay değişimi de hesaba katılır.
    final count = await ref.refresh(monthlySalesInvoiceCountProvider.future);
    if (!ref.mounted || ref.read(sessionUserIdProvider).value != userId) {
      throw StateError('Oturum değişti. Lütfen tekrar deneyin.');
    }
    if (count >= AppConstants.freeMonthlySalesInvoiceLimit) {
      throw const SalesInvoiceLimitReached();
    }
  }
}

final invoiceCreationPolicyProvider = Provider<InvoiceCreationPolicy>(
  (ref) => InvoiceCreationPolicy(ref),
);
