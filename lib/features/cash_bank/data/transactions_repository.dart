import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/data_providers.dart';
import '../presentation/models/cash_transaction_model.dart';

class TransactionsRepository {
  TransactionsRepository(this.client);
  final SupabaseClient client;

  Future<List<CashTransactionModel>> fetch(String userId) async {
    final rows = await client
        .from('transactions')
        .select(
          '*, contacts!transactions_contact_id_fkey(name), accounts!transactions_account_id_fkey(name)',
        )
        .eq('user_id', userId)
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false);
    return rows.map(CashTransactionModel.fromJson).toList();
  }

  Future<void> save(
    String userId,
    CashTransactionModel transaction, {
    required bool isNew,
  }) async {
    final values = {
      'contact_id': transaction.contactId,
      'invoice_id': transaction.invoiceId,
      'account_id': transaction.accountId.isEmpty
          ? null
          : transaction.accountId,
      'account_type': transaction.accountType,
      'direction': transaction.type == CashTransactionType.collection
          ? 'in'
          : 'out',
      'amount': transaction.amount,
      'transaction_date': transaction.date.toIso8601String().substring(0, 10),
      'description': transaction.description,
    };
    if (isNew) {
      await client.from('transactions').insert({...values, 'user_id': userId});
    } else {
      await client
          .from('transactions')
          .update(values)
          .eq('user_id', userId)
          .eq('id', transaction.id)
          .select()
          .single();
    }
  }

  Future<void> delete(String userId, String id) async {
    await client
        .from('transactions')
        .delete()
        .eq('user_id', userId)
        .eq('id', id)
        .select()
        .single();
  }
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>(
  (ref) => TransactionsRepository(ref.watch(supabaseClientProvider)),
);

class TransactionsData extends AsyncNotifier<List<CashTransactionModel>> {
  @override
  Future<List<CashTransactionModel>> build() async {
    ref.watch(dataRevisionProvider);
    final repository = ref.watch(transactionsRepositoryProvider);
    final id = await ref.watch(sessionUserIdProvider.future);
    if (id == null) throw StateError('Kullanıcı oturumu bulunamadı');
    return repository.fetch(id);
  }
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsData, List<CashTransactionModel>>(
      TransactionsData.new,
    );
