import 'package:flutter/material.dart';

/// KDV oranı seçenekleri (yüzde olarak).
const List<double> kVatRateOptions = [0, 1, 10, 20];

/// Fatura oluşturma formundaki tek bir kalemin (satırın) durumu ve
/// hesaplama mantığı.
class InvoiceLineItemData {
  InvoiceLineItemData({String initialDescription = ''})
      : descriptionController = TextEditingController(text: initialDescription),
        quantityController = TextEditingController(text: '1'),
        unitPriceController = TextEditingController(),
        discountController = TextEditingController(text: '0');

  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  final TextEditingController discountController;
  double vatRate = 20;

  double _parse(String text) => double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;

  double get quantity => _parse(quantityController.text);
  double get unitPrice => _parse(unitPriceController.text);
  double get discountPercent => _parse(discountController.text).clamp(0, 100);

  double get subtotal => quantity * unitPrice;
  double get discountAmount => subtotal * (discountPercent / 100);
  double get afterDiscount => (subtotal - discountAmount).clamp(0, double.infinity);
  double get vatAmount => afterDiscount * (vatRate / 100);
  double get total => afterDiscount + vatAmount;

  /// Satırı geçerli metin alanlarına sahip olsa bile boş kabul edip
  /// edilmeyeceğini belirler (tamamen dokunulmamış satırları tespit etmek için).
  bool get isEmpty =>
      descriptionController.text.trim().isEmpty && unitPriceController.text.trim().isEmpty;

  void addListenerToAll(VoidCallback listener) {
    descriptionController.addListener(listener);
    quantityController.addListener(listener);
    unitPriceController.addListener(listener);
    discountController.addListener(listener);
  }

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
    discountController.dispose();
  }
}
