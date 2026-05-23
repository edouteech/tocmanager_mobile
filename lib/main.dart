import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'providers/category_provider.dart';
import 'providers/product_provider.dart';
import 'providers/approvisionnement_provider.dart';
import 'providers/vente_provider.dart';
import 'screens/home_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/products_screen.dart';
import 'screens/approvisionnement_screen.dart';
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
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ApprovisionScreen()),
      );
    } else if (index == 5) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VenteScreen()),
      );
    } else if (index < 3) {
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
            _bottomItem(Icons.arrow_downward_outlined, 'Appro', () => _navigate(4)),
            _bottomItem(Icons.shopping_cart_outlined, 'Ventes', () => _navigate(5)),
            _bottomItem(Icons.inventory_outlined, 'Inventaire', null),
            _bottomItem(Icons.receipt_long_outlined, 'Facture', null),
            _bottomItem(Icons.bar_chart_outlined, 'Rapport', null),
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
