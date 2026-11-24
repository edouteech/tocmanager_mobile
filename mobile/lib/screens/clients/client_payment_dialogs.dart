import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/client.dart';
import '../../models/vente.dart';
import '../../providers/client_provider.dart';
import '../../providers/vente_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import 'client_refund_and_success_dialogs.dart';

const List<String> _kPaymentMethods = ['Espèces', 'Mobile Money', 'Carte', 'Virement'];

void showClientGlobalPaymentDialog(
  BuildContext context,
  Client client,
  ClientProvider provider, [
  List<Vente>? debtSales,
]) {
  final amountCtrl = TextEditingController(text: client.balance.toStringAsFixed(0));
  String paymentMethod = 'Espèces';
  final previousBalance = client.balance;

  showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Règlement Global de Créances', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Solde débiteur : ${client.balance.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.warning, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Le versement sera alloué en priorité aux tickets de vente les plus anciens.',
                style: TextStyle(fontSize: 11, color: AppColors.textLight, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Montant versé (FCFA)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              const Text('Mode de règlement :',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _kPaymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
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
                AppToast.showError(context, 'Veuillez saisir un montant de versement valide (> 0 FCFA).');
                return;
              }
              Navigator.pop(dialogCtx);
              final allDebtSales = debtSales ??
                  context.read<VenteProvider>().items.where((v) => v.clientId == client.id && v.isCredit).toList();
              await provider.recordGlobalPaymentAllocated(
                client: client,
                paymentAmount: val,
                debtSales: allDebtSales,
              );
              if (context.mounted) await context.read<VenteProvider>().load();
              if (context.mounted) {
                showClientPaymentSuccessOptions(
                  context,
                  client: client,
                  amountPaid: val,
                  paymentMethod: paymentMethod,
                  previousBalance: previousBalance,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Valider le versement'),
          ),
        ],
      ),
    ),
  );
}

void showClientTicketPaymentDialog(
  BuildContext context,
  Client client,
  Vente vente,
  ClientProvider provider,
) {
  final amountCtrl = TextEditingController(text: vente.remainingAmount.toStringAsFixed(0));
  String paymentMethod = 'Espèces';
  final previousBalance = client.balance;

  showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Règlement Ticket ${vente.ticketNumber}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ticket : ${vente.ticketNumber}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      'Reste à payer sur ce ticket : ${vente.remainingAmount.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.warning, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Montant du règlement (FCFA)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              const Text('Mode de règlement :',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: paymentMethod,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _kPaymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
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
                AppToast.showError(context, 'Veuillez saisir un montant valide (> 0 FCFA).');
                return;
              }
              Navigator.pop(dialogCtx);
              await provider.recordPaymentForVente(client: client, vente: vente, paymentAmount: val);
              if (context.mounted) await context.read<VenteProvider>().load();
              if (context.mounted) {
                showClientPaymentSuccessOptions(
                  context,
                  client: client,
                  amountPaid: val,
                  paymentMethod: paymentMethod,
                  previousBalance: previousBalance,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Valider le versement'),
          ),
        ],
      ),
    ),
  );
}
