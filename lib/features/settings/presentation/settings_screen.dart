import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../auth/providers/auth_providers.dart';
import '../../subscription/presentation/paywall_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isProcessingAuth = false;

  Future<void> _openPaywall(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isProcessingAuth = true);
    try {
      await SupabaseService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Google ile giriş yapılamadı: $e');
      }
    } finally {
      if (mounted) setState(() => _isProcessingAuth = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isProcessingAuth = true);
    try {
      await SupabaseService.client.auth.signOut();
      await SupabaseService.ensureSession();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Çıkış yapılamadı: $e');
      }
    } finally {
      if (mounted) setState(() => _isProcessingAuth = false);
    }
  }

  Future<void> _selectTheme(BuildContext context, WidgetRef ref) async {
    final selectedMode = await showModalBottomSheet<AppThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in AppThemeMode.values)
                ListTile(
                  leading: Icon(
                    ref.read(themeControllerProvider) == mode
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(mode.label),
                  onTap: () => Navigator.of(context).pop(mode),
                ),
            ],
          ),
        ),
      ),
    );
    if (selectedMode != null) {
      await ref.read(themeControllerProvider.notifier).setThemeMode(selectedMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeControllerProvider);
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final isPro = subscriptionStatus.value ?? false;
    // Auth durumu değiştiğinde (misafir → Google) hesap kartının güncellenmesini sağlar.
    ref.watch(authStateProvider);
    final bool isAnonymous = SupabaseService.isAnonymous;
    final String? email = SupabaseService.currentUser?.email;
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: isAnonymous ? AppTheme.primaryColor.withValues(alpha: 0.08) : null,
            child: isAnonymous
                ? ListTile(
                    leading: _isProcessingAuth
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.cloud_off_outlined, color: AppTheme.primaryColor),
                    title: const Text('Google ile Giriş Yap / Hesabını Bağla'),
                    subtitle: const Text(
                      'Verilerinizi ve aboneliğinizi buluta yedeklemek için Google ile Giriş Yapın',
                    ),
                    onTap: _isProcessingAuth ? null : _signInWithGoogle,
                  )
                : ListTile(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: Text(email ?? 'Google Hesabı'),
                    subtitle: const Text('Google ile bağlı'),
                    trailing: _isProcessingAuth
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: _signOut,
                            child: const Text('Çıkış Yap'),
                          ),
                  ),
          ),
          Card(
            child: ListTile(
              leading: Icon(
                isPro ? Icons.workspace_premium : Icons.workspace_premium_outlined,
                color: isPro ? Colors.amber.shade700 : null,
              ),
              title: const Text('Çetele Pro / Abonelik'),
              subtitle: subscriptionStatus.isLoading
                  ? const Text('Kontrol ediliyor...')
                  : Text(isPro ? 'Pro' : 'Ücretsiz'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openPaywall(context),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Tema'),
              subtitle: Text(themeMode.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectTheme(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}