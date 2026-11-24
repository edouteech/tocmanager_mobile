import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/tenant_provider.dart';
import '../screens/select_magasin_screen.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import 'app_drawer_components.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onNav;

  const AppDrawer({super.key, required this.currentIndex, required this.onNav});

  Future<void> _handleLogout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final tenant = context.read<TenantProvider>();
    final pendingCount = await SyncService.instance.getPendingQueueCount();
    if (!context.mounted) return;

    if (pendingCount > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Données non synchronisées'),
          content: Text(
            '$pendingCount opération(s) hors-ligne n\'ont pas encore été envoyées au serveur. Voulez-vous tout de même vous déconnecter et purger les données locales ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Déconnecter'),
            ),
          ],
        ),
      );
      if (proceed != true || !context.mounted) return;
    }

    Navigator.of(context).pop();
    await auth.logout();
    tenant.reset();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tenant = context.watch<TenantProvider>();
    final isAdmin = auth.currentUser?.isAdmin ?? false;
    final canAccessBackoffice = auth.currentUser?.canAccessBackofficeModules ?? false;
    final canViewAudit = auth.currentUser?.canViewAudit ?? false;
    final canSwitchMagasin =
        tenant.canConsolidate || tenant.magasins.length > 1 || tenant.boutiques.length > 1;
    final activeScopeLabel = tenant.isConsolidatedMode
        ? 'Vue Consolidée'
        : (tenant.currentMagasin?.name ?? 'Aucun magasin');

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          const AppDrawerHeader(),
          if (tenant.currentBoutique != null)
            AppDrawerTenantBanner(
              boutiqueName: tenant.currentBoutique!.displayName,
              activeScopeLabel: activeScopeLabel,
              onSwitch: canSwitchMagasin
                  ? () {
                      final nav = Navigator.of(context);
                      nav.pop();
                      nav.push(MaterialPageRoute(builder: (_) => const SelectMagasinScreen(allowBackPop: true)));
                    }
                  : null,
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                AppDrawerNavItem(index: 0, icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Accueil', current: currentIndex, onTap: onNav),
                AppDrawerNavItem(index: 1, icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Produits', current: currentIndex, onTap: onNav),
                AppDrawerNavItem(index: 2, icon: Icons.category_outlined, activeIcon: Icons.category, label: 'Catégories', current: currentIndex, onTap: onNav),
                AppDrawerNavItem(index: 3, icon: Icons.people_outline, activeIcon: Icons.people, label: 'Clients', current: currentIndex, onTap: onNav),
                if (canAccessBackoffice)
                  AppDrawerNavItem(index: 7, icon: Icons.business_outlined, activeIcon: Icons.business, label: 'Fournisseurs', current: currentIndex, onTap: onNav),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(color: AppColors.divider),
                ),
                if (canAccessBackoffice)
                  AppDrawerNavItem(index: 4, icon: Icons.arrow_downward_outlined, activeIcon: Icons.arrow_downward, label: 'Approvisionnements', current: currentIndex, onTap: onNav),
                AppDrawerNavItem(index: 5, icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart, label: 'Ventes', current: currentIndex, onTap: onNav),
                if (canAccessBackoffice) ...[
                  AppDrawerNavItem(index: 6, icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Décaissements', current: currentIndex, onTap: onNav),
                  AppDrawerNavItem(index: 9, icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Rapports & Analytique', current: currentIndex, onTap: onNav),
                ],
                if (isAdmin)
                  AppDrawerNavItem(index: 11, icon: Icons.manage_accounts_outlined, activeIcon: Icons.manage_accounts, label: 'Utilisateurs & Rôles', current: currentIndex, onTap: onNav),
                if (canViewAudit)
                  AppDrawerNavItem(index: 12, icon: Icons.shield_outlined, activeIcon: Icons.shield, label: 'Journal d\'Audit', current: currentIndex, onTap: onNav),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Divider(color: AppColors.divider),
          ),
          AppDrawerNavItem(index: 10, icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Paramètres', current: currentIndex, onTap: onNav),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _handleLogout(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: AppColors.danger, size: 22),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Déconnexion',
                          style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 20, top: 6),
            child: Text('tocmanager v1.0.0', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
