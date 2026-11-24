import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/supplier.dart';
import '../../theme/app_theme.dart';

void showSupplierDetailSheet(
  BuildContext context,
  Supplier supplier,
  NumberFormat formatter, {
  required VoidCallback onPay,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primarySurface,
                  child: Icon(Icons.business, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(supplier.name,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                      Text(supplier.contactPerson ?? 'Fournisseur',
                          style: const TextStyle(color: AppColors.textMedium, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            if (supplier.phone != null && supplier.phone!.isNotEmpty) ...[
              _infoRow(Icons.phone_outlined, 'Téléphone', supplier.phone!),
              const SizedBox(height: 10),
            ],
            if (supplier.email != null && supplier.email!.isNotEmpty) ...[
              _infoRow(Icons.email_outlined, 'Email', supplier.email!),
              const SizedBox(height: 10),
            ],
            if (supplier.address != null && supplier.address!.isNotEmpty) ...[
              _infoRow(Icons.location_on_outlined, 'Adresse', supplier.address!),
              const SizedBox(height: 10),
            ],
            _infoRow(
              Icons.account_balance_wallet_outlined,
              'Factures Impayées',
              formatter.format(supplier.balance),
              color: supplier.balance > 0 ? AppColors.danger : AppColors.success,
            ),
            const SizedBox(height: 20),
            if (supplier.balance > 0) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onPay();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('Enregistrer un règlement', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onEdit();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Modifier'),
                  ),
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
    ),
  );
}

Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
  return Row(
    children: [
      Icon(icon, size: 16, color: AppColors.textMedium),
      const SizedBox(width: 8),
      Text('$label : ', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color ?? AppColors.textDark)),
    ],
  );
}
