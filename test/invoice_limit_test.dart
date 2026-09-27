import 'package:cetele/core/providers/data_providers.dart';
import 'package:cetele/core/services/subscription_service.dart';
import 'package:cetele/features/cash_bank/data/accounts_repository.dart';
import 'package:cetele/features/cash_bank/data/transactions_repository.dart';
import 'package:cetele/features/contacts/data/contacts_repository.dart';
import 'package:cetele/features/dashboard/presentation/dashboard_screen.dart';
import 'package:cetele/features/invoices/data/invoices_repository.dart';
import 'package:cetele/features/invoices/presentation/controllers/invoice_creation_policy.dart';
import 'package:cetele/features/invoices/presentation/controllers/invoice_usage_provider.dart';
import 'package:cetele/features/invoices/presentation/controllers/invoices_controller.dart';
import 'package:cetele/features/invoices/presentation/create_invoice_screen.dart';
import 'package:cetele/features/invoices/presentation/invoices_screen.dart';
import 'package:cetele/features/invoices/presentation/models/invoice_model.dart';
import 'package:cetele/features/invoices/presentation/models/invoice_type.dart';
import 'package:cetele/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'phase2_data_test.dart'
    show FakeContacts, FakeAccounts, FakeTransactions, FakeInvoices;

class QuotaInvoices extends FakeInvoices {
  QuotaInvoices(super.client);
  int usage = 0;
  int countCalls = 0;
  bool failCount = false;

  @override
  Future<int> countMonthlySalesInvoices() async {
    countCalls++;
    if (failCount) throw StateError('Sunucuya ulaşılamadı');
    return usage;
  }

  @override
  Future<void> create(String userId, InvoiceModel invoice) async {
    await super.create(userId, invoice);
    if (invoice.type == InvoiceType.sales) usage++;
  }
}

class TestPlan extends SubscriptionStatusController {
  TestPlan(this.plan);
  final SubscriptionStatus plan;
  @override
  Future<SubscriptionStatus> build() async => plan;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SupabaseClient client;
  late QuotaInvoices repository;
  late ProviderContainer container;
  SubscriptionStatus plan = SubscriptionStatus.free;

  ProviderContainer createContainer({String? userId = 'user'}) {
    final result = ProviderContainer(
      overrides: [
        sessionUserIdProvider.overrideWith((ref) => Stream.value(userId)),
        invoicesRepositoryProvider.overrideWithValue(repository),
        subscriptionStatusProvider.overrideWith(() => TestPlan(plan)),
      ],
    );
    result.listen(sessionUserIdProvider, (_, _) {});
    return result;
  }

  Widget app(Widget child) => ProviderScope(
    overrides: [
      sessionUserIdProvider.overrideWith((ref) => Stream.value('user')),
      invoicesRepositoryProvider.overrideWithValue(repository),
      contactsRepositoryProvider.overrideWithValue(FakeContacts(client)),
      accountsRepositoryProvider.overrideWithValue(FakeAccounts(client)),
      transactionsRepositoryProvider.overrideWithValue(
        FakeTransactions(client),
      ),
      subscriptionStatusProvider.overrideWith(() => TestPlan(plan)),
    ],
    child: MaterialApp(home: child),
  );

  InvoiceModel invoice([InvoiceType type = InvoiceType.sales]) => InvoiceModel(
    id: 'invoice',
    number: 'F-1',
    type: type,
    contactName: 'Cari',
    issueDate: DateTime.now(),
  );

