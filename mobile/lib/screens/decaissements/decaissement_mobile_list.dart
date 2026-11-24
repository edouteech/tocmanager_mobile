import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/decaissement.dart';
import '../../theme/app_theme.dart';
import 'decaissement_filter_helpers.dart';

class DecaissementEmptyState extends StatelessWidget {
  const DecaissementEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.danger.withAlpha(20), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_upward, size: 48, color: AppColors.danger),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune dépense enregistrée',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          const Text('Enregistrez votre première sortie de caisse', style: TextStyle(color: AppColors.textMedium)),
        ],
      ),
    );
  }
}

class DecaissementMobileListView extends StatelessWidget {
  final List<Decaissement> items;
  final NumberFormat formatter;
  final ValueChanged<Decaissement> onTapItem;

  const DecaissementMobileListView({
    super.key,
    required this.items,
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
        final d = items[i];
        final catColor = decaissementCategoryColor(d.category);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.divider),
          ),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onTapItem(d),
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
                          color: catColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: catColor.withAlpha(50)),
                        ),
                        child: Text(
                          d.category,
                          style: TextStyle(color: catColor, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ),
                      Text(dateFormat.format(d.date),
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    d.description,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (d.notes != null && d.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.notes_outlined, size: 14, color: AppColors.textMedium),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Notes : ${d.notes}',
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
                      Text(
                        d.reference ?? 'Sortie caisse',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMedium, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        formatter.format(d.amount),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.danger),
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
