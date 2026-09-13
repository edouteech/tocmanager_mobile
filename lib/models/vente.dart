class VenteItem {
  final int? id;
  final int? venteId;
  final int productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double total;
  final double? costPrice;

  const VenteItem({
    this.id,
    this.venteId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.costPrice,
  });

  factory VenteItem.fromMap(Map<String, dynamic> map) {
    return VenteItem(
      id: map['id'] as int?,
      venteId: map['vente_id'] as int?,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String? ?? 'Produit #${map['product_id']}',
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      costPrice: map['cost_price'] != null ? (map['cost_price'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap({int? venteIdParam}) {
    return {
      if (id != null) 'id': id,
      'vente_id': venteIdParam ?? venteId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total': total,
      if (costPrice != null) 'cost_price': costPrice,
    };
  }

  VenteItem copyWith({
    int? id,
    int? venteId,
    int? productId,
    String? productName,
    double? quantity,
    double? unitPrice,
    double? total,
    double? costPrice,
  }) {
    return VenteItem(
      id: id ?? this.id,
      venteId: venteId ?? this.venteId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? (quantity != null || unitPrice != null ? (quantity ?? this.quantity) * (unitPrice ?? this.unitPrice) : this.total),
      costPrice: costPrice ?? this.costPrice,
    );
  }
}

class Vente {
  final int? id;
  final String ticketNumber;
  final int? clientId;
  final String? clientName;
  final double totalAmount;
  final double discountAmount;
  final double paidAmount;
  final String paymentMethod;
  final DateTime date;
  final String? notes;
  final List<VenteItem> items;

  const Vente({
    this.id,
    required this.ticketNumber,
    this.clientId,
    this.clientName,
    required this.totalAmount,
    this.discountAmount = 0.0,
    this.paidAmount = 0,
    this.paymentMethod = 'Espèces',
    required this.date,
    this.notes,
    this.items = const [],
  });

  bool get isPaid => paidAmount >= totalAmount;
  bool get isCredit => paidAmount < totalAmount;
  double get remainingAmount => isCredit ? totalAmount - paidAmount : 0.0;
  double get subtotalAmount => items.isNotEmpty
      ? items.fold(0.0, (sum, item) => sum + item.total)
      : (totalAmount + discountAmount);

  factory Vente.fromMap(Map<String, dynamic> map, {List<VenteItem> items = const []}) {
    return Vente(
      id: map['id'] as int?,
      ticketNumber: map['ticket_number'] as String? ?? 'VNT-${map['id'] ?? 0}',
      clientId: map['client_id'] as int?,
      clientName: map['client_name'] as String?,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? (map['total'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? (map['total_amount'] as num?)?.toDouble() ?? (map['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method'] as String? ?? 'Espèces',
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      items: items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'ticket_number': ticketNumber,
      'client_id': clientId,
      'client_name': clientName,
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'paid_amount': paidAmount,
      'payment_method': paymentMethod,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  Vente copyWith({
    int? id,
    String? ticketNumber,
    int? clientId,
    String? clientName,
    double? totalAmount,
    double? discountAmount,
    double? paidAmount,
    String? paymentMethod,
    DateTime? date,
    String? notes,
    List<VenteItem>? items,
  }) {
    return Vente(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      items: items ?? this.items,
    );
  }
}
