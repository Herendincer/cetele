import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/data_providers.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../data/invoices_repository.dart';
import '../models/invoice_model.dart';

class InvoicesData extends AsyncNotifier<List<InvoiceModel>> {
  @override
  Future<List<InvoiceModel>> build() async {
    ref.watch(dataRevisionProvider);
    final repository = ref.watch(invoicesRepositoryProvider);
    final id = await ref.watch(sessionUserIdProvider.future);
    if (id == null) throw StateError('Kullanıcı oturumu bulunamadı');
    return repository.fetch(id);
  }
}

final invoicesProvider =
    AsyncNotifierProvider<InvoicesData, List<InvoiceModel>>(InvoicesData.new);

final invoiceProvider = Provider.family<AsyncValue<InvoiceModel?>, String>((
  ref,
  id,
) {
  return ref.watch(invoicesProvider).whenData((invoices) {
    for (final invoice in invoices) {
      if (invoice.id == id) return invoice;
    }
    return null;
  });
});

class InvoicesController extends AsyncNotifier<void> {
  @override
  void build() {
    ref.watch(sessionUserIdProvider);
  }

  Future<bool> create(InvoiceModel invoice) =>
      _run((id) => ref.read(invoicesRepositoryProvider).create(id, invoice));
  Future<bool> updateStatus(String invoiceId, InvoiceStatus status) => _run(
    (id) => ref
        .read(invoicesRepositoryProvider)
        .updateStatus(id, invoiceId, status),
  );
  Future<bool> delete(String invoiceId) =>
      _run((id) => ref.read(invoicesRepositoryProvider).delete(id, invoiceId));

  Future<bool> _run(Future<void> Function(String) action) async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () async => action(await requireSession(ref)),
    );
    if (!ref.mounted) return false;
    state = result;
    if (!result.hasError) {
      ref.read(dataRevisionProvider.notifier).refresh();
      ref.invalidate(dashboardControllerProvider);
    }
    return !result.hasError;
  }
}

final invoicesControllerProvider =
    AsyncNotifierProvider<InvoicesController, void>(InvoicesController.new);
