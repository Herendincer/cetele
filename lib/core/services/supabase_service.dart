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

  /// Yalnızca kullanıcı misafir olarak devam etmeyi seçtiğinde çağrılır.
  static Future<void> ensureSession() async {
    if (currentUser != null) return;
    await client.auth.signInAnonymously();
  }

  /// Sağlayıcının native kimlik bilgileriyle giriş yapar veya misafiri yükseltir.
  /// Kullanıcının hesap seçimini iptal etmesi normal bir sonuçtur.
  static Future<bool> signInWithProvider(
    OAuthProvider provider, {
    required Future<bool> Function() confirmExistingAccount,
  }) async {
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
      return await completeProviderSignIn(
        provider: provider,
        idToken: idToken,
        accessToken: authorization.accessToken,
        confirmExistingAccount: confirmExistingAccount,
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }
  }

  /// Native sağlayıcı token'larını mevcut oturumu koruyarak Supabase'e aktarır.
  static Future<bool> completeProviderSignIn({
    required OAuthProvider provider,
    required String idToken,
    required String accessToken,
    required Future<bool> Function() confirmExistingAccount,
  }) async {
    final originalUserId = currentUser?.id;
    if (isAnonymous) {
      try {
        await client.auth.linkIdentityWithIdToken(
          provider: provider,
          idToken: idToken,
          accessToken: accessToken,
        );
        return true;
      } on AuthException catch (error) {
        if (error.code != 'identity_already_exists') rethrow;
        if (!await confirmExistingAccount()) return false;
        // Diyalog açıkken oturum değişmişse eski onayı yeni oturuma uygulama.
        if (currentUser?.id != originalUserId || !isAnonymous) return false;
      }
    }
    await client.auth.signInWithIdToken(
      provider: provider,
      idToken: idToken,
      accessToken: accessToken,
    );
    return true;
  }
}
