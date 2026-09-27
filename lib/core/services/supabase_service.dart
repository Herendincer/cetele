import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';

/// Supabase istemcisine kolay erişim sağlayan servis sınıfı.
class SupabaseService {
  SupabaseService._();

  static Future<void>? _providerInitialization;
  static const _serverClientId =
      '535679213005-gmgpu0kkt39q8i7qts0v8e9ketf8phav.apps.googleusercontent.com';

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

  /// Sağlayıcının native kimlik bilgileriyle giriş yapar veya misafiri yükseltir.
  /// Kullanıcının hesap seçimini iptal etmesi normal bir sonuçtur.
  static Future<bool> signInWithProvider(OAuthProvider provider) async {
    if (provider != OAuthProvider.google ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      throw const AuthException(
        'Bu giriş yöntemi bu platformda henüz desteklenmiyor.',
      );
    }
    try {
      await (_providerInitialization ??= GoogleSignIn.instance.initialize(
        serverClientId: _serverClientId,
      ));
    } catch (_) {
      _providerInitialization = null;
      rethrow;
    }
    try {
      const scopes = ['email', 'profile'];
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: scopes,
      );
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('Kimlik doğrulama bilgisi alınamadı.');
      }
      final authorization =
          await account.authorizationClient.authorizationForScopes(scopes) ??
          await account.authorizationClient.authorizeScopes(scopes);
      if (isAnonymous) {
        await client.auth.linkIdentityWithIdToken(
          provider: provider,
          idToken: idToken,
          accessToken: authorization.accessToken,
        );
      } else {
        await client.auth.signInWithIdToken(
          provider: provider,
          idToken: idToken,
          accessToken: authorization.accessToken,
        );
      }
      return true;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }
  }
}
