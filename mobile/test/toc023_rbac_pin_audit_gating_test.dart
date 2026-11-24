import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tocmanager/models/plan_limit_error.dart';
import 'package:tocmanager/models/user.dart';
import 'package:tocmanager/providers/auth_provider.dart';
import 'package:tocmanager/services/api_client.dart';
import 'package:tocmanager/services/secure_storage_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('TOC-023 RBAC, 4-6 digit PIN lockout, Superadmin block & 403 Plan Gating', () {
    test('AppUser role getters distinguish superadmin, owner, store_admin, manager and cashier', () {
      const owner = AppUser(id: '1', username: 'o', role: 'owner');
      const merchant = AppUser(id: '2', username: 'm', role: 'merchant');
      const storeAdmin = AppUser(id: '3', username: 'sa', role: 'store_admin');
      const admin = AppUser(id: '4', username: 'a', role: 'admin');
      const manager = AppUser(id: '5', username: 'mg', role: 'manager');
      const cashier = AppUser(id: '6', username: 'c', role: 'cashier');
      const superadmin = AppUser(id: '7', username: 'su', role: 'superadmin');

      expect(owner.isOwner, isTrue);
      expect(owner.isAdmin, isTrue);
      expect(owner.canAccessBackofficeModules, isTrue);
      expect(owner.canViewAudit, isTrue);

      expect(merchant.isOwner, isTrue);
      expect(merchant.isAdmin, isTrue);

      expect(storeAdmin.isOwner, isFalse);
      expect(storeAdmin.isAdmin, isTrue);
      expect(storeAdmin.canAccessBackofficeModules, isTrue);

      expect(admin.isOwner, isFalse);
      expect(admin.isAdmin, isTrue);

      expect(manager.isAdmin, isFalse);
      expect(manager.isManager, isTrue);
      expect(manager.canAccessBackofficeModules, isTrue);
      expect(manager.canViewAudit, isTrue);

      expect(cashier.isCashier, isTrue);
      expect(cashier.canAccessBackofficeModules, isFalse);
      expect(cashier.canViewAudit, isFalse);

      expect(superadmin.isSuperAdmin, isTrue);
      expect(superadmin.isAdmin, isFalse);
      expect(superadmin.isOwner, isFalse);
      expect(superadmin.canAccessBackofficeModules, isFalse);
      expect(superadmin.canViewAudit, isFalse);
    });

    test('AuthProvider.login blocks superadmin accounts and persists no session', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'access_token': 'tok-super',
            'refresh_token': 'ref-super',
            'user': {
              'id': 'u-su',
              'username': 'root',
              'role': 'superadmin',
            },
          }),
          200,
        );
      });

      final auth = AuthProvider(httpClient: mockClient);
      final ok = await auth.login(usernameOrEmail: 'root', password: 'secret');

      expect(ok, isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.currentUser, isNull);
      expect(auth.errorMessage, contains('/admin'));
      expect(await SecureStorageService.getAccessToken(), isNull);
      expect(await SecureStorageService.getUser(), isNull);
    });

    test('SecureStorageService supports 4 and 6 digit PINs and rejects invalid lengths', () async {
      await SecureStorageService.savePin('654321');
      expect(await SecureStorageService.getPinLength(), 6);
      expect(await SecureStorageService.verifyPin('654321'), isTrue);
      expect(await SecureStorageService.verifyPin('654320'), isFalse);

      await SecureStorageService.savePin('2468');
      expect(await SecureStorageService.getPinLength(), 4);
      expect(await SecureStorageService.verifyPin('2468'), isTrue);

      expect(() => SecureStorageService.savePin('123'), throwsArgumentError);
      expect(() => SecureStorageService.savePin('12345'), throwsArgumentError);
      expect(() => SecureStorageService.savePin('abcd'), throwsArgumentError);
    });

    test('AuthProvider clamps PIN attempts to 0 and purges tokens + PIN on 3rd failure', () async {
      await SecureStorageService.saveTokens(
        accessToken: 'acc-1',
        refreshToken: 'ref-1',
      );
      await SecureStorageService.saveUser(
        const AppUser(id: 'u-1', username: 'cashier1', role: 'cashier', hasPin: true),
      );
      await SecureStorageService.savePin('135790');

      final auth = AuthProvider();
      await auth.checkInitialSession();
      expect(auth.expectedPinLength, 6);
      expect(auth.isPinLocked, isTrue);
      expect(auth.pinAttemptsRemaining, 3);
      expect(auth.isPinBlocked, isFalse);

      expect(await auth.unlockWithPin('000000'), isFalse);
      expect(auth.pinAttemptsRemaining, 2);

      expect(await auth.unlockWithPin('111111'), isFalse);
      expect(auth.pinAttemptsRemaining, 1);

      expect(await auth.unlockWithPin('222222'), isFalse);
      expect(auth.pinAttemptsRemaining, 0);
      expect(auth.isPinBlocked, isTrue);
      expect(await SecureStorageService.getAccessToken(), isNull);
      expect(await SecureStorageService.hasPinConfigured(), isFalse);

      // 4th failure stays clamped at 0 without going negative
      expect(await auth.unlockWithPin('135790'), isFalse);
      expect(auth.pinAttemptsRemaining, 0);
    });

    test('PlanLimitError & ApiClient.inspectResponseForPlanError emit on 403 plan gating only', () async {
      final events = <PlanLimitError>[];
      final sub = ApiClient.onPlanLimitError.listen(events.add);

      final lockedRes = http.Response(
        jsonEncode({
          'detail': {
            'error': 'PLAN_FEATURE_LOCKED',
            'feature': 'multi_magasin',
            'current_plan': 'free',
            'recommended_plan': 'pro',
            'message': 'Multi-magasin reserve au forfait PRO.',
          },
        }),
        403,
      );
      final parsedLocked = ApiClient.inspectResponseForPlanError(lockedRes);
      expect(parsedLocked, isNotNull);
      expect(parsedLocked!.code, 'PLAN_FEATURE_LOCKED');
      expect(parsedLocked.recommendedPlan, 'pro');

      final quotaRes = http.Response(
        jsonEncode({
          'detail': {
            'error': 'PLAN_QUOTA_EXCEEDED',
            'feature': 'max_products',
            'current_plan': 'starter',
            'recommended_plan': 'pro',
            'limit': 500,
            'current': 500,
            'message': 'Quota max_products atteint (500/500).',
          },
        }),
        403,
      );
      final parsedQuota = ApiClient.inspectResponseForPlanError(quotaRes);
      expect(parsedQuota, isNotNull);
      expect(parsedQuota!.isQuotaExceeded, isTrue);
      expect(parsedQuota.limit, 500);

      final genericForbidden = http.Response(jsonEncode({'detail': 'Acces refuse'}), 403);
      expect(ApiClient.inspectResponseForPlanError(genericForbidden), isNull);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(events.length, 2);
      await sub.cancel();
    });
  });
}
