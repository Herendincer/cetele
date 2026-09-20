import 'models/invoice_model.dart';
import 'models/invoice_type.dart';

/// Demo amaçlı fatura listesi (Supabase entegrasyonu tamamlanana kadar).
/// Dashboard ve fatura listesi ekranları bu veriyi paylaşır.
final List<InvoiceModel> mockInvoices = [
  InvoiceModel(
    id: 'inv-1',
    number: '2026-0142',
    type: InvoiceType.sales,
    contactName: 'Aslan Tekstil Ltd. Şti.',
    contactTaxNumber: '1234567890',
    contactAddress: 'Organize Sanayi Bölgesi No:12, Bursa',
    issueDate: DateTime(2026, 9, 17),
    dueDate: DateTime(2026, 10, 1),
    status: InvoiceStatus.paid,
    items: const [
      InvoiceItemModel(description: 'Pamuklu Kumaş (Top)', quantity: 50, unitPrice: 320, vatRate: 20),
      InvoiceItemModel(description: 'Nakliye Hizmeti', quantity: 1, unitPrice: 1500, vatRate: 20, discountPercent: 10),
    ],
  ),
  InvoiceModel(
    id: 'inv-2',
    number: '2026-0141',
    type: InvoiceType.sales,
    contactName: 'Yıldız Elektronik',
    contactTaxNumber: '2345678901',
    contactAddress: 'Merkez Mah. Teknoloji Cd. No:8, İstanbul',
    issueDate: DateTime(2026, 9, 15),
    dueDate: DateTime(2026, 9, 29),
    status: InvoiceStatus.approved,
    items: const [
      InvoiceItemModel(description: 'LED Aydınlatma Ünitesi', quantity: 25, unitPrice: 290, vatRate: 20),
    ],
  ),
  InvoiceModel(
    id: 'inv-3',
    number: 'A-0087',
    type: InvoiceType.purchase,
    contactName: 'Deniz Lojistik A.Ş.',
    contactTaxNumber: '4567890123',
    contactAddress: 'Liman Cd. No:3, Kocaeli',
    issueDate: DateTime(2026, 9, 13),
    dueDate: DateTime(2026, 9, 27),
    status: InvoiceStatus.approved,
    items: const [
      InvoiceItemModel(description: 'Yurt İçi Nakliye', quantity: 4, unitPrice: 2100, vatRate: 20),
      InvoiceItemModel(description: 'Depolama Hizmeti', quantity: 1, unitPrice: 900, vatRate: 10),
    ],
  ),
  InvoiceModel(
    id: 'inv-4',
    number: 'A-0086',
    type: InvoiceType.purchase,
    contactName: 'Mert Ofis Malzemeleri',
    contactTaxNumber: '5678901234',
    contactAddress: 'Perpa Ticaret Merkezi, İstanbul',
    issueDate: DateTime(2026, 9, 10),
    dueDate: DateTime(2026, 9, 24),
    status: InvoiceStatus.paid,
    items: const [
      InvoiceItemModel(description: 'Kırtasiye Malzemesi', quantity: 1, unitPrice: 2140, vatRate: 20),
    ],
  ),
];
