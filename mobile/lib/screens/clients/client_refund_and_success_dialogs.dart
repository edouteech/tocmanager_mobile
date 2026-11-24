import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../providers/client_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/client_payment_pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';

void showClientAvoirRefundDialog(
  BuildContext context,
  Client client,
  ClientProvider provider,
) {
  final amountCtrl = TextEditingController(text: client.avoirAmount.toStringAsFixed(0));
  String paymentMethod = 'Espèces';
  final paymentMethods = ['Espèces', 'Mobile Money', 'Carte', 'Virement'];

  showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Solder / Rembourser l\'Avoir',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.purple.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.purple.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client : ${client.name}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      'Avoir disponible : ${client.avoirAmount.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.purple, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Montant à rembourser (FCFA)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              const Text('Mode de versement :',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => paymentMethod = val);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(amountCtrl.text);
              if (val == null || val <= 0) {
                AppToast.showError(context, 'Veuillez saisir un montant de remboursement valide (> 0 FCFA).');
                return;
              }
              Navigator.pop(dialogCtx);
              await provider.recordAvoirRefund(client: client, refundAmount: val);
              if (context.mounted) {
                AppToast.showSuccess(context, 'Avoir remboursé avec succès ! Solde mis à jour.');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple),
            child: const Text('Confirmer le remboursement'),
          ),
        ],
      ),
    ),
  );
}

void showClientPaymentSuccessOptions(
  BuildContext context, {
  required Client client,
  required double amountPaid,
  required String paymentMethod,
  required double previousBalance,
}) {
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.success),
          SizedBox(width: 8),
          Text('Versement Enregistré', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
      content: Text('Le versement de ${amountPaid.toStringAsFixed(0)} FCFA ($paymentMethod) a été enregistré avec succès.'),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        OutlinedButton.icon(
          onPressed: () {
            final settings = context.read<SettingsProvider>().settings;
            ClientPaymentPdfService.sharePaymentReceipt(
              context,
              client: client,
              amountPaid: amountPaid,
              paymentMethod: paymentMethod,
              previousBalance: previousBalance,
              storeSettings: settings,
            );
          },
          icon: const Icon(Icons.share_outlined, size: 18),
          label: const Text('Partager le reçu'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            final settings = context.read<SettingsProvider>().settings;
            ClientPaymentPdfService.downloadPaymentReceipt(
              context,
              client: client,
              amountPaid: amountPaid,
              paymentMethod: paymentMethod,
              previousBalance: previousBalance,
              storeSettings: settings,
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text('Télécharger le reçu (PDF)'),
        ),
        TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Fermer')),
      ],
    ),
  );
}
