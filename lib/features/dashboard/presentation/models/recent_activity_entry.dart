import '../../../cash_bank/presentation/models/cash_transaction_model.dart';
import '../../../invoices/presentation/models/invoice_model.dart';
import '../../../invoices/presentation/models/invoice_type.dart';

/// Dashboard'daki "Son Hareketler" akışında gösterilen bir kaydın türü.
enum RecentActivityKind { invoice, cashTransaction }

/// Bir fatura veya bir kasa/banka hareketini tek tip altında birleştiren
/// salt-okunur görünüm modeli. Null/eksik alanlara karşı güvenlidir: her
/// alan [kind] değerine göre ilgili kaynaktan güvenle okunur.
class RecentActivityEntry {
  const RecentActivityEntry.invoice(InvoiceModel invoice)
      : kind = RecentActivityKind.invoice,
        _invoice = invoice,
        _transaction = null;

  const RecentActivityEntry.transaction(CashTransactionModel transaction)
      : kind = RecentActivityKind.cashTransaction,
        _invoice = null,
        _transaction = transaction;

  final RecentActivityKind kind;
  final InvoiceModel? _invoice;
  final CashTransactionModel? _transaction;

  String get title => _invoice?.contactName ?? _transaction?.contactName ?? 'Bilinmiyor';

  String get subtitle {
    final invoice = _invoice;
    final transaction = _transaction;
    if (invoice != null) return '${invoice.type.label} · #${invoice.number}';
    if (transaction != null) return '${transaction.type.label} · ${transaction.accountName}';
    return '';
  }

  double get amount => _invoice?.grandTotal ?? _transaction?.amount ?? 0;

  bool get isIncome {
    final invoice = _invoice;
    if (invoice != null) return invoice.type == InvoiceType.sales;
    return _transaction?.type == CashTransactionType.collection;
  }

  DateTime get date => _invoice?.issueDate ?? _transaction?.date ?? DateTime.now();

  InvoiceModel? get invoiceOrNull => _invoice;
  CashTransactionModel? get transactionOrNull => _transaction;
}
