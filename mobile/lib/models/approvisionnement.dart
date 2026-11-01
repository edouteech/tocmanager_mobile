class Approvisionnement {
  final int? id;
  final int productId;
  final double quantity;
  final double unitPrice;
  final double total;
  final int? supplierId;
  final String? supplier;
  final double paidAmount;
  final DateTime date;
  final String? notes;

  const Approvisionnement({
    this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.supplierId,
    this.supplier,
    double? paidAmount,
    required this.date,
    this.notes,
  }) : paidAmount = paidAmount ?? total;

  double get remainingAmount => (total - paidAmount).clamp(0, double.infinity);
  bool get isCredit => remainingAmount > 0.01;

  factory Approvisionnement.fromMap(Map<String, dynamic> map) {
    final t = (map['total'] as num).toDouble();
    return Approvisionnement(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      total: t,
      supplierId: map['supplier_id'] as int?,
      supplier: map['supplier'] as String?,
      paidAmount: map['paid_amount'] != null ? (map['paid_amount'] as num).toDouble() : t,
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
      'supplier_id': supplierId,
      'supplier': supplier,
      'paid_amount': paidAmount,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  Approvisionnement copyWith({
    int? id,
    int? productId,
    double? quantity,
    double? unitPrice,
    double? total,
    int? supplierId,
    String? supplier,
    double? paidAmount,
    DateTime? date,
    String? notes,
  }) {
    return Approvisionnement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
      supplierId: supplierId ?? this.supplierId,
      supplier: supplier ?? this.supplier,
      paidAmount: paidAmount ?? this.paidAmount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}
