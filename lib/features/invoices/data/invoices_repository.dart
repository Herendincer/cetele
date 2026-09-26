import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/data_providers.dart';
import '../presentation/models/invoice_model.dart';

class InvoicesRepository {
  InvoicesRepository(this.client);
  final SupabaseClient client;

  Future<List<InvoiceModel>> fetch(String userId) async {
    final rows = await client
        .from('invoices')
        .select(
          '*, contacts!invoices_contact_id_fkey(name,tax_number,address,phone), invoice_items(*)',
        )
        .eq('user_id', userId)
        .order('issue_date', ascending: false)
        .order('created_at', ascending: false);
    return rows.map(InvoiceModel.fromJson).toList();
  }

  Future<void> create(String userId, InvoiceModel invoice) async {
    // RPC kullanıcıyı auth.uid() ile belirler; fatura + kalemler atomiktir.
    await client.rpc(
      'create_invoice_with_items',
      params: {
        'p_invoice_number': invoice.number,
        'p_type': invoice.type.name,
        'p_contact_id': invoice.contactId,
        'p_status': invoice.status.name,
        'p_issue_date': invoice.issueDate.toIso8601String().substring(0, 10),
        'p_due_date': invoice.dueDate?.toIso8601String().substring(0, 10),
        'p_subtotal': invoice.subtotal,
        'p_vat_amount': invoice.totalVat,
        'p_total_amount': invoice.grandTotal,
        'p_notes': invoice.notes,
        'p_items': invoice.items.map((item) => item.toJson()).toList(),
      },
    );
  }

  Future<void> updateStatus(
    String userId,
    String id,
    InvoiceStatus status,
  ) async {
    await client
        .from('invoices')
        .update({'status': status.name})
        .eq('user_id', userId)
        .eq('id', id)
        .select()
        .single();
  }

  Future<void> delete(String userId, String id) async {
    await client
        .from('invoices')
        .delete()
        .eq('user_id', userId)
        .eq('id', id)
        .select()
        .single();
  }
}

final invoicesRepositoryProvider = Provider<InvoicesRepository>(
  (ref) => InvoicesRepository(ref.watch(supabaseClientProvider)),
);
