import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/validators.dart';
import '../models/invoice_line_item_data.dart';

/// Fatura formundaki tek bir kalem satırını düzenlemek için kullanılan
/// bileşen.
class InvoiceLineItemRow extends StatelessWidget {
  const InvoiceLineItemRow({
    super.key,
    required this.index,
    required this.data,
    required this.onVatChanged,
    required this.onRemove,
    required this.canRemove,
  });

  final int index;
  final InvoiceLineItemData data;
  final ValueChanged<double> onVatChanged;
  final VoidCallback onRemove;
  final bool canRemove;

  static final List<TextInputFormatter> _numericFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Kalem ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                tooltip: canRemove
                    ? 'Kalemi kaldır'
                    : 'En az bir kalem bulunmalı',
                icon: const Icon(Icons.delete_outline),
                color: AppTheme.expenseColor,
                onPressed: canRemove ? onRemove : null,
              ),
            ],
          ),
          TextFormField(
            controller: data.descriptionController,
            decoration: const InputDecoration(
              labelText: 'Ürün / Hizmet Adı',
            ),
            validator: Validators.required,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: data.quantityController,
                  decoration: const InputDecoration(labelText: 'Miktar'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: _numericFormatters,
                  validator: Validators.positiveNumber,
                ),
              ),
              SizedBox(
                width: 130,
                child: TextFormField(
                  controller: data.unitPriceController,
                  decoration: const InputDecoration(labelText: 'Birim Fiyat'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: _numericFormatters,
                  validator: Validators.positiveNumber,
                ),
              ),
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<double>(
                  initialValue: data.vatRate,
                  decoration: const InputDecoration(labelText: 'KDV'),
                  items: kVatRateOptions
                      .map(
                        (rate) => DropdownMenuItem(
                          value: rate,
                          child: Text('%${rate.toStringAsFixed(0)}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onVatChanged(value);
                  },
                ),
              ),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: data.discountController,
                  decoration: const InputDecoration(labelText: 'İskonto %'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: _numericFormatters,
                  validator: Validators.optionalPercentage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Satır Toplamı: ${CurrencyHelper.formatFromKurus(CurrencyHelper.liraToKurus(data.total))}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
