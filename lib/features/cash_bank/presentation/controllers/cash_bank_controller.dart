import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/data_providers.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../data/accounts_repository.dart';
import '../../data/transactions_repository.dart';
import '../models/account_model.dart';
import '../models/cash_transaction_model.dart';

class AccountsData extends AsyncNotifier<List<AccountModel>> {
  @override
  Future<List<AccountModel>> build() async {
    ref.watch(dataRevisionProvider);
    final repository = ref.watch(accountsRepositoryProvider);
    final values = await Future.wait<Object?>([
      ref.watch(sessionUserIdProvider.future),
      ref.watch(transactionsProvider.future),
    ]);
    final id = values[0] as String?;
    if (id == null) throw StateError('Kullanıcı oturumu bulunamadı');
    final transactions = values[1] as List<CashTransactionModel>;
    final accounts = await repository.fetch(id);
    return accounts.map((account) {
      double balance = account.openingBalance;
      DateTime last = account.lastTransactionDate;
      for (final transaction in transactions.where(
        (t) => t.accountId == account.id,
      )) {
        balance += transaction.type == CashTransactionType.collection
            ? transaction.amount
            : -transaction.amount;
        if (transaction.date.isAfter(last)) last = transaction.date;
      }
      return account.copyWith(balance: balance, lastTransactionDate: last);
    }).toList();
  }
}

final accountsProvider =
    AsyncNotifierProvider<AccountsData, List<AccountModel>>(AccountsData.new);

class CashBankController extends AsyncNotifier<void> {
  @override
  void build() {
    ref.watch(sessionUserIdProvider);
  }

  Future<bool> saveAccount(AccountModel account, {required bool isNew}) => _run(
    (id) =>
        ref.read(accountsRepositoryProvider).save(id, account, isNew: isNew),
  );
  Future<bool> deleteAccount(String accountId) =>
      _run((id) => ref.read(accountsRepositoryProvider).delete(id, accountId));
  Future<bool> saveTransaction(
    CashTransactionModel transaction, {
    required bool isNew,
  }) => _run(
    (id) => ref
        .read(transactionsRepositoryProvider)
        .save(id, transaction, isNew: isNew),
  );
  Future<bool> deleteTransaction(String transactionId) => _run(
    (id) => ref.read(transactionsRepositoryProvider).delete(id, transactionId),
  );

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

final cashBankControllerProvider =
    AsyncNotifierProvider<CashBankController, void>(CashBankController.new);
