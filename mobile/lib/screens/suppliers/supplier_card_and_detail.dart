import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/supplier.dart';
import '../../providers/supplier_provider.dart';
import '../../theme/app_theme.dart';

class SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final NumberFormat formatter;
  final VoidCallback onTap;

  const SupplierCard({
    super.key,
    required this.supplier,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDebt = supplier.balance > 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primarySurface,
                child: Icon(Icons.business, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(supplier.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
                    if (supplier.contactPerson != null && supplier.contactPerson!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Contact: ${supplier.contactPerson}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                    ],
                    if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 12, color: AppColors.textMedium),
                          const SizedBox(width: 4),
                          Text(supplier.phone!, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasDebt ? AppColors.danger.withAlpha(30) : AppColors.success.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasDebt ? 'Impayé: ${formatter.format(supplier.balance)}' : 'Solde nul',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: hasDebt ? AppColors.danger : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void confirmDeleteSupplierDialog(BuildContext context, Supplier supplier, SupplierProvider provider) {
  if (supplier.balance > 0) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
            SizedBox(width: 8),
            Text('Suppression impossible', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Text(
          'Le fournisseur "${supplier.name}" a un reste dû de ${formatter.format(supplier.balance)}.\n\nVeuillez d\'abord solder ce règlement avant de supprimer ce fournisseur.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Supprimer fournisseur', style: TextStyle(fontWeight: FontWeight.w700)),
      content: Text('Supprimer "${supplier.name}" ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            await provider.deleteSupplier(supplier.id!);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
}
