class Approvisionnement {
  final int? id;
  final int productId;
  final double quantity;
  final double unitPrice;
  final double total;
  final String? supplier;
  final DateTime date;
  final String? notes;

  const Approvisionnement({
    this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.supplier,
    required this.date,
    this.notes,
  });

  factory Approvisionnement.fromMap(Map<String, dynamic> map) {
    return Approvisionnement(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      supplier: map['supplier'] as String?,
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
      'supplier': supplier,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }
}
