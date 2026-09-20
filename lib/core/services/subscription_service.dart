import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../constants/app_constants.dart';
import 'supabase_service.dart';

/// RevenueCat üzerinden Google Play abonelik/satın alma işlemlerini yöneten servis.
class SubscriptionService {
  SubscriptionService._();

  static bool _initialized = false;

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
    } catch (_) {
      // Yapılandırma başarısız olursa isPro=false ile devam edilir.
    }
  }

  /// Giriş yapan kullanıcıyı Supabase user id'si ile RevenueCat müşterisi olarak tanımlar.
  static Future<void> identifyCustomer(String supabaseUserId) async {
    try {
      await Purchases.logIn(supabaseUserId);
    } catch (_) {
      // Kimliklendirme başarısız olsa da uygulama akışı bozulmamalı.
    }
  }

  /// Kullanıcı çıkış yaptığında RevenueCat kimliğini de sıfırlar.
  static Future<void> resetCustomer() async {
    try {
      await Purchases.logOut();
    } catch (_) {}
  }

  /// "pro" entitlement'ının aktif olup olmadığını kontrol eder.
  /// RevenueCat henüz yapılandırılmamışsa (ör. init hatası) false döner.
  static Future<bool> checkSubscriptionStatus() async {
    if (!_initialized) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
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
    final package = await getMonthlyPackage();
    if (package == null) {
      throw Exception('Kullanılabilir bir abonelik paketi bulunamadı');
    }
    final result = await Purchases.purchase(PurchaseParams.package(package));
    return result.customerInfo.entitlements.active.containsKey(
      AppConstants.proEntitlementId,
    );
  }

  /// Önceki satın alımları geri yükler ve "pro" durumunu döner.
  static Future<bool> restorePurchases() async {
    final customerInfo = await Purchases.restorePurchases();
    return customerInfo.entitlements.active.containsKey(
      AppConstants.proEntitlementId,
    );
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
    state = await AsyncValue.guard(SubscriptionService.checkSubscriptionStatus);
  }

  Future<bool> purchaseMonthly() async {
    final isPro = await SubscriptionService.purchaseMonthlySubscription();
    state = AsyncData(isPro);
    return isPro;
  }

  Future<bool> restore() async {
    final isPro = await SubscriptionService.restorePurchases();
    state = AsyncData(isPro);
    return isPro;
  }
}
