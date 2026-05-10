import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'providers/category_provider.dart';
import 'providers/product_provider.dart';
import 'providers/approvisionnement_provider.dart';
import 'providers/decaissement_provider.dart';
import 'providers/vente_provider.dart';
import 'screens/home_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/products_screen.dart';
import 'screens/approvisionnement_screen.dart';
import 'screens/decaissement_screen.dart';
import 'screens/vente_screen.dart';
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
        ChangeNotifierProvider(create: (_) => DecaissementProvider()..load()),
        ChangeNotifierProvider(create: (_) => VenteProvider()),
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
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    ProductsScreen(),
    CategoriesScreen(),
  ];

  void _navigate(int index) {
    // Pop the drawer first, then navigate
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ApprovisionScreen()),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DecaissementScreen()),
      );
    } else if (index == 5) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VenteScreen()),
      );
    } else if (index < _screens.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(index: _currentIndex, children: _screens),
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
            _navItem(0, Icons.home_outlined, Icons.home, 'Accueil'),
            _navItem(1, Icons.inventory_2_outlined, Icons.inventory_2, 'Produits'),
            _navItem(2, Icons.category_outlined, Icons.category, 'Catégories'),
            _menuButton(),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final active = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  active ? activeIcon : icon,
                  key: ValueKey(active),
                  color: active ? AppColors.primary : AppColors.textLight,
                  size: 24,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.primary : AppColors.textLight,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
              if (active)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 18,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                const SizedBox(height: 7),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton() {
    return Expanded(
      child: InkWell(
        onTap: () => _scaffoldKey.currentState?.openDrawer(),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu, color: AppColors.textLight, size: 24),
              SizedBox(height: 3),
              Text(
                'Menu',
                style: TextStyle(color: AppColors.textLight, fontSize: 11),
              ),
              SizedBox(height: 7),
            ],
          ),
        ),
      ),
    );
  }
}
