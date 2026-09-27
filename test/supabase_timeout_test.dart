import 'dart:async';

import 'package:cetele/core/providers/data_providers.dart';
import 'package:cetele/core/services/supabase_request.dart';
import 'package:cetele/features/contacts/data/contacts_repository.dart';
import 'package:cetele/features/contacts/presentation/contacts_screen.dart';
import 'package:cetele/features/contacts/presentation/models/contact_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PendingRequest<T> extends PostgrestBuilder<T, T, T> {
  PendingRequest()
    : super(url: Uri.parse('https://example.invalid'), headers: {});

  final result = Completer<T>();
  final cancellation = Completer<void>();
  bool get aborted => cancellation.isCompleted;

  @override
  PostgrestBuilder<T, T, T> abortSignal(Future<void> abortSignal) {
    abortSignal.then((_) => cancellation.complete());
    return this;
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) =>
      result.future.then(onValue, onError: onError);
}

class OfflineContacts extends ContactsRepository {
  OfflineContacts(super.client);
  final pending = PendingRequest<List<ContactModel>>();
  bool online = false;
  int calls = 0;

  @override
  Future<List<ContactModel>> fetch(String userId) {
    calls++;
    if (online) return Future.value([]);
    return pending.withRequestTimeout();
  }
}

void main() {
  late SupabaseClient client;
  setUp(() {
    client = SupabaseClient(
      'https://example.invalid',
      'test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });
  tearDown(() => client.dispose());

  testWidgets('successful request completes without aborting', (tester) async {
    final request = PendingRequest<int>();
    final result = request.withRequestTimeout();
    request.result.complete(42);
    expect(await result, 42);
    await tester.pump(supabaseRequestTimeout);
    expect(request.aborted, isFalse);
  });

  testWidgets('offline request reaches stable retry state and retries online', (
    tester,
  ) async {
    final repository = OfflineContacts(client);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionUserIdProvider.overrideWith((ref) => Stream.value('user')),
          contactsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: ContactsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(supabaseRequestTimeout - const Duration(milliseconds: 1));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Tekrar dene'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(repository.pending.aborted, isTrue);
    expect(find.text('Tekrar dene'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Geç gelen sonuç hatayı temizlemez; otomatik yeniden deneme başlamaz.
    repository.pending.result.complete([]);
    await tester.pump(const Duration(minutes: 1));
    expect(repository.calls, 1);
    expect(find.text('Tekrar dene'), findsOneWidget);

    repository.online = true;
    await tester.tap(find.text('Tekrar dene'));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.text('Tekrar dene'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
