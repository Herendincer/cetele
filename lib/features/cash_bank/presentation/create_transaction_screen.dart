import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_content.dart';
import '../../contacts/presentation/widgets/contact_picker.dart';
import '../../contacts/presentation/controllers/contacts_controller.dart';
import 'controllers/cash_bank_controller.dart';
import '../data/transactions_repository.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import 'models/account_model.dart';
import 'models/cash_transaction_model.dart';

/// Demo amaçlı cari listesi (Supabase entegrasyonu tamamlanana kadar).
// ignore: unused_element
const List<String> _mockContactNames = [
  'Aslan Tekstil Ltd. Şti.',
  'Yıldız Elektronik',
  'Deniz Lojistik A.Ş.',
  'Mert Ofis Malzemeleri',
  'Nur Reklam ve Matbaa',
];

/// Müşteriden tahsilat alma veya tedarikçiye/masrafa ödeme yapma formu.
class CreateTransactionScreen extends ConsumerStatefulWidget {
  const CreateTransactionScreen({
    super.key,
    this.accounts = const [],
    this.existingTransaction,
    this.initialType = CashTransactionType.collection,
  });

  final List<AccountModel> accounts;
  final CashTransactionModel? existingTransaction;
  final CashTransactionType initialType;

  @override
  ConsumerState<CreateTransactionScreen> createState() =>
      _CreateTransactionScreenState();
}

