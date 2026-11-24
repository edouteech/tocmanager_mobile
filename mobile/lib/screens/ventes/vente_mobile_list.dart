import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vente.dart';
import '../../theme/app_theme.dart';

class VenteEmptyState extends StatelessWidget {
  const VenteEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune vente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enregistrez votre première vente',
              style: TextStyle(fontSize: 13, color: AppColors.textMedium),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class VenteMobileCardList extends StatelessWidget {
  final List<Vente> items;
  final NumberFormat formatter;
  final ValueChanged<Vente> onTapVente;

  const VenteMobileCardList({
    super.key,
    required this.items,
    required this.formatter,
    required this.onTapVente,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final v = items[index];
        final ticket = v.ticketNumber.isNotEmpty ? v.ticketNumber : 'VNT-${v.id ?? 0}';
        final clientLabel = (v.clientName != null && v.clientName!.isNotEmpty) ? v.clientName! : 'Occasionnel';
        final statusColor = v.isCredit ? AppColors.warning : AppColors.success;

        return InkWell(
          onTap: () => onTapVente(v),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(24),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.point_of_sale, color: statusColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            dateFmt.format(v.date),
                            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        v.isCredit ? 'Crédit (${formatter.format(v.remainingAmount)})' : 'Payé',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clientLabel,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${v.items.length} article(s) - ${v.paymentMethod}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatter.format(v.totalAmount),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
                        ),
                        const Text(
                          'Détails >',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
