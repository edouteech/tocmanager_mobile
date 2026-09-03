class Product {
  final int? id;
  final int? categoryId;
  final int? supplierId;
  final String name;
  final String? description;
  final double price; // Prix Détail
  final double priceSemiWholesale; // Prix Demi-Gros
  final double priceWholesale; // Prix Gros
  final double minQtySemiWholesale; // Quantité minimale Demi-Gros
  final double minQtyWholesale; // Quantité minimale Gros
  final double costPrice;
  final double quantity;
  final String unit;
  final String? barcode;
  final double alertQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? imagePath;

  const Product({
    this.id,
    this.categoryId,
    this.supplierId,
    required this.name,
    this.description,
    required this.price,
    this.priceSemiWholesale = 0,
    this.priceWholesale = 0,
    this.minQtySemiWholesale = 0,
    this.minQtyWholesale = 0,
    this.costPrice = 0,
    required this.quantity,
    this.unit = 'pce',
    this.barcode,
    this.alertQuantity = 5,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => quantity <= alertQuantity;
  double get stockValue => quantity * costPrice;

  factory Product.fromMap(Map<String, dynamic> map) => Product(
        id: map['id'] as int?,
        categoryId: map['category_id'] as int?,
        supplierId: map['supplier_id'] as int?,
        name: map['name'] as String,
        description: map['description'] as String?,
        price: (map['price'] as num).toDouble(),
        priceSemiWholesale: (map['price_semi_wholesale'] as num?)?.toDouble() ?? 0,
        priceWholesale: (map['price_wholesale'] as num?)?.toDouble() ?? 0,
        minQtySemiWholesale: (map['min_qty_semi_wholesale'] as num?)?.toDouble() ?? 0,
        minQtyWholesale: (map['min_qty_wholesale'] as num?)?.toDouble() ?? 0,
        costPrice: (map['cost_price'] as num).toDouble(),
        quantity: (map['quantity'] as num).toDouble(),
        unit: map['unit'] as String? ?? 'pce',
        barcode: map['barcode'] as String?,
        alertQuantity: (map['alert_quantity'] as num?)?.toDouble() ?? 5,
        imagePath: map['image_path'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'category_id': categoryId,
        'supplier_id': supplierId,
        'name': name,
        'description': description,
        'price': price,
        'price_semi_wholesale': priceSemiWholesale,
        'price_wholesale': priceWholesale,
        'min_qty_semi_wholesale': minQtySemiWholesale,
        'min_qty_wholesale': minQtyWholesale,
        'cost_price': costPrice,
        'quantity': quantity,
        'unit': unit,
        'barcode': barcode,
        'alert_quantity': alertQuantity,
        'image_path': imagePath,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Product copyWith({
    int? id,
    int? categoryId,
    int? supplierId,
    String? name,
    String? description,
    double? price,
    double? priceSemiWholesale,
    double? priceWholesale,
    double? minQtySemiWholesale,
    double? minQtyWholesale,
    double? costPrice,
    double? quantity,
    String? unit,
    String? barcode,
    double? alertQuantity,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Product(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        supplierId: supplierId ?? this.supplierId,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        priceSemiWholesale: priceSemiWholesale ?? this.priceSemiWholesale,
        priceWholesale: priceWholesale ?? this.priceWholesale,
        minQtySemiWholesale: minQtySemiWholesale ?? this.minQtySemiWholesale,
        minQtyWholesale: minQtyWholesale ?? this.minQtyWholesale,
        costPrice: costPrice ?? this.costPrice,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        barcode: barcode ?? this.barcode,
        alertQuantity: alertQuantity ?? this.alertQuantity,
        imagePath: imagePath ?? this.imagePath,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
