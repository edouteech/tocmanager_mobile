import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/tenant_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stock_alert_modal.dart';
import '../../widgets/sync_status_badge.dart';
import '../select_magasin_screen.dart';

class HomeSliverAppBar extends StatelessWidget {
  final VoidCallback? onOpenDrawer;

  const HomeSliverAppBar({super.key, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.divider,
      titleSpacing: 8,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textDark),
            onPressed: () => onOpenDrawer?.call(),
            tooltip: 'Menu principal',
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => onOpenDrawer?.call(),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Image.asset('assets/logo.png', height: 26),
            ),
          ),
        ],
      ),
      actions: [
        const SyncStatusBadge(),
        Consumer<ProductProvider>(
          builder: (context, productProv, _) {
            final alertCount = productProv.products.where((p) => p.isLowStock).length;
            return Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.textMedium),
                  onPressed: () => StockAlertModal.show(context),
                ),
                if (alertCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        alertCount > 9 ? '9+' : '$alertCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class HomeGreetingCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final VoidCallback onReloadData;

  const HomeGreetingCard({
    super.key,
    required this.stats,
    required this.onReloadData,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
    final dateStr = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now());
    final tenant = context.watch<TenantProvider>();
    final boutiqueName = tenant.currentBoutique?.displayName;
    final magasinLabel = tenant.isConsolidatedMode ? 'Vue Consolidée' : tenant.currentMagasin?.name;
    final canSwitch = tenant.canConsolidate || tenant.magasins.length > 1 || tenant.boutiques.length > 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(70),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting !',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(dateStr, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                if (boutiqueName != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: canSwitch
                        ? () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SelectMagasinScreen(allowBackPop: true),
                              ),
                            );
                            if (context.mounted) onReloadData();
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.store_mall_directory_outlined, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              magasinLabel != null ? '$boutiqueName · $magasinLabel' : boutiqueName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (canSwitch) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 14),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${stats['productCount'] ?? 0} produits  •  ${stats['categoryCount'] ?? 0} catégories',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withAlpha(40), shape: BoxShape.circle),
            child: const Icon(Icons.storefront_outlined, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}
