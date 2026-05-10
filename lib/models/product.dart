class Product {
  final int? id;
  final int? categoryId;
  final String name;
  final String? description;
  final double price;
  final double costPrice;
  final double quantity;
  final String unit;
  final String? barcode;
  final double alertQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.costPrice = 0,
    required this.quantity,
    this.unit = 'pce',
    this.barcode,
    this.alertQuantity = 5,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => quantity <= alertQuantity;
  double get stockValue => quantity * costPrice;

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as int?,
        categoryId: map['category_id'] as int?,
        name: map['name'] as String,
        description: map['description'] as String?,
        price: (map['price'] as num).toDouble(),
        costPrice: (map['cost_price'] as num).toDouble(),
        quantity: (map['quantity'] as num).toDouble(),
        unit: map['unit'] as String? ?? 'pce',
        barcode: map['barcode'] as String?,
        alertQuantity: (map['alert_quantity'] as num?)?.toDouble() ?? 5,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'category_id': categoryId,
        'name': name,
        'description': description,
        'price': price,
        'cost_price': costPrice,
        'quantity': quantity,
        'unit': unit,
        'barcode': barcode,
        'alert_quantity': alertQuantity,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Product copyWith({
    int? id,
    int? categoryId,
    String? name,
    String? description,
    double? price,
    double? costPrice,
    double? quantity,
    String? unit,
    String? barcode,
    double? alertQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Product(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        costPrice: costPrice ?? this.costPrice,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        barcode: barcode ?? this.barcode,
        alertQuantity: alertQuantity ?? this.alertQuantity,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
