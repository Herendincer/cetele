import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/data_providers.dart';
import '../../../core/services/supabase_request.dart';
import '../../../core/utils/currency_helper.dart';
import '../presentation/models/account_model.dart';

class AccountsRepository {
  AccountsRepository(this.client);
  final SupabaseClient client;

  Future<List<AccountModel>> fetch(String userId) async {
    final rows = await client
        .from('accounts')
        .select()
        .eq('user_id', userId)
        .order('created_at')
        .withRequestTimeout();
    return rows.map(AccountModel.fromJson).toList();
  }

  Future<void> save(
    String userId,
    AccountModel account, {
    required bool isNew,
  }) async {
    final values = {
      'name': account.name,
      'type': account.type.name,
      // BIGINT açılış tutarı kuruş; NUMERIC transactions.amount ise TL'dir.
      'opening_balance': CurrencyHelper.liraToKurus(account.openingBalance),
    };
    if (isNew) {
      await client.from('accounts').insert({
        ...values,
        'user_id': userId,
      }).withRequestTimeout();
    } else {
      await client
          .from('accounts')
          .update(values)
          .eq('user_id', userId)
          .eq('id', account.id)
          .select()
          .single()
          .withRequestTimeout();
    }
  }

  Future<void> delete(String userId, String id) async {
    // Bağlı hareket varsa FK silmeyi reddeder; hareketler sessizce silinmez.
    await client
        .from('accounts')
        .delete()
        .eq('user_id', userId)
        .eq('id', id)
        .select()
        .single()
        .withRequestTimeout();
  }
}

final accountsRepositoryProvider = Provider<AccountsRepository>(
  (ref) => AccountsRepository(ref.watch(supabaseClientProvider)),
);
