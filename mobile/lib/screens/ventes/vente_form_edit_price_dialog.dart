import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/vente.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';

void showVenteEditUnitPriceModal(
  BuildContext context, {
  required VenteItem item,
  required Product? prod,
  required Future<void> Function(double newPrice, String applyTarget) onConfirm,
}) {
  final priceCtrl = TextEditingController(
    text: item.unitPrice % 1 == 0 ? item.unitPrice.toInt().toString() : item.unitPrice.toString(),
  );
  String applyTarget = 'sale_only';
  bool submitting = false;

  showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Modifier le prix unitaire', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item.productName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMedium),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau prix unitaire (FCFA)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _targetOption(
              title: 'Pour cette vente uniquement',
              selected: applyTarget == 'sale_only',
              onTap: () => setDialogState(() => applyTarget = 'sale_only'),
            ),
            if (prod != null) ...[
              const SizedBox(height: 6),
              _targetOption(
                title: 'Également dans le catalogue produit',
                selected: applyTarget == 'global_catalog',
                onTap: () => setDialogState(() => applyTarget = 'global_catalog'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: submitting ? null : () => Navigator.pop(dialogCtx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: submitting
                ? null
                : () async {
                    final parsed = double.tryParse(priceCtrl.text.trim().replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) {
                      AppToast.showError(context, 'Prix unitaire invalide (> 0).');
                      return;
                    }
                    setDialogState(() => submitting = true);
                    await onConfirm(parsed, applyTarget);
                    if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    ),
  );
}

Widget _targetOption({
  required String title,
  required bool selected,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryLight : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: selected ? AppColors.primary : AppColors.textLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primaryDark : AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
