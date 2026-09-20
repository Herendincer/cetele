import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import 'models/invoice_line_item_data.dart';
import 'models/invoice_type.dart';
import 'widgets/invoice_line_item_row.dart';
import 'widgets/invoice_summary_card.dart';

/// Demo amaçlı cari listesi (Supabase entegrasyonu tamamlanana kadar).
const List<String> _mockContactNames = [
  'Aslan Tekstil Ltd. Şti.',
  'Yıldız Elektronik',
  'Deniz Lojistik A.Ş.',
  'Mert Ofis Malzemeleri',
  'Nur Reklam ve Matbaa',
];

/// Yeni satış/alış faturası oluşturma formu.
class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key, this.initialType = InvoiceType.sales});

  final InvoiceType initialType;

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final List<InvoiceLineItemData> _items = [];

  late InvoiceType _invoiceType;
  String? _selectedContact;
  DateTime _issueDate = DateTime.now();
  DateTime? _dueDate;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _invoiceType = widget.initialType;
    _invoiceNumberController.addListener(_markDirty);
    _addLineItem(markDirty: false);
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _onItemChanged() {
    if (!mounted) return;
    setState(() => _isDirty = true);
  }

  void _addLineItem({bool markDirty = true}) {
    final item = InvoiceLineItemData();
    item.addListenerToAll(_onItemChanged);
    setState(() {
      _items.add(item);
      if (markDirty) _isDirty = true;
    });
  }

  Future<void> _removeLineItem(int index) async {
    if (_items.length <= 1) {
      AppSnackBar.showError(context, 'Faturada en az bir kalem bulunmalıdır');
      return;
    }
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Kalemi Kaldır',
      message: 'Bu kalemi silmek istediğinize emin misiniz?',
      confirmLabel: 'Sil',
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
      _isDirty = true;
    });
  }

  Future<void> _pickDate({required bool isIssueDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isIssueDate ? _issueDate : (_dueDate ?? _issueDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isIssueDate) {
        _issueDate = picked;
      } else {
        _dueDate = picked;
      }
      _isDirty = true;
    });
  }

  double get _subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get _totalDiscount =>
      _items.fold(0.0, (sum, item) => sum + item.discountAmount);
  double get _totalVat => _items.fold(0.0, (sum, item) => sum + item.vatAmount);
  double get _grandTotal => _items.fold(0.0, (sum, item) => sum + item.total);

  Future<bool> _confirmDiscardChanges() {
    return showConfirmDialog(
      context,
      title: 'Kaydedilmemiş Değişiklikler',
      message: 'Kaydedilmemiş değişiklikleriniz var. Çıkmak istiyor musunuz?',
      cancelLabel: 'Vazgeç',
      confirmLabel: 'Çık',
    );
  }

  void _handleSave() {
    final bool formValid = _formKey.currentState?.validate() ?? false;

    if (_selectedContact == null) {
      AppSnackBar.showError(context, 'Lütfen bir cari seçin');
      return;
    }
    if (!formValid) {
      AppSnackBar.showError(context, 'Lütfen zorunlu alanları eksiksiz ve doğru doldurun');
      return;
    }
    if (_dueDate != null && _dueDate!.isBefore(_issueDate)) {
      AppSnackBar.showError(context, 'Vade tarihi, düzenleme tarihinden önce olamaz');
      return;
    }
    if (_grandTotal <= 0) {
      AppSnackBar.showError(context, 'Fatura tutarı sıfırdan büyük olmalıdır');
      return;
    }

    setState(() => _isDirty = false);
    AppSnackBar.showSuccess(context, 'Fatura başarıyla kaydedildi');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy', 'tr_TR');

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldDiscard = await _confirmDiscardChanges();
        if (shouldDiscard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Yeni Fatura')),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                        Text('Fatura Bilgileri', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        SegmentedButton<InvoiceType>(
                          segments: const [
                            ButtonSegment(
                              value: InvoiceType.sales,
                              label: Text('Satış'),
                              icon: Icon(Icons.call_received_rounded),
                            ),
                            ButtonSegment(
                              value: InvoiceType.purchase,
                              label: Text('Alış'),
                              icon: Icon(Icons.call_made_rounded),
                            ),
                          ],
                          selected: {_invoiceType},
                          onSelectionChanged: (selection) {
                            _markDirty();
                            setState(() => _invoiceType = selection.first);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedContact,
                          decoration: const InputDecoration(labelText: 'Cari Seçimi'),
                          items: _mockContactNames
                              .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                              .toList(),
                          validator: (value) =>
                              value == null ? 'Lütfen bir cari seçin' : null,
                          onChanged: (value) {
                            _markDirty();
                            setState(() => _selectedContact = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _invoiceNumberController,
                          decoration: const InputDecoration(labelText: 'Fatura No'),
                          validator: Validators.required,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DatePickerField(
                                label: 'Düzenleme Tarihi',
                                value: dateFormat.format(_issueDate),
                                onTap: () => _pickDate(isIssueDate: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DatePickerField(
                                label: 'Vade Tarihi',
                                value: _dueDate == null ? 'Seçiniz' : dateFormat.format(_dueDate!),
                                onTap: () => _pickDate(isIssueDate: false),
                              ),
                            ),
                          ],
                        ),
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
                        const SizedBox(height: 12),
                        for (int i = 0; i < _items.length; i++)
                          InvoiceLineItemRow(
                            index: i,
                            data: _items[i],
                            canRemove: _items.length > 1,
                            onVatChanged: (rate) {
                              setState(() {
                                _items[i].vatRate = rate;
                                _isDirty = true;
                              });
                            },
                            onRemove: () => _removeLineItem(i),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => _addLineItem(),
                          icon: const Icon(Icons.add),
                          label: const Text('Yeni Satır Ekle'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InvoiceSummaryCard(
                  subtotal: _subtotal,
                  totalDiscount: _totalDiscount,
                  totalVat: _totalVat,
                  grandTotal: _grandTotal,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _handleSave,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Kaydet'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(value),
      ),
    );
  }
}


