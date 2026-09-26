import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_content.dart';
import '../../../core/widgets/app_snackbar.dart';
import 'controllers/contacts_controller.dart';
import '../../cash_bank/data/transactions_repository.dart';

import '../../../core/services/pdf_invoice_service.dart';
import '../../../core/utils/currency_helper.dart';
import 'models/contact_model.dart';
import '../../cash_bank/presentation/models/cash_transaction_model.dart';

class ContactDetailScreen extends ConsumerStatefulWidget {
  const ContactDetailScreen({super.key, required this.contact});

  final ContactModel contact;

  @override
  ConsumerState<ContactDetailScreen> createState() =>
      _ContactDetailScreenState();
}

class _ContactDetailScreenState extends ConsumerState<ContactDetailScreen> {
  bool _isPrinting = false;

  Future<void> _printStatement(
    ContactModel contact,
    List<CashTransactionModel> transactions,
  ) async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      await PdfContactStatementService.printStatement(
        contact: contact,
        transactions: transactions,
      );
    } catch (_) {
      if (mounted) AppSnackBar.showError(context, 'Ekstre hazırlanamadı');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncContent<ContactModel?>(
      value: ref.watch(contactProvider(widget.contact.id)),
      onRetry: () => ref.invalidate(contactsProvider),
      data: (contact) {
        if (contact == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Cari')),
            body: const Center(child: Text('Cari bulunamadı')),
          );
        }
        return AsyncContent<List<CashTransactionModel>>(
          value: ref.watch(transactionsProvider),
          onRetry: () => ref.invalidate(transactionsProvider),
          data: (rows) => _buildDetail(
            contact,
            rows.where((t) => t.contactId == contact.id).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDetail(
    ContactModel contact,
    List<CashTransactionModel> transactions,
  ) {
    final balance = CurrencyHelper.formatFromKurus(
      CurrencyHelper.liraToKurus(contact.balance.abs()),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(contact.name),
        actions: [
          IconButton(
            tooltip: 'Ekstre Yazdır',
            icon: _isPrinting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_outlined),
            onPressed: () => _printStatement(contact, transactions),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(contact.name),
              subtitle: Text(contact.type.label),
              trailing: SizedBox(
                width: 150,
                child: Text(
                  contact.balance == 0
                      ? 'Bakiye yok'
                      : '${contact.balance > 0 ? 'Alacak' : 'Borç'}: $balance',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Hareketler', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (transactions.isEmpty)
            const Card(
              child: ListTile(title: Text('Kayıtlı hareket bulunmuyor')),
            )
          else
            for (final transaction in transactions)
              Card(
                child: ListTile(
                  title: Text(transaction.type.label),
                  subtitle: Text(
                    transaction.description.isEmpty
                        ? transaction.accountName
                        : transaction.description,
                  ),
                  trailing: SizedBox(
                    width: 150,
                    child: Text(
                      CurrencyHelper.formatFromKurus(
                        CurrencyHelper.liraToKurus(transaction.amount),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
