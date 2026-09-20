import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import 'models/account_model.dart';

/// Yeni bir nakit kasa veya banka hesabı ekleme formu.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key, this.initialType = AccountType.cash});

  final AccountType initialType;

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _openingBalanceController = TextEditingController(text: '0');

  late AccountType _accountType;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _accountType = widget.initialType;
    _nameController.addListener(_markDirty);
    _openingBalanceController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

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
    if (!formValid) {
      AppSnackBar.showError(context, 'Lütfen zorunlu alanları eksiksiz ve doğru doldurun');
      return;
    }

    final double openingBalance = _openingBalanceController.text.trim().isEmpty
        ? 0
        : double.parse(_openingBalanceController.text.trim().replaceAll(',', '.'));

    final AccountModel account = AccountModel(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _accountType,
      balance: openingBalance,
      lastTransactionDate: DateTime.now(),
    );

    setState(() => _isDirty = false);
    AppSnackBar.showSuccess(context, 'Hesap başarıyla eklendi');
    Navigator.of(context).pop(account);
  }

  @override
  Widget build(BuildContext context) {
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
        appBar: AppBar(title: const Text('Yeni Hesap Ekle')),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<AccountType>(
                  segments: const [
                    ButtonSegment(
                      value: AccountType.cash,
                      label: Text('Nakit Kasa'),
                      icon: Icon(Icons.savings_outlined),
                    ),
                    ButtonSegment(
                      value: AccountType.bank,
                      label: Text('Banka Hesabı'),
                      icon: Icon(Icons.account_balance_outlined),
                    ),
                  ],
                  selected: {_accountType},
                  onSelectionChanged: (selection) {
                    _markDirty();
                    setState(() => _accountType = selection.first);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Hesap Adı'),
                  validator: Validators.required,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _openingBalanceController,
                  decoration: const InputDecoration(labelText: 'Açılış Bakiyesi'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final double? parsed = double.tryParse(value.trim().replaceAll(',', '.'));
                    return parsed == null ? 'Geçerli bir tutar girin' : null;
                  },
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
