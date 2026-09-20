import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_helper.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../cash_bank/presentation/mock_cash_data.dart';
import 'contact_detail_screen.dart';
import 'create_contact_screen.dart';
import 'models/contact_model.dart';

final List<ContactModel> _mockContacts = [
  const ContactModel(
    id: 'c1',
    type: ContactType.customer,
    name: 'Aslan Tekstil Ltd. Şti.',
    taxNumber: '1234567890',
    phone: '0212 555 10 20',
    balance: 24500,
  ),
  const ContactModel(
    id: 'c2',
    type: ContactType.customer,
    name: 'Yıldız Elektronik',
    taxNumber: '2345678901',
    phone: '0212 555 30 40',
    balance: 7250,
  ),
  const ContactModel(
    id: 'c3',
    type: ContactType.customer,
    name: 'Nur Reklam ve Matbaa',
    taxNumber: '3456789012',
    phone: '0212 555 50 60',
    balance: 0,
  ),
  const ContactModel(
    id: 'c4',
    type: ContactType.supplier,
    name: 'Deniz Lojistik A.Ş.',
    taxNumber: '4567890123',
    phone: '0216 555 70 80',
    balance: -9840,
  ),
  const ContactModel(
    id: 'c5',
    type: ContactType.supplier,
    name: 'Mert Ofis Malzemeleri',
    taxNumber: '5678901234',
    phone: '0216 555 90 10',
    balance: -2140,
  ),
];

/// Müşteri ve tedarikçi cari kartlarını bakiyeleriyle listeleyen ekran.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ContactModel> _filter(ContactType type) {
    final String query = _query.trim().toLowerCase();
    return _mockContacts.where((contact) {
      if (contact.type != type) return false;
      if (query.isEmpty) return true;
      return contact.name.toLowerCase().contains(query) ||
          contact.taxNumber.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openCreateContact(BuildContext context) async {
    final ContactModel? created = await Navigator.of(context).push<ContactModel>(
      MaterialPageRoute(builder: (_) => const CreateContactScreen()),
    );
    if (created == null) return;
    setState(() => _mockContacts.add(created));
  }

  Future<void> _openEditContact(BuildContext context, ContactModel contact) async {
    final ContactModel? updated = await Navigator.of(context).push<ContactModel>(
      MaterialPageRoute(builder: (_) => CreateContactScreen(existingContact: contact)),
    );
    if (updated == null) return;
    setState(() {
      final int index = _mockContacts.indexWhere((c) => c.id == updated.id);
      if (index != -1) _mockContacts[index] = updated;
    });
  }

  void _openContactDetail(BuildContext context, ContactModel contact) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ContactDetailScreen(
          contact: contact,
          transactions: mockCashTransactions
              .where((transaction) => transaction.contactName == contact.name)
              .toList(),
        ),
      ),
    );
  }

  Future<void> _deleteContact(ContactModel contact) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: 'Cariyi Sil',
      message:
          'Bu cari hesabı silmek istediğinize emin misiniz? Varsa geçmiş hareketleri etkilenebilir.',
      confirmLabel: 'Sil',
    );
    if (!confirmed || !mounted) return;
    setState(() => _mockContacts.removeWhere((c) => c.id == contact.id));
    if (mounted) AppSnackBar.showSuccess(context, 'Cari silindi');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cariler'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Müşteriler'),
              Tab(text: 'Tedarikçiler'),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton.extended(
            onPressed: () => _openCreateContact(context),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Cari Ekle'),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'İsim veya vergi numarasına göre ara',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ContactList(
                    contacts: _filter(ContactType.customer),
                    onTap: (contact) => _openContactDetail(context, contact),
                    onEdit: (contact) => _openEditContact(context, contact),
                    onDelete: _deleteContact,
                  ),
                  _ContactList(
                    contacts: _filter(ContactType.supplier),
                    onTap: (contact) => _openContactDetail(context, contact),
                    onEdit: (contact) => _openEditContact(context, contact),
                    onDelete: _deleteContact,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactList extends StatelessWidget {
  const _ContactList({
    required this.contacts,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ContactModel> contacts;
  final ValueChanged<ContactModel> onTap;
  final ValueChanged<ContactModel> onEdit;
  final ValueChanged<ContactModel> onDelete;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return const Center(child: Text('Kayıtlı cari bulunamadı'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: contacts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final bool isReceivable = contact.balance > 0;
        final bool isSettled = contact.balance == 0;
        final Color color = isSettled
            ? AppTheme.textSecondaryColor
            : (isReceivable ? AppTheme.incomeColor : AppTheme.expenseColor);
        final int kurus = CurrencyHelper.liraToKurus(contact.balance.abs());

        return Card(
          child: InkWell(
            onTap: () => onTap(contact),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    foregroundColor: AppTheme.primaryColor,
                    child: Text(contact.name.substring(0, 1).toUpperCase()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (contact.taxNumber.isNotEmpty) contact.taxNumber,
                            if (contact.phone.isNotEmpty) contact.phone,
                          ].join(' · '),
                          style: TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isSettled
                            ? 'Bakiye yok'
                            : '${isReceivable ? 'Alacak' : 'Borç'}: ${CurrencyHelper.formatFromKurus(kurus)}',
                        textAlign: TextAlign.end,
                        style: TextStyle(color: color, fontWeight: FontWeight.w700),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Cariyi düzenle',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => onEdit(contact),
                          ),
                          IconButton(
                            tooltip: 'Cariyi sil',
                            icon: const Icon(Icons.delete_outline),
                            color: AppTheme.expenseColor,
                            onPressed: () => onDelete(contact),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
