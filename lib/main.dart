import 'providers/settings_provider.dart';
import 'screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'providers/category_provider.dart';
import 'providers/product_provider.dart';
import 'providers/approvisionnement_provider.dart';
import 'providers/vente_provider.dart';
import 'providers/decaissement_provider.dart';
import 'providers/client_provider.dart';
import 'providers/supplier_provider.dart';
import 'screens/home_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/products_screen.dart';
import 'screens/approvisionnement_screen.dart';
import 'screens/vente_screen.dart';
import 'screens/decaissement_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/suppliers_screen.dart';
import 'screens/reports_screen.dart';
import 'widgets/app_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const TocManagerApp());
}

class TocManagerApp extends StatelessWidget {
  const TocManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _homeKey = GlobalKey();
  int _currentIndex = 0;

  Future<void> _navigate(int index, {String? statusFilter}) async {
    if (index == 3) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ClientsScreen()),
      );
      (_homeKey.currentState as dynamic)?.reload();
    } else if (index == 7) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SuppliersScreen()),
      );
      (_homeKey.currentState as dynamic)?.reload();
    } else if (index == 4) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ApprovisionScreen()),
      );
      (_homeKey.currentState as dynamic)?.reload();
    } else if (index == 5) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VenteScreen()),
      );
      (_homeKey.currentState as dynamic)?.reload();
    } else if (index == 6) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DecaissementScreen()),
      );
      (_homeKey.currentState as dynamic)?.reload();
    } else if (index == 9) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReportsScreen()),
      );
      (_homeKey.currentState as dynamic)?.reload();
    } else if (index == 10) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
      (_homeKey.currentState as dynamic)?.reload();
    } else if (index < 3) {
      setState(() => _currentIndex = index);
      if (index == 0) {
        (_homeKey.currentState as dynamic)?.reload();
      } else if (index == 1 && statusFilter != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductsScreen(initialStatusFilter: statusFilter),
          ),
        );
        (_homeKey.currentState as dynamic)?.reload();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        key: _homeKey,
        onNav: _navigate,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      ProductsScreen(onBackToHome: () => _navigate(0)),
      CategoriesScreen(onBackToHome: () => _navigate(0)),
    ];

    return Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(index: _currentIndex, children: screens),
      drawer: AppDrawer(currentIndex: _currentIndex, onNav: _navigate),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _bottomItem(Icons.arrow_downward_outlined, 'Appro', () => _navigate(4)),
            _bottomItem(Icons.shopping_cart_outlined, 'Ventes', () => _navigate(5)),
            _bottomItem(Icons.account_balance_wallet_outlined, 'Dépenses', () => _navigate(6)),
            _bottomItem(Icons.people_outline, 'Clients', () => _navigate(3)),
            _bottomItem(Icons.bar_chart_outlined, 'Rapport', () => _navigate(9)),
          ],
        ),
      ),
    );
  }

  Widget _bottomItem(IconData icon, String label, VoidCallback? onTap) {
    final disabled = onTap == null;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: disabled
                    ? AppColors.textLight.withAlpha(80)
                    : AppColors.textLight,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: disabled
                      ? AppColors.textLight.withAlpha(80)
                      : AppColors.textLight,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 7),
            ],
          ),
        ),
      ),
    );
  }
}
