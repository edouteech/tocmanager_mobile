import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/client.dart';
import '../../models/vente.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vente_provider.dart';
import '../../theme/app_theme.dart';
import 'client_detail_sales_list.dart';

void showClientDetailSheet(
  BuildContext context,
  Client client,
  NumberFormat formatter, {
  required void Function(List<Vente> debtSales) onPayGlobal,
  required VoidCallback onRefundAvoir,
  required void Function(Vente v) onPayTicket,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Consumer<VenteProvider>(
      builder: (context, venteProvider, _) {
        final clientSales = venteProvider.items.where((v) {
          final matchId = client.id != null && v.clientId == client.id;
          final matchName = v.clientName?.trim().toLowerCase() == client.name.trim().toLowerCase();
          return matchId || matchName;
        }).toList();

        final debtSales = clientSales.where((v) => v.isCredit).toList();
        final bannerColor = client.hasCreance
            ? AppColors.warning
            : (client.hasAvoir ? AppColors.purple : AppColors.success);

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: client.balance > 0 ? AppColors.warning.withAlpha(30) : AppColors.primarySurface,
                      child: Text(
                        client.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: client.balance > 0 ? AppColors.warning : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(client.name,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                          Text(client.phone ?? 'Pas de numéro',
                              style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                if (client.email != null && client.email!.isNotEmpty) ...[
                  _infoRow(Icons.email_outlined, 'Email', client.email!),
                  const SizedBox(height: 8),
                ],
                if (client.address != null && client.address!.isNotEmpty) ...[
                  _infoRow(Icons.location_on_outlined, 'Adresse', client.address!),
                  const SizedBox(height: 8),
                ],
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bannerColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: bannerColor.withAlpha(60)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            client.hasCreance
                                ? Icons.account_balance_wallet_outlined
                                : (client.hasAvoir ? Icons.savings_outlined : Icons.check_circle_outline),
                            color: bannerColor,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                client.hasCreance
                                    ? 'Créance / Dette Totale'
                                    : (client.hasAvoir ? 'Avoir / Solde Créditeur' : 'Solde client'),
                                style: const TextStyle(fontSize: 11, color: AppColors.textMedium, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                client.hasAvoir ? '${formatter.format(client.avoirAmount)} (Avoir)' : formatter.format(client.balance),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: bannerColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (client.hasCreance)
                        ElevatedButton.icon(
                          onPressed: () => onPayGlobal(debtSales),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          icon: const Icon(Icons.payments_outlined, size: 16),
                          label: const Text('Régler', style: TextStyle(fontSize: 12)),
                        ),
                      if (client.hasAvoir)
                        ElevatedButton.icon(
                          onPressed: onRefundAvoir,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purple,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          icon: const Icon(Icons.savings_outlined, size: 16),
                          label: const Text('Solder l\'avoir', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                if (client.balance > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withAlpha(30)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.mark_chat_unread_outlined, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text('Relance client',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            final settings = context.read<SettingsProvider>().settings;
                            final storeName = settings.name.isNotEmpty ? settings.name : 'notre boutique';
                            final message =
                                'Bonjour ${client.name}, nous vous rappelons votre solde débiteur de ${formatter.format(client.balance)} auprès de $storeName. Merci pour votre confiance !';
                            Share.share(message);
                          },
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                          icon: const Icon(Icons.send_outlined, size: 14),
                          label: const Text('Envoyer rappel', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                ClientDetailSalesList(
                  clientSales: clientSales,
                  debtSales: debtSales,
                  formatter: formatter,
                  onSettleTicket: onPayTicket,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onEdit();
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Modifier'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onDelete();
                      },
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget _infoRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 16, color: AppColors.textMedium),
      const SizedBox(width: 8),
      Text('$label : ', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    ],
  );
}
