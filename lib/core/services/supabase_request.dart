import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseRequestTimeout = Duration(seconds: 12);

extension SupabaseRequestDeadline<T, S, R> on PostgrestBuilder<T, S, R> {
  Future<T> withRequestTimeout() {
    final abort = Completer<void>();
    return abortSignal(abort.future).timeout(
      supabaseRequestTimeout,
      onTimeout: () {
        // Bekleyen HTTP isteği yeniden bağlantıda arka planda sürdürülmesin.
        // Sunucunun zaten işlediği bir yazmayı geri almaz.
        abort.complete();
        throw TimeoutException(
          'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.',
          supabaseRequestTimeout,
        );
      },
    );
  }
}
