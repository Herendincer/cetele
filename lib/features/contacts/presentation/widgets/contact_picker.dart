import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/async_content.dart';
import '../controllers/contacts_controller.dart';
import '../models/contact_model.dart';

class ContactPicker extends ConsumerWidget {
  const ContactPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      AsyncContent<List<ContactModel>>(
        value: ref.watch(contactsProvider),
        onRetry: () => ref.invalidate(contactsProvider),
        data: (contacts) {
          if (contacts.isEmpty) {
            return const Text(
              'Kayıtlı cari yok. Önce Cariler ekranından cari ekleyin.',
            );
          }
          final selected = contacts.any((c) => c.id == value) ? value : null;
          return DropdownButtonFormField<String>(
            key: ValueKey(selected),
            initialValue: selected,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'İlgili Cari'),
            items: contacts
                .map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            validator: (id) => id == null ? 'Lütfen bir cari seçin' : null,
            onChanged: onChanged,
          );
        },
      );
}
