import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../constants/app_constants.dart';
import 'supabase_service.dart';

/// RevenueCat üzerinden Google Play abonelik/satın alma işlemlerini yöneten servis.
class SubscriptionService {
  SubscriptionService._();

  static bool _initialized = false;
  static String? _identifiedUserId;

  static bool get isEligible {
    final user = SupabaseService.currentUser;
    return user != null && !user.isAnonymous;
  }

  static bool get isReady =>
      isEligible &&
      _initialized &&
      _identifiedUserId == SupabaseService.currentUser?.id;

  /// main() içinde, Supabase başlatıldıktan sonra çağrılmalıdır.
  /// RevenueCat yapılandırılamasa bile (ör. geçersiz API anahtarı) uygulama
  /// akışını bozmamalı, bu yüzden hataları yutar.
  static Future<void> initialize({String? apiKey}) async {
    if (_initialized) return;
    final key = apiKey ?? AppConstants.revenueCatGoogleApiKey;
    if (!isEligible || key.isEmpty) return;
    try {
      await Purchases.setLogLevel(LogLevel.warn);
      final configuration = PurchasesConfiguration(key);
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
    if (!isEligible || SupabaseService.currentUser?.id != supabaseUserId) {
      return;
    }
    try {
      if (!_initialized) await initialize();
      if (!_initialized) return;
      await Purchases.logIn(supabaseUserId);
      if (isEligible && SupabaseService.currentUser?.id == supabaseUserId) {
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
    if (!isReady || userId == null) {
      return false;
    }
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      if (!isEligible ||
          SupabaseService.currentUser?.id != userId ||
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
    _requireIdentifiedCustomer();
    final offerings = await Purchases.getOfferings();
    final current = offerings.getOffering(AppConstants.offeringId);
    if (current == null) return null;
    return current.availablePackages
        .where((package) => package.identifier == AppConstants.monthlyPackageId)
        .firstOrNull;
  }

  /// Aylık abonelik paketini satın alır ve "pro" entitlement'ının aktif olup
  /// olmadığını döner.
  static Future<bool> purchaseMonthlySubscription({Package? package}) async {
    final userId = _requireIdentifiedCustomer();
    package ??= await getMonthlyPackage();
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
    if (!isReady || userId == null) {
      throw StateError(
        'Abonelik hesabı doğrulanamadı. Lütfen tekrar giriş yapın.',
      );
    }
    return userId;
  }
}

enum SubscriptionStatus { signInRequired, free, pro, unavailable }

final isProProvider = Provider<bool>(
  (ref) =>
      ref.watch(subscriptionStatusProvider).value == SubscriptionStatus.pro,
);

/// Hesaba bağlı haklar; misafirler için RevenueCat sorgusu yapılmaz.
final subscriptionStatusProvider =
    AsyncNotifierProvider<SubscriptionStatusController, SubscriptionStatus>(
      SubscriptionStatusController.new,
    );

class SubscriptionStatusController extends AsyncNotifier<SubscriptionStatus> {
  int _revision = 0;

  @override
  Future<SubscriptionStatus> build() async {
    if (!SubscriptionService.isEligible) {
      return SubscriptionStatus.signInRequired;
    }
    final userId = SupabaseService.currentUser?.id;
    final lifecycle = AppLifecycleListener(onResume: () => refresh());
    void onInfo(CustomerInfo info) {
      if (!ref.mounted ||
          !SubscriptionService.isReady ||
          userId != SupabaseService.currentUser?.id) {
        return;
      }
      _revision++;
      state = AsyncData(
        info.entitlements.active.containsKey(AppConstants.proEntitlementId)
            ? SubscriptionStatus.pro
            : SubscriptionStatus.free,
      );
    }

    Purchases.addCustomerInfoUpdateListener(onInfo);
    ref.onDispose(() {
      lifecycle.dispose();
      Purchases.removeCustomerInfoUpdateListener(onInfo);
    });
    return _load();
  }

  Future<SubscriptionStatus> _load() async {
    if (!SubscriptionService.isEligible) {
      return SubscriptionStatus.signInRequired;
    }
    if (!SubscriptionService.isReady) return SubscriptionStatus.unavailable;
    return await SubscriptionService.checkSubscriptionStatus()
        ? SubscriptionStatus.pro
        : SubscriptionStatus.free;
  }

  Future<void> refresh() async {
    final revision = ++_revision;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      if (SubscriptionService.isReady) {
        await Purchases.invalidateCustomerInfoCache();
      }
      return _load();
    });
    if (ref.mounted && revision == _revision) state = result;
  }

  Future<bool> purchaseMonthly(Package package) async {
    final isPro = await SubscriptionService.purchaseMonthlySubscription(
      package: package,
    );
    if (ref.mounted) await refresh();
    return isPro;
  }

  Future<bool> restore() async {
    final isPro = await SubscriptionService.restorePurchases();
    if (ref.mounted) await refresh();
    return isPro;
  }
}
