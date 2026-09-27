import 'dart:async';
import 'dart:convert';

import 'package:cetele/core/providers/data_providers.dart';
import 'package:cetele/core/services/subscription_service.dart';
import 'package:cetele/core/services/supabase_service.dart';
import 'package:cetele/features/auth/screens/auth_session_scope.dart';
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
  String customerId = '';

  Map<String, dynamic> customerInfo() => {
    'entitlements': {'all': {}, 'active': {}},
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
    await SubscriptionService.initialize();
  });

  tearDown(() async {
    await SubscriptionService.resetCustomer();
    await Supabase.instance.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

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
}
