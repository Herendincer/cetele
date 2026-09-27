import 'dart:async';
import 'dart:convert';

import 'package:cetele/core/providers/data_providers.dart';
import 'package:cetele/core/services/subscription_service.dart';
import 'package:cetele/core/services/supabase_service.dart';
import 'package:cetele/features/auth/screens/auth_session_scope.dart';
import 'package:cetele/features/subscription/presentation/subscription_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('purchases_flutter');
  late List<String> calls;
  Completer<void>? pendingLogin;
  bool failLogin = false;
  bool activePro = false;
  String customerId = '';

  Map<String, dynamic> customerInfo() => {
    'entitlements': {
      'all': {},
      'active': {
        if (activePro)
          'pro': {
            'identifier': 'pro',
            'isActive': true,
            'willRenew': true,
            'latestPurchaseDate': '2026-01-01T00:00:00Z',
            'originalPurchaseDate': '2026-01-01T00:00:00Z',
            'productIdentifier': 'test-product',
            'isSandbox': true,
          },
      },
    },
    'allPurchaseDates': {},
    'activeSubscriptions': [],
    'allPurchasedProductIdentifiers': [],
    'nonSubscriptionTransactions': [],
    'firstSeen': '2026-01-01T00:00:00Z',
    'originalAppUserId': customerId,
    'allExpirationDates': {},
    'requestDate': '2026-01-01T00:00:00Z',
  };

  Future<void> setSession(String id, {bool anonymous = false}) =>
      SupabaseService.client.auth.setInitialSession(
        jsonEncode({
          'access_token': 'test-token',
          'refresh_token': 'test-refresh',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': {
            'id': id,
            'aud': 'authenticated',
            'app_metadata': {},
            'user_metadata': {},
            'created_at': '2026-01-01T00:00:00Z',
            'is_anonymous': anonymous,
          },
        }),
      );

  setUp(() async {
    calls = [];
    pendingLogin = null;
    failLogin = false;
    activePro = false;
    SubscriptionIntent.pending = false;
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          if (call.method == 'logIn') {
            await pendingLogin?.future;
            if (failLogin) throw PlatformException(code: 'offline');
            customerId = (call.arguments as Map)['appUserID'] as String;
            return {'customerInfo': customerInfo(), 'created': false};
          }
          if (call.method == 'logOut' || call.method == 'getCustomerInfo') {
            return customerInfo();
          }
          return null;
        });
    await Supabase.initialize(
      url: 'https://example.invalid',
      publishableKey: 'test',
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
    );
    await setSession('bootstrap');
    await SubscriptionService.initialize(apiKey: 'test-unit-sdk-key');
  });

  tearDown(() async {
    await SubscriptionService.resetCustomer();
    await Supabase.instance.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'guests never identify, query, purchase or restore with RevenueCat',
    () async {
      await setSession('guest', anonymous: true);
      calls.clear();
      await SubscriptionService.identifyCustomer('guest');
      expect(await SubscriptionService.checkSubscriptionStatus(), isFalse);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        await container.read(subscriptionStatusProvider.future),
        SubscriptionStatus.signInRequired,
      );
      await expectLater(
        SubscriptionService.purchaseMonthlySubscription(),
        throwsStateError,
      );
      await expectLater(
        SubscriptionService.restorePurchases(),
        throwsStateError,
      );
      expect(calls, isEmpty);
    },
  );

  testWidgets(
    'subscription intent survives anonymous upgrade and opens paywall once',
    (tester) async {
      await setSession('guest', anonymous: true);
      await tester.pumpWidget(
        const AuthSessionScope(
          child: MaterialApp(
            home: SubscriptionEntry(child: Scaffold(body: Text('Ana ekran'))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      SubscriptionIntent.pending = true;
      await setSession('guest');
      await tester.pumpAndSettle();
      expect(find.text('Çetele Pro'), findsOneWidget);
      expect(SubscriptionIntent.pending, isFalse);
      expect(calls, isNot(contains('purchasePackage')));
      final context = tester.element(find.text('Çetele Pro'));
      Navigator.of(context).pop();
      await tester.pumpAndSettle();
      expect(find.text('Ana ekran'), findsOneWidget);
    },
  );

  testWidgets('account changes and same-id upgrades discard the entire cache', (
    tester,
  ) async {
    late ProviderContainer container;
    final child = Consumer(
      builder: (context, ref, _) {
        container = ProviderScope.containerOf(context);
        final revision = ref.watch(dataRevisionProvider);
        ref.watch(subscriptionStatusProvider);
        return MaterialApp(home: Text('Önbellek $revision'));
      },
    );
    await setSession('guest', anonymous: true);
    await tester.pumpWidget(AuthSessionScope(child: child));
    await tester.pumpAndSettle();
    final guestContainer = container;
    guestContainer.read(dataRevisionProvider.notifier).refresh();
    await tester.pump();
    expect(find.text('Önbellek 1'), findsOneWidget);

    await setSession('guest');
    await tester.pumpAndSettle();
    expect(identical(container, guestContainer), isFalse);
    expect(find.text('Önbellek 0'), findsOneWidget);
    final permanentContainer = container;

    // Token yenileme kullanıcı verilerini ve açık ekranları silmemeli.
    // Gerçek token yenileme olayını ağ çağrısı olmadan testte üret.
    // ignore: invalid_use_of_internal_member
    SupabaseService.client.auth.notifyAllSubscribers(
      AuthChangeEvent.tokenRefreshed,
    );
    await tester.pumpAndSettle();
    expect(identical(container, permanentContainer), isTrue);

    pendingLogin = Completer<void>();
    calls.clear();
    await setSession('another');
    await tester.pump();
    expect(find.text('Önbellek 0'), findsNothing);
    expect(calls, contains('logIn'));
    expect(calls, isNot(contains('getCustomerInfo')));
    pendingLogin!.complete();
    await tester.pumpAndSettle();
    expect(identical(container, permanentContainer), isFalse);
    expect(customerId, 'another');
    expect(
      calls.indexOf('getCustomerInfo'),
      greaterThan(calls.indexOf('logIn')),
    );
  });

  testWidgets(
    'offline sign-out still clears local account state and resets customer',
    (tester) async {
      late ProviderContainer container;
      await setSession('account');
      await tester.pumpWidget(
        AuthSessionScope(
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              ref.watch(dataRevisionProvider);
              return const MaterialApp(home: Text('Hazır'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final previous = container;
      calls.clear();
      // Widget test HTTP istemcisi 400 döndürür; yerel oturum yine silinmelidir.
      await tester.runAsync(() async {
        await expectLater(
          SupabaseService.signOut(),
          throwsA(isA<AuthException>()),
        );
      });
      await tester.pumpAndSettle();
      expect(SupabaseService.currentUser, isNull);
      expect(calls, contains('logOut'));
      expect(identical(container, previous), isFalse);
      expect(await SubscriptionService.checkSubscriptionStatus(), isFalse);
    },
  );

  test(
    'failed identify never queries the previous customer entitlements',
    () async {
      await setSession('previous');
      await SubscriptionService.identifyCustomer('previous');
      await setSession('new');
      failLogin = true;
      await SubscriptionService.identifyCustomer('new');
      calls.clear();
      expect(await SubscriptionService.checkSubscriptionStatus(), isFalse);
      expect(calls, isNot(contains('getCustomerInfo')));
    },
  );

  testWidgets('customer info events and app resume refresh derived Pro state', (
    tester,
  ) async {
    await setSession('account');
    await SubscriptionService.identifyCustomer('account');
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            return MaterialApp(
              home: Text(ref.watch(isProProvider) ? 'Pro' : 'Ücretsiz'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ücretsiz'), findsOneWidget);
    activePro = true;
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'purchases_flutter',
      const StandardMethodCodec().encodeMethodCall(
        MethodCall('Purchases-CustomerInfoUpdated', customerInfo()),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
    expect(find.text('Pro'), findsOneWidget);
    activePro = false;
    calls.clear();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Ücretsiz'), findsOneWidget);
    expect(calls, contains('invalidateCustomerInfoCache'));
    expect(calls, contains('getCustomerInfo'));
    expect(calls, isNot(contains('purchasePackage')));
  });
}
