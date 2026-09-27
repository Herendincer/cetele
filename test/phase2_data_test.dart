import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cetele/core/providers/data_providers.dart';
import 'package:cetele/core/services/subscription_service.dart';
import 'package:cetele/features/contacts/data/contacts_repository.dart';
import 'package:cetele/features/contacts/presentation/controllers/contacts_controller.dart';
import 'package:cetele/features/contacts/presentation/contacts_screen.dart';
import 'package:cetele/features/contacts/presentation/create_contact_screen.dart';
import 'package:cetele/features/contacts/presentation/models/contact_model.dart';
import 'package:cetele/features/cash_bank/data/accounts_repository.dart';
import 'package:cetele/features/cash_bank/data/transactions_repository.dart';
import 'package:cetele/features/cash_bank/presentation/controllers/cash_bank_controller.dart';
import 'package:cetele/features/cash_bank/presentation/cash_bank_screen.dart';
import 'package:cetele/features/cash_bank/presentation/create_transaction_screen.dart';
import 'package:cetele/features/cash_bank/presentation/create_account_screen.dart';
import 'package:cetele/features/cash_bank/presentation/models/account_model.dart';
import 'package:cetele/features/cash_bank/presentation/models/cash_transaction_model.dart';
import 'package:cetele/features/invoices/data/invoices_repository.dart';
import 'package:cetele/features/invoices/presentation/controllers/invoices_controller.dart';
import 'package:cetele/features/invoices/presentation/invoices_screen.dart';
import 'package:cetele/features/invoices/presentation/create_invoice_screen.dart';
import 'package:cetele/features/invoices/presentation/models/invoice_model.dart';
import 'package:cetele/features/invoices/presentation/models/invoice_type.dart';
import 'package:cetele/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:cetele/features/dashboard/presentation/dashboard_screen.dart';

const userId = '00000000-0000-0000-0000-000000000001';
const contact = ContactModel(
  id: 'contact',
  type: ContactType.both,
  name: 'Gerçek Cari',
  balance: 120,
);

class FakeContacts extends ContactsRepository {
  FakeContacts(super.client);
  List<ContactModel> rows = [contact];
  bool fail = false;
  final List<String> users = [];
  @override
  Future<List<ContactModel>> fetch(String userId) async {
    users.add(userId);
    if (fail) throw StateError('offline');
    return [...rows];
  }

  @override
  Future<void> save(
    String userId,
    ContactModel contact, {
    required bool isNew,
  }) async {
    users.add(userId);
    if (fail) throw StateError('offline');
    if (isNew) {
      rows.add(contact);
    } else {
      rows = [
        for (final c in rows)
          if (c.id == contact.id) contact else c,
      ];
    }
  }

  @override
  Future<void> delete(String userId, String id) async {
    rows.removeWhere((c) => c.id == id);
  }
}

class FakeAccounts extends AccountsRepository {
  FakeAccounts(super.client);
  List<AccountModel> rows = [
    AccountModel(
      id: 'account',
      name: 'Gerçek Kasa',
      type: AccountType.cash,
      openingBalance: 100,
      balance: 100,
      lastTransactionDate: DateTime(2026),
    ),
  ];
  @override
  Future<List<AccountModel>> fetch(String userId) async => [...rows];
  @override
  Future<void> save(
    String userId,
    AccountModel account, {
    required bool isNew,
  }) async {
    rows = [
      for (final a in rows)
        if (a.id != account.id) a,
      account,
    ];
  }

  @override
  Future<void> delete(String userId, String id) async {
    rows.removeWhere((a) => a.id == id);
  }
}

class FakeTransactions extends TransactionsRepository {
  FakeTransactions(super.client);
  List<CashTransactionModel> rows = [];
  @override
  Future<List<CashTransactionModel>> fetch(String userId) async => [...rows];
  @override
  Future<void> save(
    String userId,
    CashTransactionModel transaction, {
    required bool isNew,
  }) async {
    rows = [
      for (final t in rows)
        if (t.id != transaction.id) t,
      transaction,
    ];
  }

  @override
  Future<void> delete(String userId, String id) async {
    rows.removeWhere((t) => t.id == id);
  }
}

class FakeInvoices extends InvoicesRepository {
  FakeInvoices(super.client);
  List<InvoiceModel> rows = [];
  InvoiceStatus? lastStatus;
  @override
  Future<int> countMonthlySalesInvoices() async =>
      rows.where((invoice) => invoice.type == InvoiceType.sales).length;
  @override
  Future<List<InvoiceModel>> fetch(String userId) async => [...rows];
  @override
  Future<void> create(String userId, InvoiceModel invoice) async {
    rows.add(invoice);
  }

  @override
  Future<void> updateStatus(
    String userId,
    String id,
    InvoiceStatus status,
  ) async {
    lastStatus = status;
  }

