import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/invoices/presentation/models/invoice_model.dart';
import '../../features/invoices/presentation/models/invoice_type.dart';
import '../../features/cash_bank/presentation/models/cash_transaction_model.dart';
import '../../features/contacts/presentation/models/contact_model.dart';
import '../constants/app_constants.dart';
import '../utils/currency_helper.dart';

/// Fatura için A4 PDF belgesi oluşturan ve yazdırma/paylaşma akışını
/// yöneten servis.
class PdfInvoiceService {
  PdfInvoiceService._();

  /// [invoice] için PDF oluşturur ve işletim sisteminin yazdırma/paylaşma
  /// arayüzünü açar. Beklenmeyen hatalarda uygulamayı çökertmeden
  /// [Exception] fırlatır; çağıran taraf bunu yakalayıp kullanıcıya
  /// bildirmelidir.
  static Future<void> printOrShareInvoice(InvoiceModel invoice) async {
    try {
      final pw.Document document = await _buildDocument(invoice);
      await Printing.layoutPdf(
        onLayout: (format) async => document.save(),
        name: 'Fatura_${invoice.number}.pdf',
      );
    } catch (error) {
      throw Exception('PDF oluşturulurken bir hata oluştu: $error');
    }
  }

  static Future<pw.Document> _buildDocument(InvoiceModel invoice) async {
    final regularFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(invoice),
            pw.SizedBox(height: 24),
            _buildPartiesSection(invoice),
            pw.SizedBox(height: 24),
            _buildItemsTable(invoice),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: _buildTotals(invoice),
            ),
            if (invoice.notes.trim().isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Text('Notlar', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.notes),
            ],
          ],
        ),
      ),
    );

    return document;
  }

  static pw.Widget _buildHeader(InvoiceModel invoice) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                AppConstants.companyName,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              if (AppConstants.companyAddress.isNotEmpty)
                pw.Text(AppConstants.companyAddress, style: const pw.TextStyle(fontSize: 10)),
              if (AppConstants.companyTaxOffice.isNotEmpty || AppConstants.companyTaxNumber.isNotEmpty)
                pw.Text(
                  '${AppConstants.companyTaxOffice} · VKN: ${AppConstants.companyTaxNumber}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              if (AppConstants.companyPhone.isNotEmpty)
                pw.Text(AppConstants.companyPhone, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              invoice.type.label.toUpperCase(),
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Fatura No: ${invoice.number}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(
              'Düzenleme Tarihi: ${_formatDate(invoice.issueDate)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            if (invoice.dueDate != null)
              pw.Text(
                'Vade Tarihi: ${_formatDate(invoice.dueDate!)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildPartiesSection(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Müşteri / Cari', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.SizedBox(height: 4),
          pw.Text(
            invoice.contactName.isNotEmpty ? invoice.contactName : 'Belirtilmemiş',
            style: const pw.TextStyle(fontSize: 11),
          ),
          if (invoice.contactTaxNumber.isNotEmpty)
            pw.Text('Vergi No: ${invoice.contactTaxNumber}', style: const pw.TextStyle(fontSize: 10)),
          if (invoice.contactAddress.isNotEmpty)
            pw.Text(invoice.contactAddress, style: const pw.TextStyle(fontSize: 10)),
          if (invoice.contactPhone.isNotEmpty)
            pw.Text(invoice.contactPhone, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(InvoiceModel invoice) {
    final headers = ['Açıklama', 'Miktar', 'Birim Fiyat', 'KDV %', 'İskonto %', 'Tutar'];

    if (invoice.items.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.TableHelper.fromTextArray(headers: headers, data: const []),
          pw.SizedBox(height: 8),
          pw.Text('Bu faturada henüz kalem bulunmuyor.', style: const pw.TextStyle(fontSize: 10)),
        ],
      );
    }

    final rows = invoice.items
        .map(
          (item) => [
            item.description.isNotEmpty ? item.description : '-',
            item.quantity.toStringAsFixed(2),
            CurrencyHelper.formatFromKurus(CurrencyHelper.liraToKurus(item.unitPrice)),
            '%${item.vatRate.toStringAsFixed(0)}',
            '%${item.discountPercent.toStringAsFixed(0)}',
            CurrencyHelper.formatFromKurus(CurrencyHelper.liraToKurus(item.total)),
          ],
        )
        .toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    );
  }

  static pw.Widget _buildTotals(InvoiceModel invoice) {
    return pw.SizedBox(
      width: 220,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _totalRow('Ara Toplam', invoice.subtotal),
          _totalRow('Toplam İskonto', -invoice.totalDiscount),
          _totalRow('KDV Toplamı', invoice.totalVat),
          pw.Divider(),
          _totalRow('Genel Toplam', invoice.grandTotal, isEmphasized: true),
        ],
      ),
    );
  }

  static pw.Widget _totalRow(String label, double amount, {bool isEmphasized = false}) {
    final String sign = amount < 0 ? '-' : '';
    final String formatted = CurrencyHelper.formatFromKurus(
      CurrencyHelper.liraToKurus(amount).abs(),
    );
    final style = pw.TextStyle(
      fontSize: isEmphasized ? 13 : 10,
      fontWeight: isEmphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text('$sign$formatted', style: style),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

/// Cari hesap hareketlerini A4 ekstre olarak oluşturan servis.
class PdfContactStatementService {
  PdfContactStatementService._();

  static Future<void> printStatement({
    required ContactModel contact,
    required List<CashTransactionModel> transactions,
  }) async {
    try {
      final regularFont = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      final document = pw.Document(
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
      );
      final sortedTransactions = List<CashTransactionModel>.from(transactions)
        ..sort((a, b) => a.date.compareTo(b.date));
      final double movementTotal = sortedTransactions.fold(
        0,
        (sum, transaction) =>
            sum + (transaction.type == CashTransactionType.collection
                ? -transaction.amount
                : transaction.amount),
      );
      final double openingBalance = contact.balance - movementTotal;
      double runningBalance = openingBalance;

      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (_) => pw.Text(
            'Cari Ekstresi',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          build: (_) => [
            pw.SizedBox(height: 8),
            pw.Text(AppConstants.companyName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(contact.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  if (contact.taxNumber.isNotEmpty) pw.Text('Vergi No: ${contact.taxNumber}'),
                  if (contact.phone.isNotEmpty) pw.Text(contact.phone),
                  if (contact.address.isNotEmpty) pw.Text(contact.address),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Açılış Bakiyesi: ${_formatAmount(openingBalance)}'),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: const ['Tarih', 'İşlem', 'Açıklama', 'Hesap', 'Tutar', 'Bakiye'],
              data: [
                for (final transaction in sortedTransactions)
                  [
                    _formatDate(transaction.date),
                    transaction.type.label,
                    transaction.description.isEmpty ? '-' : transaction.description,
                    transaction.accountName,
                    _formatAmount(transaction.amount),
                    _formatAmount(runningBalance += transaction.type == CashTransactionType.collection
                        ? -transaction.amount
                        : transaction.amount),
                  ],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
              cellStyle: const pw.TextStyle(fontSize: 9),
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            ),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Güncel Bakiye: ${_formatAmount(contact.balance)}',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      await Printing.layoutPdf(
        onLayout: (format) async => document.save(),
        name: 'Ekstre_${contact.name}.pdf',
      );
    } catch (error) {
      throw Exception('Ekstre oluşturulurken bir hata oluştu: $error');
    }
  }

  static String _formatAmount(double amount) {
    final String sign = amount < 0 ? '-' : '';
    return '$sign${CurrencyHelper.formatFromKurus(CurrencyHelper.liraToKurus(amount.abs()))}';
  }

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}
