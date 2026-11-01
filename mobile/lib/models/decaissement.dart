class Decaissement {
  final int? id;
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final String? reference;

  const Decaissement({
    this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.reference,
  });

  factory Decaissement.fromMap(Map<String, dynamic> map) {
    return Decaissement(
      id: map['id'] as int?,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      reference: map['reference'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'description': description,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
      'reference': reference,
    };
  }
}