  setUpAll(() => initializeDateFormatting('tr_TR'));
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
    client = Supabase.instance.client;
    repository = QuotaInvoices(client);
    plan = SubscriptionStatus.free;
    container = createContainer();
    await container.read(sessionUserIdProvider.future);
    await container.read(invoicesControllerProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await Supabase.instance.dispose();
  });

  test('free account can create fifth invoice but not sixth', () async {
    repository.usage = 4;
    final controller = container.read(invoicesControllerProvider.notifier);
    expect(await controller.create(invoice()), isTrue);
    expect(await controller.create(invoice()), isFalse);
    expect(repository.rows, hasLength(1));
    expect(
      container.read(invoicesControllerProvider).error,
      isA<SalesInvoiceLimitReached>(),
    );
  });

  test(
    'creation refreshes stale usage instead of trusting cached count',
    () async {
      repository.usage = 4;
      expect(await container.read(monthlySalesInvoiceCountProvider.future), 4);
      repository.usage = 5;
      expect(
        await container
            .read(invoicesControllerProvider.notifier)
            .create(invoice()),
        isFalse,
      );
      expect(repository.rows, isEmpty);
    },
  );

  test('Pro sales and purchase invoices bypass quota RPC', () async {
    repository.usage = 99;
    expect(
      await container
          .read(invoicesControllerProvider.notifier)
          .create(invoice(InvoiceType.purchase)),
      isTrue,
    );
    expect(repository.countCalls, 0);
    container.dispose();
    plan = SubscriptionStatus.pro;
    container = createContainer();
    await container.read(sessionUserIdProvider.future);
    await container.read(invoicesControllerProvider.future);
    expect(
      await container
          .read(invoicesControllerProvider.notifier)
          .create(invoice()),
      isTrue,
    );
    expect(repository.countCalls, 0);
  });

  test('RPC errors block new sales without writing an invoice', () async {
    repository.failCount = true;
    expect(
      await container
          .read(invoicesControllerProvider.notifier)
          .create(invoice()),
      isFalse,
    );
    expect(repository.rows, isEmpty);
  });

  test(
    'existing invoice updates and deletion remain allowed above quota',
    () async {
      repository.usage = 99;
      final controller = container.read(invoicesControllerProvider.notifier);
      expect(
        await controller.updateStatus('invoice', InvoiceStatus.paid),
        isTrue,
      );
      expect(await controller.delete('invoice'), isTrue);
      expect(repository.countCalls, 0);
    },
  );

  test('missing session returns empty usage and cannot create', () async {
    container.dispose();
    container = createContainer(userId: null);
    await container.read(sessionUserIdProvider.future);
    expect(await container.read(monthlySalesInvoiceCountProvider.future), 0);
    await container.read(invoicesControllerProvider.future);
    expect(
      await container
          .read(invoicesControllerProvider.notifier)
          .create(invoice()),
      isFalse,
    );
    expect(repository.countCalls, 0);
  });

  testWidgets('sales list opens paywall instead of form at five', (
    tester,
  ) async {
    repository.usage = 5;
    await tester.pumpWidget(app(const InvoicesScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fatura Oluştur'));
    await tester.pumpAndSettle();
    expect(find.text('Bu ay ücretsiz fatura hakkınız doldu'), findsOneWidget);
    expect(find.byType(CreateInvoiceScreen), findsNothing);
  });

  testWidgets('purchase form opens at five but cannot switch to sales', (
    tester,
  ) async {
    repository.usage = 5;
    await tester.pumpWidget(app(const InvoicesScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alış Faturaları'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fatura Oluştur'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateInvoiceScreen), findsOneWidget);
    expect(repository.countCalls, 0);
    await tester.tap(find.text('Satış'));
    await tester.pumpAndSettle();
    expect(find.text('Bu ay ücretsiz fatura hakkınız doldu'), findsOneWidget);
  });

  testWidgets('dashboard quick action also respects quota', (tester) async {
    repository.usage = 5;
    await tester.pumpWidget(app(const DashboardScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Satış Faturası Oluştur'));
    await tester.pumpAndSettle();
    expect(find.text('Bu ay ücretsiz fatura hakkınız doldu'), findsOneWidget);
  });

  testWidgets(
    'settings shows server usage and refreshes after returning to app',
    (tester) async {
      repository.usage = 4;
      await tester.pumpWidget(app(const SettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Bu ay satış faturası: 4 / 5'), findsOneWidget);
      repository.usage = 5;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Bu ay satış faturası: 5 / 5'), findsOneWidget);
    },
  );

  testWidgets('settings count failure can be retried', (tester) async {
    repository.failCount = true;
    await tester.pumpWidget(app(const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Fatura kullanımı alınamadı.'), findsOneWidget);
    repository.failCount = false;
    repository.usage = 2;
    await tester.tap(find.byTooltip('Fatura kullanımını yenile'));
    await tester.pumpAndSettle();
    expect(find.text('Bu ay satış faturası: 2 / 5'), findsOneWidget);
  });

  testWidgets(
    'Pro settings hides quota and exposes subscription management at 320px',
    (tester) async {
      plan = SubscriptionStatus.pro;
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app(const SettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Pro'), findsOneWidget);
      expect(find.text('Aboneliği Yönet'), findsOneWidget);
      expect(find.textContaining('Bu ay satış faturası:'), findsNothing);
      expect(repository.countCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
