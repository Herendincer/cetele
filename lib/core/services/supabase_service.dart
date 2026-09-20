import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';

/// Supabase istemcisine kolay erişim sağlayan servis sınıfı.
class SupabaseService {
  SupabaseService._();

  /// Google OAuth/linkIdentity akışından uygulamaya dönüş için deep link şeması.
  static const String _oauthRedirect = 'io.cetele.auth://login-callback';

  /// main() içinde çağrılmalıdır.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static bool get isLoggedIn => currentUser != null;

  /// Kullanıcı misafir (anonim) oturumla mı giriş yapmış?
  static bool get isAnonymous => currentUser?.isAnonymous ?? false;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  /// Geçerli bir oturum yoksa misafir (anonim) oturum açar, böylece
  /// `user.id` uygulama genelinde her zaman mevcut olur.
  static Future<void> ensureSession() async {
    if (currentUser != null) return;
    try {
      await client.auth.signInAnonymously();
    } catch (_) {
      // Ağ/servis hatası olsa bile uygulama akışı bozulmamalı.
    }
  }

  /// Google ile giriş yapar. Kullanıcı misafirse mevcut anonim oturumu Google
  /// kimliğine bağlayarak cariler/faturalar gibi verilerin korunmasını sağlar.
  static Future<void> signInWithGoogle() async {
    if (isAnonymous && currentUser != null) {
      await client.auth.linkIdentity(
        OAuthProvider.google,
        redirectTo: _oauthRedirect,
      );
    } else {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _oauthRedirect,
      );
    }
  }
}
