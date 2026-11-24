class MagasinModel {
  final String id;
  final String? boutiqueId;
  final String name;
  final String? code;
  final String? address;
  final String? phone;
  final bool isWarehouse;
  final bool isActive;

  const MagasinModel({
    required this.id,
    this.boutiqueId,
    required this.name,
    this.code,
    this.address,
    this.phone,
    this.isWarehouse = false,
    this.isActive = true,
  });

  factory MagasinModel.fromMap(Map<String, dynamic> map) {
    final isWh = map['is_warehouse'];
    final isAct = map['is_active'];
    return MagasinModel(
      id: map['id'] as String,
      boutiqueId: map['boutique_id'] as String?,
      name: map['name'] as String? ?? 'Magasin',
      code: map['code'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      isWarehouse: isWh is bool ? isWh : (isWh == 1),
      isActive: isAct == null ? true : (isAct is bool ? isAct : isAct == 1),
    );
  }

  Map<String, dynamic> toSqlMap(String fallbackBoutiqueId) => {
        'id': id,
        'boutique_id': boutiqueId ?? fallbackBoutiqueId,
        'name': name,
        'code': code,
        'address': address,
        'phone': phone,
        'is_warehouse': isWarehouse ? 1 : 0,
        'is_active': isActive ? 1 : 0,
      };
}

class BoutiqueModel {
  final String id;
  final String slug;
  final String name;
  final String? companyName;
  final String currency;
  final String country;
  final String? phone;
  final String? email;
  final String? address;
  final String? logoUrl;
  final String ownerUserId;
  final bool isActive;
  final List<MagasinModel> magasins;
  final String? userRole;
  final List<String> assignedMagasinIds;

  const BoutiqueModel({
    required this.id,
    required this.slug,
    required this.name,
    this.companyName,
    this.currency = 'XOF',
    this.country = 'Sénégal',
    this.phone,
    this.email,
    this.address,
    this.logoUrl,
    this.ownerUserId = '',
    this.isActive = true,
    this.magasins = const [],
    this.userRole,
    this.assignedMagasinIds = const [],
  });

  String get displayName => (companyName != null && companyName!.trim().isNotEmpty) ? companyName! : name;

  factory BoutiqueModel.fromMap(Map<String, dynamic> map) {
    final rawMagasins = map['magasins'] as List<dynamic>? ?? const [];
    final isAct = map['is_active'];
    return BoutiqueModel(
      id: map['id'] as String,
      slug: map['slug'] as String? ?? '',
      name: map['name'] as String? ?? 'Boutique',
      companyName: map['company_name'] as String?,
      currency: map['currency'] as String? ?? 'XOF',
      country: map['country'] as String? ?? 'Sénégal',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      logoUrl: map['logo_url'] as String?,
      ownerUserId: map['owner_user_id'] as String? ?? '',
      isActive: isAct == null ? true : (isAct is bool ? isAct : isAct == 1),
      magasins: rawMagasins
          .map((m) => MagasinModel.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
      userRole: map['user_role'] as String?,
      assignedMagasinIds: (map['assigned_magasin_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class PlanStatusModel {
  final String planId;
  final String planName;
  final String planCode;
  final String status;
  final bool trialActive;
  final int trialDaysLeft;
  final Map<String, dynamic> features;

  const PlanStatusModel({
    required this.planId,
    required this.planName,
    required this.planCode,
    required this.status,
    this.trialActive = false,
    this.trialDaysLeft = 0,
    this.features = const {},
  });

  factory PlanStatusModel.fromMap(Map<String, dynamic> map) {
    final rawFeatures = map['features'];
    return PlanStatusModel(
      planId: map['plan_id'] as String? ?? '',
      planName: map['plan_name'] as String? ?? 'Starter',
      planCode: map['plan_code'] as String? ?? 'free',
      status: map['status'] as String? ?? 'active',
      trialActive: map['trial_active'] as bool? ?? false,
      trialDaysLeft: (map['trial_days_left'] as num?)?.toInt() ?? 0,
      features: rawFeatures is Map ? Map<String, dynamic>.from(rawFeatures) : const {},
    );
  }

  bool hasFeature(String code) {
    final val = features[code];
    if (val is bool) return val;
    if (val is num) return val != 0;
    return false;
  }

  int getLimit(String code) {
    final val = features[code];
    if (val is num) return val.toInt();
    return 0;
  }
}
