import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncContent<T> extends StatelessWidget {
  const AsyncContent({
    super.key,
    required this.value,
    required this.onRetry,
    required this.data,
    this.pageTitle,
  });

  final String? pageTitle;
  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T) data;

  Widget _fallback(Widget child) => pageTitle == null
      ? child
      : Scaffold(
          appBar: AppBar(title: Text(pageTitle!)),
          body: child,
        );

  @override
  Widget build(BuildContext context) => value.when(
    skipLoadingOnRefresh: false,
    loading: () => _fallback(const Center(child: CircularProgressIndicator())),
    error: (_, _) => _fallback(
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Veriler yüklenemedi. Lütfen tekrar deneyin.',
              textAlign: TextAlign.center,
            ),
            TextButton(onPressed: onRetry, child: const Text('Tekrar dene')),
          ],
        ),
      ),
    ),
    data: data,
  );
}

class MutationError extends StatelessWidget {
  const MutationError({super.key, required this.value, required this.onRetry});
  final AsyncValue<void> value;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => value.hasError
      ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'İşlem tamamlanamadı. Lütfen tekrar deneyin.',
              textAlign: TextAlign.center,
            ),
            TextButton(onPressed: onRetry, child: const Text('Tekrar dene')),
          ],
        )
      : const SizedBox.shrink();
}
