import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/screens/existing_account_dialog.dart';
import '../../invoices/presentation/controllers/invoice_usage_provider.dart';
import '../../subscription/presentation/paywall_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isProcessingAuth = false;
  late final AppLifecycleListener _lifecycle;
  late final Timer _monthTimer;
  late int _displayMonth;

  // Bu saat yalnızca yenilemeyi tetikler; sayılacak ayı RPC sunucuda belirler.
  int get _monthKey {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));
    return now.year * 12 + now.month;
  }

  @override
  void initState() {
    super.initState();
    _displayMonth = _monthKey;
    _lifecycle = AppLifecycleListener(onResume: _refreshUsage);
    _monthTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_monthKey != _displayMonth) _refreshUsage();
    });
  }

  void _refreshUsage() {
    if (!mounted) return;
    _displayMonth = _monthKey;
    ref.invalidate(monthlySalesInvoiceCountProvider);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _monthTimer.cancel();
    super.dispose();
  }

  Future<void> _openPaywall(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
  }

  Future<void> _manageSubscription() async {
    try {
      if (await launchUrl(
        Uri.parse(AppConstants.manageSubscriptionsUrl),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      // Ortak Türkçe hata gösterilir.
    }
    if (mounted) AppSnackBar.showError(context, 'Abonelik yönetimi açılamadı.');
  }

  Future<void> _signInWithProvider(OAuthProvider provider) async {
    setState(() => _isProcessingAuth = true);
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
      if (mounted) setState(() => _isProcessingAuth = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isProcessingAuth = true);
    try {
      await SupabaseService.signOut();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Çıkış işlemi tamamlanamadı. Lütfen tekrar deneyin.',
        );
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
      await ref
          .read(themeControllerProvider.notifier)
          .setThemeMode(selectedMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeControllerProvider);
    final subscriptionStatus = ref.watch(subscriptionStatusProvider);
    final isPro = ref.watch(isProProvider);
    final usage = isPro || subscriptionStatus.isLoading
        ? null
        : ref.watch(monthlySalesInvoiceCountProvider);
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
            color: isAnonymous
                ? AppTheme.primaryColor.withValues(alpha: 0.08)
                : null,
            child: isAnonymous
                ? ListTile(
                    leading: _isProcessingAuth
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.cloud_off_outlined,
                            color: AppTheme.primaryColor,
                          ),
                    title: const Text(
                      'Google ile Giriş Yap',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: const Text(
                      'Misafir hesabınızı bağlayarak verilerinize başka cihazlardan da erişin.',
                    ),
                    onTap: _isProcessingAuth
                        ? null
                        : () => _signInWithProvider(OAuthProvider.google),
                  )
                : ListTile(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: Text(
                      email ?? 'Hesabım',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: Icon(
                    isPro
                        ? Icons.workspace_premium
                        : Icons.workspace_premium_outlined,
                    color: isPro ? Colors.amber.shade700 : null,
                  ),
                  title: const Text('Planım'),
                  subtitle: subscriptionStatus.isLoading
                      ? const Text('Kontrol ediliyor...')
                      : Text(isPro ? 'Pro' : 'Ücretsiz'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openPaywall(context),
                ),
                if (usage != null)
                  ListTile(
                    dense: true,
                    title: usage.when(
                      skipLoadingOnRefresh: false,
                      data: (count) => Text(
                        'Bu ay satış faturası: $count / ${AppConstants.freeMonthlySalesInvoiceLimit}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      loading: () => const Text(
                        'Fatura kullanımı yükleniyor...',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      error: (_, _) => const Text(
                        'Fatura kullanımı alınamadı.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Fatura kullanımını yenile',
                      onPressed: _refreshUsage,
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                if (subscriptionStatus.hasError ||
                    subscriptionStatus.value == SubscriptionStatus.unavailable)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Abonelik durumu şu anda doğrulanamıyor.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: isPro
                      ? _manageSubscription
                      : () => _openPaywall(context),
                  child: Text(
                    isPro
                        ? 'Aboneliği Yönet'
                        : (isAnonymous
                              ? 'Google ile giriş yapıp Pro’ya geç'
                              : 'Pro’ya Yükselt'),
                  ),
                ),
              ],
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
