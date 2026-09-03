class Client {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double balance; // Positive = client owes money (créance), Negative = overpaid
  final String clientType; // 'detail', 'demi_gros', 'gros'
  final String? notes;
  final DateTime createdAt;

  Client({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.balance = 0,
    this.clientType = 'detail',
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isGros => clientType == 'gros';
  bool get isDemiGros => clientType == 'demi_gros';
  bool get hasCreance => balance > 0.01;
  bool get hasAvoir => balance < -0.01;
  double get creanceAmount => balance > 0 ? balance : 0.0;
  double get avoirAmount => balance < 0 ? balance.abs() : 0.0;

  String get typeLabel {
    switch (clientType) {
      case 'gros':
        return 'Grossiste';
      case 'demi_gros':
        return 'Demi-Gros';
      default:
        return 'Détail';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'balance': balance,
      'client_type': clientType,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      clientType: map['client_type'] as String? ?? 'detail',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Client copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? balance,
    String? clientType,
    String? notes,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      balance: balance ?? this.balance,
      clientType: clientType ?? this.clientType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
