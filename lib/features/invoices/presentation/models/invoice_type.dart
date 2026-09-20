/// Fatura türü (satış / alış).
enum InvoiceType { sales, purchase }

extension InvoiceTypeLabel on InvoiceType {
  String get label => switch (this) {
        InvoiceType.sales => 'Satış Faturası',
        InvoiceType.purchase => 'Alış Faturası',
      };
}
