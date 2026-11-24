import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/approvisionnement.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';

class ApprovisionEmptyState extends StatelessWidget {
  const ApprovisionEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_downward, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun approvisionnement',
            style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text('Enregistrez votre premier approvisionnement', style: TextStyle(color: AppColors.textMedium)),
        ],
      ),
    );
  }
}

class ApprovisionMobileListView extends StatelessWidget {
  final List<Approvisionnement> items;
  final List<Product> products;
  final NumberFormat formatter;
  final void Function(Approvisionnement appro, String prodName) onTapItem;

  const ApprovisionMobileListView({
    super.key,
    required this.items,
    required this.products,
    required this.formatter,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final a = items[i];
        final prod = products.where((p) => p.id == a.productId).firstOrNull;
        final prodName = prod?.name ?? 'Produit #${a.productId}';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.divider),
          ),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onTapItem(a, prodName),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: a.isCredit ? AppColors.danger.withAlpha(20) : AppColors.success.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: a.isCredit ? AppColors.danger.withAlpha(50) : AppColors.success.withAlpha(50),
                          ),
                        ),
                        child: Text(
                          a.isCredit ? 'À crédit (Reste: ${formatter.format(a.remainingAmount)})' : 'Payé Cash',
                          style: TextStyle(
                            color: a.isCredit ? AppColors.danger : AppColors.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(dateFormat.format(a.date),
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(prodName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.textMedium),
                      const SizedBox(width: 4),
                      Text(
                        'Qté : ${a.quantity} ${prod?.unit ?? 'unités'} × ${formatter.format(a.unitPrice)}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                      ),
                    ],
                  ),
                  if (a.supplier != null && a.supplier!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.business_outlined, size: 14, color: AppColors.textMedium),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Fournisseur : ${a.supplier}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Achat :',
                          style: TextStyle(fontSize: 12, color: AppColors.textMedium, fontWeight: FontWeight.w600)),
                      Text(
                        formatter.format(a.total),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
