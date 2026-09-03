class Supplier {
  final int? id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final double balance; // Positive = we owe supplier money
  final String? notes;
  final DateTime createdAt;

  Supplier({
    this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.balance = 0,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'balance': balance,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      name: map['name'] as String,
      contactPerson: map['contact_person'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Supplier copyWith({
    int? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    double? balance,
    String? notes,
    DateTime? createdAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