  @override
  Future<void> delete(String userId, String id) async {
    rows.removeWhere((i) => i.id == id);
  }
}

class FreeSubscription extends SubscriptionStatusController {
  @override
  Future<SubscriptionStatus> build() async => SubscriptionStatus.free;
}

void main() {
  late SupabaseClient client;
  late FakeContacts contacts;
  late FakeAccounts accounts;
  late FakeTransactions transactions;
  late FakeInvoices invoices;
  late ProviderContainer container;

  setUpAll(() => initializeDateFormatting('tr_TR'));
  setUp(() async {
    // Yalnızca repository constructor'ları için; testler ağ isteği göndermez.
    client = SupabaseClient('http://localhost:54321', 'test-only-key');
    contacts = FakeContacts(client);
    accounts = FakeAccounts(client);
    transactions = FakeTransactions(client);
    invoices = FakeInvoices(client);
    container = ProviderContainer(
      retry: (count, error) => null,
      overrides: [
        subscriptionStatusProvider.overrideWith(FreeSubscription.new),
        sessionUserIdProvider.overrideWith((ref) => Stream.value(userId)),
        contactsRepositoryProvider.overrideWithValue(contacts),
        accountsRepositoryProvider.overrideWithValue(accounts),
        transactionsRepositoryProvider.overrideWithValue(transactions),
        invoicesRepositoryProvider.overrideWithValue(invoices),
      ],
    );
    container.listen(sessionUserIdProvider, (_, _) {});
    await container.read(sessionUserIdProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await client.dispose();
  });

  test('contact writes omit derived balance and dashboard refreshes after mutations', () async {
    expect(contact.toJson().containsKey('balance'), isFalse);
    expect(
      (await container.read(dashboardControllerProvider.future))
          .totalReceivables,
      120,
    );
    await container.read(contactsControllerProvider.future);
    expect(
      await container
          .read(contactsControllerProvider.notifier)
          .delete(contact.id),
      isTrue,
    );
    expect(
      (await container.read(dashboardControllerProvider.future))
          .totalReceivables,
      0,
    );
    expect(contacts.users.every((u) => u == userId), isTrue);
  });

  test(
    'transaction create, edit and delete update accounts and dashboard',
    () async {
      await container.read(cashBankControllerProvider.future);
      final controller = container.read(cashBankControllerProvider.notifier);
      CashTransactionModel tx(double amount) => CashTransactionModel(
        id: 'tx',
        type: CashTransactionType.collection,
        contactName: contact.name,
        contactId: contact.id,
        accountId: 'account',
        accountName: 'Gerçek Kasa',
        amount: amount,
        date: DateTime.now(),
      );
      expect(await controller.saveTransaction(tx(50), isNew: true), isTrue);
      expect(
        (await container.read(accountsProvider.future)).single.balance,
        150,
      );
      expect(
        (await container.read(dashboardControllerProvider.future))
            .cashAndBankBalance,
        150,
      );
      expect(await controller.saveTransaction(tx(70), isNew: false), isTrue);
      expect(
        (await container.read(accountsProvider.future)).single.balance,
        170,
      );
      expect(await controller.deleteTransaction('tx'), isTrue);
      expect(
        (await container.read(dashboardControllerProvider.future))
            .cashAndBankBalance,
        100,
      );
    },
  );

  test('discount is serialized and stored line total is authoritative', () {
    const item = InvoiceItemModel(
      description: 'Ürün',
      quantity: 2,
      unitPrice: 100,
      vatRate: 20,
      discountPercent: 10,
    );
    expect(item.total, 216);
    expect(item.toJson()['discount_percent'], 10);
    expect(
      InvoiceItemModel.fromJson({...item.toJson(), 'line_total': 215.99}).total,
      215.99,
    );
    expect(
      AccountModel.fromJson({
        'id': 'a',
        'name': 'Kasa',
        'type': 'cash',
        'opening_balance': 12345,
        'created_at': '2026-09-26T00:00:00Z',
      }).openingBalance,
      123.45,
    );
  });

  test(
    'invoice mutations refresh recent activity and use status controller',
    () async {
      expect(await container.read(recentActivitiesProvider.future), isEmpty);
      await container.read(invoicesControllerProvider.future);
      final controller = container.read(invoicesControllerProvider.notifier);
      final invoice = InvoiceModel(
        id: 'invoice',
        number: 'F-1',
        type: InvoiceType.sales,
        contactName: contact.name,
        contactId: contact.id,
        issueDate: DateTime.now(),
      );
      expect(await controller.create(invoice), isTrue);
      expect(
        (await container.read(recentActivitiesProvider.future))
            .single
            .invoiceOrNull
            ?.number,
        'F-1',
      );
      expect(
        await controller.updateStatus('invoice', InvoiceStatus.approved),
        isTrue,
      );
      expect(invoices.lastStatus, InvoiceStatus.approved);
      expect(await controller.delete('invoice'), isTrue);
      expect(await container.read(recentActivitiesProvider.future), isEmpty);
    },
  );

  test('failed mutation preserves data and can be retried', () async {
    await container.read(contactsControllerProvider.future);
    contacts.fail = true;
    final controller = container.read(contactsControllerProvider.notifier);
    expect(await controller.save(contact, isNew: false), isFalse);
    expect(container.read(contactsControllerProvider).hasError, isTrue);
    contacts.fail = false;
    expect(await controller.save(contact, isNew: false), isTrue);
    expect(container.read(contactsControllerProvider).hasError, isFalse);
  });

  testWidgets(
    'contacts show an error, retry real source, and show empty state',
    (tester) async {
      contacts.fail = true;
      await tester.pumpWidget(
        ProviderScope(
          retry: (count, error) => null,
          overrides: [
            sessionUserIdProvider.overrideWith((ref) => Stream.value(userId)),
            contactsRepositoryProvider.overrideWithValue(contacts),
            accountsRepositoryProvider.overrideWithValue(accounts),
            transactionsRepositoryProvider.overrideWithValue(transactions),
            invoicesRepositoryProvider.overrideWithValue(invoices),
          ],
          child: const MaterialApp(home: ContactsScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tekrar dene'), findsOneWidget);
      contacts.fail = false;
      contacts.rows = [];
      await tester.tap(find.text('Tekrar dene'));
      await tester.pumpAndSettle();
      expect(find.text('Kayıtlı cari bulunamadı'), findsWidgets);
      expect(find.text('Aslan Tekstil Ltd. Şti.'), findsNothing);
    },
  );

  testWidgets('contact balance is read-only and fetched from the provider', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (count, error) => null,
        overrides: [
          sessionUserIdProvider.overrideWith((ref) => Stream.value(userId)),
          contactsRepositoryProvider.overrideWithValue(contacts),
          accountsRepositoryProvider.overrideWithValue(accounts),
          transactionsRepositoryProvider.overrideWithValue(transactions),
          invoicesRepositoryProvider.overrideWithValue(invoices),
        ],
        child: const MaterialApp(
          home: CreateContactScreen(existingContact: contact),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Güncel Bakiye'));
    expect(find.text('Güncel Bakiye'), findsOneWidget);
    expect(find.text('Açılış Bakiyesi'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(6));
  });

  testWidgets('transaction pickers use actual contact/account ids', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (count, error) => null,
        overrides: [
          sessionUserIdProvider.overrideWith((ref) => Stream.value(userId)),
          contactsRepositoryProvider.overrideWithValue(contacts),
          accountsRepositoryProvider.overrideWithValue(accounts),
          transactionsRepositoryProvider.overrideWithValue(transactions),
          invoicesRepositoryProvider.overrideWithValue(invoices),
        ],
        child: const MaterialApp(home: CreateTransactionScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    expect(find.text(contact.name), findsWidgets);
    expect(find.text('Aslan Tekstil Ltd. Şti.'), findsNothing);
  });

  testWidgets('new contact is saved before returning to the real list', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        retry: (count, error) => null,
        overrides: [
          sessionUserIdProvider.overrideWith((ref) => Stream.value(userId)),
          contactsRepositoryProvider.overrideWithValue(contacts),
          accountsRepositoryProvider.overrideWithValue(accounts),
          transactionsRepositoryProvider.overrideWithValue(transactions),
          invoicesRepositoryProvider.overrideWithValue(invoices),
        ],
        child: const MaterialApp(home: ContactsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cari Ekle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Yeni Kalıcı Cari',
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(contacts.rows.any((c) => c.name == 'Yeni Kalıcı Cari'), isTrue);
    expect(find.text('Cariler'), findsOneWidget);
    expect(find.text('Yeni Kalıcı Cari'), findsOneWidget);
  });

  for (final entry in <String, Widget>{
    'contacts': const ContactsScreen(),
    'cash': const CashBankScreen(),
    'invoices': const InvoicesScreen(),
    'dashboard': const DashboardScreen(),
    'contact form': const CreateContactScreen(existingContact: contact),
    'account form': const CreateAccountScreen(),
    'invoice form': const CreateInvoiceScreen(),
    'transaction form': const CreateTransactionScreen(),
  }.entries) {
    testWidgets('${entry.key} loads at 320px without widget exceptions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          retry: (count, error) => null,
          overrides: [
            sessionUserIdProvider.overrideWith((ref) => Stream.value(userId)),
            contactsRepositoryProvider.overrideWithValue(contacts),
            accountsRepositoryProvider.overrideWithValue(accounts),
            transactionsRepositoryProvider.overrideWithValue(transactions),
            invoicesRepositoryProvider.overrideWithValue(invoices),
          ],
          child: MaterialApp(home: entry.value),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
