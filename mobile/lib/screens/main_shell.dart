import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/client_provider.dart';
import '../providers/decaissement_provider.dart';
import '../providers/product_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/tenant_provider.dart';
import '../services/api_client.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/plan_upsell_dialog.dart';
import 'approvisionnement_screen.dart';
import 'audit_logs_screen.dart';
import 'categories_screen.dart';
import 'clients_screen.dart';
import 'decaissement_screen.dart';
import 'home_screen.dart';
import 'products_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'suppliers_screen.dart';
import 'users_screen.dart';
import 'vente_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _homeKey = GlobalKey();
  int _currentIndex = 0;
  StreamSubscription? _syncSub;
  StreamSubscription? _planErrorSub;
  bool _upsellDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<TenantProvider>().consumeOpenConsolidatedReports()) {
        _navigate(9);
      }
    });
    _syncSub = SyncService.onSyncCompleted.listen((_) {
      if (!mounted) return;
      context.read<CategoryProvider>().load();
      context.read<ProductProvider>().load();
      context.read<ClientProvider>().loadClients();
      context.read<SupplierProvider>().loadSuppliers();
      context.read<DecaissementProvider>().load();
      (_homeKey.currentState as dynamic)?.reload();
    });
    _planErrorSub = ApiClient.onPlanLimitError.listen((err) async {
      if (!mounted || _upsellDialogOpen) return;
      _upsellDialogOpen = true;
      try {
        await PlanUpsellDialog.show(context, err);
      } finally {
        _upsellDialogOpen = false;
      }
    });
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _planErrorSub?.cancel();
    super.dispose();
  }

  Widget? _screenForModalIndex(int index) {
    switch (index) {
      case 3:
        return const ClientsScreen();
      case 4:
        return const ApprovisionScreen();
      case 5:
        return const VenteScreen();
      case 6:
        return const DecaissementScreen();
      case 7:
        return const SuppliersScreen();
      case 9:
        return const ReportsScreen();
      case 10:
        return const SettingsScreen();
      case 11:
        return const UsersScreen();
      case 12:
        return const AuditLogsScreen();
      default:
        return null;
    }
  }

  Future<void> _navigate(int index, {String? statusFilter}) async {
    final user = context.read<AuthProvider>().currentUser;
    final canBackoffice = user?.canAccessBackofficeModules ?? false;
    final isAdmin = user?.isAdmin ?? false;
    final canAudit = user?.canViewAudit ?? false;

    if ((index == 4 || index == 6 || index == 7 || index == 9) && !canBackoffice) return;
    if (index == 11 && !isAdmin) return;
    if (index == 12 && !canAudit) return;

    final modalScreen = _screenForModalIndex(index);
    if (modalScreen != null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => modalScreen));
      (_homeKey.currentState as dynamic)?.reload();
      return;
    }

    if (index < 3) {
      setState(() => _currentIndex = index);
      if (index == 0) {
        (_homeKey.currentState as dynamic)?.reload();
      } else if (index == 1 && statusFilter != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductsScreen(initialStatusFilter: statusFilter)),
        );
        (_homeKey.currentState as dynamic)?.reload();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(key: _homeKey, onNav: _navigate, onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer()),
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
    final canBackoffice =
        context.watch<AuthProvider>().currentUser?.canAccessBackofficeModules ?? false;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (canBackoffice) _bottomItem(Icons.arrow_downward_outlined, 'Appro', () => _navigate(4)),
            _bottomItem(Icons.shopping_cart_outlined, 'Ventes', () => _navigate(5)),
            if (canBackoffice) _bottomItem(Icons.account_balance_wallet_outlined, 'Dépenses', () => _navigate(6)),
            _bottomItem(Icons.people_outline, 'Clients', () => _navigate(3)),
            if (canBackoffice) _bottomItem(Icons.bar_chart_outlined, 'Rapport', () => _navigate(9)),
          ],
        ),
      ),
    );
  }

  Widget _bottomItem(IconData icon, String label, VoidCallback? onTap) {
    final disabled = onTap == null;
    final color = disabled ? AppColors.textLight.withAlpha(80) : AppColors.textLight;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(color: color, fontSize: 10)),
              const SizedBox(height: 7),
            ],
          ),
        ),
      ),
    );
  }
}
