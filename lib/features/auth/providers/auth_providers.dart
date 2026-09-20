import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';

/// Supabase auth durumundaki değişiklikleri (misafir → Google vb.) dinler.
final authStateProvider = StreamProvider<AuthState>(
  (ref) => SupabaseService.authStateChanges,
);
