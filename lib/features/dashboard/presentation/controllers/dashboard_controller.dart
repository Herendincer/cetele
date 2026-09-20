import 'dart:async';



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



  @override

  Future<DashboardMetrics> build() {

    // Soğuk başlangıçta oturum henüz geri yüklenmemiş olabilir; oturum

    // hazır olduğunda veriler otomatik olarak yeniden yüklensin.

    _authSubscription?.cancel();

    _authSubscription = SupabaseService.authStateChanges.listen((authState) {

      final hasSession = authState.session?.user.id != null;

      if (hasSession && (state.hasError || state.value == null)) {

        ref.invalidateSelf();

      }

    });

    ref.onDispose(() => _authSubscription?.cancel());

    return _fetchMetrics();

  }



  Future<void> refresh() async {

    state = const AsyncLoading();

    state = await AsyncValue.guard(_fetchMetrics);

  }



  Future<DashboardMetrics> _fetchMetrics() async {

    final userId = await _resolveUserId();

    if (userId == null) {

      throw Exception('Kullanıcı oturumu bulunamadı');

    }



    final client = SupabaseService.client;



    final contactRows = await client

        .from(AppConstants.tableContacts)

        .select('balance')

        .eq('user_id', userId);



    double receivables = 0;

    double payables = 0;

    for (final row in contactRows as List) {

      final balance = ((row as Map)['balance'] as num?)?.toDouble() ?? 0;

      if (balance > 0) {

        receivables += balance;

      } else {

        payables += -balance;

      }

    }



    final transactionRows = await client

        .from(AppConstants.tableTransactions)

        .select('amount, direction, transaction_date')

        .eq('user_id', userId);



    double cashAndBankBalance = 0;

    for (final row in transactionRows as List) {

      final map = row as Map;

      final amount = (map['amount'] as num?)?.toDouble() ?? 0;

      cashAndBankBalance += map['direction'] == 'in' ? amount : -amount;

    }



    return DashboardMetrics(

      totalReceivables: receivables,

      totalPayables: payables,

      cashAndBankBalance: cashAndBankBalance,

      monthlySeries: _buildMonthlySeries(transactionRows),

    );

  }



  /// Oturum hen\u00fcz geri y\u00fcklenmemi\u015fse (so\u011fuk ba\u015flang\u0131\u00e7), ilk auth olay\u0131n\u0131

  /// bekleyerek yar\u0131\u015f durumunu \u00f6nler.

  Future<String?> _resolveUserId() async {

    final immediate = SupabaseService.currentUser?.id;

    if (immediate != null) return immediate;

    try {

      final authState = await SupabaseService.authStateChanges.first.timeout(

        const Duration(seconds: 5),

      );

      return authState.session?.user.id ?? SupabaseService.currentUser?.id;

    } catch (_) {

      return SupabaseService.currentUser?.id;

    }

  }



  List<MonthlyFinancials> _buildMonthlySeries(List transactionRows) {

    final DateTime now = DateTime.now();

    final List<DateTime> months = [

      for (int i = 5; i >= 0; i--) DateTime(now.year, now.month - i, 1),

    ];

    final Map<String, double> incomeByMonth = {for (final m in months) _monthKey(m): 0};

    final Map<String, double> expenseByMonth = {for (final m in months) _monthKey(m): 0};



    for (final row in transactionRows) {

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

