import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/approvisionnement_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/client_provider.dart';
import 'providers/decaissement_provider.dart';
import 'providers/product_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/tenant_provider.dart';
import 'providers/vente_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/pin_lock_screen.dart';
import 'screens/select_boutique_screen.dart';
import 'screens/select_magasin_screen.dart';
import 'theme/app_theme.dart';

export 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await initializeDateFormatting('fr_FR', null);
  runApp(const TocManagerApp());
}

class TocManagerApp extends StatelessWidget {
  const TocManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkInitialSession()),
        ChangeNotifierProvider(create: (_) => TenantProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..load()),
        ChangeNotifierProvider(create: (_) => ProductProvider()..load()),
        ChangeNotifierProvider(create: (_) => ApprovisionnementProvider()),
        ChangeNotifierProvider(create: (_) => VenteProvider()),
        ChangeNotifierProvider(create: (_) => DecaissementProvider()..load()),
        ChangeNotifierProvider(create: (_) => ClientProvider()..loadClients()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()..loadSuppliers()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
      ],
      child: MaterialApp(
        title: 'TocManager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AppRootGate(),
      ),
    );
  }
}

class AppRootGate extends StatelessWidget {
  const AppRootGate({super.key});

  Widget _splashLoader() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', height: 48),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tenant = context.watch<TenantProvider>();

    if (!auth.isInitialized) return _splashLoader();
    if (!auth.isAuthenticated) return const LoginScreen();
    if (auth.isPinLocked) {
      return PinLockScreen(onUnlocked: () {});
    }

    final currentUser = auth.currentUser;
    if (currentUser != null && !tenant.isInitialized) {
      if (!tenant.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.read<TenantProvider>().initializeForUser(currentUser);
          }
        });
      }
      return _splashLoader();
    }

    if (tenant.needsBoutiqueSelection) return const SelectBoutiqueScreen();
    if (tenant.needsMagasinSelection) return const SelectMagasinScreen();
    return const MainShell();
  }
}
