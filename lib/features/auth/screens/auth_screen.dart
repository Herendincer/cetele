import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import 'existing_account_dialog.dart';

/// Google ile Devam Et / Giriş Yapmadan Devam Et seçeneklerini sunan giriş ekranı.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;

  Future<void> _continueWithProvider(OAuthProvider provider) async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService.signInWithProvider(
        provider,
        confirmExistingAccount: () => confirmExistingAccount(context),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Giriş yapılamadı. Lütfen tekrar deneyin.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService.ensureSession();
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Misafir oturumu açılamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Çetele\'ye Hoş Geldiniz',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Verilerinize başka cihazlardan da erişmek için Google ile '
                  'giriş yapın veya hesap oluşturmadan devam edin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _continueWithProvider(OAuthProvider.google),
                    icon: const Icon(Icons.login),
                    label: const Text(
                      'Google ile Giriş Yap',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading ? null : _continueAsGuest,
                    child: const Text(
                      'Hesap oluşturmadan devam et',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
