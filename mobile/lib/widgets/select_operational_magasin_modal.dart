import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tenant.dart';
import '../providers/tenant_provider.dart';
import '../theme/app_theme.dart';

class SelectOperationalMagasinModal extends StatelessWidget {
  final bool isSale;

  const SelectOperationalMagasinModal({super.key, required this.isSale});

  static Future<MagasinModel?> show(
    BuildContext context, {
    required bool isSale,
  }) {
    return showModalBottomSheet<MagasinModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectOperationalMagasinModal(isSale: isSale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = context.watch<TenantProvider>().operationalMagasins(isSale: isSale);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSale ? 'Choisir le point de vente' : 'Choisir le dépôt / magasin',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSale
                          ? 'Requis en vue consolidée pour encaisser et décrémenter le stock du bon magasin.'
                          : 'Sélectionnez le magasin ou entrepôt qui reçoit le stock.',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (options.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Aucun point de vente disponible pour cette opération.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMedium),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final m = options[idx];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.divider),
                    ),
                    leading: Icon(
                      m.isWarehouse ? Icons.warehouse_rounded : Icons.point_of_sale_rounded,
                      color: m.isWarehouse ? AppColors.purple : AppColors.primary,
                    ),
                    title: Text(
                      m.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: (m.address ?? '').isNotEmpty ? Text(m.address!) : null,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(ctx).pop(m),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
