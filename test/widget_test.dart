// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cetele/main.dart';
import 'package:cetele/core/widgets/app_shell.dart';
import 'package:cetele/features/auth/screens/existing_account_dialog.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr_TR', null);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
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
  });

  tearDown(() => Supabase.instance.dispose());

  testWidgets('cold start shows auth options at 320px without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    expect(find.text('Google ile Giriş Yap'), findsOneWidget);
    expect(find.text('Hesap oluşturmadan devam et'), findsOneWidget);
    expect(find.text('Genel Durum'), findsNothing);
    expect(Supabase.instance.client.auth.currentSession, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing account dialog cancels safely on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                confirmed = await confirmExistingAccount(context);
              },
              child: const Text('Göster'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Göster'));
    await tester.pumpAndSettle();
    expect(find.textContaining('birleştirilmeyecek'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(confirmed, isFalse);
  });

  testWidgets('app shell opens settings and exposes theme selection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AppShell())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Genel Durum'), findsWidgets);
    await tester.tap(find.text('Ayarlar').last);
    await tester.pumpAndSettle();

    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Sistem Teması'), findsOneWidget);
  });
}
