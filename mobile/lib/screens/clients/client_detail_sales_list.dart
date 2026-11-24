import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/vente.dart';
import '../../theme/app_theme.dart';
import '../vente_screen.dart';

class ClientDetailSalesList extends StatelessWidget {
  final List<Vente> clientSales;
  final List<Vente> debtSales;
  final NumberFormat formatter;
  final ValueChanged<Vente> onSettleTicket;

  const ClientDetailSalesList({
    super.key,
    required this.clientSales,
    required this.debtSales,
    required this.formatter,
    required this.onSettleTicket,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ventes liées / Créances (${clientSales.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
            ),
            if (debtSales.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${debtSales.length} dette(s) en cours',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (clientSales.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: Text('Aucune vente enregistrée pour ce client',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight)),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: clientSales.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final v = clientSales[idx];
              return Material(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => showVenteDetailsModal(context, v),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: v.isCredit ? AppColors.warning.withAlpha(80) : AppColors.divider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: v.isCredit ? AppColors.warningLight : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            color: v.isCredit ? AppColors.warning : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.ticketNumber.isNotEmpty ? v.ticketNumber : 'Vente #${v.id}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(v.date)} • ${v.items.length} article(s)',
                                style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatter.format(v.totalAmount),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
                            ),
                            if (v.isCredit) ...[
                              Text(
                                'Reste: ${formatter.format(v.remainingAmount)}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => onSettleTicket(v),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withAlpha(20),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.success.withAlpha(60)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.payments_outlined, size: 12, color: AppColors.success),
                                      SizedBox(width: 4),
                                      Text('Régler ticket',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)),
                                    ],
                                  ),
                                ),
                              ),
                            ] else
                              const Text('Payé',
                                  style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 18, color: AppColors.textLight),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
