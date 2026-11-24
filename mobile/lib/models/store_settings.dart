class StoreSettings {
  final String name;
  final String phone;
  final String email;
  final String address;
  final String receiptFooter;
  final String currency;
  final bool enableAverageCostPrice;

  const StoreSettings({
    this.name = 'TOC Manager',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.receiptFooter = 'Merci de votre confiance !',
    this.currency = 'FCFA',
    this.enableAverageCostPrice = false,
  });

  StoreSettings copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? receiptFooter,
    String? currency,
    bool? enableAverageCostPrice,
  }) {
    return StoreSettings(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      currency: currency ?? this.currency,
      enableAverageCostPrice:
          enableAverageCostPrice ?? this.enableAverageCostPrice,
    );
  }
}
