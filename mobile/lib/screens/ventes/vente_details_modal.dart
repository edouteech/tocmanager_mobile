import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/vente.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vente_provider.dart';
import '../../theme/app_theme.dart';
import 'vente_details_footer.dart';
import 'vente_filter_helpers.dart';

void showVenteDetailsModal(BuildContext context, Vente initialVente) {
  final rootCtx = context;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (modalCtx) => Consumer<VenteProvider>(
      builder: (_, provider, __) {
        final vente = provider.items.where((v) => v.id != null && v.id == initialVente.id).firstOrNull ?? initialVente;
        final currency = rootCtx.read<SettingsProvider>().settings.currency;
        final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: currency, decimalDigits: 0);
        final dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
        final ticket = vente.ticketNumber.isNotEmpty ? vente.ticketNumber : 'VNT-${vente.id ?? 0}';
        final clientLabel = (vente.clientName != null && vente.clientName!.isNotEmpty)
            ? vente.clientName!
            : 'Client occasionnel';

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (_, scrollCtrl) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark),
                          ),
                          Text(
                            dateFmt.format(vente.date),
                            style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMedium),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _infoPill(Icons.person_outline, clientLabel, AppColors.primary),
                    _infoPill(Icons.payments_outlined, vente.paymentMethod, AppColors.success),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Articles achetés (${vente.items.length})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    itemCount: vente.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 12),
                    itemBuilder: (_, idx) {
                      final item = vente.items[idx];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                                ),
                                Text(
                                  '${formatVenteQty(item.quantity)} x ${formatter.format(item.unitPrice)}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatter.format(item.total),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                VenteDetailsTotalsAndActions(
                  modalCtx: modalCtx,
                  rootCtx: rootCtx,
                  vente: vente,
                  formatter: formatter,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _infoPill(IconData icon, String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withAlpha(18),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    ),
  );
}
