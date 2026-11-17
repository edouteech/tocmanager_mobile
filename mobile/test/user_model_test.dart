import 'package:flutter_test/flutter_test.dart';
import 'package:tocmanager/models/user.dart';

void main() {
  group('AppUser Model & RBAC Tests', () {
    test('AppUser parses correctly from Map with admin role', () {
      final map = {
        'id': 'usr-admin-1',
        'username': 'admin_boss',
        'email': 'admin@tocmanager.com',
        'full_name': 'Super Admin',
        'role': 'admin',
        'permissions': ['*'],
        'has_pin': true,
        'is_active': true,
      };

      final user = AppUser.fromMap(map);
      expect(user.id, 'usr-admin-1');
      expect(user.username, 'admin_boss');
      expect(user.isAdmin, isTrue);
      expect(user.isOwner, isTrue);
      expect(user.isManager, isFalse);
      expect(user.isCashier, isFalse);
      expect(user.hasPin, isTrue);
      expect(user.isActive, isTrue);
      expect(user.hasPermission('users.manage'), isTrue);
    });

    test('AppUser parses correctly for merchant/owner with multi-magasins', () {
      final map = {
        'id': 'usr-owner-1',
        'username': 'amadou_proprio',
        'email': 'amadou@boutique.com',
        'full_name': 'Amadou Propriétaire',
        'role': 'merchant',
        'permissions': ['*'],
        'has_pin': true,
        'is_active': true,
        'assigned_magasin_ids': ['mag-01', 'mag-02'],
      };

      final user = AppUser.fromMap(map);
      expect(user.isOwner, isTrue);
      expect(user.assignedMagasinIds.length, 2);
      expect(user.assignedMagasinIds.contains('mag-01'), isTrue);
      expect(user.hasPermission('reports.consolidated'), isTrue);
    });

    test('AppUser parses correctly for cashier with assigned single magasin', () {
      final map = {
        'id': 'usr-cashier-2',
        'username': 'caissier_junior',
        'role': 'cashier',
        'permissions': ['sales.create'],
        'has_pin': false,
        'is_active': false,
        'assigned_magasin_ids': ['mag-01'],
      };

      final user = AppUser.fromMap(map);
      expect(user.isAdmin, isFalse);
      expect(user.isOwner, isFalse);
      expect(user.isCashier, isTrue);
      expect(user.hasPin, isFalse);
      expect(user.isActive, isFalse);
      expect(user.assignedMagasinIds, ['mag-01']);
      expect(user.hasPermission('sales.create'), isTrue);
      expect(user.hasPermission('users.manage'), isFalse);
    });

    test('AppUser toMap serializes all fields properly', () {
      const user = AppUser(
        id: '123',
        username: 'testuser',
        role: 'manager',
        isActive: true,
        hasPin: true,
        assignedMagasinIds: ['mag-01'],
      );

      final map = user.toMap();
      expect(map['id'], '123');
      expect(map['username'], 'testuser');
      expect(map['role'], 'manager');
      expect(map['is_active'], isTrue);
      expect(map['has_pin'], isTrue);
      expect(map['assigned_magasin_ids'], ['mag-01']);
    });
  });
}
