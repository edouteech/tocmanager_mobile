import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tocmanager/models/plan_limit_error.dart';
import 'package:tocmanager/models/tenant.dart';
import 'package:tocmanager/models/user.dart';
import 'package:tocmanager/providers/auth_provider.dart';
import 'package:tocmanager/providers/tenant_provider.dart';
import 'package:tocmanager/screens/pin_lock_screen.dart';
import 'package:tocmanager/screens/select_magasin_screen.dart';
import 'package:tocmanager/services/secure_storage_service.dart';
import 'package:tocmanager/widgets/plan_upsell_dialog.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('SecureStorageService.apiUrl uses compile-time API_URL with HTTPS prod fallback', () {
    expect(SecureStorageService.apiUrl, startsWith('https://'));
    expect(
      SecureStorageService.apiUrl,
      'https://api.tocmanager.locarapide.com/api/v1',
    );
  });

  testWidgets('PlanUpsellDialog shows quota/feature details and closes on Compris', (tester) async {
    const err = PlanLimitError(
      code: 'PLAN_QUOTA_EXCEEDED',
      feature: 'max_products',
      currentPlan: 'starter',
      recommendedPlan: 'pro',
      message: 'Quota produits atteint.',
      limit: 500,
      current: 500,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => PlanUpsellDialog.show(context, err),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Quota du forfait atteint'), findsOneWidget);
    expect(find.text('Quota produits atteint.'), findsOneWidget);
    expect(find.textContaining('PRO'), findsOneWidget);

    await tester.tap(find.text('Compris'));
    await tester.pumpAndSettle();
    expect(find.text('Quota du forfait atteint'), findsNothing);
  });

  testWidgets('SelectMagasinScreen displays Passer for owner and hides Passer for cashier', (tester) async {
    final c1 = const MagasinModel(id: 'm1', boutiqueId: 'b1', name: 'Caisse 1');
    final c2 = const MagasinModel(id: 'm2', boutiqueId: 'b1', name: 'Caisse 2');

    final ownerTenant = TenantProvider();
    await ownerTenant.initializeForUser(
      const AppUser(id: 'u1', username: 'owner', role: 'owner'),
      preloadedBoutiques: [BoutiqueModel(id: 'b1', slug: 's1', name: 'Shop', userRole: 'owner', magasins: [c1, c2])],
      triggerSync: false,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: ownerTenant),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(home: SelectMagasinScreen()),
      ),
    );
    expect(find.text('Passer'), findsOneWidget);

    final cashierTenant = TenantProvider();
    await cashierTenant.initializeForUser(
      const AppUser(id: 'u2', username: 'cashier', role: 'cashier', assignedMagasinIds: ['m1']),
      preloadedBoutiques: [
        BoutiqueModel(
          id: 'b1',
          slug: 's1',
          name: 'Shop',
          userRole: 'cashier',
          assignedMagasinIds: const ['m1'],
          magasins: [c1, c2],
        ),
      ],
      triggerSync: false,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: cashierTenant),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(home: SelectMagasinScreen()),
      ),
    );
    expect(find.text('Passer'), findsNothing);
  });

  testWidgets('PinLockScreen renders 6 dots for 6-digit PIN and locks keypad after 3 failures', (tester) async {
    await tester.runAsync(() async {
      await SecureStorageService.saveTokens(accessToken: 't', refreshToken: 'r');
      await SecureStorageService.saveUser(const AppUser(id: 'u', username: 'cash', role: 'cashier', hasPin: true));
      await SecureStorageService.savePin('654321');
    });

    final auth = AuthProvider();
    await tester.runAsync(() => auth.checkInitialSession());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(home: PinLockScreen(onUnlocked: () {})),
      ),
    );
    expect(find.byType(AnimatedContainer), findsNWidgets(6));

    await tester.runAsync(() async {
      await auth.unlockWithPin('000000');
      await auth.unlockWithPin('111111');
      await auth.unlockWithPin('222222');
    });
    await tester.pump();

    expect(auth.isPinBlocked, isTrue);
    expect(find.textContaining('Trop de tentatives'), findsOneWidget);
  });
}
