import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/pdf_invoice_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_helper.dart';
import '../../../core/widgets/app_snackbar.dart';
import 'models/invoice_model.dart';
import 'models/invoice_type.dart';
import 'widgets/invoice_summary_card.dart';

/// Kaydedilmiş bir faturanın salt-okunur detay görünümü ve PDF
/// yazdırma/paylaşma aksiyonu.
class InvoiceDetailsScreen extends StatefulWidget {
  const InvoiceDetailsScreen({super.key, required this.invoice});

  final InvoiceModel invoice;

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  bool _isGeneratingPdf = false;

  Future<void> _handlePrintOrShare() async {
    if (_isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);
    try {
      await PdfInvoiceService.printOrShareInvoice(widget.invoice);
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, 'PDF oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.');
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final InvoiceModel invoice = widget.invoice;
    final dateFormat = DateFormat('d MMM yyyy', 'tr_TR');

    return Scaffold(
      appBar: AppBar(
        title: Text('#${invoice.number}'),
        actions: [
          IconButton(
            tooltip: 'Yazdır / Paylaş',
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                  )
                : const Icon(Icons.print_outlined),
            onPressed: _handlePrintOrShare,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          invoice.contactName.isEmpty ? 'Belirtilmemiş' : invoice.contactName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        _StatusBadge(status: invoice.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${invoice.type.label} · #${invoice.number}'),
                    const SizedBox(height: 4),
                    Text('Düzenleme: ${dateFormat.format(invoice.issueDate)}'),
                    if (invoice.dueDate != null)
                      Text('Vade: ${dateFormat.format(invoice.dueDate!)}'),
                    if (invoice.contactTaxNumber.isNotEmpty)
                      Text('Vergi No: ${invoice.contactTaxNumber}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kalemler', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (invoice.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Bu faturada kalem bulunmuyor'),
                      )
                    else
                      for (final item in invoice.items) ...[
                        _ItemRow(item: item),
                        const Divider(height: 16),
                      ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            InvoiceSummaryCard(
              subtotal: invoice.subtotal,
              totalDiscount: invoice.totalDiscount,
              totalVat: invoice.totalVat,
              grandTotal: invoice.grandTotal,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final InvoiceItemModel item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.description.isEmpty ? '-' : item.description,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          '${item.quantity.toStringAsFixed(2)} x '
          '${CurrencyHelper.formatFromKurus(CurrencyHelper.liraToKurus(item.unitPrice))}'
          ' · KDV %${item.vatRate.toStringAsFixed(0)}'
          '${item.discountPercent > 0 ? ' · İskonto %${item.discountPercent.toStringAsFixed(0)}' : ''}',
          style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            CurrencyHelper.formatFromKurus(CurrencyHelper.liraToKurus(item.total)),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
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
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
