import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/subscription_service.dart';
import '../../../core/services/supabase_service.dart';

/// Oturum kapanınca provider önbelleklerini ve tüm Navigator rotalarını siler.
/// Eski hesaba ait geç tamamlanan istekler yeni kapsama sonuç yazamaz.
class AuthSessionScope extends StatefulWidget {
  const AuthSessionScope({required this.child, super.key});

  final Widget child;

  @override
  State<AuthSessionScope> createState() => _AuthSessionScopeState();
}

class _AuthSessionScopeState extends State<AuthSessionScope> {
  StreamSubscription<AuthState>? _subscription;
  int _revision = 0;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    _subscription = SupabaseService.authStateChanges.listen((event) {
      if (event.event == AuthChangeEvent.signedOut) {
        unawaited(_resetSession());
      }
    });
  }

  Future<void> _resetSession() async {
    setState(() {
      _resetting = true;
      _revision++;
    });
    await SubscriptionService.resetCustomer();
    if (mounted) setState(() => _resetting = false);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_resetting) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    // Kapsamı değiştirmek contacts, accounts, transactions, invoices, dashboard,
    // detay aileleri, yazma controller'ları ve abonelik dahil her provider'ı siler.
    return ProviderScope(key: ValueKey(_revision), child: widget.child);
  }
}
