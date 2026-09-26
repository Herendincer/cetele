import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_content.dart';
import '../../../core/utils/currency_helper.dart';
import 'controllers/contacts_controller.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import 'models/contact_model.dart';

/// Yeni cari ekleme veya mevcut bir cariyi düzenleme formu.
class CreateContactScreen extends ConsumerStatefulWidget {
  const CreateContactScreen({super.key, this.existingContact});

  /// Doluysa düzenleme modunda açılır.
  final ContactModel? existingContact;

  @override
  ConsumerState<CreateContactScreen> createState() =>
      _CreateContactScreenState();
}

class _CreateContactScreenState extends ConsumerState<CreateContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _taxOfficeController;
  late final TextEditingController _taxNumberController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;

  late ContactType _contactType;
  bool _isDirty = false;

  bool get _isEditing => widget.existingContact != null;

  @override
  void initState() {
    super.initState();
    final contact = widget.existingContact;
    _contactType = contact?.type ?? ContactType.customer;
    _nameController = TextEditingController(text: contact?.name ?? '');
    _taxOfficeController = TextEditingController(
      text: contact?.taxOffice ?? '',
    );
    _taxNumberController = TextEditingController(
      text: contact?.taxNumber ?? '',
    );
    _phoneController = TextEditingController(text: contact?.phone ?? '');
    _emailController = TextEditingController(text: contact?.email ?? '');
    _addressController = TextEditingController(text: contact?.address ?? '');
    for (final controller in [
      _nameController,
      _taxOfficeController,
      _taxNumberController,
      _phoneController,
      _emailController,
      _addressController,
    ]) {
      controller.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxOfficeController.dispose();
    _taxNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
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

  Future<void> _handleSave() async {
    if (ref.read(contactsControllerProvider).isLoading) return;
    final bool formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) {
      AppSnackBar.showError(
        context,
        'Lütfen zorunlu alanları eksiksiz ve doğru doldurun',
      );
      return;
    }

    final ContactModel result = ContactModel(
      id: widget.existingContact?.id ?? '',
      type: _contactType,
      name: _nameController.text.trim(),
      taxOffice: _taxOfficeController.text.trim(),
      taxNumber: _taxNumberController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
    );

    final ok = await ref
        .read(contactsControllerProvider.notifier)
        .save(result, isNew: !_isEditing);
    if (!mounted || !ok) return;
    setState(() => _isDirty = false);
    AppSnackBar.showSuccess(
      context,
      _isEditing ? 'Cari başarıyla güncellendi' : 'Cari başarıyla eklendi',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
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
        appBar: AppBar(
          title: Text(_isEditing ? 'Cariyi Düzenle' : 'Yeni Cari Ekle'),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<ContactType>(
                  segments: const [
                    ButtonSegment(
                      value: ContactType.customer,
                      label: Text('Müşteri'),
                      icon: Icon(Icons.person_outline),
                    ),
                    ButtonSegment(
                      value: ContactType.supplier,
                      label: Text('Tedarikçi'),
                      icon: Icon(Icons.local_shipping_outlined),
                    ),
                    ButtonSegment(
                      value: ContactType.both,
                      label: Text('Her ikisi'),
                    ),
                  ],
                  selected: {_contactType},
                  onSelectionChanged: (selection) {
                    _markDirty();
                    setState(() => _contactType = selection.first);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Unvan / Ad Soyad',
                  ),
                  validator: Validators.required,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _taxOfficeController,
                  decoration: const InputDecoration(labelText: 'Vergi Dairesi'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _taxNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Vergi No / TC Kimlik No',
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Telefon'),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final bool isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(value.trim());
                    return isValid ? null : 'Geçerli bir e-posta adresi girin';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Adres'),
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                if (_isEditing)
                  AsyncContent<ContactModel?>(
                    value: ref.watch(
                      contactProvider(widget.existingContact!.id),
                    ),
                    onRetry: () => ref.invalidate(contactsProvider),
                    data: (contact) => InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Güncel Bakiye',
                      ),
                      child: Text(
                        contact == null
                            ? 'Cari bulunamadı'
                            : CurrencyHelper.formatFromKurus(
                                CurrencyHelper.liraToKurus(contact.balance),
                              ),
                      ),
                    ),
                  )
                else
                  const InputDecorator(
                    decoration: InputDecoration(labelText: 'Güncel Bakiye'),
                    child: Text('0,00 ₺'),
                  ),
                MutationError(
                  value: ref.watch(contactsControllerProvider),
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
                onPressed: ref.watch(contactsControllerProvider).isLoading
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
