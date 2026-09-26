import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncContent<T> extends StatelessWidget {
  const AsyncContent({
    super.key,
    required this.value,
    required this.onRetry,
    required this.data,
  });

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T) data;

  @override
  Widget build(BuildContext context) => value.when(
    skipLoadingOnRefresh: false,
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, _) => Center(
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
