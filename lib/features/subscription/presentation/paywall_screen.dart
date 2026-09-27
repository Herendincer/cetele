import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/subscription_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/screens/existing_account_dialog.dart';
import 'subscription_entry.dart';

/// Çetele Pro aboneliğini tanıtan ve satın alma/geri yükleme akışını sunan ekran.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({this.limitReached = false, super.key});
  final bool limitReached;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isProcessing = false;
  Package? _monthlyPackage;
  bool _loadingPackage = true;

  static const _benefits = [
    (icon: Icons.receipt_long, text: 'Sınırsız fatura kesme'),
  ];

  @override
  void initState() {
    super.initState();
    if (SubscriptionService.isEligible) _loadPackage();
  }

  Future<void> _signIn() async {
    setState(() => _isProcessing = true);
    SubscriptionIntent.pending = true;
    try {
      final success = await SupabaseService.signInWithProvider(
        OAuthProvider.google,
        confirmExistingAccount: () => confirmExistingAccount(context),
      );
      if (!success) SubscriptionIntent.pending = false;
    } catch (_) {
      SubscriptionIntent.pending = false;
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Giriş yapılamadı. Lütfen tekrar deneyin.',
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _loadPackage() async {
    setState(() => _loadingPackage = true);
    try {
      final package = await SubscriptionService.getMonthlyPackage();
      if (!mounted) return;
      setState(() {
        _monthlyPackage = package;
        _loadingPackage = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPackage = false);
    }
  }

  Future<void> _purchase() async {
    setState(() => _isProcessing = true);
    try {
      final package = _monthlyPackage;
      if (package == null) return;
      final isPro = await ref
          .read(subscriptionStatusProvider.notifier)
          .purchaseMonthly(package);
      if (!mounted) return;
      if (isPro) {
        AppSnackBar.showSuccess(
          context,
          'Çetele Pro aboneliğiniz başarıyla etkinleşti',
        );
        Navigator.of(context).pop();
      }
    } on PlatformException catch (error) {
      if (!mounted) return;
      if (PurchasesErrorHelper.getErrorCode(error) !=
          PurchasesErrorCode.purchaseCancelledError) {
        AppSnackBar.showError(
          context,
          'Satın alma tamamlanamadı. Lütfen tekrar deneyin.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        'Satın alma tamamlanamadı. Lütfen tekrar deneyin.',
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isProcessing = true);
    try {
      final isPro = await ref
          .read(subscriptionStatusProvider.notifier)
          .restore();
      if (!mounted) return;
      if (isPro) {
        AppSnackBar.showSuccess(context, 'Satın alımlarınız geri yüklendi');
        Navigator.of(context).pop();
      } else {
        AppSnackBar.showError(
          context,
          'Geri yüklenecek aktif bir abonelik bulunamadı',
        );
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        'Satın almalar geri yüklenemedi. Lütfen tekrar deneyin.',
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _openLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Aşağıdaki ortak Türkçe hata gösterilir.
    }
    if (!mounted) return;
    AppSnackBar.showError(context, 'Bağlantı açılamadı');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceText = _monthlyPackage?.storeProduct.priceString ?? '--';
    final isPro = ref.watch(isProProvider);
    if (!SubscriptionService.isEligible) {
      return Scaffold(
        appBar: AppBar(title: const Text('Çetele Pro')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (widget.limitReached)
              const Text('Bu ay ücretsiz fatura hakkınız doldu'),
            const SizedBox(height: 16),
            const Text(
              'Abone olmak için Google hesabınızla giriş yapmanız gerekiyor. '
              'Girişten sonra abonelik seçeneklerine devam edeceksiniz.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isProcessing ? null : _signIn,
              icon: const Icon(Icons.login),
              label: const Text(
                'Google ile Giriş Yap',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Çetele Pro')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              Icons.workspace_premium,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              widget.limitReached
                  ? 'Bu ay ücretsiz fatura hakkınız doldu'
                  : 'Çetele Pro ile sınırsız satış faturası',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ücretsiz planda ayda 5 satış faturası oluşturabilirsiniz. '
              'Cariler, hesaplar, hareketler, PDF dışa aktarma ve genel durum ücretsiz planda sınırsızdır.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final benefit in _benefits)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              benefit.icon,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(benefit.text)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Aylık Abonelik',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_loadingPackage)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(),
                      )
                    else if (_monthlyPackage != null)
                      Text(
                        '$priceText / ay',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else ...[
                      const Text('Abonelik seçenekleri şu anda yüklenemiyor.'),
                      TextButton(
                        onPressed: _loadPackage,
                        child: const Text('Tekrar dene'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            (_isProcessing || _monthlyPackage == null || isPro)
                            ? null
                            : _purchase,
                        child: _isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isPro ? 'Pro etkin' : 'Satın Al'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isProcessing ? null : _restore,
              child: const Text('Satın Almaları Geri Yükle'),
            ),
            if (isPro)
              TextButton(
                onPressed: () => _openLink(AppConstants.manageSubscriptionsUrl),
                child: const Text('Aboneliği Yönet'),
              ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _openLink(AppConstants.privacyPolicyUrl),
                  child: const Text('Gizlilik Politikası'),
                ),
                TextButton(
                  onPressed: () => _openLink(AppConstants.termsOfUseUrl),
                  child: const Text('Kullanım Koşulları'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
