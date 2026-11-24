import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/vente.dart';
import '../../providers/client_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vente_provider.dart';
import '../../services/ticket_pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import 'vente_form_modal.dart';

class VenteDetailsTotalsAndActions extends StatelessWidget {
  final BuildContext modalCtx;
  final BuildContext rootCtx;
  final Vente vente;
  final NumberFormat formatter;

  const VenteDetailsTotalsAndActions({
    super.key,
    required this.modalCtx,
    required this.rootCtx,
    required this.vente,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final settings = rootCtx.read<SettingsProvider>().settings;
    final hasChange = vente.paidAmount > vente.totalAmount + 0.01;
    final hasNotes = vente.notes != null && vente.notes!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        if (vente.discountAmount > 0) ...[
          _kvRow('Sous-total brut', formatter.format(vente.subtotalAmount)),
          const SizedBox(height: 4),
          _kvRow('Remise appliquée', '- ${formatter.format(vente.discountAmount)}', color: AppColors.danger),
          const SizedBox(height: 6),
        ],
        _kvRow('TOTAL NET', formatter.format(vente.totalAmount), isBold: true, fontSize: 16),
        const SizedBox(height: 4),
        _kvRow('Montant Versé (${vente.paymentMethod})', formatter.format(vente.paidAmount), color: AppColors.success),
        if (hasChange) ...[
          const SizedBox(height: 4),
          _kvRow('Monnaie / Surplus', formatter.format(vente.paidAmount - vente.totalAmount), color: AppColors.purple),
        ],
        if (vente.isCredit) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withAlpha(80)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reste à payer (Crédit)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.warning),
                ),
                Text(
                  formatter.format(vente.remainingAmount),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.warning),
                ),
              ],
            ),
          ),
        ],
        if (hasNotes) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
            child: Text('Note : ${vente.notes!.trim()}', style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openEditModal(context),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Modifier'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => TicketPdfService.shareTicketPdf(rootCtx, vente, settings),
                icon: const Icon(Icons.share_outlined, size: 17),
                label: const Text('Partager'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => TicketPdfService.downloadTicketPdf(rootCtx, vente, settings),
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Télécharger'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.dangerLight,
                foregroundColor: AppColors.danger,
                padding: const EdgeInsets.all(12),
              ),
              tooltip: 'Supprimer la vente',
              onPressed: () => showConfirmDeleteVenteModal(
                modalCtx,
                vente,
                rootCtx.read<VenteProvider>(),
                rootCtx.read<ProductProvider>(),
                parentContext: modalCtx,
                clientProvider: rootCtx.read<ClientProvider>(),
              ),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ],
    );
  }

  void _openEditModal(BuildContext context) {
    final venteProv = rootCtx.read<VenteProvider>();
    final productProv = rootCtx.read<ProductProvider>();
    final clientProv = rootCtx.read<ClientProvider>();
    Navigator.pop(modalCtx);
    showModalBottomSheet(
      context: rootCtx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => VenteFormModal(
        initialVente: vente,
        onSave: (updated) async {
          await venteProv.update(updated);
          await productProv.load();
          await clientProv.loadClients();
        },
      ),
    );
  }

  Widget _kvRow(String label, String value, {bool isBold = false, double fontSize = 13, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: color ?? AppColors.textMedium,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: color ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

void showConfirmDeleteVenteModal(
  BuildContext context,
  Vente vente,
  VenteProvider venteProvider,
  ProductProvider productProvider, {
  BuildContext? parentContext,
  ClientProvider? clientProvider,
}) {
  final clientProv = clientProvider ?? context.read<ClientProvider>();
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Supprimer la vente ?', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text(
        'Le ticket ${vente.ticketNumber} sera supprimé, le stock des articles sera restauré et le solde client ajusté.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () async {
            Navigator.pop(dialogCtx);
            await venteProvider.delete(vente);
            await productProvider.load();
            await clientProv.loadClients();
            if (parentContext != null && parentContext.mounted) {
              Navigator.pop(parentContext);
            }
            if (context.mounted) {
              AppToast.showSuccess(context, 'Vente supprimée et stock restauré.');
            }
          },
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}
