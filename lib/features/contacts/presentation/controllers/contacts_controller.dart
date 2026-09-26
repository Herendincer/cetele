import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/data_providers.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../data/contacts_repository.dart';
import '../models/contact_model.dart';

class ContactsData extends AsyncNotifier<List<ContactModel>> {
  @override
  Future<List<ContactModel>> build() async {
    ref.watch(dataRevisionProvider);
    final repository = ref.watch(contactsRepositoryProvider);
    final id = await ref.watch(sessionUserIdProvider.future);
    if (id == null) throw StateError('Kullanıcı oturumu bulunamadı');
    return repository.fetch(id);
  }
}

final contactsProvider =
    AsyncNotifierProvider<ContactsData, List<ContactModel>>(ContactsData.new);

final contactProvider = Provider.family<AsyncValue<ContactModel?>, String>((
  ref,
  id,
) {
  return ref.watch(contactsProvider).whenData((contacts) {
    for (final contact in contacts) {
      if (contact.id == id) return contact;
    }
    return null;
  });
});

class ContactsController extends AsyncNotifier<void> {
  @override
  void build() {
    ref.watch(sessionUserIdProvider);
  }

  Future<bool> save(ContactModel contact, {required bool isNew}) => _run(
    (id) =>
        ref.read(contactsRepositoryProvider).save(id, contact, isNew: isNew),
  );

  Future<bool> delete(String contactId) =>
      _run((id) => ref.read(contactsRepositoryProvider).delete(id, contactId));

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

final contactsControllerProvider =
    AsyncNotifierProvider<ContactsController, void>(ContactsController.new);
