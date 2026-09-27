import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/subscription_service.dart';
import '../../../core/services/supabase_service.dart';

/// Hesap değişince provider önbelleklerini ve tüm Navigator rotalarını siler.
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
  bool _resetting = true;
  String? _userId;
  bool? _anonymous;
  Future<void> _pendingTransition = Future.value();

  @override
  void initState() {
    super.initState();
    _subscription = SupabaseService.authStateChanges.listen(
      (event) {
        final user = event.session?.user;
        if (user?.id != _userId ||
            user?.isAnonymous != _anonymous ||
            event.event == AuthChangeEvent.signedIn ||
            event.event == AuthChangeEvent.signedOut) {
          _changeSession(user);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        // Geçici token yenileme/ağ hatası mevcut oturumu veya uygulamayı kapatmaz.
        // Geçersiz oturum Supabase'in signedOut olayıyla ayrıca ele alınır.
      },
    );
    _changeSession(SupabaseService.currentUser);
  }

  void _changeSession(User? user) {
    _userId = user?.id;
    _anonymous = user?.isAnonymous;
    final revision = ++_revision;
    setState(() {
      _resetting = true;
    });
    // Çıkış ve hızlı yeniden giriş SDK'da ters sırayla tamamlanmasın.
    _pendingTransition = _pendingTransition.then((_) async {
      if (user == null) {
        await SubscriptionService.resetCustomer();
      } else {
        await SubscriptionService.identifyCustomer(user.id);
      }
      if (mounted && revision == _revision) {
        setState(() => _resetting = false);
      }
    });
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
