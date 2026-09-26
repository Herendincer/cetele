import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_helper.dart';
import 'create_invoice_screen.dart';
import 'invoice_details_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_content.dart';
import 'controllers/invoices_controller.dart';
import 'models/invoice_model.dart';
import 'models/invoice_type.dart';

/// Satış ve alış faturalarını sekmeli şekilde listeleyen ekran.
class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  void _openCreateInvoice(BuildContext context) {
    final int activeTab = DefaultTabController.of(context).index;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateInvoiceScreen(
          initialType: activeTab == 0
              ? InvoiceType.sales
              : InvoiceType.purchase,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Faturalar'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Satış Faturaları'),
              Tab(text: 'Alış Faturaları'),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton.extended(
            onPressed: () => _openCreateInvoice(context),
            icon: const Icon(Icons.add),
            label: const Text('Fatura Oluştur'),
          ),
        ),
        body: AsyncContent<List<InvoiceModel>>(
          value: ref.watch(invoicesProvider),
          onRetry: () => ref.invalidate(invoicesProvider),
          data: (invoices) => TabBarView(
            children: [
              _InvoiceList(
                invoices: invoices
                    .where((invoice) => invoice.type == InvoiceType.sales)
                    .toList(),
              ),
              _InvoiceList(
                invoices: invoices
                    .where((invoice) => invoice.type == InvoiceType.purchase)
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceList extends StatelessWidget {
  const _InvoiceList({required this.invoices});

  final List<InvoiceModel> invoices;

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const Center(child: Text('Kayıtlı fatura bulunamadı'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: invoices.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        final bool isSales = invoice.type == InvoiceType.sales;
        final int kurus = CurrencyHelper.liraToKurus(invoice.grandTotal);
        return Card(
          child: ListTile(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InvoiceDetailsScreen(invoice: invoice),
              ),
            ),
            title: Text(
              invoice.contactName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '#${invoice.number} · ${DateFormat('d MMM yyyy', 'tr_TR').format(invoice.issueDate)}',
            ),
            trailing: SizedBox(
              width: 130,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyHelper.formatFromKurus(kurus),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSales
                          ? AppTheme.incomeColor
                          : AppTheme.expenseColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusBadge(status: invoice.status),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      InvoiceStatus.paid => AppTheme.incomeColor,
      InvoiceStatus.approved => AppTheme.primaryColor,
      InvoiceStatus.cancelled => AppTheme.expenseColor,
      InvoiceStatus.draft => AppTheme.textSecondaryColor,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
