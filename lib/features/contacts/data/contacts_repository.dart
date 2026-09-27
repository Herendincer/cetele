import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/services/supabase_request.dart';
import '../presentation/models/contact_model.dart';

class ContactsRepository {
  ContactsRepository(this.client);
  final SupabaseClient client;

  Future<List<ContactModel>> fetch(String userId) async {
    final rows = await client
        .from('contacts')
        .select()
        .eq('user_id', userId)
        .order('name')
        .withRequestTimeout();
    return rows.map(ContactModel.fromJson).toList();
  }

  Future<void> save(
    String userId,
    ContactModel contact, {
    required bool isNew,
  }) async {
    // balance yalnızca veritabanı trigger'ları tarafından hesaplanır.
    final values = contact.toJson();
    if (isNew) {
      await client.from('contacts').insert({
        ...values,
        'user_id': userId,
      }).withRequestTimeout();
    } else {
      await client
          .from('contacts')
          .update(values)
          .eq('user_id', userId)
          .eq('id', contact.id)
          .select()
          .single()
          .withRequestTimeout();
    }
  }

  Future<void> delete(String userId, String id) async {
    await client
        .from('contacts')
        .delete()
        .eq('user_id', userId)
        .eq('id', id)
        .select()
        .single()
        .withRequestTimeout();
  }
}

final contactsRepositoryProvider = Provider<ContactsRepository>(
  (ref) => ContactsRepository(ref.watch(supabaseClientProvider)),
);
