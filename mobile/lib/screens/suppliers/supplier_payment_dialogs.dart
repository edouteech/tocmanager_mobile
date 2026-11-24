import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/supplier.dart';
import '../../providers/approvisionnement_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../services/supplier_payment_pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';

void showSupplierPaymentDialog(BuildContext context, Supplier supplier, NumberFormat formatter) {
  final amountCtrl = TextEditingController(text: supplier.balance.toStringAsFixed(0));
  String paymentMethod = 'Espèces';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, color: AppColors.success, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Règlement Fournisseur : ${supplier.name}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withAlpha(50)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Dette actuelle :',
                          style: TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600)),
                      Text(formatter.format(supplier.balance),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.danger)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Mode de règlement', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['Espèces', 'Mobile Money', 'Virement', 'Chèque'].map((mode) {
                    final selected = paymentMethod == mode;
                    return ChoiceChip(
                      label: Text(mode,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? Colors.white : AppColors.textDark)),
                      selected: selected,
                      selectedColor: AppColors.success,
                      backgroundColor: AppColors.background,
                      side: BorderSide(color: selected ? AppColors.success : AppColors.divider),
                      onSelected: (val) {
                        if (val) setSheetState(() => paymentMethod = mode);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Montant versé',
                    suffixText: 'F',
                    filled: true,
                    fillColor: AppColors.primarySurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final paid = double.tryParse(amountCtrl.text.trim()) ?? 0;
                      if (paid <= 0) {
                        AppToast.showError(context, 'Saisissez un montant valide');
                        return;
                      }

                      await context.read<SupplierProvider>().recordSupplierPayment(supplier.id!, paid);
                      if (!context.mounted) return;
                      await context.read<ApprovisionnementProvider>().load();
                      if (!context.mounted) return;
                      final updatedSupplier =
                          context.read<SupplierProvider>().suppliers.where((s) => s.id == supplier.id).firstOrNull ??
                              supplier;
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        showSupplierPaymentSuccessDialog(
                            context, updatedSupplier, paid, paymentMethod, updatedSupplier.balance);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Valider le versement', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

void showSupplierPaymentSuccessDialog(
  BuildContext context,
  Supplier supplier,
  double amountPaid,
  String paymentMethod,
  double remainingDebt,
) {
  final settings = context.read<SettingsProvider>().settings;
  final fmt = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.success, size: 24),
          SizedBox(width: 8),
          Text('Règlement enregistré', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Un versement de ${fmt.format(amountPaid)} a été imputé au fournisseur "${supplier.name}".'),
          const SizedBox(height: 12),
          Text('Nouveau solde dû : ${fmt.format(remainingDebt)}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
        ],
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () => SupplierPaymentPdfService.shareReceipt(
            context: context,
            supplier: supplier,
            amountPaid: amountPaid,
            paymentMethod: paymentMethod,
            remainingDebt: remainingDebt,
            settings: settings,
          ),
          icon: const Icon(Icons.share_outlined, size: 16),
          label: const Text('Partager'),
        ),
        ElevatedButton.icon(
          onPressed: () => SupplierPaymentPdfService.downloadReceipt(
            context: context,
            supplier: supplier,
            amountPaid: amountPaid,
            paymentMethod: paymentMethod,
            remainingDebt: remainingDebt,
            settings: settings,
          ),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          icon: const Icon(Icons.download_outlined, size: 16),
          label: const Text('Télécharger Reçu'),
        ),
      ],
    ),
  );
}
