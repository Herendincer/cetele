import 'package:flutter/material.dart';

import '../../../core/services/pdf_invoice_service.dart';
import '../../../core/utils/currency_helper.dart';
import 'models/contact_model.dart';
import '../../cash_bank/presentation/models/cash_transaction_model.dart';

class ContactDetailScreen extends StatefulWidget {
  const ContactDetailScreen({super.key, required this.contact, required this.transactions});

  final ContactModel contact;
  final List<CashTransactionModel> transactions;

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  bool _isPrinting = false;

  Future<void> _printStatement() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      await PdfContactStatementService.printStatement(
        contact: widget.contact,
        transactions: widget.transactions,
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = CurrencyHelper.formatFromKurus(
      CurrencyHelper.liraToKurus(widget.contact.balance.abs()),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact.name),
        actions: [
          IconButton(
            tooltip: 'Ekstre Yazdır',
            icon: _isPrinting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.print_outlined),
            onPressed: _printStatement,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(widget.contact.name),
              subtitle: Text(widget.contact.type.label),
              trailing: Text(
                widget.contact.balance == 0
                    ? 'Bakiye yok'
                    : '${widget.contact.balance > 0 ? 'Alacak' : 'Borç'}: $balance',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Hareketler', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (widget.transactions.isEmpty)
            const Card(child: ListTile(title: Text('Kayıtlı hareket bulunmuyor')))
          else
            for (final transaction in widget.transactions)
              Card(
                child: ListTile(
                  title: Text(transaction.type.label),
                  subtitle: Text(transaction.description.isEmpty ? transaction.accountName : transaction.description),
                  trailing: Text(CurrencyHelper.formatFromKurus(
                    CurrencyHelper.liraToKurus(transaction.amount),
                  )),
                ),
              ),
        ],
      ),
    );
  }
}