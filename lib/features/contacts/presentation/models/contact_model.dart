/// Cari hesap tipi.
enum ContactType { customer, supplier, both }

extension ContactTypeLabel on ContactType {
  String get label => switch (this) {
    ContactType.customer => 'Müşteri',
    ContactType.supplier => 'Tedarikçi',
    ContactType.both => 'Müşteri / Tedarikçi',
  };
}

/// Müşteri/tedarikçi cari kartı verisi.
class ContactModel {
  const ContactModel({
    required this.id,
    required this.type,
    required this.name,
    this.taxOffice = '',
    this.taxNumber = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.balance = 0,
  });

  final String id;
  final ContactType type;
  final String name;
  final String taxOffice;
  final String taxNumber;
  final String phone;
  final String email;
  final String address;

  /// Pozitif: alacak, negatif: borç.
  final double balance;

  factory ContactModel.fromJson(Map<String, dynamic> row) => ContactModel(
    id: row['id'] as String,
    type: ContactType.values.byName(row['type'] as String),
    name: row['name'] as String,
    taxOffice: row['tax_office'] as String? ?? '',
    taxNumber: row['tax_number'] as String? ?? '',
    phone: row['phone'] as String? ?? '',
    email: row['email'] as String? ?? '',
    address: row['address'] as String? ?? '',
    balance: (row['balance'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'tax_office': taxOffice,
    'tax_number': taxNumber,
    'phone': phone,
    'email': email,
    'address': address,
  };

  ContactModel copyWith({
    ContactType? type,
    String? name,
    String? taxOffice,
    String? taxNumber,
    String? phone,
    String? email,
    String? address,
    double? balance,
  }) {
    return ContactModel(
      id: id,
      type: type ?? this.type,
      name: name ?? this.name,
      taxOffice: taxOffice ?? this.taxOffice,
      taxNumber: taxNumber ?? this.taxNumber,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      balance: balance ?? this.balance,
    );
  }
}
