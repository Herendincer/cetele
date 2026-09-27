import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/data_providers.dart';
import '../../data/invoices_repository.dart';

/// Veri değişiminde ve oturum değişiminde yeni sunucu sayımını getirir.
final monthlySalesInvoiceCountProvider = FutureProvider<int>((ref) async {
  ref.watch(dataRevisionProvider);
  final repository = ref.watch(invoicesRepositoryProvider);
  final userId = await ref.watch(sessionUserIdProvider.future);
  if (userId == null) return 0;
  return repository.countMonthlySalesInvoices();
}, retry: manualDataRetry);
