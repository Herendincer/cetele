import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../constants/app_constants.dart';
import 'supabase_service.dart';

/// RevenueCat üzerinden Google Play abonelik/satın alma işlemlerini yöneten servis.
class SubscriptionService {
  SubscriptionService._();

  static bool _initialized = false;
  static String? _identifiedUserId;

  /// main() içinde, Supabase başlatıldıktan sonra çağrılmalıdır.
  /// RevenueCat yapılandırılamasa bile (ör. geçersiz API anahtarı) uygulama
  /// akışını bozmamalı, bu yüzden hataları yutar.
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Purchases.setLogLevel(LogLevel.warn);
      final configuration = PurchasesConfiguration(
        AppConstants.revenueCatGoogleApiKey,
      );
      final userId = SupabaseService.currentUser?.id;
      if (userId != null) {
        configuration.appUserID = userId;
      }
      await Purchases.configure(configuration);
      _initialized = true;
      _identifiedUserId = userId;
    } catch (_) {
      // Yapılandırma başarısız olursa isPro=false ile devam edilir.
    }
  }

  /// Giriş yapan kullanıcıyı Supabase user id'si ile RevenueCat müşterisi olarak tanımlar.
  static Future<void> identifyCustomer(String supabaseUserId) async {
    _identifiedUserId = null;
    try {
      if (!_initialized) await initialize();
      if (!_initialized) return;
      await Purchases.logIn(supabaseUserId);
      if (SupabaseService.currentUser?.id == supabaseUserId) {
        _identifiedUserId = supabaseUserId;
      }
    } catch (_) {
      _identifiedUserId = null;
      // Kimliklendirme başarısız olsa da uygulama akışı bozulmamalı.
    }
  }

  /// Kullanıcı çıkış yaptığında RevenueCat kimliğini de sıfırlar.
  static Future<void> resetCustomer() async {
    _identifiedUserId = null;
    if (!_initialized) return;
    try {
      await Purchases.logOut();
    } catch (_) {}
  }

  /// "pro" entitlement'ının aktif olup olmadığını kontrol eder.
  /// RevenueCat henüz yapılandırılmamışsa (ör. init hatası) false döner.
  static Future<bool> checkSubscriptionStatus() async {
    final userId = SupabaseService.currentUser?.id;
    if (!_initialized || userId == null || userId != _identifiedUserId) {
      return false;
    }
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      if (SupabaseService.currentUser?.id != userId ||
          _identifiedUserId != userId) {
        return false;
      }
      return customerInfo.entitlements.active.containsKey(
        AppConstants.proEntitlementId,
      );
    } catch (_) {
      return false;
    }
  }

  /// Mevcut aylık abonelik paketini (varsa) döner.
  static Future<Package?> getMonthlyPackage() async {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) return null;
    return current.monthly ??
        current.availablePackages
            .where((package) => package.packageType == PackageType.monthly)
            .firstOrNull;
  }

  /// Aylık abonelik paketini satın alır ve "pro" entitlement'ının aktif olup
  /// olmadığını döner.
  static Future<bool> purchaseMonthlySubscription() async {
    final userId = _requireIdentifiedCustomer();
    final package = await getMonthlyPackage();
    if (package == null) {
      throw Exception('Kullanılabilir bir abonelik paketi bulunamadı');
    }
    if (_requireIdentifiedCustomer() != userId) {
      throw StateError('Hesap değişti. Lütfen tekrar deneyin.');
    }
    final result = await Purchases.purchase(PurchaseParams.package(package));
    if (_requireIdentifiedCustomer() != userId) return false;
    return result.customerInfo.entitlements.active.containsKey(
      AppConstants.proEntitlementId,
    );
  }

  /// Önceki satın alımları geri yükler ve "pro" durumunu döner.
  static Future<bool> restorePurchases() async {
    final userId = _requireIdentifiedCustomer();
    final customerInfo = await Purchases.restorePurchases();
    if (_requireIdentifiedCustomer() != userId) return false;
    return customerInfo.entitlements.active.containsKey(
      AppConstants.proEntitlementId,
    );
  }

  static String _requireIdentifiedCustomer() {
    final userId = SupabaseService.currentUser?.id;
    if (!_initialized || userId == null || userId != _identifiedUserId) {
      throw StateError(
        'Abonelik hesabı doğrulanamadı. Lütfen tekrar giriş yapın.',
      );
    }
    return userId;
  }
}

/// Uygulama genelinde abonelik durumunu (Ücretsiz/Pro) tutan Riverpod controller.
final subscriptionStatusProvider =
    AsyncNotifierProvider<SubscriptionStatusController, bool>(
      SubscriptionStatusController.new,
    );

class SubscriptionStatusController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => SubscriptionService.checkSubscriptionStatus();

  Future<void> refresh() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      SubscriptionService.checkSubscriptionStatus,
    );
    if (ref.mounted) state = result;
  }

  Future<bool> purchaseMonthly() async {
    final isPro = await SubscriptionService.purchaseMonthlySubscription();
    if (ref.mounted) state = AsyncData(isPro);
    return isPro;
  }

  Future<bool> restore() async {
    final isPro = await SubscriptionService.restorePurchases();
    if (ref.mounted) state = AsyncData(isPro);
    return isPro;
  }
}
