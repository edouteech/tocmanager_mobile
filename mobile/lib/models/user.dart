class AppUser {
  final String id;
  final String username;
  final String? email;
  final String? fullName;
  final String role; // 'superadmin', 'merchant', 'admin', 'manager', 'cashier'
  final List<String> permissions;
  final bool hasPin;
  final bool isActive;
  final List<String> assignedMagasinIds;

  const AppUser({
    required this.id,
    required this.username,
    this.email,
    this.fullName,
    required this.role,
    this.permissions = const [],
    this.hasPin = false,
    this.isActive = true,
    this.assignedMagasinIds = const [],
  });

  bool get isAdmin => role == 'admin' || role == 'superadmin';
  bool get isOwner => role == 'owner' || role == 'merchant' || role == 'superadmin' || role == 'admin';
  bool get isManager => role == 'manager';
  bool get isCashier => role == 'cashier';

  bool hasPermission(String perm) {
    if (isAdmin || isOwner || permissions.contains('*')) return true;
    return permissions.contains(perm);
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      username: map['username'] as String,
      email: map['email'] as String?,
      fullName: map['full_name'] as String?,
      role: map['role'] as String? ?? 'cashier',
      permissions: (map['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      hasPin: map['has_pin'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true,
      assignedMagasinIds: (map['assigned_magasin_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
      'permissions': permissions,
      'has_pin': hasPin,
      'is_active': isActive,
      'assigned_magasin_ids': assignedMagasinIds,
    };
  }
}
