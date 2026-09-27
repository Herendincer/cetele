import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

// Hata ekranı otomatik tekrar denemeyle yeniden yükleme durumuna dönmesin.
// Veri okumaları ekrandaki "Tekrar dene" veya yenileme işlemiyle tekrarlanır.
Duration? manualDataRetry(int retryCount, Object error) => null;

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => SupabaseService.client,
);

// Oturumun geri yüklenmesini ve kullanıcı değişimini tüm veri kaynaklarına iletir.
final sessionUserIdProvider = StreamProvider<String?>((ref) async* {
  final client = ref.watch(supabaseClientProvider);
  yield client.auth.currentUser?.id;
  yield* client.auth.onAuthStateChange
      .map((event) => event.session?.user.id)
      .distinct();
});

class DataRevision extends Notifier<int> {
  @override
  int build() => 0;

  void refresh() => state++;
}

final dataRevisionProvider = NotifierProvider<DataRevision, int>(
  DataRevision.new,
);

Future<String> requireSession(Ref ref) async {
  final id = await ref.read(sessionUserIdProvider.future);
  if (id == null) throw StateError('Kullanıcı oturumu bulunamadı');
  return id;
}
