class Vente {
  final int? id;
  final int productId;
  final double quantity;
  final double unitPrice;
  final double total;
  final String? clientName;
  final DateTime date;
  final String? notes;

  const Vente({
    this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.clientName,
    required this.date,
    this.notes,
  });

  factory Vente.fromMap(Map<String, dynamic> map) {
    return Vente(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      clientName: map['client_name'] as String?,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
      'client_name': clientName,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }
}
