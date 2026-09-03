class VenteItem {
  final int? id;
  final int? venteId;
  final int productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double total;

  const VenteItem({
    this.id,
    this.venteId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
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
  }) {
    return VenteItem(
      id: id ?? this.id,
      venteId: venteId ?? this.venteId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? (quantity != null || unitPrice != null ? (quantity ?? this.quantity) * (unitPrice ?? this.unitPrice) : this.total),
    );
  }
}

class Vente {
  final int? id;
  final String ticketNumber;
  final int? clientId;
  final String? clientName;
  final double totalAmount;
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
    this.paidAmount = 0,
    this.paymentMethod = 'Espèces',
    required this.date,
    this.notes,
    this.items = const [],
  });

  bool get isPaid => paidAmount >= totalAmount;
  bool get isCredit => paidAmount < totalAmount;
  double get remainingAmount => isCredit ? totalAmount - paidAmount : 0.0;

  factory Vente.fromMap(Map<String, dynamic> map, {List<VenteItem> items = const []}) {
    return Vente(
      id: map['id'] as int?,
      ticketNumber: map['ticket_number'] as String? ?? 'VNT-${map['id'] ?? 0}',
      clientId: map['client_id'] as int?,
      clientName: map['client_name'] as String?,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? (map['total'] as num?)?.toDouble() ?? 0.0,
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
      'paid_amount': paidAmount,
      'payment_method': paymentMethod,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }
}
