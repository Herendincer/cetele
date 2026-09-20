import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/subscription_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/constants/app_constants.dart';

/// Çetele Pro aboneliğini tanıtan ve satın alma/geri yükleme akışını sunan ekran.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isProcessing = false;
  Package? _monthlyPackage;
  bool _loadingPackage = true;

  static const _benefits = [
    (icon: Icons.receipt_long, text: 'Sınırsız fatura kesme'),
    (icon: Icons.picture_as_pdf_outlined, text: 'PDF ve WhatsApp ekstre paylaşımı'),
    (icon: Icons.devices_outlined, text: 'Çoklu cihaz eşitleme'),
  ];

  @override
  void initState() {
    super.initState();
    _loadPackage();
  }

  Future<void> _loadPackage() async {
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
      final isPro = await ref.read(subscriptionStatusProvider.notifier).purchaseMonthly();
      if (!mounted) return;
      if (isPro) {
        AppSnackBar.showSuccess(context, 'Çetele Pro aboneliğiniz başarıyla etkinleşti');
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Satın alma tamamlanamadı: $error');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _isProcessing = true);
    try {
      final isPro = await ref.read(subscriptionStatusProvider.notifier).restore();
      if (!mounted) return;
      if (isPro) {
        AppSnackBar.showSuccess(context, 'Satın alımlarınız geri yüklendi');
        Navigator.of(context).pop();
      } else {
        AppSnackBar.showError(context, 'Geri yüklenecek aktif bir abonelik bulunamadı');
      }
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Satın alımlar geri yüklenemedi: $error');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Bağlantı açılamadı');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceText = _monthlyPackage?.storeProduct.priceString ?? '--';

    return Scaffold(
      appBar: AppBar(title: const Text('Çetele Pro')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.workspace_premium, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Çetele Pro ile işinizi büyütün',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'İşletmenizi yönetmek için ihtiyacınız olan her şey tek pakette.',
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
                            Icon(benefit.icon, color: theme.colorScheme.primary),
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
                    else
                      Text(
                        '$priceText / ay',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (_isProcessing || _monthlyPackage == null) ? null : _purchase,
                        child: _isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Abone Ol'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isProcessing ? null : _restore,
              child: const Text('Satın Alımları Geri Yükle'),
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
