import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tenant.dart';
import '../providers/auth_provider.dart';
import '../providers/tenant_provider.dart';
import '../theme/app_theme.dart';

class SelectMagasinScreen extends StatelessWidget {
  final bool allowBackPop;

  const SelectMagasinScreen({super.key, this.allowBackPop = false});

  Future<void> _onSelectMagasin(BuildContext context, MagasinModel m) async {
    await context.read<TenantProvider>().selectMagasin(m);
    if (allowBackPop && context.mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onPasser(BuildContext context) async {
    await context.read<TenantProvider>().enterConsolidatedMode(openReports: true);
    if (allowBackPop && context.mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantProvider>();
    final magasins = tenant.magasins;
    final canConsolidate = tenant.canConsolidate;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          tenant.currentBoutique?.displayName ?? 'Choix du Point de Vente',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (canConsolidate)
            TextButton.icon(
              onPressed: () => _onPasser(context),
              icon: const Icon(Icons.skip_next_rounded, color: AppColors.primary),
              label: const Text(
                'Passer',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          if (!allowBackPop)
            IconButton(
              tooltip: 'Déconnexion',
              icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
              onPressed: () async {
                final tenant = context.read<TenantProvider>();
                await context.read<AuthProvider>().logout();
                tenant.reset();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderCard(canConsolidate: canConsolidate),
              const SizedBox(height: 20),
              const Text(
                'MAGASINS DISPONIBLES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: magasins.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.store_mall_directory_outlined, size: 48, color: AppColors.textLight),
                            const SizedBox(height: 12),
                            const Text(
                              'Aucun point de vente attribué à ce compte.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMedium, fontSize: 13),
                            ),
                            if (tenant.boutiques.length > 1) ...[
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => tenant.reset(),
                                child: const Text('Revenir'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: magasins.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final m = magasins[idx];
                          return _MagasinCard(
                            magasin: m,
                            isSelected: tenant.currentMagasin?.id == m.id,
                            onTap: () => _onSelectMagasin(context, m),
                          );
                        },
                      ),
              ),
              if (canConsolidate)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _onPasser(context),
                    icon: const Icon(Icons.trending_up_rounded, color: AppColors.primary),
                    label: const Text(
                      'Passer à la Vue Financière Consolidée',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final bool canConsolidate;
  const _HeaderCard({required this.canConsolidate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store_mall_directory_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canConsolidate ? 'Vue Propriétaire' : 'Session Collaborateur',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  canConsolidate
                      ? 'Sélectionnez une caisse ou appuyez sur Passer pour consulter les rapports consolidés.'
                      : 'Veuillez sélectionner le point de vente actif pour ce terminal.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MagasinCard extends StatelessWidget {
  final MagasinModel magasin;
  final bool isSelected;
  final VoidCallback onTap;

  const _MagasinCard({required this.magasin, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconColor = magasin.isWarehouse ? AppColors.purple : AppColors.primary;
    final bgColor = magasin.isWarehouse ? AppColors.purpleLight : AppColors.primaryLight;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(magasin.isWarehouse ? Icons.warehouse_rounded : Icons.point_of_sale_rounded, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(magasin.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  if ((magasin.address ?? '').isNotEmpty)
                    Text(magasin.address!, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
