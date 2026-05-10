import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onNav;

  const AppDrawer({super.key, required this.currentIndex, required this.onNav});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _DrawerHeader(),
          const SizedBox(height: 8),
          _NavItem(
            index: 0, icon: Icons.home_outlined, activeIcon: Icons.home,
            label: 'Accueil', current: currentIndex, onTap: onNav,
          ),
          _NavItem(
            index: 1, icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2,
            label: 'Produits', current: currentIndex, onTap: onNav,
          ),
          _NavItem(
            index: 2, icon: Icons.category_outlined, activeIcon: Icons.category,
            label: 'Catégories', current: currentIndex, onTap: onNav,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(color: AppColors.divider),
          ),
          _NavItem(
            index: 3, icon: Icons.arrow_downward_outlined,
            activeIcon: Icons.arrow_downward,
            label: 'Approvisionnements', current: currentIndex, onTap: onNav,
          ),
          _NavItem(
            index: 4, icon: Icons.arrow_upward_outlined,
            activeIcon: Icons.arrow_upward,
            label: 'Décaissements', current: currentIndex, onTap: onNav,
          ),
          _NavItem(
            index: 5, icon: Icons.shopping_cart_outlined,
            activeIcon: Icons.shopping_cart,
            label: 'Ventes', current: currentIndex, onTap: onNav,
          ),
          _NavItem(
            index: 6, icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long,
            label: 'Factures', current: currentIndex, onTap: onNav,
            comingSoon: true,
          ),
          _NavItem(
            index: 6, icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart,
            label: 'Rapports', current: currentIndex, onTap: onNav,
            comingSoon: true,
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Divider(color: AppColors.divider),
          ),
          _NavItem(
            index: 7, icon: Icons.settings_outlined, activeIcon: Icons.settings,
            label: 'Paramètres', current: currentIndex, onTap: onNav,
            comingSoon: true,
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 24, top: 8),
            child: Text(
              'tocmanager v1.0.0',
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset('assets/icon.png', width: 34, height: 34),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'tocmanager',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Gestion simplifiée',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int current;
  final void Function(int) onTap;
  final bool comingSoon;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.current,
    required this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: active ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: comingSoon ? null : () => onTap(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  active ? activeIcon : icon,
                  color: active ? AppColors.primary : AppColors.textMedium,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: active ? AppColors.primary : AppColors.textMedium,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (comingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Bientôt',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
