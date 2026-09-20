import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/dashboard_metrics.dart';
import '../models/monthly_financials.dart';

/// Giriş yapan kullanıcının Supabase verilerinden dashboard metriklerini
/// hesaplayan controller.
class DashboardController extends AsyncNotifier<DashboardMetrics> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isFetching = false;

  @override
  Future<DashboardMetrics> build() {
    _authSubscription?.cancel();
    _authSubscription = SupabaseService.authStateChanges.listen((authState) {
      final userId = authState.session?.user.id;
      // Yalnızca oturum değiştiğinde ve halihazırda veri çekilmiyorsa tetikle
      if (userId != null && !_isFetching) {
        // Döngüyü kırmak için microtask ile güvenli yenileme
        Future.microtask(() => ref.invalidateSelf());
      }
    });

    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    return _fetchMetricsSafe();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchMetricsSafe);
  }

  Future<DashboardMetrics> _fetchMetricsSafe() async {
    if (_isFetching) {
      return state.value ?? _emptyMetrics();
    }

    _isFetching = true;
    try {
      final userId = await _resolveUserId();
      debugPrint('--> DASHBOARD: Veri çekme başladı. User ID: $userId');

      // Kullanıcı oturumu yoksa kilitlenmek yerine sıfır değerlerle aç
      if (userId == null) {
        debugPrint('--> DASHBOARD: Kullanıcı oturumu yok, sıfır değerler yükleniyor.');
        return _emptyMetrics();
      }

      final client = SupabaseService.client;

      // 5 saniye timeout ile cari bakiyelerini çek
      final contactRows = await client
          .from(AppConstants.tableContacts)
          .select('balance')
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 5));

      double receivables = 0;
      double payables = 0;
      for (final row in (contactRows as List)) {
        final balance = ((row as Map)['balance'] as num?)?.toDouble() ?? 0;
        if (balance > 0) {
          receivables += balance;
        } else {
          payables += -balance;
        }
      }

      // 5 saniye timeout ile işlem geçmişini çek
      final transactionRows = await client
          .from(AppConstants.tableTransactions)
          .select('amount, direction, transaction_date')
          .eq('user_id', userId)
          .timeout(const Duration(seconds: 5));

      double cashAndBankBalance = 0;
      for (final row in (transactionRows as List)) {
        final map = row as Map;
        final amount = (map['amount'] as num?)?.toDouble() ?? 0;
        cashAndBankBalance += map['direction'] == 'in' ? amount : -amount;
      }

      debugPrint('--> DASHBOARD: Veriler başarıyla hesaplandı.');
      return DashboardMetrics(
        totalReceivables: receivables,
        totalPayables: payables,
        cashAndBankBalance: cashAndBankBalance,
        monthlySeries: _buildMonthlySeries(transactionRows),
      );
    } catch (e, stack) {
      debugPrint('--> DASHBOARD HATA ALINDI: $e');
      debugPrint(stack.toString());
      // Hata veya timeout durumunda donmayı engelle, mevcut veriyi veya sıfır değerleri bas
      return state.value ?? _emptyMetrics();
    } finally {
      _isFetching = false;
    }
  }

  Future<String?> _resolveUserId() async {
    final immediate = SupabaseService.currentUser?.id;
    if (immediate != null) return immediate;
    try {
      final authState = await SupabaseService.authStateChanges.first.timeout(
        const Duration(seconds: 2),
      );
      return authState.session?.user.id ?? SupabaseService.currentUser?.id;
    } catch (_) {
      return SupabaseService.currentUser?.id;
    }
  }

  DashboardMetrics _emptyMetrics() {
    final DateTime now = DateTime.now();
    final List<DateTime> months = [
      for (int i = 5; i >= 0; i--) DateTime(now.year, now.month - i, 1),
    ];
    final DateFormat labelFormat = DateFormat('MMM', 'tr_TR');

    return DashboardMetrics(
      totalReceivables: 0.0,
      totalPayables: 0.0,
      cashAndBankBalance: 0.0,
      monthlySeries: [
        for (final month in months)
          MonthlyFinancials(
            monthLabel: labelFormat.format(month),
            income: 0.0,
            expense: 0.0,
          ),
      ],
    );
  }

  List<MonthlyFinancials> _buildMonthlySeries(List transactionRows) {
    final DateTime now = DateTime.now();
    final List<DateTime> months = [
      for (int i = 5; i >= 0; i--) DateTime(now.year, now.month - i, 1),
    ];
    final Map<String, double> incomeByMonth = {for (final m in months) _monthKey(m): 0};
    final Map<String, double> expenseByMonth = {for (final m in months) _monthKey(m): 0};

    for (final row in transactionRows) {
      try {
        final map = row as Map;
        final date = DateTime.parse(map['transaction_date'] as String);
        final key = _monthKey(DateTime(date.year, date.month));
        if (!incomeByMonth.containsKey(key)) continue;
        final amount = (map['amount'] as num?)?.toDouble() ?? 0;
        if (map['direction'] == 'in') {
          incomeByMonth[key] = incomeByMonth[key]! + amount;
        } else {
          expenseByMonth[key] = expenseByMonth[key]! + amount;
        }
      } catch (_) {
        // Tarih formatı bozuk satır varsa akışı bozma
      }
    }

    final DateFormat labelFormat = DateFormat('MMM', 'tr_TR');
    return [
      for (final month in months)
        MonthlyFinancials(
          monthLabel: labelFormat.format(month),
          income: incomeByMonth[_monthKey(month)]!,
          expense: expenseByMonth[_monthKey(month)]!,
        ),
    ];
  }

  String _monthKey(DateTime month) => '${month.year}-${month.month}';
}

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardMetrics>(
  DashboardController.new,
);