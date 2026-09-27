import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_constants.dart';
import 'core/services/subscription_service.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/app_shell.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/auth/screens/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await SupabaseService.initialize();
  try {
    await SubscriptionService.initialize();
  } catch (_) {
    // RevenueCat başlatılamasa bile Supabase oturumu ve uygulama akışı devam etmeli.
  }
  SupabaseService.authStateChanges.listen((authState) {
    final userId = authState.session?.user.id;
    if (userId != null) {
      SubscriptionService.identifyCustomer(userId);
    }
  });
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    ref.watch(authStateProvider);
    final user = SupabaseService.currentUser;
    return MaterialApp(
      // Hesap değiştiğinde açık detay/form rotalarını ve ekran durumunu da sil.
      key: ValueKey(user?.id),
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode.themeMode,
      home: user == null ? const AuthScreen() : const AppShell(),
    );
  }
}
