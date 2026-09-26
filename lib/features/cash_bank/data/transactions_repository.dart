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