class _CreateTransactionScreenState
    extends ConsumerState<CreateTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  late CashTransactionType _transactionType;
  String? _selectedContact;
  String? _selectedAccountId;
  DateTime _date = DateTime.now();
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    _transactionType = existing?.type ?? widget.initialType;
    _selectedAccountId = existing?.accountId;
    _selectedContact = existing?.contactId;
    _date = existing?.date ?? DateTime.now();
    _amountController.text = existing?.amount.toStringAsFixed(2) ?? '';
    _descriptionController.text = existing?.description ?? '';
    _amountController.addListener(_onFieldChanged);
    _descriptionController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _onFieldChanged() {
    if (!mounted) return;
    setState(() => _isDirty = true);
  }

  AccountModel? get _selectedAccount {
    if (_selectedAccountId == null) return null;
    for (final account
        in ref.read(accountsProvider).value ?? <AccountModel>[]) {
      if (account.id == _selectedAccountId) return account;
    }
    return null;
  }

  double get _amount =>
      double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0;

  bool get _hasInsufficientBalance =>
      _transactionType == CashTransactionType.payment &&
      _selectedAccount != null &&
      _amount > _selectedAccount!.balance;

  Future<bool> _confirmDiscardChanges() {
    return showConfirmDialog(
      context,
      title: 'Kaydedilmemiş Değişiklikler',
      message: 'Kaydedilmemiş değişiklikleriniz var. Çıkmak istiyor musunuz?',
      cancelLabel: 'Vazgeç',
      confirmLabel: 'Çık',
    );
  }

  Future<void> _handleSave() async {
    if (ref.read(cashBankControllerProvider).isLoading) return;
    final bool formValid = _formKey.currentState?.validate() ?? false;

    if (_selectedContact == null ||
        !(ref
                .read(contactsProvider)
                .value
                ?.any((c) => c.id == _selectedContact) ??
            false)) {
      AppSnackBar.showError(context, 'Lütfen ilgili cariyi seçin');
      return;
    }
    if (_selectedAccount == null) {
      AppSnackBar.showError(context, 'Lütfen bir kasa/banka hesabı seçin');
      return;
    }
    if (!formValid) {
      AppSnackBar.showError(
        context,
        'Lütfen zorunlu alanları eksiksiz ve doğru doldurun',
      );
      return;
    }

    if (_hasInsufficientBalance) {
      final bool proceed = await showConfirmDialog(
        context,
        title: 'Yetersiz Bakiye',
        message:
            '${_selectedAccount!.name} hesabında yeterli bakiye yok '
            '(mevcut: ${CurrencyHelper.formatFromKurus(CurrencyHelper.liraToKurus(_selectedAccount!.balance))}). '
            'Yine de kaydetmek istiyor musunuz?',
        confirmLabel: 'Yine de Kaydet',
      );
      if (!proceed || !mounted) return;
    }

    final CashTransactionModel result = CashTransactionModel(
      id: widget.existingTransaction?.id ?? '',
      type: _transactionType,
      contactId: _selectedContact,
      invoiceId: widget.existingTransaction?.invoiceId,
      contactName: ref
          .read(contactsProvider)
          .requireValue
          .firstWhere((c) => c.id == _selectedContact)
          .name,
      accountType: _selectedAccount!.type.name,
      accountId: _selectedAccount!.id,
      accountName: _selectedAccount!.name,
      amount: _amount,
      date: _date,
      description: _descriptionController.text.trim(),
    );

    final ok = await ref
        .read(cashBankControllerProvider.notifier)
        .saveTransaction(result, isNew: widget.existingTransaction == null);
    if (!mounted || !ok) return;
    setState(() => _isDirty = false);
    AppSnackBar.showSuccess(
      context,
      _transactionType == CashTransactionType.collection
          ? 'Tahsilat başarıyla kaydedildi'
          : 'Ödeme başarıyla kaydedildi',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _isDirty = true;
    });
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
        appBar: AppBar(
          title: Text(
            _transactionType == CashTransactionType.collection
                ? 'Tahsilat Al'
                : 'Ödeme Yap',
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<CashTransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: CashTransactionType.collection,
                      label: Text('Tahsilat'),
                      icon: Icon(Icons.call_received_rounded),
                    ),
                    ButtonSegment(
                      value: CashTransactionType.payment,
                      label: Text('Ödeme'),
                      icon: Icon(Icons.call_made_rounded),
                    ),
                  ],
                  selected: {_transactionType},
                  onSelectionChanged: (selection) {
                    _markDirty();
                    setState(() => _transactionType = selection.first);
                  },
                ),
                const SizedBox(height: 16),
                ContactPicker(
                  value: _selectedContact,
                  onChanged: (value) {
                    _markDirty();
                    setState(() => _selectedContact = value);
                  },
                ),
                const SizedBox(height: 12),
                AsyncContent<List<AccountModel>>(
                  value: ref.watch(accountsProvider),
                  onRetry: () {
                    ref.invalidate(transactionsProvider);
                    ref.invalidate(accountsProvider);
                  },
                  data: (accounts) {
                    if (accounts.isEmpty) {
                      return const Text(
                        'Kayıtlı hesap yok. Önce Kasa & Banka ekranından hesap ekleyin.',
                      );
                    }
                    final selected =
                        accounts.any((a) => a.id == _selectedAccountId)
                        ? _selectedAccountId
                        : null;
                    return DropdownButtonFormField<String>(
                      key: ValueKey(selected),
                      initialValue: selected,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Kasa / Banka Hesabı',
                      ),
                      items: accounts
                          .map(
                            (account) => DropdownMenuItem(
                              value: account.id,
                              child: Text(
                                account.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      validator: (value) =>
                          value == null ? 'Lütfen bir hesap seçin' : null,
                      onChanged: (value) {
                        _markDirty();
                        setState(() => _selectedAccountId = value);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Tutar'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.positiveNumber,
                ),
                if (_hasInsufficientBalance) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Yetersiz bakiye: mevcut bakiye '
                    '${CurrencyHelper.formatFromKurus(CurrencyHelper.liraToKurus(_selectedAccount!.balance))}',
                    style: const TextStyle(
                      color: AppTheme.expenseColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tarih',
                      suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                    ),
                    child: Text(dateFormat.format(_date)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama / Kategori',
                  ),
                  maxLines: 2,
                ),
                MutationError(
                  value: ref.watch(cashBankControllerProvider),
                  onRetry: _handleSave,
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
                onPressed:
                    ref.watch(cashBankControllerProvider).isLoading ||
                        ref.watch(accountsProvider).isLoading ||
                        ref.watch(accountsProvider).hasError ||
                        ref.watch(contactsProvider).isLoading ||
                        ref.watch(contactsProvider).hasError
                    ? null
                    : _handleSave,
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
